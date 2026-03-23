import '../domain/models/attendance_type.dart';
import '../domain/models/calendar_filter_state.dart';
import '../domain/models/calendar_item.dart';
import '../domain/models/calendar_item_source.dart';
import '../domain/models/calendar_item_status.dart';
import '../domain/models/calendar_layer.dart';
import '../domain/models/leave_status.dart';
import '../domain/models/leave_type.dart';
import '../domain/models/time_range.dart';
import '../domain/services/polish_holiday_service.dart';
import 'calendar_remote_datasource.dart';

abstract class CalendarRepository {
  Future<List<CalendarItem>> fetchItems({
    required TimeRange range,
    required CalendarFilterState filters,
  });
}

class SupabaseCalendarRepository implements CalendarRepository {
  SupabaseCalendarRepository(this._remoteDataSource);

  final CalendarRemoteDataSource _remoteDataSource;
  final PolishHolidayService _holidayService = const PolishHolidayService();

  static const Set<AttendanceType> _leaveAttendanceTypes = {
    AttendanceType.urlopWypoczynkowy,
    AttendanceType.urlopNagrodowy,
    AttendanceType.urlopDodatkowy,
    AttendanceType.l4,
    AttendanceType.podrozSluzbowa,
    AttendanceType.poSluzbie,
  };

  @override
  Future<List<CalendarItem>> fetchItems({
    required TimeRange range,
    required CalendarFilterState filters,
  }) async {
    final results = await Future.wait([
      _remoteDataSource.fetchCalendarEventsRaw(
        rangeStart: range.start,
        rangeEnd: range.end,
      ),
      _remoteDataSource.fetchTasksRaw(
        rangeStart: range.start,
        rangeEnd: range.end,
      ),
      _remoteDataSource.fetchAttendanceEntriesRaw(
        rangeStart: range.start,
        rangeEnd: range.end,
      ),
    ]);

    final eventsRaw = results[0];
    final tasksRaw = results[1];
    final attendanceRaw = results[2];

    final profileIds = <String>{};

    for (final row in tasksRaw) {
      final personId = _readStringValue(row['responsible_person_id']);
      if (personId != null && personId.isNotEmpty) {
        profileIds.add(personId);
      }
    }

    for (final row in attendanceRaw) {
      final personId = _readStringValue(row['person_id']);
      if (personId != null && personId.isNotEmpty) {
        profileIds.add(personId);
      }
    }

    final profilesById = await _remoteDataSource.fetchProfilesByIds(profileIds);

    final items = <CalendarItem>[
      ...eventsRaw.map(_mapEvent),
      ...tasksRaw.map((row) => _mapTask(row, profilesById)),
      ...attendanceRaw.map((row) => _mapAttendance(row, profilesById)),
      if (filters.showPolishHolidays) ..._buildHolidayItems(range),
    ];

    final filtered = _applyFilters(
      items: items,
      range: range,
      filters: filters,
    )..sort((a, b) {
      if (a.allDay != b.allDay) {
        return a.allDay ? -1 : 1;
      }

      final startCompare = a.startAt.compareTo(b.startAt);
      if (startCompare != 0) {
        return startCompare;
      }

      if (a.personName != null && b.personName != null) {
        final personCompare = a.personName!.compareTo(b.personName!);
        if (personCompare != 0) {
          return personCompare;
        }
      }

      return a.title.compareTo(b.title);
    });

    return filtered;
  }

  List<CalendarItem> _applyFilters({
    required List<CalendarItem> items,
    required TimeRange range,
    required CalendarFilterState filters,
  }) {
    return items.where((item) {
      if (!item.overlaps(range.start, range.end)) {
        return false;
      }

      if (!filters.layers.contains(item.layer)) {
        return false;
      }

      if (!filters.showTasks && item.layer == CalendarLayer.tasks) {
        return false;
      }

      if (!filters.showDeadlines && item.layer == CalendarLayer.deadlines) {
        return false;
      }

      if (!filters.showEvents && item.layer == CalendarLayer.events) {
        return false;
      }

      if (!filters.showAttendance && item.layer == CalendarLayer.attendance) {
        return false;
      }

      if (!filters.showPlannedLeave &&
          item.layer == CalendarLayer.plannedLeave) {
        return false;
      }

      if (!filters.showRequestedLeave &&
          item.layer == CalendarLayer.requestedLeave) {
        return false;
      }

      if (!filters.showUnassignedItems && item.isUnassigned) {
        return false;
      }

      if (filters.sources.isNotEmpty &&
          !filters.sources.contains(item.source)) {
        return false;
      }

      if (filters.statuses.isNotEmpty &&
          !filters.statuses.contains(item.status)) {
        return false;
      }

      if (filters.attendanceTypes.isNotEmpty) {
        if (item.attendanceType == null ||
            !filters.attendanceTypes.contains(item.attendanceType)) {
          return false;
        }
      }

      if (filters.leaveTypes.isNotEmpty) {
        if (item.leaveType == null ||
            !filters.leaveTypes.contains(item.leaveType)) {
          return false;
        }
      }

      if (filters.leaveStatuses.isNotEmpty) {
        if (item.leaveStatus == null ||
            !filters.leaveStatuses.contains(item.leaveStatus)) {
          return false;
        }
      }

      if (filters.personIds.isNotEmpty) {
        if (item.personId == null || !filters.personIds.contains(item.personId)) {
          return false;
        }
      }

      if (filters.teamIds.isNotEmpty) {
        if (item.teamId == null || !filters.teamIds.contains(item.teamId)) {
          return false;
        }
      }

      if (filters.locationIds.isNotEmpty) {
        if (item.locationId == null ||
            !filters.locationIds.contains(item.locationId)) {
          return false;
        }
      }

      if (filters.onlyCritical && !item.isCritical) {
        return false;
      }

      return true;
    }).toList();
  }

  CalendarItem _mapEvent(Map<String, dynamic> row) {
    final startAt = _readDateTimeRequired(row['starts_at']);
    final isAllDay = row['is_all_day'] == true;

    final endAt = _readDateTimeNullable(row['ends_at']) ??
        (isAllDay
            ? DateTime(startAt.year, startAt.month, startAt.day + 1)
            : startAt.add(const Duration(hours: 1)));

    return CalendarItem(
      id: 'event_${_readId(row)}',
      source: CalendarItemSource.event,
      layer: CalendarLayer.events,
      status: row['is_cancelled'] == true
          ? CalendarItemStatus.cancelled
          : CalendarItemStatus.confirmed,
      title: _readStringValue(row['title']) ?? 'Wydarzenie',
      subtitle: _readStringValue(row['location']),
      description: _readStringValue(row['details']),
      startAt: startAt,
      endAt: endAt,
      allDay: isAllDay,
      personId: null,
      personName: null,
      teamId: null,
      teamName: null,
      sourceId: _readId(row),
      eventId: _readId(row),
      locationId: null,
      colorKey: 'event',
      isCritical: false,
      isLocked: false,
      isUnassigned: false,
    );
  }

  CalendarItem _mapTask(
      Map<String, dynamic> row,
      Map<String, Map<String, dynamic>> profilesById,
      ) {
    final deadline = _readDateTimeRequired(row['deadline']);
    final personId = _readStringValue(row['responsible_person_id']);
    final sectionUnit = _readStringValue(row['section_unit']);
    final priority = _readStringValue(row['priority']);
    final statusRaw = _readStringValue(row['status']) ?? 'new_task';
    final personName = _profileDisplayName(
      profilesById[personId],
      fallbackId: personId,
    );

    return CalendarItem(
      id: 'task_${_readId(row)}',
      source: CalendarItemSource.deadline,
      layer: CalendarLayer.deadlines,
      status: _mapTaskStatus(statusRaw),
      title: _readStringValue(row['title']) ?? 'Zadanie',
      subtitle: _mapTaskSubtitle(
        sectionUnit: sectionUnit,
        priority: priority,
        status: statusRaw,
      ),
      description: _readStringValue(row['description']),
      startAt: deadline,
      endAt: deadline.add(const Duration(minutes: 30)),
      allDay: false,
      personId: personId,
      personName: personName,
      teamId: sectionUnit,
      teamName: _prettifyEnumLabel(sectionUnit),
      sourceId: _readId(row),
      taskId: _readId(row),
      locationId: null,
      colorKey: 'deadline',
      isCritical: _isTaskCritical(priority),
      isLocked: false,
      isUnassigned: personId == null,
    );
  }

  CalendarItem _mapAttendance(
      Map<String, dynamic> row,
      Map<String, Map<String, dynamic>> profilesById,
      ) {
    final attendanceType = _mapAttendanceType(
      _readStringValue(row['attendance_type']),
    );

    final allDay = row['is_all_day'] == true;
    final personId = _readStringValue(row['person_id']);
    final startAt = _buildAttendanceStart(row, allDay);
    final endAt = _buildAttendanceEnd(row, allDay, startAt);
    final personName = _profileDisplayName(
      profilesById[personId],
      fallbackId: personId,
    );

    final isLeave =
        attendanceType != null && _leaveAttendanceTypes.contains(attendanceType);

    return CalendarItem(
      id: 'attendance_${_readId(row)}',
      source: isLeave
          ? CalendarItemSource.leavePlanned
          : CalendarItemSource.attendance,
      layer: isLeave ? CalendarLayer.plannedLeave : CalendarLayer.attendance,
      status: isLeave
          ? CalendarItemStatus.approved
          : CalendarItemStatus.confirmed,
      title: attendanceType?.label ?? 'Obecność',
      subtitle: _buildAttendanceSubtitle(
        startAt: startAt,
        endAt: endAt,
        allDay: allDay,
      ),
      description: _readStringValue(row['note']),
      startAt: startAt,
      endAt: endAt,
      allDay: allDay,
      personId: personId,
      personName: personName,
      teamId: null,
      teamName: null,
      sourceId: _readId(row),
      attendanceEntryId: _readId(row),
      locationId: null,
      colorKey: isLeave ? 'planned_leave' : 'attendance',
      attendanceType: attendanceType,
      leaveType: _mapLeaveTypeFromAttendance(attendanceType),
      leaveStatus: isLeave ? LeaveStatus.approved : null,
      isCritical: false,
      isLocked: true,
      isUnassigned: false,
    );
  }

  List<CalendarItem> _buildHolidayItems(TimeRange range) {
    final startYear = range.start.year;
    final endYear = range.end.subtract(const Duration(seconds: 1)).year;
    final items = <CalendarItem>[];

    for (int year = startYear; year <= endYear; year++) {
      for (final holiday in _holidayService.holidaysForYear(year)) {
        final startAt = DateTime(
          holiday.date.year,
          holiday.date.month,
          holiday.date.day,
        );
        final endAt = startAt.add(const Duration(days: 1));

        if (!(startAt.isBefore(range.end) && endAt.isAfter(range.start))) {
          continue;
        }

        items.add(
          CalendarItem(
            id: 'holiday_${holiday.date.toIso8601String()}',
            source: CalendarItemSource.event,
            layer: CalendarLayer.events,
            status: CalendarItemStatus.confirmed,
            title: holiday.name,
            subtitle: 'Święto państwowe',
            description: holiday.name,
            startAt: startAt,
            endAt: endAt,
            allDay: true,
            personId: null,
            personName: null,
            teamId: null,
            teamName: null,
            sourceId: 'holiday_${holiday.date.toIso8601String()}',
            eventId: 'holiday_${holiday.date.toIso8601String()}',
            locationId: null,
            colorKey: 'holiday',
            isCritical: false,
            isLocked: true,
            isUnassigned: false,
          ),
        );
      }
    }

    return items;
  }

  DateTime _buildAttendanceStart(Map<String, dynamic> row, bool allDay) {
    final date = _readDateRequired(row['attendance_date']);

    if (allDay) {
      return DateTime(date.year, date.month, date.day);
    }

    final timeFrom = _readTimeNullable(row['time_from']);
    if (timeFrom == null) {
      return DateTime(date.year, date.month, date.day);
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      timeFrom.$1,
      timeFrom.$2,
    );
  }

  DateTime _buildAttendanceEnd(
      Map<String, dynamic> row,
      bool allDay,
      DateTime startAt,
      ) {
    final date = _readDateRequired(row['attendance_date']);

    if (allDay) {
      return DateTime(date.year, date.month, date.day + 1);
    }

    final timeTo = _readTimeNullable(row['time_to']);
    if (timeTo == null) {
      return startAt.add(const Duration(hours: 8));
    }

    return DateTime(
      date.year,
      date.month,
      date.day,
      timeTo.$1,
      timeTo.$2,
    );
  }

  CalendarItemStatus _mapTaskStatus(String raw) {
    switch (raw) {
      case 'completed':
        return CalendarItemStatus.done;
      case 'cancelled':
        return CalendarItemStatus.cancelled;
      case 'in_progress':
        return CalendarItemStatus.inProgress;
      case 'waiting':
      case 'unassigned':
      case 'new_task':
      default:
        return CalendarItemStatus.planned;
    }
  }

  bool _isTaskCritical(String? priority) {
    return priority == 'urgent' || priority == 'very_urgent';
  }

  String? _mapTaskSubtitle({
    required String? sectionUnit,
    required String? priority,
    required String? status,
  }) {
    final parts = <String>[];

    final section = _prettifyEnumLabel(sectionUnit);
    final priorityLabel = _prettifyEnumLabel(priority);
    final statusLabel = _prettifyEnumLabel(status);

    if (section != null && section.isNotEmpty) {
      parts.add(section);
    }
    if (priorityLabel != null && priorityLabel.isNotEmpty) {
      parts.add(priorityLabel);
    }
    if (statusLabel != null && statusLabel.isNotEmpty) {
      parts.add(statusLabel);
    }

    if (parts.isEmpty) {
      return null;
    }

    return parts.join(' • ');
  }

  AttendanceType? _mapAttendanceType(String? raw) {
    switch (raw) {
      case 'sztab':
        return AttendanceType.sztab;
      case 'loty':
        return AttendanceType.loty;
      case 'podroz_sluzbowa':
        return AttendanceType.podrozSluzbowa;
      case 'inne':
        return AttendanceType.inne;
      case 'l4':
        return AttendanceType.l4;
      case 'sluzba':
        return AttendanceType.sluzba;
      case 'po_sluzbie':
        return AttendanceType.poSluzbie;
      case 'urlop_wypoczynkowy':
        return AttendanceType.urlopWypoczynkowy;
      case 'urlop_nagrodowy':
        return AttendanceType.urlopNagrodowy;
      case 'urlop_dodatkowy':
        return AttendanceType.urlopDodatkowy;
      default:
        return null;
    }
  }

  LeaveType? _mapLeaveTypeFromAttendance(AttendanceType? type) {
    switch (type) {
      case AttendanceType.urlopWypoczynkowy:
        return LeaveType.annual;
      case AttendanceType.urlopNagrodowy:
        return LeaveType.reward;
      case AttendanceType.urlopDodatkowy:
        return LeaveType.additional;
      default:
        return null;
    }
  }

  String _buildAttendanceSubtitle({
    required DateTime startAt,
    required DateTime endAt,
    required bool allDay,
  }) {
    if (allDay) {
      return 'Cały dzień';
    }

    final startHour = startAt.hour.toString().padLeft(2, '0');
    final startMinute = startAt.minute.toString().padLeft(2, '0');
    final endHour = endAt.hour.toString().padLeft(2, '0');
    final endMinute = endAt.minute.toString().padLeft(2, '0');

    return '$startHour:$startMinute-$endHour:$endMinute';
  }

  String? _profileDisplayName(
      Map<String, dynamic>? row, {
        required String? fallbackId,
      }) {
    if (row == null) {
      return _fallbackPersonLabel(fallbackId);
    }

    final fullNameCandidates = [
      row['full_name'],
      row['display_name'],
      row['name'],
    ];

    for (final candidate in fullNameCandidates) {
      final text = _readStringValue(candidate);
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }

    final firstName = _readStringValue(row['first_name']) ??
        _readStringValue(row['firstName']) ??
        _readStringValue(row['given_name']);
    final lastName = _readStringValue(row['last_name']) ??
        _readStringValue(row['lastName']) ??
        _readStringValue(row['surname']);

    final parts = <String>[];
    if (firstName != null && firstName.isNotEmpty) {
      parts.add(firstName);
    }
    if (lastName != null && lastName.isNotEmpty) {
      parts.add(lastName);
    }

    if (parts.isNotEmpty) {
      return parts.join(' ');
    }

    return _fallbackPersonLabel(fallbackId);
  }

  String? _fallbackPersonLabel(String? id) {
    if (id == null || id.trim().isEmpty) {
      return null;
    }

    final trimmed = id.trim();
    final shortId = trimmed.length <= 6 ? trimmed : trimmed.substring(0, 6);
    return 'Osoba • $shortId';
  }

  String _readId(Map<String, dynamic> row) {
    return row['id'].toString();
  }

  String? _readStringValue(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    return text;
  }

  DateTime _readDateTimeRequired(dynamic value) {
    final parsed = _readDateTimeNullable(value);
    return parsed ?? DateTime.now();
  }

  DateTime? _readDateTimeNullable(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  DateTime _readDateRequired(dynamic value) {
    if (value is DateTime) {
      return DateTime(value.year, value.month, value.day);
    }

    if (value is String && value.trim().isNotEmpty) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  (int, int)? _readTimeNullable(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();
    if (text.isEmpty) return null;

    final parts = text.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null) return null;

    return (hour, minute);
  }

  String? _prettifyEnumLabel(String? value) {
    if (value == null || value.isEmpty) return null;

    return value
        .split('_')
        .map((part) {
      if (part.isEmpty) return part;
      return part[0].toUpperCase() + part.substring(1);
    })
        .join(' ');
  }
}
import 'attendance_type.dart';
import 'calendar_item_source.dart';
import 'calendar_item_status.dart';
import 'calendar_layer.dart';
import 'leave_status.dart';
import 'leave_type.dart';

class CalendarItem {
  final String id;
  final CalendarItemSource source;
  final CalendarLayer layer;
  final CalendarItemStatus status;

  final String title;
  final String? subtitle;
  final String? description;

  final DateTime startAt;
  final DateTime endAt;
  final bool allDay;

  final String? personId;
  final String? personName;
  final String? teamId;
  final String? teamName;

  final String? sourceId;
  final String? taskId;
  final String? eventId;
  final String? attendanceEntryId;
  final String? leaveRequestId;
  final String? leavePlanId;
  final String? locationId;
  final String? colorKey;

  final AttendanceType? attendanceType;
  final LeaveType? leaveType;
  final LeaveStatus? leaveStatus;

  final bool isCritical;
  final bool isLocked;
  final bool isUnassigned;

  const CalendarItem({
    required this.id,
    required this.source,
    required this.layer,
    required this.status,
    required this.title,
    this.subtitle,
    this.description,
    required this.startAt,
    required this.endAt,
    required this.allDay,
    this.personId,
    this.personName,
    this.teamId,
    this.teamName,
    this.sourceId,
    this.taskId,
    this.eventId,
    this.attendanceEntryId,
    this.leaveRequestId,
    this.leavePlanId,
    this.locationId,
    this.colorKey,
    this.attendanceType,
    this.leaveType,
    this.leaveStatus,
    required this.isCritical,
    required this.isLocked,
    required this.isUnassigned,
  });

  Duration get duration => endAt.difference(startAt);

  bool overlaps(DateTime rangeStart, DateTime rangeEnd) {
    return startAt.isBefore(rangeEnd) && endAt.isAfter(rangeStart);
  }

  bool belongsToPerson(String id) => personId == id;

  CalendarItem copyWith({
    String? id,
    CalendarItemSource? source,
    CalendarLayer? layer,
    CalendarItemStatus? status,
    String? title,
    String? subtitle,
    String? description,
    DateTime? startAt,
    DateTime? endAt,
    bool? allDay,
    String? personId,
    String? personName,
    String? teamId,
    String? teamName,
    String? sourceId,
    String? taskId,
    String? eventId,
    String? attendanceEntryId,
    String? leaveRequestId,
    String? leavePlanId,
    String? locationId,
    String? colorKey,
    AttendanceType? attendanceType,
    LeaveType? leaveType,
    LeaveStatus? leaveStatus,
    bool? isCritical,
    bool? isLocked,
    bool? isUnassigned,
  }) {
    return CalendarItem(
      id: id ?? this.id,
      source: source ?? this.source,
      layer: layer ?? this.layer,
      status: status ?? this.status,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      allDay: allDay ?? this.allDay,
      personId: personId ?? this.personId,
      personName: personName ?? this.personName,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      sourceId: sourceId ?? this.sourceId,
      taskId: taskId ?? this.taskId,
      eventId: eventId ?? this.eventId,
      attendanceEntryId: attendanceEntryId ?? this.attendanceEntryId,
      leaveRequestId: leaveRequestId ?? this.leaveRequestId,
      leavePlanId: leavePlanId ?? this.leavePlanId,
      locationId: locationId ?? this.locationId,
      colorKey: colorKey ?? this.colorKey,
      attendanceType: attendanceType ?? this.attendanceType,
      leaveType: leaveType ?? this.leaveType,
      leaveStatus: leaveStatus ?? this.leaveStatus,
      isCritical: isCritical ?? this.isCritical,
      isLocked: isLocked ?? this.isLocked,
      isUnassigned: isUnassigned ?? this.isUnassigned,
    );
  }
}
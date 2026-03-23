import '../../domain/models/attendance_type.dart';
import '../../domain/models/calendar_item.dart';
import '../../domain/models/calendar_item_source.dart';
import '../../domain/models/calendar_item_status.dart';
import '../../domain/models/calendar_layer.dart';
import '../../domain/models/leave_status.dart';
import '../../domain/models/leave_type.dart';

class CalendarEventMapper {
  const CalendarEventMapper();

  CalendarItem fromMap(Map<String, dynamic> map) {
    final source = _mapSource(map['source'] as String?);
    final leaveStatus = _mapLeaveStatus(map['leave_status'] as String?);
    final leaveType = _mapLeaveType(map['leave_type'] as String?);
    final attendanceType = _mapAttendanceType(map['attendance_type'] as String?);

    return CalendarItem(
      id: map['id'] as String,
      source: source,
      layer: _mapLayer(
        layer: map['layer'] as String?,
        source: source,
        leaveStatus: leaveStatus,
      ),
      status: _mapStatus(map['status'] as String?),
      title: map['title'] as String? ?? 'Untitled',
      subtitle: map['subtitle'] as String?,
      description: map['description'] as String?,
      startAt: DateTime.parse(map['start_at'] as String),
      endAt: DateTime.parse(map['end_at'] as String),
      allDay: map['all_day'] as bool? ?? false,
      personId: map['person_id'] as String?,
      personName: map['person_name'] as String?,
      teamId: map['team_id'] as String?,
      teamName: map['team_name'] as String?,
      sourceId: map['source_id'] as String?,
      taskId: map['task_id'] as String?,
      eventId: map['event_id'] as String?,
      attendanceEntryId: map['attendance_entry_id'] as String?,
      leaveRequestId: map['leave_request_id'] as String?,
      leavePlanId: map['leave_plan_id'] as String?,
      locationId: map['location_id'] as String?,
      colorKey: map['color_key'] as String?,
      attendanceType: attendanceType,
      leaveType: leaveType,
      leaveStatus: leaveStatus,
      isCritical: map['is_critical'] as bool? ?? false,
      isLocked: map['is_locked'] as bool? ?? false,
      isUnassigned: map['is_unassigned'] as bool? ??
          ((map['person_id'] == null) && (map['team_id'] == null)),
    );
  }

  CalendarItemSource _mapSource(String? value) {
    switch (value) {
      case 'task':
        return CalendarItemSource.task;
      case 'deadline':
        return CalendarItemSource.deadline;
      case 'event':
        return CalendarItemSource.event;
      case 'attendance':
        return CalendarItemSource.attendance;
      case 'leave_planned':
        return CalendarItemSource.leavePlanned;
      case 'leave_requested':
        return CalendarItemSource.leaveRequested;
      default:
        return CalendarItemSource.event;
    }
  }

  CalendarLayer _mapLayer({
    required String? layer,
    required CalendarItemSource source,
    required LeaveStatus? leaveStatus,
  }) {
    switch (layer) {
      case 'tasks':
        return CalendarLayer.tasks;
      case 'deadlines':
        return CalendarLayer.deadlines;
      case 'events':
        return CalendarLayer.events;
      case 'attendance':
        return CalendarLayer.attendance;
      case 'planned_leave':
        return CalendarLayer.plannedLeave;
      case 'requested_leave':
        return CalendarLayer.requestedLeave;
      case 'unassigned_items':
        return CalendarLayer.unassignedItems;
      default:
        switch (source) {
          case CalendarItemSource.task:
            return CalendarLayer.tasks;
          case CalendarItemSource.deadline:
            return CalendarLayer.deadlines;
          case CalendarItemSource.event:
            return CalendarLayer.events;
          case CalendarItemSource.attendance:
            return CalendarLayer.attendance;
          case CalendarItemSource.leavePlanned:
            return CalendarLayer.plannedLeave;
          case CalendarItemSource.leaveRequested:
            return CalendarLayer.requestedLeave;
        }
    }
  }

  CalendarItemStatus _mapStatus(String? value) {
    switch (value) {
      case 'draft':
        return CalendarItemStatus.draft;
      case 'planned':
        return CalendarItemStatus.planned;
      case 'requested':
        return CalendarItemStatus.requested;
      case 'confirmed':
        return CalendarItemStatus.confirmed;
      case 'approved':
        return CalendarItemStatus.approved;
      case 'rejected':
        return CalendarItemStatus.rejected;
      case 'in_progress':
        return CalendarItemStatus.inProgress;
      case 'done':
        return CalendarItemStatus.done;
      case 'cancelled':
        return CalendarItemStatus.cancelled;
      default:
        return CalendarItemStatus.planned;
    }
  }

  AttendanceType? _mapAttendanceType(String? value) {
    if (value == null || value.isEmpty) return null;
    return AttendanceTypeX.fromCode(value);
  }

  LeaveType? _mapLeaveType(String? value) {
    if (value == null || value.isEmpty) return null;
    return LeaveTypeX.fromCode(value);
  }

  LeaveStatus? _mapLeaveStatus(String? value) {
    if (value == null || value.isEmpty) return null;
    return LeaveStatusX.fromCode(value);
  }
}
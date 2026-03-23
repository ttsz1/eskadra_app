import 'attendance_type.dart';
import 'calendar_item_source.dart';
import 'calendar_item_status.dart';
import 'calendar_layer.dart';
import 'calendar_mode.dart';
import 'calendar_resource_mode.dart';
import 'leave_status.dart';
import 'leave_type.dart';

class CalendarFilterState {
  final CalendarMode mode;
  final CalendarResourceMode resourceMode;

  final Set<CalendarLayer> layers;
  final Set<CalendarItemSource> sources;
  final Set<CalendarItemStatus> statuses;

  final Set<AttendanceType> attendanceTypes;
  final Set<LeaveType> leaveTypes;
  final Set<LeaveStatus> leaveStatuses;

  final Set<String> personIds;
  final Set<String> teamIds;
  final Set<String> locationIds;

  final bool onlyMine;
  final bool onlyCritical;
  final bool showConflicts;
  final bool showWeekends;
  final bool showPolishHolidays;
  final bool showUnassignedItems;
  final bool showPlannedLeave;
  final bool showRequestedLeave;
  final bool showAttendance;
  final bool showTasks;
  final bool showDeadlines;
  final bool showEvents;

  const CalendarFilterState({
    this.mode = CalendarMode.operations,
    this.resourceMode = CalendarResourceMode.none,
    this.layers = const {
      CalendarLayer.tasks,
      CalendarLayer.deadlines,
      CalendarLayer.events,
      CalendarLayer.attendance,
      CalendarLayer.plannedLeave,
      CalendarLayer.requestedLeave,
      CalendarLayer.unassignedItems,
    },
    this.sources = const {},
    this.statuses = const {},
    this.attendanceTypes = const {},
    this.leaveTypes = const {},
    this.leaveStatuses = const {},
    this.personIds = const {},
    this.teamIds = const {},
    this.locationIds = const {},
    this.onlyMine = false,
    this.onlyCritical = false,
    this.showConflicts = true,
    this.showWeekends = true,
    this.showPolishHolidays = true,
    this.showUnassignedItems = true,
    this.showPlannedLeave = true,
    this.showRequestedLeave = true,
    this.showAttendance = true,
    this.showTasks = true,
    this.showDeadlines = true,
    this.showEvents = true,
  });

  CalendarFilterState copyWith({
    CalendarMode? mode,
    CalendarResourceMode? resourceMode,
    Set<CalendarLayer>? layers,
    Set<CalendarItemSource>? sources,
    Set<CalendarItemStatus>? statuses,
    Set<AttendanceType>? attendanceTypes,
    Set<LeaveType>? leaveTypes,
    Set<LeaveStatus>? leaveStatuses,
    Set<String>? personIds,
    Set<String>? teamIds,
    Set<String>? locationIds,
    bool? onlyMine,
    bool? onlyCritical,
    bool? showConflicts,
    bool? showWeekends,
    bool? showPolishHolidays,
    bool? showUnassignedItems,
    bool? showPlannedLeave,
    bool? showRequestedLeave,
    bool? showAttendance,
    bool? showTasks,
    bool? showDeadlines,
    bool? showEvents,
  }) {
    return CalendarFilterState(
      mode: mode ?? this.mode,
      resourceMode: resourceMode ?? this.resourceMode,
      layers: layers ?? this.layers,
      sources: sources ?? this.sources,
      statuses: statuses ?? this.statuses,
      attendanceTypes: attendanceTypes ?? this.attendanceTypes,
      leaveTypes: leaveTypes ?? this.leaveTypes,
      leaveStatuses: leaveStatuses ?? this.leaveStatuses,
      personIds: personIds ?? this.personIds,
      teamIds: teamIds ?? this.teamIds,
      locationIds: locationIds ?? this.locationIds,
      onlyMine: onlyMine ?? this.onlyMine,
      onlyCritical: onlyCritical ?? this.onlyCritical,
      showConflicts: showConflicts ?? this.showConflicts,
      showWeekends: showWeekends ?? this.showWeekends,
      showPolishHolidays: showPolishHolidays ?? this.showPolishHolidays,
      showUnassignedItems: showUnassignedItems ?? this.showUnassignedItems,
      showPlannedLeave: showPlannedLeave ?? this.showPlannedLeave,
      showRequestedLeave: showRequestedLeave ?? this.showRequestedLeave,
      showAttendance: showAttendance ?? this.showAttendance,
      showTasks: showTasks ?? this.showTasks,
      showDeadlines: showDeadlines ?? this.showDeadlines,
      showEvents: showEvents ?? this.showEvents,
    );
  }

  bool get hasPersonFilter => personIds.isNotEmpty;
  bool get hasTeamFilter => teamIds.isNotEmpty;
  bool get hasLocationFilter => locationIds.isNotEmpty;
}
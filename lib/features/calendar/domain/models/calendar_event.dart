enum CalendarEventType {
  task,
  shift,
  absence,
  assignment,
  general,
}

enum CalendarEventStatus {
  draft,
  planned,
  confirmed,
  inProgress,
  done,
  cancelled,
}

class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime endAt;
  final bool allDay;

  final CalendarEventType type;
  final CalendarEventStatus status;

  final String? personId;
  final String? teamId;
  final String? taskId;
  final String? locationId;

  final bool isCritical;
  final bool isLocked;

  const CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startAt,
    required this.endAt,
    required this.allDay,
    required this.type,
    required this.status,
    this.personId,
    this.teamId,
    this.taskId,
    this.locationId,
    required this.isCritical,
    required this.isLocked,
  });

  Duration get duration => endAt.difference(startAt);

  bool overlaps(DateTime rangeStart, DateTime rangeEnd) {
    return startAt.isBefore(rangeEnd) && endAt.isAfter(rangeStart);
  }

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startAt,
    DateTime? endAt,
    bool? allDay,
    CalendarEventType? type,
    CalendarEventStatus? status,
    String? personId,
    String? teamId,
    String? taskId,
    String? locationId,
    bool? isCritical,
    bool? isLocked,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      allDay: allDay ?? this.allDay,
      type: type ?? this.type,
      status: status ?? this.status,
      personId: personId ?? this.personId,
      teamId: teamId ?? this.teamId,
      taskId: taskId ?? this.taskId,
      locationId: locationId ?? this.locationId,
      isCritical: isCritical ?? this.isCritical,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}
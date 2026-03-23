class EventItem {
  final String id;
  final String title;
  final String details;
  final String? location;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool isAllDay;
  final bool isCancelled;
  final String createdBy;

  const EventItem({
    required this.id,
    required this.title,
    required this.details,
    required this.startsAt,
    required this.createdBy,
    this.location,
    this.endsAt,
    this.isAllDay = false,
    this.isCancelled = false,
  });

  factory EventItem.fromMap(Map<String, dynamic> map) {
    return EventItem(
      id: map['id'] as String,
      title: map['title'] as String? ?? '',
      details: map['details'] as String? ?? '',
      location: map['location'] as String?,
      startsAt: DateTime.parse(map['starts_at'] as String),
      endsAt: map['ends_at'] != null
          ? DateTime.parse(map['ends_at'] as String)
          : null,
      isAllDay: map['is_all_day'] as bool? ?? false,
      isCancelled: map['is_cancelled'] as bool? ?? false,
      createdBy: map['created_by'] as String,
    );
  }
}
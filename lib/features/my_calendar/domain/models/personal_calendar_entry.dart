class PersonalCalendarEntry {
  final String id;
  final String userId;
  final String ownerId;
  final String title;
  final String? description;
  final DateTime startAt;
  final DateTime endAt;
  final bool allDay;

  const PersonalCalendarEntry({
    required this.id,
    required this.userId,
    required this.ownerId,
    required this.title,
    this.description,
    required this.startAt,
    required this.endAt,
    required this.allDay,
  });

  bool occursOn(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return startAt.isBefore(dayEnd) && endAt.isAfter(dayStart);
  }

  PersonalCalendarEntry copyWith({
    String? id,
    String? userId,
    String? ownerId,
    String? title,
    String? description,
    DateTime? startAt,
    DateTime? endAt,
    bool? allDay,
  }) {
    return PersonalCalendarEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      allDay: allDay ?? this.allDay,
    );
  }

  factory PersonalCalendarEntry.fromMap(Map<String, dynamic> map) {
    final startAt = DateTime.parse(map['starts_at'] as String).toLocal();
    final endAt = map['ends_at'] != null
        ? DateTime.parse(map['ends_at'] as String).toLocal()
        : startAt;

    return PersonalCalendarEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String? ?? '',
      ownerId: map['owner_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      startAt: startAt,
      endAt: endAt,
      allDay: map['is_all_day'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toInsertMap() {
    final normalizedDescription = description?.trim();

    return {
      'user_id': userId,
      'owner_id': ownerId,
      'title': title.trim(),
      'description': normalizedDescription == null || normalizedDescription.isEmpty
          ? null
          : normalizedDescription,
      'starts_at': startAt.toUtc().toIso8601String(),
      'ends_at': endAt.toUtc().toIso8601String(),
      'is_all_day': allDay,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    final normalizedDescription = description?.trim();

    return {
      'title': title.trim(),
      'description': normalizedDescription == null || normalizedDescription.isEmpty
          ? null
          : normalizedDescription,
      'starts_at': startAt.toUtc().toIso8601String(),
      'ends_at': endAt.toUtc().toIso8601String(),
      'is_all_day': allDay,
    };
  }
}
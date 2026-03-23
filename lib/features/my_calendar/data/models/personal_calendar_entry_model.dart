import '../../domain/models/personal_calendar_entry.dart';

class PersonalCalendarEntryModel {
  static PersonalCalendarEntry fromMap(Map<String, dynamic> map) {
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
}
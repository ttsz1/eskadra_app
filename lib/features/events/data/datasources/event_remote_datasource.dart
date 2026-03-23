import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/event_item.dart';

class EventRemoteDatasource {
  final SupabaseClient client;

  EventRemoteDatasource(this.client);

  Future<List<EventItem>> fetchUpcomingEvents({
    int limit = 12,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();

    final response = await client
        .from('events')
        .select()
        .eq('is_cancelled', false)
        .gte('starts_at', now)
        .order('starts_at')
        .limit(limit);

    return List<Map<String, dynamic>>.from(response)
        .map(EventItem.fromMap)
        .toList();
  }

  Future<void> createEvent({
    required String createdBy,
    required String title,
    required String details,
    required String? location,
    required DateTime startsAt,
    DateTime? endsAt,
    bool isAllDay = false,
  }) async {
    await client.from('events').insert({
      'title': title.trim(),
      'details': details.trim(),
      'location': location?.trim().isEmpty ?? true ? null : location!.trim(),
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt?.toUtc().toIso8601String(),
      'created_by': createdBy,
      'is_all_day': isAllDay,
    });
  }

  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String details,
    required String? location,
    required DateTime startsAt,
    DateTime? endsAt,
    bool isAllDay = false,
  }) async {
    await client.from('events').update({
      'title': title.trim(),
      'details': details.trim(),
      'location': location?.trim().isEmpty ?? true ? null : location!.trim(),
      'starts_at': startsAt.toUtc().toIso8601String(),
      'ends_at': endsAt?.toUtc().toIso8601String(),
      'is_all_day': isAllDay,
    }).eq('id', eventId);
  }

  Future<void> deleteEvent({
    required String eventId,
  }) async {
    await client.from('events').delete().eq('id', eventId);
  }
}
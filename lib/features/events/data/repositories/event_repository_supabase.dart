import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/event_item.dart';
import '../datasources/event_remote_datasource.dart';

class EventRepositorySupabase {
  final EventRemoteDatasource remote;

  EventRepositorySupabase(this.remote);

  factory EventRepositorySupabase.fromClient(SupabaseClient client) {
    return EventRepositorySupabase(EventRemoteDatasource(client));
  }

  Future<List<EventItem>> fetchUpcomingEvents({
    int limit = 12,
  }) {
    return remote.fetchUpcomingEvents(limit: limit);
  }

  Future<void> createEvent({
    required String createdBy,
    required String title,
    required String details,
    required String? location,
    required DateTime startsAt,
    DateTime? endsAt,
    bool isAllDay = false,
  }) {
    return remote.createEvent(
      createdBy: createdBy,
      title: title,
      details: details,
      location: location,
      startsAt: startsAt,
      endsAt: endsAt,
      isAllDay: isAllDay,
    );
  }

  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String details,
    required String? location,
    required DateTime startsAt,
    DateTime? endsAt,
    bool isAllDay = false,
  }) {
    return remote.updateEvent(
      eventId: eventId,
      title: title,
      details: details,
      location: location,
      startsAt: startsAt,
      endsAt: endsAt,
      isAllDay: isAllDay,
    );
  }

  Future<void> deleteEvent({
    required String eventId,
  }) {
    return remote.deleteEvent(eventId: eventId);
  }
}
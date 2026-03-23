import 'package:supabase_flutter/supabase_flutter.dart';

class PrivateCalendarRemoteDatasource {
  PrivateCalendarRemoteDatasource(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> fetchAllEntries() async {
    final response = await client
        .from('private_calendar_entries')
        .select()
        .order('starts_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> insertEntry({
    required String title,
    String? description,
    required DateTime startAt,
    required DateTime endAt,
    required bool allDay,
  }) async {
    final currentUser = client.auth.currentUser;
    if (currentUser == null) {
      throw StateError('Brak aktywnej sesji auth.');
    }

    final row = await client
        .from('private_calendar_entries')
        .insert({
      'owner_id': currentUser.id,
      'title': title,
      'description': description ?? '',
      'starts_at': startAt.toUtc().toIso8601String(),
      'ends_at': endAt.toUtc().toIso8601String(),
      'is_all_day': allDay,
    })
        .select()
        .single();

    return Map<String, dynamic>.from(row);
  }

  Future<Map<String, dynamic>> updateEntry({
    required String id,
    required String title,
    String? description,
    required DateTime startAt,
    required DateTime endAt,
    required bool allDay,
  }) async {
    final row = await client
        .from('private_calendar_entries')
        .update({
      'title': title,
      'description': description ?? '',
      'starts_at': startAt.toUtc().toIso8601String(),
      'ends_at': endAt.toUtc().toIso8601String(),
      'is_all_day': allDay,
    })
        .eq('id', id)
        .select()
        .single();

    return Map<String, dynamic>.from(row);
  }

  Future<void> deleteEntry(String id) async {
    await client.from('private_calendar_entries').delete().eq('id', id);
  }
}
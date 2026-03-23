import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/personal_calendar_entry.dart';

final myCalendarEntriesProvider = StateNotifierProvider<
    MyCalendarEntriesNotifier, List<PersonalCalendarEntry>>(
      (ref) => MyCalendarEntriesNotifier()..load(),
);

class MyCalendarEntriesNotifier
    extends StateNotifier<List<PersonalCalendarEntry>> {
  MyCalendarEntriesNotifier() : super(const []);

  final SupabaseClient _client = Supabase.instance.client;

  Future<void> load() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      state = const [];
      return;
    }

    final rows = await _client
        .from('private_calendar_entries')
        .select(
      'id, user_id, owner_id, title, description, starts_at, ends_at, is_all_day',
    )
        .or('user_id.eq.$currentUserId,owner_id.eq.$currentUserId')
        .order('starts_at', ascending: true);

    state = (rows as List<dynamic>)
        .map(
          (row) => PersonalCalendarEntry.fromMap(
        Map<String, dynamic>.from(row as Map),
      ),
    )
        .toList();
  }

  Future<void> addEntry(PersonalCalendarEntry entry) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('Brak zalogowanego użytkownika.');
    }

    final payload = entry.copyWith(
      userId: currentUserId,
      ownerId: currentUserId,
    );

    await _client.from('private_calendar_entries').insert(
      payload.toInsertMap(),
    );

    await load();
  }

  Future<void> updateEntry(PersonalCalendarEntry entry) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('Brak zalogowanego użytkownika.');
    }

    final payload = entry.copyWith(
      userId: currentUserId,
      ownerId: currentUserId,
    );

    await _client
        .from('private_calendar_entries')
        .update(payload.toUpdateMap())
        .eq('id', payload.id)
        .or('user_id.eq.$currentUserId,owner_id.eq.$currentUserId');

    await load();
  }

  Future<void> removeEntry(String entryId) async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('Brak zalogowanego użytkownika.');
    }

    await _client
        .from('private_calendar_entries')
        .delete()
        .eq('id', entryId)
        .or('user_id.eq.$currentUserId,owner_id.eq.$currentUserId');

    state = state.where((entry) => entry.id != entryId).toList();
  }

  Future<void> reload() async {
    await load();
  }
}
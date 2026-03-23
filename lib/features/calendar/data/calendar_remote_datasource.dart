import 'package:supabase_flutter/supabase_flutter.dart';

class CalendarRemoteDataSource {
  CalendarRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchCalendarEventsRaw({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final response = await _client
        .from('events')
        .select()
        .eq('is_cancelled', false)
        .lt('starts_at', rangeEnd.toIso8601String())
        .or('ends_at.is.null,ends_at.gt.${rangeStart.toIso8601String()}');

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchTasksRaw({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final response = await _client
        .from('tasks')
        .select()
        .gte('deadline', rangeStart.toIso8601String())
        .lt('deadline', rangeEnd.toIso8601String());

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchAttendanceEntriesRaw({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final startDate = DateTime(
      rangeStart.year,
      rangeStart.month,
      rangeStart.day,
    );
    final endDateExclusive = DateTime(
      rangeEnd.year,
      rangeEnd.month,
      rangeEnd.day,
    );

    final response = await _client
        .from('attendance_entries')
        .select()
        .gte('attendance_date', startDate.toIso8601String().split('T').first)
        .lt(
      'attendance_date',
      endDateExclusive.toIso8601String().split('T').first,
    );

    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, Map<String, dynamic>>> fetchProfilesByIds(
      Set<String> ids,
      ) async {
    if (ids.isEmpty) {
      return {};
    }

    try {
      final response = await _client
          .from('profiles')
          .select()
          .inFilter('id', ids.toList());

      final rows = List<Map<String, dynamic>>.from(response);
      final result = <String, Map<String, dynamic>>{};

      for (final row in rows) {
        final id = row['id']?.toString();
        if (id == null || id.trim().isEmpty) {
          continue;
        }
        result[id] = row;
      }

      return result;
    } catch (_) {
      return {};
    }
  }
}
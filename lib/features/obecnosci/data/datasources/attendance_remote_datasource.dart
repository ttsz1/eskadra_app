import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/attendance_entry.dart';
import '../models/attendance_entry_model.dart';

class AttendanceRemoteDatasource {
  AttendanceRemoteDatasource(this.client);

  final SupabaseClient client;

  Future<List<Map<String, dynamic>>> fetchEntriesInRange({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final response = await client
        .from('attendance_entries')
        .select()
        .gte('attendance_date', _dateOnly(rangeStart))
        .lte('attendance_date', _dateOnly(rangeEnd))
        .order('attendance_date', ascending: true)
        .order('person_id', ascending: true)
        .order('time_from', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchPeopleOptions() async {
    final response = await client
        .from('profiles')
        .select('id, full_name, is_active')
        .eq('is_active', true)
        .order('full_name', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> createEntriesBatch({
    required List<String> personIds,
    required List<DateTime> dates,
    required AttendanceType attendanceType,
    required bool isAllDay,
    String? timeFrom,
    String? timeTo,
    required String note,
  }) async {
    final currentUser = client.auth.currentUser;
    if (currentUser == null) {
      throw const AuthException('Brak aktywnej sesji Supabase.');
    }

    if (personIds.isEmpty || dates.isEmpty) {
      return;
    }

    final rows = <Map<String, dynamic>>[];

    for (final personId in personIds) {
      for (final date in dates) {
        rows.add(
          AttendanceEntryModel.toInsertMap(
            personId: personId,
            attendanceDate: date,
            attendanceType: attendanceType,
            isAllDay: isAllDay,
            timeFrom: timeFrom,
            timeTo: timeTo,
            note: note,
            createdBy: currentUser.id,
          ),
        );
      }
    }

    await client.from('attendance_entries').insert(rows);
  }

  Future<Map<String, dynamic>> updateEntry({
    required String id,
    required DateTime attendanceDate,
    required AttendanceType attendanceType,
    required bool isAllDay,
    String? timeFrom,
    String? timeTo,
    required String note,
  }) async {
    final currentUser = client.auth.currentUser;
    if (currentUser == null) {
      throw const AuthException('Brak aktywnej sesji Supabase.');
    }

    final row = await client
        .from('attendance_entries')
        .update(
      AttendanceEntryModel.toUpdateMap(
        attendanceDate: attendanceDate,
        attendanceType: attendanceType,
        isAllDay: isAllDay,
        timeFrom: timeFrom,
        timeTo: timeTo,
        note: note,
      ),
    )
        .eq('id', id)
        .select()
        .single();

    return Map<String, dynamic>.from(row);
  }

  Future<void> deleteEntry(String id) async {
    final currentUser = client.auth.currentUser;
    if (currentUser == null) {
      throw const AuthException('Brak aktywnej sesji Supabase.');
    }

    await client.from('attendance_entries').delete().eq('id', id);
  }

  String _dateOnly(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    return normalized.toIso8601String().split('T').first;
  }
}
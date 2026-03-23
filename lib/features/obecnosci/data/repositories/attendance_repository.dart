import '../../domain/models/attendance_entry.dart';
import '../datasources/attendance_remote_datasource.dart';
import '../models/attendance_entry_model.dart';

class AttendanceRepository {
  AttendanceRepository(this._datasource);

  final AttendanceRemoteDatasource _datasource;

  Future<List<AttendanceEntry>> getEntriesInRange({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    final rows = await _datasource.fetchEntriesInRange(
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );

    return rows.map(AttendanceEntryModel.fromMap).toList();
  }

  Future<List<AttendancePersonOption>> getPeopleOptions() async {
    final rows = await _datasource.fetchPeopleOptions();

    return rows
        .map(
          (row) => AttendancePersonOption(
        id: row['id'] as String,
        fullName: row['full_name'] as String,
      ),
    )
        .toList();
  }

  Future<void> createEntriesBatch({
    required List<String> personIds,
    required List<DateTime> dates,
    required AttendanceType attendanceType,
    required bool isAllDay,
    String? timeFrom,
    String? timeTo,
    required String note,
  }) {
    return _datasource.createEntriesBatch(
      personIds: personIds,
      dates: dates,
      attendanceType: attendanceType,
      isAllDay: isAllDay,
      timeFrom: timeFrom,
      timeTo: timeTo,
      note: note,
    );
  }

  Future<AttendanceEntry> updateEntry({
    required String id,
    required DateTime attendanceDate,
    required AttendanceType attendanceType,
    required bool isAllDay,
    String? timeFrom,
    String? timeTo,
    required String note,
  }) async {
    final row = await _datasource.updateEntry(
      id: id,
      attendanceDate: attendanceDate,
      attendanceType: attendanceType,
      isAllDay: isAllDay,
      timeFrom: timeFrom,
      timeTo: timeTo,
      note: note,
    );

    return AttendanceEntryModel.fromMap(row);
  }

  Future<void> deleteEntry(String id) {
    return _datasource.deleteEntry(id);
  }
}
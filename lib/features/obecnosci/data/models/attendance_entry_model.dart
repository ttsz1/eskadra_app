import '../../domain/models/attendance_entry.dart';

class AttendanceEntryModel {
  static AttendanceEntry fromMap(Map<String, dynamic> map) {
    return AttendanceEntry(
      id: map['id'] as String,
      personId: map['person_id'] as String,
      attendanceDate: DateTime.parse(map['attendance_date'] as String),
      attendanceType: AttendanceTypeX.fromDb(map['attendance_type'] as String),
      isAllDay: map['is_all_day'] as bool? ?? false,
      timeFrom: map['time_from'] as String?,
      timeTo: map['time_to'] as String?,
      note: (map['note'] as String?) ?? '',
      createdBy: map['created_by'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }

  static Map<String, dynamic> toInsertMap({
    required String personId,
    required DateTime attendanceDate,
    required AttendanceType attendanceType,
    required bool isAllDay,
    String? timeFrom,
    String? timeTo,
    required String note,
    required String createdBy,
  }) {
    return {
      'person_id': personId,
      'attendance_date': _dateOnly(attendanceDate),
      'attendance_type': attendanceType.dbValue,
      'is_all_day': isAllDay,
      'time_from': isAllDay ? null : timeFrom,
      'time_to': isAllDay ? null : timeTo,
      'note': note,
      'created_by': createdBy,
    };
  }

  static Map<String, dynamic> toUpdateMap({
    required DateTime attendanceDate,
    required AttendanceType attendanceType,
    required bool isAllDay,
    String? timeFrom,
    String? timeTo,
    required String note,
  }) {
    return {
      'attendance_date': _dateOnly(attendanceDate),
      'attendance_type': attendanceType.dbValue,
      'is_all_day': isAllDay,
      'time_from': isAllDay ? null : timeFrom,
      'time_to': isAllDay ? null : timeTo,
      'note': note,
    };
  }

  static String _dateOnly(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    return normalized.toIso8601String().split('T').first;
  }
}
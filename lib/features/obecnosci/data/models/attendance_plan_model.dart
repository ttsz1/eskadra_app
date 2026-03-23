import '../../domain/models/attendance_plan.dart';

class AttendancePlanModel {
  static AttendancePlan fromMap(
      Map<String, dynamic> map, {
        List<String> personIds = const [],
      }) {
    return AttendancePlan(
      id: map['id'] as String,
      createdBy: map['created_by'] as String,
      attendanceType: AttendanceTypeX.fromDb(map['attendance_type'] as String),
      dateFrom: DateTime.parse(map['date_from'] as String),
      dateTo: DateTime.parse(map['date_to'] as String),
      isAllDay: map['is_all_day'] as bool? ?? false,
      timeFrom: map['time_from'] as String?,
      timeTo: map['time_to'] as String?,
      repeatMode: map['repeat_mode'] as bool? ?? false,
      applyMonday: map['apply_monday'] as bool? ?? true,
      applyTuesday: map['apply_tuesday'] as bool? ?? true,
      applyWednesday: map['apply_wednesday'] as bool? ?? true,
      applyThursday: map['apply_thursday'] as bool? ?? true,
      applyFriday: map['apply_friday'] as bool? ?? true,
      applySaturday: map['apply_saturday'] as bool? ?? false,
      applySunday: map['apply_sunday'] as bool? ?? false,
      note: (map['note'] as String?) ?? '',
      personIds: personIds,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }

  static Map<String, dynamic> toPlanInsertMap({
    required AttendanceType attendanceType,
    required DateTime dateFrom,
    required DateTime dateTo,
    required bool isAllDay,
    String? timeFrom,
    String? timeTo,
    required bool repeatMode,
    required bool applyMonday,
    required bool applyTuesday,
    required bool applyWednesday,
    required bool applyThursday,
    required bool applyFriday,
    required bool applySaturday,
    required bool applySunday,
    required String note,
    required String createdBy,
  }) {
    return {
      'attendance_type': attendanceType.dbValue,
      'date_from': _dateOnly(dateFrom),
      'date_to': _dateOnly(dateTo),
      'is_all_day': isAllDay,
      'time_from': isAllDay ? null : timeFrom,
      'time_to': isAllDay ? null : timeTo,
      'repeat_mode': repeatMode,
      'apply_monday': applyMonday,
      'apply_tuesday': applyTuesday,
      'apply_wednesday': applyWednesday,
      'apply_thursday': applyThursday,
      'apply_friday': applyFriday,
      'apply_saturday': applySaturday,
      'apply_sunday': applySunday,
      'note': note,
      'created_by': createdBy,
    };
  }

  static String _dateOnly(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    return normalized.toIso8601String().split('T').first;
  }
}
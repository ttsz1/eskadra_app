import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../domain/models/attendance_entry.dart';

DateTime startOfWeek(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.subtract(Duration(days: normalized.weekday - 1));
}

class AttendanceRange {
  const AttendanceRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;

  AttendanceRange normalized() {
    return AttendanceRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AttendanceRange &&
        other.start.year == start.year &&
        other.start.month == start.month &&
        other.start.day == start.day &&
        other.end.year == end.year &&
        other.end.month == end.month &&
        other.end.day == end.day;
  }

  @override
  int get hashCode => Object.hash(
    start.year,
    start.month,
    start.day,
    end.year,
    end.month,
    end.day,
  );
}

/// Globalny znacznik odświeżenia danych obecności.
/// Każdy zapis/edycja/usunięcie zwiększa licznik.
/// Providery, które go watchują, pobiorą dane ponownie.
final attendanceDataVersionProvider = StateProvider<int>((ref) => 0);

final attendanceWeekStartProvider = StateProvider<DateTime>((ref) {
  return startOfWeek(DateTime.now());
});

final currentAttendanceRangeProvider = Provider<AttendanceRange>((ref) {
  final weekStart = ref.watch(attendanceWeekStartProvider);
  final normalizedStart = DateTime(
    weekStart.year,
    weekStart.month,
    weekStart.day,
  );
  final weekEnd = normalizedStart.add(const Duration(days: 6));

  return AttendanceRange(
    start: normalizedStart,
    end: weekEnd,
  );
});

final attendanceRemoteDatasourceProvider =
Provider<AttendanceRemoteDatasource>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AttendanceRemoteDatasource(client);
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final datasource = ref.watch(attendanceRemoteDatasourceProvider);
  return AttendanceRepository(datasource);
});

final attendancePeopleProvider =
FutureProvider<List<AttendancePersonOption>>((ref) async {
  ref.watch(attendanceDataVersionProvider);

  final repository = ref.watch(attendanceRepositoryProvider);
  return repository.getPeopleOptions();
});

final attendanceEntriesProvider =
FutureProvider.family<List<AttendanceEntry>, AttendanceRange>(
        (ref, range) async {
      ref.watch(attendanceDataVersionProvider);

      final repository = ref.watch(attendanceRepositoryProvider);
      final normalized = range.normalized();

      return repository.getEntriesInRange(
        rangeStart: normalized.start,
        rangeEnd: normalized.end,
      );
    });

final myAttendanceEntriesInRangeProvider =
FutureProvider.family<List<AttendanceEntry>, AttendanceRange>(
        (ref, range) async {
      ref.watch(attendanceDataVersionProvider);

      final client = ref.watch(supabaseClientProvider);
      final currentUserId = client.auth.currentUser?.id;

      if (currentUserId == null) {
        return const [];
      }

      final entries = await ref.watch(attendanceEntriesProvider(range).future);

      return entries.where((entry) => entry.personId == currentUserId).toList();
    });

final currentWeekAttendanceEntriesProvider =
FutureProvider<List<AttendanceEntry>>((ref) async {
  ref.watch(attendanceDataVersionProvider);

  final repository = ref.watch(attendanceRepositoryProvider);
  final range = ref.watch(currentAttendanceRangeProvider);

  return repository.getEntriesInRange(
    rangeStart: range.start,
    rangeEnd: range.end,
  );
});

class AttendanceTodaySummary {
  const AttendanceTodaySummary({
    required this.presentCount,
    required this.absentCount,
    required this.missingCount,
    required this.activePeopleCount,
  });

  final int presentCount;
  final int absentCount;
  final int missingCount;
  final int activePeopleCount;
}

final attendanceTodaySummaryProvider =
FutureProvider<AttendanceTodaySummary>((ref) async {
  ref.watch(attendanceDataVersionProvider);

  final repository = ref.watch(attendanceRepositoryProvider);
  final people = await repository.getPeopleOptions();

  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);

  final entries = await repository.getEntriesInRange(
    rangeStart: todayStart,
    rangeEnd: todayStart,
  );

  final presentIds = entries
      .where((entry) => entry.attendanceType.countsAsPresence)
      .map((entry) => entry.personId)
      .toSet();

  final absentIds = entries
      .where((entry) => !entry.attendanceType.countsAsPresence)
      .map((entry) => entry.personId)
      .toSet();

  final activePeopleCount = people.length;
  final presentCount = presentIds.length;
  final absentCount = absentIds.length;

  final missingCount = activePeopleCount - presentCount - absentCount < 0
      ? 0
      : activePeopleCount - presentCount - absentCount;

  return AttendanceTodaySummary(
    presentCount: presentCount,
    absentCount: absentCount,
    missingCount: missingCount,
    activePeopleCount: activePeopleCount,
  );
});

final attendanceControllerProvider = Provider<AttendanceController>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return AttendanceController(ref, repository);
});

class AttendanceController {
  AttendanceController(this._ref, this._repository);

  final Ref _ref;
  final AttendanceRepository _repository;

  bool _forcesAllDay(AttendanceType type) {
    switch (type) {
      case AttendanceType.urlopWypoczynkowy:
      case AttendanceType.urlopNagrodowy:
      case AttendanceType.urlopDodatkowy:
      case AttendanceType.l4:
      case AttendanceType.podrozSluzbowa:
        return true;
      case AttendanceType.sztab:
      case AttendanceType.loty:
      case AttendanceType.inne:
      case AttendanceType.sluzba:
      case AttendanceType.poSluzbie:
        return false;
    }
  }

  Future<void> createEntriesBatch({
    required List<String> personIds,
    required DateTime dateFrom,
    required DateTime dateTo,
    required bool repeatMode,
    required bool applyMonday,
    required bool applyTuesday,
    required bool applyWednesday,
    required bool applyThursday,
    required bool applyFriday,
    required bool applySaturday,
    required bool applySunday,
    required AttendanceType attendanceType,
    required bool isAllDay,
    String? timeFrom,
    String? timeTo,
    required String note,
  }) async {
    final dates = _expandDates(
      dateFrom: dateFrom,
      dateTo: dateTo,
      repeatMode: repeatMode,
      applyMonday: applyMonday,
      applyTuesday: applyTuesday,
      applyWednesday: applyWednesday,
      applyThursday: applyThursday,
      applyFriday: applyFriday,
      applySaturday: applySaturday,
      applySunday: applySunday,
    );

    final forcedAllDay = _forcesAllDay(attendanceType);

    await _repository.createEntriesBatch(
      personIds: personIds,
      dates: dates,
      attendanceType: attendanceType,
      isAllDay: forcedAllDay ? true : isAllDay,
      timeFrom: forcedAllDay ? null : timeFrom,
      timeTo: forcedAllDay ? null : timeTo,
      note: note,
    );

    _invalidateAll();
  }

  Future<void> updateEntry({
    required String id,
    required DateTime attendanceDate,
    required AttendanceType attendanceType,
    required bool isAllDay,
    String? timeFrom,
    String? timeTo,
    required String note,
  }) async {
    final forcedAllDay = _forcesAllDay(attendanceType);

    await _repository.updateEntry(
      id: id,
      attendanceDate: attendanceDate,
      attendanceType: attendanceType,
      isAllDay: forcedAllDay ? true : isAllDay,
      timeFrom: forcedAllDay ? null : timeFrom,
      timeTo: forcedAllDay ? null : timeTo,
      note: note,
    );

    _invalidateAll();
  }

  Future<void> deleteEntry(String id) async {
    await _repository.deleteEntry(id);
    _invalidateAll();
  }

  void _invalidateAll() {
    _ref.read(attendanceDataVersionProvider.notifier).state++;

    _ref.invalidate(attendancePeopleProvider);
    _ref.invalidate(attendanceEntriesProvider);
    _ref.invalidate(myAttendanceEntriesInRangeProvider);
    _ref.invalidate(currentAttendanceRangeProvider);
    _ref.invalidate(currentWeekAttendanceEntriesProvider);
    _ref.invalidate(attendanceTodaySummaryProvider);
  }

  List<DateTime> _expandDates({
    required DateTime dateFrom,
    required DateTime dateTo,
    required bool repeatMode,
    required bool applyMonday,
    required bool applyTuesday,
    required bool applyWednesday,
    required bool applyThursday,
    required bool applyFriday,
    required bool applySaturday,
    required bool applySunday,
  }) {
    final start = DateTime(dateFrom.year, dateFrom.month, dateFrom.day);
    final end = DateTime(dateTo.year, dateTo.month, dateTo.day);

    final dates = <DateTime>[];
    var current = start;

    while (!current.isAfter(end)) {
      final allowed = !repeatMode ||
          switch (current.weekday) {
            DateTime.monday => applyMonday,
            DateTime.tuesday => applyTuesday,
            DateTime.wednesday => applyWednesday,
            DateTime.thursday => applyThursday,
            DateTime.friday => applyFriday,
            DateTime.saturday => applySaturday,
            DateTime.sunday => applySunday,
            _ => false,
          };

      if (allowed) {
        dates.add(current);
      }

      current = current.add(const Duration(days: 1));
    }

    return dates;
  }
}
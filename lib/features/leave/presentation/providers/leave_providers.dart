import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../obecnosci/domain/models/attendance_entry.dart';
import '../../../obecnosci/presentation/providers/attendance_provider.dart';
import '../../data/leave_repository.dart';
import '../../domain/models/leave_request.dart';
import '../../domain/models/leave_year_balance.dart';
import '../../domain/models/public_holiday.dart';
import '../../domain/models/team_leave_balance_overview_row.dart';
import '../../domain/models/team_leave_plan_entry.dart';

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) {
  return LeaveRepository(Supabase.instance.client);
});

final leaveDataVersionProvider = StateProvider<int>((ref) => 0);

final myLeaveRequestsProvider = FutureProvider<List<LeaveRequest>>((ref) async {
  ref.watch(leaveDataVersionProvider);
  return ref.watch(leaveRepositoryProvider).fetchMyLeaveRequests();
});

final leavePlanningYearProvider = StateProvider<int>((ref) {
  final now = DateTime.now();
  return now.year;
});

final myPlannedLeavesForYearProvider =
FutureProvider.family<List<LeaveRequest>, int>((ref, targetYear) async {
  ref.watch(leaveDataVersionProvider);
  return ref
      .watch(leaveRepositoryProvider)
      .fetchMyPlannedLeaveRequestsForYear(targetYear);
});

final leavePlanningBalancesProvider =
FutureProvider.family<List<LeaveYearBalance>, int>((ref, targetYear) async {
  ref.watch(leaveDataVersionProvider);
  return ref.watch(leaveRepositoryProvider).fetchMyBalancesForYearRange(
    startYear: targetYear - 6,
    endYear: targetYear,
  );
});

final leavePlanningHolidaysProvider =
FutureProvider.family<List<PublicHoliday>, int>((ref, targetYear) async {
  ref.watch(leaveDataVersionProvider);
  return ref.watch(leaveRepositoryProvider).fetchPublicHolidays(
    from: DateTime(targetYear, 1, 1),
    to: DateTime(targetYear, 12, 31),
  );
});

final teamPlannedLeavesProvider =
FutureProvider.family<List<TeamLeavePlanEntry>, int>((ref, targetYear) async {
  ref.watch(leaveDataVersionProvider);
  return ref.watch(leaveRepositoryProvider).fetchTeamPlannedLeavesForYear(
    targetYear,
  );
});

final teamLeaveBalanceOverviewProvider = FutureProvider.family<
    List<TeamLeaveBalanceOverviewRow>, int>((ref, currentYear) async {
  ref.watch(leaveDataVersionProvider);
  return ref.watch(leaveRepositoryProvider).fetchTeamBalanceOverview(
    currentYear: currentYear,
  );
});

class LeaveUsageSummary {
  const LeaveUsageSummary({
    required this.year,
    required this.availableVacation,
    required this.availableAdditional,
    required this.availableReward,
    required this.usedVacation,
    required this.usedAdditional,
    required this.usedReward,
  });

  final int year;

  final int availableVacation;
  final int availableAdditional;
  final int availableReward;

  final int usedVacation;
  final int usedAdditional;
  final int usedReward;

  int get remainingVacation => availableVacation - usedVacation;
  int get remainingAdditional => availableAdditional - usedAdditional;
  int get remainingReward => availableReward - usedReward;

  int get totalAvailable =>
      availableVacation + availableAdditional + availableReward;

  int get totalUsed => usedVacation + usedAdditional + usedReward;

  int get totalRemaining =>
      remainingVacation + remainingAdditional + remainingReward;
}

final currentYearUsedLeaveEntriesProvider =
FutureProvider<List<AttendanceEntry>>((ref) async {
  ref.watch(attendanceDataVersionProvider);

  final year = DateTime.now().year;
  final range = AttendanceRange(
    start: DateTime(year, 1, 1),
    end: DateTime(year, 12, 31),
  );

  final entries = await ref.watch(myAttendanceEntriesInRangeProvider(range).future);

  final used = entries.where((entry) {
    switch (entry.attendanceType) {
      case AttendanceType.urlopWypoczynkowy:
      case AttendanceType.urlopNagrodowy:
      case AttendanceType.urlopDodatkowy:
        return true;
      case AttendanceType.sztab:
      case AttendanceType.loty:
      case AttendanceType.podrozSluzbowa:
      case AttendanceType.inne:
      case AttendanceType.l4:
      case AttendanceType.sluzba:
      case AttendanceType.poSluzbie:
        return false;
    }
  }).toList()
    ..sort((a, b) => b.attendanceDate.compareTo(a.attendanceDate));

  return used;
});

final currentYearLeaveUsageSummaryProvider =
FutureProvider<LeaveUsageSummary>((ref) async {
  ref.watch(leaveDataVersionProvider);
  ref.watch(attendanceDataVersionProvider);

  final year = DateTime.now().year;

  final balances = await ref.watch(leaveRepositoryProvider).fetchMyBalancesForYearRange(
    startYear: year,
    endYear: year,
  );

  final usedEntries = await ref.watch(currentYearUsedLeaveEntriesProvider.future);

  final availableVacation = balances.fold<int>(
    0,
        (sum, item) => sum + item.vacationDays,
  );

  final availableAdditional = balances.fold<int>(
    0,
        (sum, item) => sum + item.additionalDays,
  );

  final availableReward = balances.fold<int>(
    0,
        (sum, item) => sum + item.rewardDays,
  );

  var usedVacation = 0;
  var usedAdditional = 0;
  var usedReward = 0;

  for (final entry in usedEntries) {
    switch (entry.attendanceType) {
      case AttendanceType.urlopWypoczynkowy:
        usedVacation++;
        break;
      case AttendanceType.urlopNagrodowy:
        usedReward++;
        break;
      case AttendanceType.urlopDodatkowy:
        usedAdditional++;
        break;
      case AttendanceType.sztab:
      case AttendanceType.loty:
      case AttendanceType.podrozSluzbowa:
      case AttendanceType.inne:
      case AttendanceType.l4:
      case AttendanceType.sluzba:
      case AttendanceType.poSluzbie:
        break;
    }
  }

  return LeaveUsageSummary(
    year: year,
    availableVacation: availableVacation,
    availableAdditional: availableAdditional,
    availableReward: availableReward,
    usedVacation: usedVacation,
    usedAdditional: usedAdditional,
    usedReward: usedReward,
  );
});

final leaveActionsProvider = Provider<LeaveActions>((ref) {
  return LeaveActions(ref);
});

class LeaveActions {
  LeaveActions(this.ref);

  final Ref ref;

  Future<void> refresh() async {
    ref.read(leaveDataVersionProvider.notifier).state++;
  }

  Future<void> saveBalance({
    required int year,
    required int vacationDays,
    required int additionalDays,
    required String source,
    int rewardDays = 0,
  }) async {
    await ref.read(leaveRepositoryProvider).upsertMyBalance(
      year: year,
      vacationDays: vacationDays,
      additionalDays: additionalDays,
      rewardDays: rewardDays,
      source: source,
    );

    ref.read(leaveDataVersionProvider.notifier).state++;
  }

  Future<void> saveBalanceForUser({
    required String userId,
    required int year,
    required int vacationDays,
    required int additionalDays,
    required String source,
    int rewardDays = 0,
  }) async {
    await ref.read(leaveRepositoryProvider).upsertBalanceForUser(
      userId: userId,
      year: year,
      vacationDays: vacationDays,
      additionalDays: additionalDays,
      rewardDays: rewardDays,
      source: source,
    );

    ref.read(leaveDataVersionProvider.notifier).state++;
  }

  Future<void> replacePlannedLeavesForYear({
    required int targetYear,
    required List<PlannedLeaveSegmentPayload> segments,
  }) async {
    await ref.read(leaveRepositoryProvider).replaceMyPlannedLeavesForYear(
      targetYear: targetYear,
      segments: segments,
    );

    ref.read(leaveDataVersionProvider.notifier).state++;
  }

  Future<void> updatePlannedLeave({
    required String requestId,
    required DateTime startDate,
    required DateTime endDate,
    required String leaveType,
    String? title,
    String? notes,
  }) async {
    await ref.read(leaveRepositoryProvider).updatePlannedLeave(
      requestId: requestId,
      startDate: startDate,
      endDate: endDate,
      leaveType: leaveType,
      title: title,
      notes: notes,
    );

    ref.read(leaveDataVersionProvider.notifier).state++;
  }

  Future<void> deletePlannedLeave(String requestId) async {
    await ref.read(leaveRepositoryProvider).deletePlannedLeave(requestId);
    ref.read(leaveDataVersionProvider.notifier).state++;
  }

  Future<void> createPlannedLeave({
    required DateTime startDate,
    required DateTime endDate,
    required String leaveType,
    String? title,
    String? notes,
  }) async {
    await ref.read(leaveRepositoryProvider).createLeaveRequest(
      startDate: startDate,
      endDate: endDate,
      leaveType: leaveType,
      status: 'planned',
      title: title,
      notes: notes,
    );

    ref.read(leaveDataVersionProvider.notifier).state++;
  }
}
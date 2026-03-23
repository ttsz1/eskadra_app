import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/models/org_structure.dart';
import '../domain/enums/leave_request_status.dart';
import '../domain/models/leave_request.dart';
import '../domain/models/leave_year_balance.dart';
import '../domain/models/public_holiday.dart';
import '../domain/models/team_leave_balance_overview_row.dart';
import '../domain/models/team_leave_plan_entry.dart';

class LeaveRepository {
  LeaveRepository(this._client);

  final SupabaseClient _client;

  static const String _leaveRequestSelect =
      'id, user_id, created_by, leave_type, status, '
      'start_date, end_date, starts_on, ends_on, '
      'working_days, title, notes, created_at, updated_at';

  static const String _leaveBalanceSelect =
      'id, user_id, year, vacation_days, additional_days, reward_days, '
      'source, created_at, updated_at';

  static const String _profileSelect =
      'id, email, full_name, org_unit, org_function, '
      'personnel_type, rank_group, is_active';

  Future<List<LeaveRequest>> fetchMyLeaveRequests() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Brak zalogowanego użytkownika.');
    }

    final rows = await _client
        .from('leave_requests')
        .select(_leaveRequestSelect)
        .eq('user_id', userId)
        .neq('status', LeaveRequestStatus.cancelled.dbValue)
        .order('starts_on', ascending: false);

    return (rows as List<dynamic>)
        .map((e) => _mapLeaveRequestRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<LeaveRequest>> fetchMyPlannedLeaveRequestsForYear(int year) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Brak zalogowanego użytkownika.');
    }

    final rows = await _client
        .from('leave_requests')
        .select(_leaveRequestSelect)
        .eq('user_id', userId)
        .eq('status', LeaveRequestStatus.planned.dbValue)
        .gte('starts_on', '$year-01-01')
        .lte('starts_on', '$year-12-31')
        .order('starts_on', ascending: true);

    return (rows as List<dynamic>)
        .map((e) => _mapLeaveRequestRow(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<LeaveYearBalance>> fetchMyBalancesForYearRange({
    required int startYear,
    required int endYear,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Brak zalogowanego użytkownika.');
    }

    final rows = await _client
        .from('leave_year_balances')
        .select(_leaveBalanceSelect)
        .eq('user_id', userId)
        .gte('year', startYear)
        .lte('year', endYear)
        .order('year', ascending: true)
        .order('source', ascending: true);

    return (rows as List<dynamic>)
        .map((e) => LeaveYearBalance.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> upsertMyBalance({
    required int year,
    required int vacationDays,
    required int additionalDays,
    required String source,
    int rewardDays = 0,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Brak zalogowanego użytkownika.');
    }

    await _client.from('leave_year_balances').upsert(
      {
        'user_id': userId,
        'year': year,
        'vacation_days': vacationDays,
        'additional_days': additionalDays,
        'reward_days': rewardDays,
        'source': source,
      },
      onConflict: 'user_id,year,source',
    );
  }

  Future<void> upsertBalanceForUser({
    required String userId,
    required int year,
    required int vacationDays,
    required int additionalDays,
    required String source,
    int rewardDays = 0,
  }) async {
    await _client.from('leave_year_balances').upsert(
      {
        'user_id': userId,
        'year': year,
        'vacation_days': vacationDays,
        'additional_days': additionalDays,
        'reward_days': rewardDays,
        'source': source,
      },
      onConflict: 'user_id,year,source',
    );
  }

  Future<void> createLeaveRequest({
    required DateTime startDate,
    required DateTime endDate,
    required String leaveType,
    required String status,
    String? title,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Brak zalogowanego użytkownika.');
    }

    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);

    await _client.from('leave_requests').insert({
      'user_id': userId,
      'created_by': userId,
      'leave_type': leaveType,
      'status': status,
      'start_date': start,
      'end_date': end,
      'starts_on': start,
      'ends_on': end,
      'title': title?.trim(),
      'notes': notes?.trim(),
    });
  }

  Future<void> updatePlannedLeave({
    required String requestId,
    required DateTime startDate,
    required DateTime endDate,
    required String leaveType,
    String? title,
    String? notes,
  }) async {
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);

    await _client
        .from('leave_requests')
        .update({
      'leave_type': leaveType,
      'start_date': start,
      'end_date': end,
      'starts_on': start,
      'ends_on': end,
      'title': title?.trim(),
      'notes': notes?.trim(),
    })
        .eq('id', requestId)
        .eq('status', LeaveRequestStatus.planned.dbValue);
  }

  Future<void> deletePlannedLeave(String requestId) async {
    await _client
        .from('leave_requests')
        .delete()
        .eq('id', requestId)
        .eq('status', LeaveRequestStatus.planned.dbValue);
  }

  Future<void> replaceMyPlannedLeavesForYear({
    required int targetYear,
    required List<PlannedLeaveSegmentPayload> segments,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Brak zalogowanego użytkownika.');
    }

    await _client
        .from('leave_requests')
        .delete()
        .eq('user_id', userId)
        .eq('status', LeaveRequestStatus.planned.dbValue)
        .gte('starts_on', '$targetYear-01-01')
        .lte('starts_on', '$targetYear-12-31');

    if (segments.isEmpty) return;

    await _client.from('leave_requests').insert(
      segments
          .map(
            (segment) => {
          'user_id': userId,
          'created_by': userId,
          'leave_type': segment.leaveType,
          'status': LeaveRequestStatus.planned.dbValue,
          'start_date': _dateOnly(segment.startDate),
          'end_date': _dateOnly(segment.endDate),
          'starts_on': _dateOnly(segment.startDate),
          'ends_on': _dateOnly(segment.endDate),
          'title': segment.title.trim(),
          'notes': segment.notes?.trim(),
        },
      )
          .toList(),
    );
  }

  Future<List<PublicHoliday>> fetchPublicHolidays({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _client
        .from('public_holidays')
        .select('holiday_date, name')
        .gte('holiday_date', _dateOnly(from))
        .lte('holiday_date', _dateOnly(to))
        .order('holiday_date', ascending: true);

    return (rows as List<dynamic>)
        .map((e) => PublicHoliday.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<TeamLeavePlanEntry>> fetchTeamPlannedLeavesForYear(int year) async {
    final rows = await _client
        .from('leave_requests')
        .select(_leaveRequestSelect)
        .eq('status', LeaveRequestStatus.planned.dbValue)
        .gte('starts_on', '$year-01-01')
        .lte('starts_on', '$year-12-31')
        .order('starts_on', ascending: true);

    final requests = (rows as List<dynamic>)
        .map((e) => _mapLeaveRequestRow(Map<String, dynamic>.from(e as Map)))
        .toList();

    final userIds = requests.map((e) => e.userId).toSet().toList();
    if (userIds.isEmpty) return const [];

    final profileRows = await _client
        .from('profiles')
        .select(_profileSelect)
        .inFilter('id', userIds);

    final namesById = <String, String>{};
    final sectionsById = <String, String>{};

    for (final row in (profileRows as List<dynamic>)) {
      final map = Map<String, dynamic>.from(row as Map);
      final id = map['id']?.toString();
      if (id == null) continue;

      namesById[id] = _resolveFullName(map);
      sectionsById[id] = _resolveSectionName(map);
    }

    return requests
        .map(
          (request) => TeamLeavePlanEntry(
        userId: request.userId,
        fullName: namesById[request.userId] ?? 'Nieznany użytkownik',
        sectionName: sectionsById[request.userId] ?? 'Bez sekcji',
        request: request,
      ),
    )
        .toList();
  }

  Future<List<TeamLeaveBalanceOverviewRow>> fetchTeamBalanceOverview({
    required int currentYear,
  }) async {
    final profileRows = await _client
        .from('profiles')
        .select(_profileSelect)
        .eq('is_active', true)
        .order('full_name');

    final profiles = (profileRows as List<dynamic>)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    if (profiles.isEmpty) {
      return const [];
    }

    final userIds = profiles
        .map((e) => e['id']?.toString())
        .whereType<String>()
        .toList();

    final balanceRows = await _client
        .from('leave_year_balances')
        .select(_leaveBalanceSelect)
        .inFilter('user_id', userIds)
        .gte('year', currentYear - 10)
        .lte('year', currentYear)
        .order('year', ascending: true);

    final balances = (balanceRows as List<dynamic>)
        .map((e) => LeaveYearBalance.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    final result = <TeamLeaveBalanceOverviewRow>[];

    for (final profile in profiles) {
      final userId = profile['id']?.toString();
      if (userId == null) continue;

      final userBalances = balances.where((e) => e.userId == userId).toList();

      LeaveYearBalance sumForYears(Iterable<int> years) {
        var vacation = 0;
        var additional = 0;
        var reward = 0;

        for (final item in userBalances.where((e) => years.contains(e.year))) {
          vacation += item.vacationDays;
          additional += item.additionalDays;
          reward += item.rewardDays;
        }

        return LeaveYearBalance(
          id: 'virtual-$userId-${years.join('-')}',
          userId: userId,
          year: currentYear,
          vacationDays: vacation,
          additionalDays: additional,
          rewardDays: reward,
          source: 'virtual',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      final earlierYears = userBalances
          .where((e) => e.year <= currentYear - 4)
          .map((e) => e.year)
          .toSet();

      result.add(
        TeamLeaveBalanceOverviewRow(
          userId: userId,
          fullName: _resolveFullName(profile),
          sectionName: _resolveSectionName(profile),
          earlier: sumForYears(earlierYears),
          minus3: sumForYears([currentYear - 3]),
          minus2: sumForYears([currentYear - 2]),
          minus1: sumForYears([currentYear - 1]),
          current: sumForYears([currentYear]),
        ),
      );
    }

    result.sort((a, b) {
      final sectionCompare = a.sectionName.compareTo(b.sectionName);
      if (sectionCompare != 0) return sectionCompare;
      return a.fullName.compareTo(b.fullName);
    });

    return result;
  }

  LeaveRequest _mapLeaveRequestRow(Map<String, dynamic> row) {
    final mapped = <String, dynamic>{
      ...row,
      'start_date': row['start_date'] ?? row['starts_on'],
      'end_date': row['end_date'] ?? row['ends_on'],
    };
    return LeaveRequest.fromMap(mapped);
  }

  String _resolveFullName(Map<String, dynamic> map) {
    final candidates = [
      map['full_name'],
      map['display_name'],
      map['name'],
      _joinNameParts(map['last_name'], map['first_name']),
      _joinNameParts(map['surname'], map['name']),
      map['email'],
    ];

    for (final value in candidates) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty) return text;
    }

    return 'Nieznany użytkownik';
  }

  String _resolveSectionName(Map<String, dynamic> map) {
    final rawOrgUnit = map['org_unit']?.toString().trim();
    if (rawOrgUnit == null || rawOrgUnit.isEmpty) {
      return 'Bez sekcji';
    }

    final parsed = _parseOrgUnitFromDb(rawOrgUnit);
    if (parsed != null) {
      return parsed.label;
    }

    return _humanizeFallback(rawOrgUnit);
  }

  OrgUnit? _parseOrgUnitFromDb(String raw) {
    switch (raw) {
      case 'command':
        return OrgUnit.command;
      case 'flight_training_section':
        return OrgUnit.flightTrainingSection;
      case 'standardization_and_evaluation_section':
        return OrgUnit.standardizationAndEvaluationSection;
      case 'current_operations_section':
        return OrgUnit.currentOperationsSection;
      case 'wys_rat_support_section':
        return OrgUnit.wysRatSupportSection;
      case 'trainer_device_support':
        return OrgUnit.trainerDeviceSupport;
      case 'flight_training_subunit':
        return OrgUnit.flightTrainingSubunit;
      default:
        return null;
    }
  }

  String _humanizeFallback(String raw) {
    final normalized = raw.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return 'Bez sekcji';

    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
      '${part[0].toUpperCase()}${part.length > 1 ? part.substring(1) : ''}',
    )
        .join(' ');
  }

  String _joinNameParts(dynamic left, dynamic right) {
    final a = left?.toString().trim() ?? '';
    final b = right?.toString().trim() ?? '';
    return '$a $b'.trim();
  }

  String _dateOnly(DateTime value) => value.toIso8601String().split('T').first;
}

class PlannedLeaveSegmentPayload {
  const PlannedLeaveSegmentPayload({
    required this.startDate,
    required this.endDate,
    required this.leaveType,
    required this.title,
    this.notes,
  });

  final DateTime startDate;
  final DateTime endDate;
  final String leaveType;
  final String title;
  final String? notes;
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/ops_panel.dart';
import '../../../calendar/domain/services/polish_holiday_service.dart';
import '../../data/leave_repository.dart';
import '../../domain/enums/leave_request_type.dart';
import '../../domain/models/leave_request.dart';
import '../../domain/models/leave_year_balance.dart';
import '../../domain/models/public_holiday.dart';
import '../../domain/models/team_leave_plan_entry.dart';
import '../providers/leave_providers.dart';
import 'leave_balance_correction_dialog.dart';
import 'leave_year_planner_overview.dart';

class LeavePlanTab extends ConsumerStatefulWidget {
  const LeavePlanTab({super.key});

  @override
  ConsumerState<LeavePlanTab> createState() => _LeavePlanTabState();
}

class _LeavePlanTabState extends ConsumerState<LeavePlanTab> {
  final _vacationTargetYearController = TextEditingController();
  final _additionalTargetYearController = TextEditingController();
  final _rewardTargetYearController = TextEditingController();
  final ScrollController _calendarScrollController = ScrollController();

  LeaveRequestType _type = LeaveRequestType.vacation;
  DateTime? _anchorDate;
  bool _saving = false;
  bool _showQuotaEditor = false;
  int? _syncedQuotaYear;
  int? _syncedPlannedYear;

  final List<_DraftSegment> _segments = [];

  @override
  void initState() {
    super.initState();
    _vacationTargetYearController.addListener(_onQuotaChanged);
    _additionalTargetYearController.addListener(_onQuotaChanged);
    _rewardTargetYearController.addListener(_onQuotaChanged);
  }

  void _onQuotaChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _vacationTargetYearController.removeListener(_onQuotaChanged);
    _additionalTargetYearController.removeListener(_onQuotaChanged);
    _rewardTargetYearController.removeListener(_onQuotaChanged);
    _vacationTargetYearController.dispose();
    _additionalTargetYearController.dispose();
    _rewardTargetYearController.dispose();
    _calendarScrollController.dispose();
    super.dispose();
  }

  void _switchToCurrentYear() {
    final year = DateTime.now().year;
    ref.read(leavePlanningYearProvider.notifier).state = year;
    _syncedQuotaYear = null;
    _syncedPlannedYear = null;
    _clearDraft();
  }

  void _switchToNextYear() {
    final year = DateTime.now().year + 1;
    ref.read(leavePlanningYearProvider.notifier).state = year;
    _syncedQuotaYear = null;
    _syncedPlannedYear = null;
    _clearDraft();
  }

  void _clearDraft() {
    setState(() {
      _segments.clear();
      _anchorDate = null;
    });
  }

  void _syncAnnualQuotaFromBalances({
    required int targetYear,
    required List<LeaveYearBalance> balances,
  }) {
    if (_syncedQuotaYear == targetYear) return;

    final annualItems = balances.where(
      (e) => e.year == targetYear && e.source == 'annual',
    );

    var vacation = 0;
    var additional = 0;
    var reward = 0;

    for (final item in annualItems) {
      vacation += item.vacationDays;
      additional += item.additionalDays;
      reward += item.rewardDays;
    }

    _syncedQuotaYear = targetYear;
    _vacationTargetYearController.text =
        vacation == 0 ? '' : vacation.toString();
    _additionalTargetYearController.text =
        additional == 0 ? '' : additional.toString();
    _rewardTargetYearController.text = reward == 0 ? '' : reward.toString();
  }

  void _syncPlannedSegments({
    required int targetYear,
    required List<LeaveRequest> plannedRequests,
    required Set<String> holidaySet,
  }) {
    if (_syncedPlannedYear == targetYear) return;

    _segments
      ..clear()
      ..addAll(
        plannedRequests.map(
          (e) => _DraftSegment(
            requestId: e.id,
            startDate: e.startDate,
            endDate: e.endDate,
            leaveType: _mapDbTypeToEnum(e.leaveType),
            workingDays: _countBusinessDays(
              e.startDate,
              e.endDate,
              holidaySet,
            ),
          ),
        ),
      );

    _syncedPlannedYear = targetYear;
  }

  LeaveRequestType _mapDbTypeToEnum(String dbValue) {
    return LeaveRequestType.fromDbValue(dbValue);
  }

  Future<void> _openCorrectionDialog(int targetYear) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => LeaveBalanceCorrectionDialog(targetYear: targetYear),
    );
  }

  Future<void> _openPlannerDialog({
    required int targetYear,
    required List<LeaveYearBalance> balances,
    required List<TeamLeavePlanEntry> teamPlans,
    required List<PublicHoliday> holidayList,
    required Map<String, String> holidayMap,
    required Set<String> holidaySet,
    required String? currentUserId,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog.fullscreen(
          child: SafeArea(
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                final totals = _buildTotals(balances, targetYear);

                void refreshDialog() => setDialogState(() {});

                return Scaffold(
                  appBar: AppBar(
                    title: Text('Planner urlopów • $targetYear'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Zamknij'),
                      ),
                    ],
                  ),
                  body: Padding(
                    padding: const EdgeInsets.all(AppSpacing.pagePadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TotalsHeader(totals: totals),
                        const SizedBox(height: AppSpacing.lg),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: 5,
                                child: _CalendarPlannerArea(
                                  controller: _calendarScrollController,
                                  holidayMap: holidayMap,
                                  holidaySet: holidaySet,
                                  year: targetYear,
                                  teamPlans: teamPlans,
                                  currentUserId: currentUserId,
                                  draftSegments: _segments,
                                  anchorDate: _anchorDate,
                                  selectedType: _type,
                                  onTypeChanged: (value) {
                                    setState(() => _type = value);
                                    refreshDialog();
                                  },
                                  onCancelAnchor: () {
                                    setState(() => _anchorDate = null);
                                    refreshDialog();
                                  },
                                  onDayTap: (day) async {
                                    await _handleDayTap(day, holidaySet, totals);
                                    refreshDialog();
                                  },
                                  formatDate: _formatDate,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              SizedBox(
                                width: 400,
                                child: _RightStickyPlanPanel(
                                  segments: _segments,
                                  saving: _saving,
                                  anchorDate: _anchorDate,
                                  selectedType: _type,
                                  onRemove: (index) {
                                    setState(() {
                                      _segments.removeAt(index);
                                    });
                                    refreshDialog();
                                  },
                                  onSave: () async {
                                    await _savePlan(targetYear, totals);
                                    refreshDialog();
                                  },
                                  onCancelAnchor: () {
                                    setState(() => _anchorDate = null);
                                    refreshDialog();
                                  },
                                  formatDate: _formatDate,
                                  totals: totals,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          height: 320,
                          child: LeaveYearPlannerOverview(
                            year: targetYear,
                            entries: teamPlans,
                            holidays: holidayList,
                            currentUserId: currentUserId,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDayTap(
    DateTime day,
    Set<String> holidaySet,
    _LeaveTotals totals,
  ) async {
    if (_anchorDate == null) {
      setState(() {
        _anchorDate = day;
      });
      return;
    }

    final start = day.isBefore(_anchorDate!) ? day : _anchorDate!;
    final end = day.isBefore(_anchorDate!) ? _anchorDate! : day;
    final workingDays = _countBusinessDays(start, end, holidaySet);

    final remaining = _remainingForType(_type, totals);
    if (workingDays > remaining) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Za mało dostępnych dni. Odcinek ma $workingDays dni roboczych, a zostało $remaining.',
          ),
        ),
      );
      setState(() {
        _anchorDate = null;
      });
      return;
    }

    setState(() {
      _segments.add(
        _DraftSegment(
          startDate: start,
          endDate: end,
          leaveType: _type,
          workingDays: workingDays,
        ),
      );
      _anchorDate = null;
    });
  }

  Future<void> _saveAnnualQuota(int targetYear) async {
    await ref.read(leaveActionsProvider).saveBalance(
          year: targetYear,
          vacationDays:
              int.tryParse(_vacationTargetYearController.text.trim()) ?? 0,
          additionalDays:
              int.tryParse(_additionalTargetYearController.text.trim()) ?? 0,
          rewardDays: int.tryParse(_rewardTargetYearController.text.trim()) ?? 0,
          source: 'annual',
        );

    _syncedQuotaYear = null;

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Zapisano pulę na rok $targetYear.')),
    );
  }

  Future<void> _savePlan(int targetYear, _LeaveTotals totals) async {
    if (totals.remainingVacation < 0 ||
        totals.remainingAdditional < 0 ||
        totals.remainingReward < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nie można zapisać planu z ujemnym saldem dni.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final payload = _segments
          .map(
            (segment) => PlannedLeaveSegmentPayload(
              startDate: segment.startDate,
              endDate: segment.endDate,
              leaveType: segment.leaveType.dbValue,
              title: 'Plan urlopu $targetYear',
            ),
          )
          .toList();

      await ref.read(leaveActionsProvider).replacePlannedLeavesForYear(
            targetYear: targetYear,
            segments: payload,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Plan urlopu zapisany.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się zapisać planu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  _LeaveTotals _buildTotals(List<LeaveYearBalance> balances, int targetYear) {
    final previousVacation = _sumCarryover(balances, targetYear, true);
    final previousAdditional = _sumCarryover(balances, targetYear, false);

    final annualItems = balances.where(
      (e) => e.year == targetYear && e.source == 'annual',
    );

    var vacationBase = 0;
    var additionalBase = 0;
    var rewardBase = 0;
    for (final item in annualItems) {
      vacationBase += item.vacationDays;
      additionalBase += item.additionalDays;
      rewardBase += item.rewardDays;
    }

    final plannedVacation = _sumDraftDays(LeaveRequestType.vacation);
    final plannedAdditional = _sumDraftDays(LeaveRequestType.additional);
    final plannedReward = _sumDraftDays(LeaveRequestType.reward);

    return _LeaveTotals(
      totalVacation: previousVacation + vacationBase,
      totalAdditional: previousAdditional + additionalBase,
      totalReward: rewardBase,
      usedVacation: plannedVacation,
      usedAdditional: plannedAdditional,
      usedReward: plannedReward,
    );
  }

  int _remainingForType(LeaveRequestType type, _LeaveTotals totals) {
    switch (type) {
      case LeaveRequestType.additional:
        return totals.remainingAdditional;
      case LeaveRequestType.reward:
        return totals.remainingReward;
      case LeaveRequestType.vacation:
        return totals.remainingVacation;
    }
  }

  int _countBusinessDays(
    DateTime start,
    DateTime end,
    Set<String> holidaySet,
  ) {
    var count = 0;
    var current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(last)) {
      final isWeekend = current.weekday >= DateTime.saturday;
      final isHoliday = holidaySet.contains(_dateKey(current));

      if (!isWeekend && !isHoliday) {
        count++;
      }

      current = current.add(const Duration(days: 1));
    }

    return count;
  }

  int _sumCarryover(
    List<LeaveYearBalance> balances,
    int targetYear,
    bool vacation,
  ) {
    return balances
        .where((item) => item.source == 'manual' && item.year < targetYear)
        .fold<int>(
          0,
          (sum, item) =>
              sum + (vacation ? item.vacationDays : item.additionalDays),
        );
  }

  int _sumDraftDays(LeaveRequestType type) {
    return _segments
        .where((e) => e.leaveType == type)
        .fold<int>(0, (sum, e) => sum + e.workingDays);
  }

  Map<String, String> _buildHolidayMap(int year) {
    const service = PolishHolidayService();
    final holidays = service.holidaysForYear(year);

    final result = <String, String>{};
    for (final holiday in holidays) {
      result[_dateKey(holiday.date)] = holiday.name;
    }
    return result;
  }

  List<PublicHoliday> _buildHolidayList(int year) {
    const service = PolishHolidayService();
    return service
        .holidaysForYear(year)
        .map((e) => PublicHoliday(date: e.date, name: e.name))
        .toList();
  }

  String _dateKey(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}.'
        '${value.month.toString().padLeft(2, '0')}.'
        '${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final targetYear = ref.watch(leavePlanningYearProvider);
    final balancesAsync = ref.watch(leavePlanningBalancesProvider(targetYear));
    final teamPlansAsync = ref.watch(teamPlannedLeavesProvider(targetYear));
    final plannedAsync = ref.watch(myPlannedLeavesForYearProvider(targetYear));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    final holidayMap = _buildHolidayMap(targetYear);
    final holidayList = _buildHolidayList(targetYear);
    final holidaySet = holidayMap.keys.toSet();

    return OpsPanel(
      child: balancesAsync.when(
        data: (balances) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _syncAnnualQuotaFromBalances(
              targetYear: targetYear,
              balances: balances,
            );
          });

          return plannedAsync.when(
            data: (plannedRequests) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _syncPlannedSegments(
                  targetYear: targetYear,
                  plannedRequests: plannedRequests,
                  holidaySet: holidaySet,
                );
              });

              return teamPlansAsync.when(
                data: (teamPlans) {
                  final totals = _buildTotals(balances, targetYear);

                  return ListView(
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          FilledButton.icon(
                            onPressed: _switchToCurrentYear,
                            icon: const Icon(Icons.edit_calendar_outlined),
                            label:
                                const Text('Zmień planowany urlop na ten rok'),
                          ),
                          FilledButton.icon(
                            onPressed: _switchToNextYear,
                            icon: const Icon(Icons.upcoming_outlined),
                            label: const Text('Zaplanuj na przyszły rok'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _openCorrectionDialog(targetYear),
                            icon: const Icon(Icons.tune_outlined),
                            label: const Text(
                              'Korekta ilości dni za poprzednie lata',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showQuotaEditor = !_showQuotaEditor;
                              });
                            },
                            icon: Icon(
                              _showQuotaEditor ? Icons.edit_off_outlined : Icons.edit_outlined,
                            ),
                            label: Text(
                              _showQuotaEditor
                                  ? 'Zamknij edycję puli na $targetYear'
                                  : 'Edytuj pulę dni / nagrodowy na $targetYear',
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _openPlannerDialog(
                              targetYear: targetYear,
                              balances: balances,
                              teamPlans: teamPlans,
                              holidayList: holidayList,
                              holidayMap: holidayMap,
                              holidaySet: holidaySet,
                              currentUserId: currentUserId,
                            ),
                            icon: const Icon(Icons.open_in_full_rounded),
                            label:
                                const Text('Otwórz planner w osobnym oknie'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Planowanie urlopu • $targetYear',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (_showQuotaEditor) ...[
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final rowWide = constraints.maxWidth >= 900;

                            if (!rowWide) {
                              return Column(
                                children: [
                                  _TargetYearQuotaCard(
                                    title: 'Wypoczynkowy na rok $targetYear',
                                    controller: _vacationTargetYearController,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _TargetYearQuotaCard(
                                    title: 'Dodatkowy na rok $targetYear',
                                    controller: _additionalTargetYearController,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  _TargetYearQuotaCard(
                                    title: 'Nagrodowy na rok $targetYear',
                                    controller: _rewardTargetYearController,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: FilledButton.icon(
                                      onPressed: () =>
                                          _saveAnnualQuota(targetYear),
                                      icon: const Icon(Icons.save_outlined),
                                      label: Text(
                                        'Zapisz pulę na rok $targetYear',
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: _TargetYearQuotaCard(
                                    title: 'Wypoczynkowy na rok $targetYear',
                                    controller: _vacationTargetYearController,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _TargetYearQuotaCard(
                                    title: 'Dodatkowy na rok $targetYear',
                                    controller: _additionalTargetYearController,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _TargetYearQuotaCard(
                                    title: 'Nagrodowy na rok $targetYear',
                                    controller: _rewardTargetYearController,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                FilledButton.icon(
                                  onPressed: () => _saveAnnualQuota(targetYear),
                                  icon: const Icon(Icons.save_outlined),
                                  label: Text('Zapisz pulę $targetYear'),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      _TotalsHeader(totals: totals),
                      const SizedBox(height: AppSpacing.lg),
                      _RightStickyPlanPanel(
                        segments: _segments,
                        saving: _saving,
                        anchorDate: _anchorDate,
                        selectedType: _type,
                        onRemove: (index) {
                          setState(() {
                            _segments.removeAt(index);
                          });
                        },
                        onSave: () => _savePlan(targetYear, totals),
                        onCancelAnchor: () {
                          setState(() {
                            _anchorDate = null;
                          });
                        },
                        formatDate: _formatDate,
                        totals: totals,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        height: 320,
                        child: LeaveYearPlannerOverview(
                          year: targetYear,
                          entries: teamPlans,
                          holidays: holidayList,
                          currentUserId: currentUserId,
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) =>
                    Center(child: Text('Błąd planów zespołu: $error')),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                Center(child: Text('Błąd planowanych: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Błąd sald: $error')),
      ),
    );
  }
}

class _TotalsHeader extends StatelessWidget {
  const _TotalsHeader({
    required this.totals,
  });

  final _LeaveTotals totals;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: [
        _SummaryStat(
          title: 'Pozostało wypoczynkowego',
          value: '${totals.remainingVacation} dni',
          subtitle:
              'Do dyspozycji: ${totals.totalVacation} • Zaplanowano: ${totals.usedVacation}',
        ),
        _SummaryStat(
          title: 'Pozostało dodatkowego',
          value: '${totals.remainingAdditional} dni',
          subtitle:
              'Do dyspozycji: ${totals.totalAdditional} • Zaplanowano: ${totals.usedAdditional}',
        ),
        _SummaryStat(
          title: 'Pozostało nagrodowego',
          value: '${totals.remainingReward} dni',
          subtitle:
              'Do dyspozycji: ${totals.totalReward} • Zaplanowano: ${totals.usedReward}',
        ),
      ],
    );
  }
}

class _CalendarPlannerArea extends StatelessWidget {
  const _CalendarPlannerArea({
    required this.controller,
    required this.holidayMap,
    required this.holidaySet,
    required this.year,
    required this.teamPlans,
    required this.currentUserId,
    required this.draftSegments,
    required this.anchorDate,
    required this.selectedType,
    required this.onTypeChanged,
    required this.onCancelAnchor,
    required this.onDayTap,
    required this.formatDate,
  });

  final ScrollController controller;
  final Map<String, String> holidayMap;
  final Set<String> holidaySet;
  final int year;
  final List<TeamLeavePlanEntry> teamPlans;
  final String? currentUserId;
  final List<_DraftSegment> draftSegments;
  final DateTime? anchorDate;
  final LeaveRequestType selectedType;
  final ValueChanged<LeaveRequestType> onTypeChanged;
  final VoidCallback onCancelAnchor;
  final ValueChanged<DateTime> onDayTap;
  final String Function(DateTime) formatDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            DropdownButton<LeaveRequestType>(
              value: selectedType,
              items: LeaveRequestType.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                onTypeChanged(value);
              },
            ),
            FilledButton.icon(
              onPressed: anchorDate == null ? null : onCancelAnchor,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Anuluj pierwszy klik'),
            ),
            if (anchorDate != null)
              Text('Początek odcinka: ${formatDate(anchorDate!)}'),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _HolidayLegend(holidayCount: holidaySet.length),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView(
            controller: controller,
            children: List.generate(12, (index) {
              final month = index + 1;
              return Padding(
                padding:
                    EdgeInsets.only(bottom: month == 12 ? 0 : AppSpacing.md),
                child: _MonthPanel(
                  year: year,
                  month: month,
                  holidayMap: holidayMap,
                  teamPlans: teamPlans,
                  currentUserId: currentUserId,
                  draftSegments: draftSegments,
                  anchorDate: anchorDate,
                  selectedType: selectedType,
                  onDayTap: onDayTap,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _RightStickyPlanPanel extends StatelessWidget {
  const _RightStickyPlanPanel({
    required this.segments,
    required this.saving,
    required this.anchorDate,
    required this.selectedType,
    required this.onRemove,
    required this.onSave,
    required this.onCancelAnchor,
    required this.formatDate,
    required this.totals,
  });

  final List<_DraftSegment> segments;
  final bool saving;
  final DateTime? anchorDate;
  final LeaveRequestType selectedType;
  final ValueChanged<int> onRemove;
  final VoidCallback onSave;
  final VoidCallback onCancelAnchor;
  final String Function(DateTime) formatDate;
  final _LeaveTotals totals;

  @override
  Widget build(BuildContext context) {
    final maxListHeight = MediaQuery.of(context).size.height * 0.30;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Planowane odcinki',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Widoczne cały czas. Usunięcie odcinka od razu oddaje dni do puli.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tryb zaznaczania: ${selectedType.label}'),
                const SizedBox(height: AppSpacing.xs),
                if (anchorDate != null)
                  Text('Wybrany start: ${formatDate(anchorDate!)}')
                else
                  const Text('Kliknij pierwszy dzień odcinka na kalendarzu.'),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Pozostało: '
                  '${totals.remainingVacation}(w) / '
                  '${totals.remainingAdditional}(d) / '
                  '${totals.remainingReward}(N)',
                ),
                const SizedBox(height: AppSpacing.sm),
                FilledButton.tonalIcon(
                  onPressed: anchorDate == null ? null : onCancelAnchor,
                  icon: const Icon(Icons.close_rounded),
                  label: const Text('Anuluj pierwszy klik'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: segments.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Text('Brak dodanych odcinków.'),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: segments.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = segments[index];
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: Theme.of(context).dividerColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.leaveType.label} • ${item.dateLabel} • ${item.workingDays} dni roboczych',
                              ),
                            ),
                            IconButton(
                              onPressed: () => onRemove(index),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Zapisz plan urlopu'),
          ),
        ],
      ),
    );
  }
}

class _MonthPanel extends StatelessWidget {
  const _MonthPanel({
    required this.year,
    required this.month,
    required this.holidayMap,
    required this.teamPlans,
    required this.currentUserId,
    required this.draftSegments,
    required this.anchorDate,
    required this.selectedType,
    required this.onDayTap,
  });

  final int year;
  final int month;
  final Map<String, String> holidayMap;
  final List<TeamLeavePlanEntry> teamPlans;
  final String? currentUserId;
  final List<_DraftSegment> draftSegments;
  final DateTime? anchorDate;
  final LeaveRequestType selectedType;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startOffset = firstDay.weekday - 1;
    final totalCells = ((startOffset + daysInMonth) / 7).ceil() * 7;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _monthName(month),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                _TypeLegendChip(type: selectedType),
              ],
            ),
          ),
          Row(
            children: const [
              _WeekdayHeader(label: 'Pn'),
              _WeekdayHeader(label: 'Wt'),
              _WeekdayHeader(label: 'Śr'),
              _WeekdayHeader(label: 'Cz'),
              _WeekdayHeader(label: 'Pt'),
              _WeekdayHeader(label: 'Sb'),
              _WeekdayHeader(label: 'Nd'),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalCells,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              childAspectRatio: 1.55,
            ),
            itemBuilder: (context, index) {
              final dayNumber = index - startOffset + 1;
              if (dayNumber < 1 || dayNumber > daysInMonth) {
                return const SizedBox.shrink();
              }

              final day = DateTime(year, month, dayNumber);
              final key = _dateKey(day);
              final isWeekend = day.weekday >= DateTime.saturday;
              final holidayName = holidayMap[key];
              final isHoliday = holidayName != null;
              final isAnchor = anchorDate != null &&
                  day.year == anchorDate!.year &&
                  day.month == anchorDate!.month &&
                  day.day == anchorDate!.day;

              final myDraftType = _draftTypeForDay(day);
              final teamCount = _teamCountForDay(day);
              final someoneElsePlanned = teamCount > 0;

              return _DayCell(
                day: day,
                isWeekend: isWeekend,
                isHoliday: isHoliday,
                holidayName: holidayName,
                isAnchor: isAnchor,
                myDraftType: myDraftType,
                someoneElsePlanned: someoneElsePlanned,
                teamCount: teamCount,
                onTap: () => onDayTap(day),
              );
            },
          ),
        ],
      ),
    );
  }

  LeaveRequestType? _draftTypeForDay(DateTime day) {
    for (final segment in draftSegments) {
      if (!_isBeforeDay(day, segment.startDate) &&
          !_isAfterDay(day, segment.endDate)) {
        return segment.leaveType;
      }
    }
    return null;
  }

  int _teamCountForDay(DateTime day) {
    var count = 0;
    for (final entry in teamPlans) {
      if (entry.userId == currentUserId) continue;
      if (!_isBeforeDay(day, entry.request.startDate) &&
          !_isAfterDay(day, entry.request.endDate)) {
        count++;
      }
    }
    return count;
  }

  bool _isBeforeDay(DateTime a, DateTime b) {
    final aa = DateTime(a.year, a.month, a.day);
    final bb = DateTime(b.year, b.month, b.day);
    return aa.isBefore(bb);
  }

  bool _isAfterDay(DateTime a, DateTime b) {
    final aa = DateTime(a.year, a.month, a.day);
    final bb = DateTime(b.year, b.month, b.day);
    return aa.isAfter(bb);
  }

  String _dateKey(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String _monthName(int month) {
    const names = [
      '',
      'Styczeń',
      'Luty',
      'Marzec',
      'Kwiecień',
      'Maj',
      'Czerwiec',
      'Lipiec',
      'Sierpień',
      'Wrzesień',
      'Październik',
      'Listopad',
      'Grudzień',
    ];
    return names[month];
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isWeekend,
    required this.isHoliday,
    required this.holidayName,
    required this.isAnchor,
    required this.myDraftType,
    required this.someoneElsePlanned,
    required this.teamCount,
    required this.onTap,
  });

  final DateTime day;
  final bool isWeekend;
  final bool isHoliday;
  final String? holidayName;
  final bool isAnchor;
  final LeaveRequestType? myDraftType;
  final bool someoneElsePlanned;
  final int teamCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Color? fillColor;
    BorderSide borderSide = BorderSide(color: Theme.of(context).dividerColor);

    if (myDraftType != null) {
      switch (myDraftType!) {
        case LeaveRequestType.vacation:
          fillColor = Colors.lightBlueAccent.withValues(alpha: 0.42);
          break;
        case LeaveRequestType.additional:
          fillColor = Colors.orangeAccent.withValues(alpha: 0.42);
          break;
        case LeaveRequestType.reward:
          fillColor = Colors.purpleAccent.withValues(alpha: 0.42);
          break;
      }
    } else if (isHoliday) {
      fillColor = Colors.redAccent.withValues(alpha: 0.18);
    } else if (isWeekend) {
      fillColor = Colors.white.withValues(alpha: 0.05);
    }

    if (isAnchor) {
      borderSide = const BorderSide(
        color: Colors.amberAccent,
        width: 2,
      );
    }

    return Tooltip(
      message: isHoliday
          ? '${day.day}.${day.month}.${day.year} • ${holidayName ?? 'Święto państwowe'}'
          : '${day.day}.${day.month}.${day.year}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: fillColor,
            border: Border.fromBorderSide(borderSide),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  '${day.day}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              if (isHoliday)
                const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.flag_rounded,
                      size: 10,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              if (someoneElsePlanned)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 1),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              if (teamCount > 0)
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$teamCount',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HolidayLegend extends StatelessWidget {
  const _HolidayLegend({
    required this.holidayCount,
  });

  final int holidayCount;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_rounded, size: 14, color: Colors.redAccent),
              SizedBox(width: 6),
              Text('Święto państwowe'),
            ],
          ),
        ),
        Text('Świąt w roku: $holidayCount'),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _TypeLegendChip extends StatelessWidget {
  const _TypeLegendChip({
    required this.type,
  });

  final LeaveRequestType type;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (type) {
      case LeaveRequestType.vacation:
        color = Colors.lightBlueAccent;
        break;
      case LeaveRequestType.additional:
        color = Colors.orangeAccent;
        break;
      case LeaveRequestType.reward:
        color = Colors.purpleAccent;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        'Tryb: ${type.label}',
        style: Theme.of(context).textTheme.labelSmall,
      ),
    );
  }
}

class _TargetYearQuotaCard extends StatelessWidget {
  const _TargetYearQuotaCard({
    required this.title,
    required this.controller,
  });

  final String title;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Liczba dni',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaveTotals {
  const _LeaveTotals({
    required this.totalVacation,
    required this.totalAdditional,
    required this.totalReward,
    required this.usedVacation,
    required this.usedAdditional,
    required this.usedReward,
  });

  final int totalVacation;
  final int totalAdditional;
  final int totalReward;
  final int usedVacation;
  final int usedAdditional;
  final int usedReward;

  int get remainingVacation => totalVacation - usedVacation;
  int get remainingAdditional => totalAdditional - usedAdditional;
  int get remainingReward => totalReward - usedReward;
}

class _DraftSegment {
  const _DraftSegment({
    this.requestId,
    required this.startDate,
    required this.endDate,
    required this.leaveType,
    required this.workingDays,
  });

  final String? requestId;
  final DateTime startDate;
  final DateTime endDate;
  final LeaveRequestType leaveType;
  final int workingDays;

  String get dateLabel {
    final a =
        '${startDate.day.toString().padLeft(2, '0')}.${startDate.month.toString().padLeft(2, '0')}.${startDate.year}';
    final b =
        '${endDate.day.toString().padLeft(2, '0')}.${endDate.month.toString().padLeft(2, '0')}.${endDate.year}';
    return '$a - $b';
  }
}

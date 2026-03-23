import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/ops_panel.dart';
import '../../domain/enums/leave_request_type.dart';
import '../../domain/models/leave_request.dart';
import '../../domain/models/leave_year_balance.dart';
import '../providers/leave_providers.dart';

class LeavePlannedTab extends ConsumerWidget {
  const LeavePlannedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final year = DateTime.now().year;
    final plannedAsync = ref.watch(myPlannedLeavesForYearProvider(year));
    final balancesAsync = ref.watch(leavePlanningBalancesProvider(year));

    return OpsPanel(
      child: balancesAsync.when(
        data: (balances) {
          return plannedAsync.when(
            data: (planned) {
              final totals = _buildTotals(balances, planned, year);

              return ListView(
                children: [
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      _StatCard(
                        title: 'Wypoczynkowy',
                        value:
                        '${totals.usedVacation} wykorzystanych / ${totals.remainingVacation} pozostało',
                      ),
                      _StatCard(
                        title: 'Dodatkowy',
                        value:
                        '${totals.usedAdditional} wykorzystanych / ${totals.remainingAdditional} pozostało',
                      ),
                      _StatCard(
                        title: 'Nagrodowy',
                        value:
                        '${totals.usedReward} wykorzystanych / ${totals.remainingReward} pozostało',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (planned.isEmpty)
                    const Text('Brak zaplanowanych urlopów.')
                  else
                    ...planned.map(
                          (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _PlannedLeaveRow(item: item),
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Text('Błąd planowanych: $error'),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Text('Błąd sald: $error'),
      ),
    );
  }

  _PlannedTotals _buildTotals(
      List<LeaveYearBalance> balances,
      List<LeaveRequest> planned,
      int year,
      ) {
    final annual = balances.where((e) => e.year == year && e.source == 'annual');
    final manual = balances.where((e) => e.year < year && e.source == 'manual');

    var totalVacation = 0;
    var totalAdditional = 0;
    var totalReward = 0;

    for (final item in annual) {
      totalVacation += item.vacationDays;
      totalAdditional += item.additionalDays;
      totalReward += item.rewardDays;
    }

    for (final item in manual) {
      totalVacation += item.vacationDays;
      totalAdditional += item.additionalDays;
    }

    var usedVacation = 0;
    var usedAdditional = 0;
    var usedReward = 0;

    for (final item in planned) {
      final days = item.workingDays;
      switch (item.leaveType) {
        case 'additional':
          usedAdditional += days;
          break;
        case 'reward':
          usedReward += days;
          break;
        case 'vacation':
        default:
          usedVacation += days;
          break;
      }
    }

    return _PlannedTotals(
      totalVacation: totalVacation,
      totalAdditional: totalAdditional,
      totalReward: totalReward,
      usedVacation: usedVacation,
      usedAdditional: usedAdditional,
      usedReward: usedReward,
    );
  }
}

class _PlannedLeaveRow extends ConsumerWidget {
  const _PlannedLeaveRow({
    required this.item,
  });

  final LeaveRequest item;

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final start = item.startDate;
    final end = item.endDate;

    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(start.year - 1),
      lastDate: DateTime(start.year + 2),
      initialDateRange: DateTimeRange(start: start, end: end),
    );

    if (range == null) return;

    await ref.read(leaveActionsProvider).updatePlannedLeave(
      requestId: item.id,
      startDate: range.start,
      endDate: range.end,
      leaveType: item.leaveType,
      title: item.title,
      notes: item.notes,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Zaktualizowano plan urlopu.')),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    await ref.read(leaveActionsProvider).deletePlannedLeave(item.id);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Usunięto planowany urlop.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label =
        '${item.startDate.day.toString().padLeft(2, '0')}.${item.startDate.month.toString().padLeft(2, '0')}.${item.startDate.year}'
        ' - '
        '${item.endDate.day.toString().padLeft(2, '0')}.${item.endDate.month.toString().padLeft(2, '0')}.${item.endDate.year}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_labelForType(item.leaveType)} • $label • ${item.workingDays} dni',
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _edit(context, ref),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edytuj'),
          ),
          const SizedBox(width: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _delete(context, ref),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Usuń'),
          ),
        ],
      ),
    );
  }

  String _labelForType(String dbValue) {
    switch (dbValue) {
      case 'additional':
        return LeaveRequestType.additional.label;
      case 'reward':
        return LeaveRequestType.reward.label;
      case 'vacation':
      default:
        return LeaveRequestType.vacation.label;
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

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
              const SizedBox(height: AppSpacing.sm),
              Text(value),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlannedTotals {
  const _PlannedTotals({
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
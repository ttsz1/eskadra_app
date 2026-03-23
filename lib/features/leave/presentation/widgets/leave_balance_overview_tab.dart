import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/ops_panel.dart';
import '../../domain/models/team_leave_balance_overview_row.dart';
import '../providers/leave_providers.dart';

class LeaveBalanceOverviewTab extends ConsumerStatefulWidget {
  const LeaveBalanceOverviewTab({super.key});

  @override
  ConsumerState<LeaveBalanceOverviewTab> createState() =>
      _LeaveBalanceOverviewTabState();
}

class _LeaveBalanceOverviewTabState
    extends ConsumerState<LeaveBalanceOverviewTab> {
  final Map<String, TextEditingController> _rewardControllers = {};
  final Map<String, ScrollController> _tableScrollControllers = {};

  @override
  void dispose() {
    for (final controller in _rewardControllers.values) {
      controller.dispose();
    }
    for (final controller in _tableScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(TeamLeaveBalanceOverviewRow row) {
    return _rewardControllers.putIfAbsent(
      row.userId,
          () => TextEditingController(
        text: row.current.rewardDays.toString().padLeft(2, '0'),
      ),
    );
  }

  ScrollController _scrollControllerFor(String userId) {
    return _tableScrollControllers.putIfAbsent(
      userId,
          () => ScrollController(),
    );
  }

  Future<void> _saveReward(TeamLeaveBalanceOverviewRow row, int year) async {
    final reward = int.tryParse(_controllerFor(row).text.trim()) ?? 0;

    await ref.read(leaveActionsProvider).saveBalanceForUser(
      userId: row.userId,
      year: year,
      vacationDays: row.current.vacationDays,
      additionalDays: row.current.additionalDays,
      rewardDays: reward,
      source: 'annual',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Zapisano nagrodowy dla ${row.fullName}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    final overviewAsync = ref.watch(teamLeaveBalanceOverviewProvider(year));

    return OpsPanel(
      child: overviewAsync.when(
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(
              child: Text('Brak danych sald urlopowych.'),
            );
          }

          String? currentSection;

          return ListView(
            children: [
              Text(
                'Sprawdź ile kto ma urlopu',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Format: 00(w)+00(d)+00(N) • w = wypoczynkowy, d = dodatkowy, N = nagrodowy',
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tabela ma poziomy suwak — przy większej liczbie kolumn przesuń w bok.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              ...rows.expand((row) {
                final widgets = <Widget>[];

                if (currentSection != row.sectionName) {
                  currentSection = row.sectionName;
                  widgets.add(
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Text(
                        currentSection!,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  );
                }

                widgets.add(
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _OverviewRowCard(
                      row: row,
                      rewardController: _controllerFor(row),
                      tableScrollController: _scrollControllerFor(row.userId),
                      currentYear: year,
                      onSaveReward: () => _saveReward(row, year),
                    ),
                  ),
                );

                return widgets;
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Błąd overview: $error')),
      ),
    );
  }
}

class _OverviewRowCard extends StatelessWidget {
  const _OverviewRowCard({
    required this.row,
    required this.rewardController,
    required this.tableScrollController,
    required this.currentYear,
    required this.onSaveReward,
  });

  final TeamLeaveBalanceOverviewRow row;
  final TextEditingController rewardController;
  final ScrollController tableScrollController;
  final int currentYear;
  final VoidCallback onSaveReward;

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
          Text(
            row.fullName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          Scrollbar(
            controller: tableScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            notificationPredicate: (notification) =>
            notification.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: tableScrollController,
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  const DataColumn(label: Text('Wcześniejsze')),
                  DataColumn(label: Text('${currentYear - 3}')),
                  DataColumn(label: Text('${currentYear - 2}')),
                  DataColumn(label: Text('${currentYear - 1}')),
                  DataColumn(label: Text('$currentYear')),
                  const DataColumn(label: Text('Nagrodowy')),
                ],
                rows: [
                  DataRow(
                    cells: [
                      DataCell(Text(row.earlier.formatCompact())),
                      DataCell(Text(row.minus3.formatCompact())),
                      DataCell(Text(row.minus2.formatCompact())),
                      DataCell(Text(row.minus1.formatCompact())),
                      DataCell(Text(row.current.formatCompact())),
                      DataCell(
                        SizedBox(
                          width: 190,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: rewardController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    labelText: '00(N)',
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              FilledButton(
                                onPressed: onSaveReward,
                                child: const Text('Zapisz'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
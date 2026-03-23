import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/models/public_holiday.dart';
import '../../domain/models/team_leave_plan_entry.dart';

class LeaveYearPlannerOverview extends StatefulWidget {
  const LeaveYearPlannerOverview({
    super.key,
    required this.year,
    required this.entries,
    required this.holidays,
    required this.currentUserId,
  });

  final int year;
  final List<TeamLeavePlanEntry> entries;
  final List<PublicHoliday> holidays;
  final String? currentUserId;

  @override
  State<LeaveYearPlannerOverview> createState() =>
      _LeaveYearPlannerOverviewState();
}

class _LeaveYearPlannerOverviewState extends State<LeaveYearPlannerOverview> {
  static const double _nameColumnWidth = 240;
  static const double _dayCellWidth = 18;
  static const double _rowHeight = 32;
  static const double _sectionHeaderHeight = 36;

  final ScrollController _horizontalController = ScrollController();
  Set<String> _selectedSections = <String>{};

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groupedBySection = <String, Map<String, _UserPlanRow>>{};
    final holidaySet = widget.holidays.map((e) => _key(e.date)).toSet();

    for (final entry in widget.entries) {
      final section =
      entry.sectionName.trim().isEmpty ? 'Bez sekcji' : entry.sectionName;
      groupedBySection.putIfAbsent(section, () => <String, _UserPlanRow>{});

      final existing = groupedBySection[section]![entry.userId];
      if (existing == null) {
        groupedBySection[section]![entry.userId] = _UserPlanRow(
          userId: entry.userId,
          fullName: entry.fullName,
          sectionName: section,
          requests: [entry],
        );
      } else {
        existing.requests.add(entry);
      }
    }

    final allSectionNames = groupedBySection.keys.toList()..sort();

    if (_selectedSections.isEmpty && allSectionNames.isNotEmpty) {
      _selectedSections = allSectionNames.toSet();
    } else {
      _selectedSections = _selectedSections
          .where((section) => allSectionNames.contains(section))
          .toSet();
      if (_selectedSections.isEmpty && allSectionNames.isNotEmpty) {
        _selectedSections = allSectionNames.toSet();
      }
    }

    final visibleSectionNames = allSectionNames
        .where((section) => _selectedSections.contains(section))
        .toList();

    final rowsBySection = <String, List<_UserPlanRow>>{};
    for (final section in visibleSectionNames) {
      final rows = groupedBySection[section]!.values.toList()
        ..sort((a, b) => a.fullName.compareTo(b.fullName));
      rowsBySection[section] = rows;
    }

    final daysInYear = DateTime(widget.year + 1, 1, 1)
        .difference(DateTime(widget.year, 1, 1))
        .inDays;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Plan urlopów zespołu i eskadry • ${widget.year}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    FilterChip(
                      label: const Text('Wszystkie'),
                      selected: visibleSectionNames.length == allSectionNames.length &&
                          allSectionNames.isNotEmpty,
                      onSelected: (_) {
                        setState(() {
                          _selectedSections = allSectionNames.toSet();
                        });
                      },
                    ),
                    for (final section in allSectionNames)
                      FilterChip(
                        label: Text(section),
                        selected: _selectedSections.contains(section),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSections.add(section);
                            } else {
                              _selectedSections.remove(section);
                              if (_selectedSections.isEmpty) {
                                _selectedSections = allSectionNames.toSet();
                              }
                            }
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Scrollbar(
              controller: _horizontalController,
              thumbVisibility: true,
              trackVisibility: true,
              interactive: true,
              notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: _nameColumnWidth + (daysInYear * _dayCellWidth),
                  child: Column(
                    children: [
                      _buildHeader(context, daysInYear, holidaySet),
                      Expanded(
                        child: ListView(
                          children: [
                            for (final section in visibleSectionNames) ...[
                              _buildSectionHeader(context, section),
                              for (final row in rowsBySection[section]!)
                                _buildUserRow(
                                  context,
                                  row,
                                  daysInYear,
                                  holidaySet,
                                ),
                            ],
                            if (visibleSectionNames.isEmpty)
                              SizedBox(
                                height: 120,
                                child: Center(
                                  child: Text(
                                    'Brak sekcji do wyświetlenia.',
                                    style:
                                    Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                            if (allSectionNames.isEmpty)
                              SizedBox(
                                height: 120,
                                child: Center(
                                  child: Text(
                                    'Brak zaplanowanych urlopów w tym roku.',
                                    style:
                                    Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String section) {
    return SizedBox(
      height: _sectionHeaderHeight,
      child: Row(
        children: [
          Container(
            width: _nameColumnWidth,
            height: _sectionHeaderHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.35),
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Text(
              section,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Expanded(
            child: Container(
              height: _sectionHeaderHeight,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.18),
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context,
      int daysInYear,
      Set<String> holidaySet,
      ) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Container(
            width: _nameColumnWidth,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: const Text('Nazwisko i imię'),
          ),
          ...List.generate(daysInYear, (index) {
            final date = DateTime(widget.year, 1, 1).add(Duration(days: index));
            final isWeekend = date.weekday >= DateTime.saturday;
            final isHoliday = holidaySet.contains(_key(date));

            return Container(
              width: _dayCellWidth,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isHoliday
                    ? Colors.redAccent.withValues(alpha: 0.18)
                    : isWeekend
                    ? Colors.white.withValues(alpha: 0.06)
                    : null,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
                  ),
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  '${date.day}.${date.month}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUserRow(
      BuildContext context,
      _UserPlanRow row,
      int daysInYear,
      Set<String> holidaySet,
      ) {
    return SizedBox(
      height: _rowHeight,
      child: Row(
        children: [
          Container(
            width: _nameColumnWidth,
            height: _rowHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: Theme.of(context).dividerColor),
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Text(
              row.fullName + (row.userId == widget.currentUserId ? ' (ja)' : ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...List.generate(daysInYear, (index) {
            final date = DateTime(widget.year, 1, 1).add(Duration(days: index));
            final isWeekend = date.weekday >= DateTime.saturday;
            final isHoliday = holidaySet.contains(_key(date));
            final isPlanned = row.requests.any(
                  (entry) =>
              !date.isBefore(entry.request.startDate) &&
                  !date.isAfter(entry.request.endDate),
            );

            return Container(
              width: _dayCellWidth,
              height: _rowHeight,
              decoration: BoxDecoration(
                color: isPlanned
                    ? (row.userId == widget.currentUserId
                    ? Colors.lightBlueAccent.withValues(alpha: 0.65)
                    : Colors.orangeAccent.withValues(alpha: 0.55))
                    : isHoliday
                    ? Colors.redAccent.withValues(alpha: 0.12)
                    : isWeekend
                    ? Colors.white.withValues(alpha: 0.04)
                    : null,
                border: Border(
                  right: BorderSide(
                    color:
                    Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _key(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

class _UserPlanRow {
  _UserPlanRow({
    required this.userId,
    required this.fullName,
    required this.sectionName,
    required this.requests,
  });

  final String userId;
  final String fullName;
  final String sectionName;
  final List<TeamLeavePlanEntry> requests;
}
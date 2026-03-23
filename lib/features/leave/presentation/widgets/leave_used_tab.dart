import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/ops_panel.dart';
import '../../../obecnosci/domain/models/attendance_entry.dart';
import '../providers/leave_providers.dart';

class LeaveUsedTab extends ConsumerWidget {
  const LeaveUsedTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(currentYearLeaveUsageSummaryProvider);
    final usedEntriesAsync = ref.watch(currentYearUsedLeaveEntriesProvider);

    return OpsPanel(
      child: summaryAsync.when(
        data: (summary) {
          return usedEntriesAsync.when(
            data: (usedEntries) {
              final groupedEntries = _groupLeaveEntries(usedEntries);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wykorzystany urlop • ${summary.year}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Liczone z obecności. Planowany urlop nie wpływa na te wartości.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      _StatCard(
                        title: 'Wypoczynkowy',
                        available: summary.availableVacation,
                        used: summary.usedVacation,
                        remaining: summary.remainingVacation,
                      ),
                      _StatCard(
                        title: 'Dodatkowy',
                        available: summary.availableAdditional,
                        used: summary.usedAdditional,
                        remaining: summary.remainingAdditional,
                      ),
                      _StatCard(
                        title: 'Nagrodowy',
                        available: summary.availableReward,
                        used: summary.usedReward,
                        remaining: summary.remainingReward,
                      ),
                      _StatCard(
                        title: 'Razem',
                        available: summary.totalAvailable,
                        used: summary.totalUsed,
                        remaining: summary.totalRemaining,
                        highlight: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Rozliczone dni z obecności',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Expanded(
                    child: groupedEntries.isEmpty
                        ? const Center(
                      child: Text('Brak wykorzystanych urlopów w tym roku.'),
                    )
                        : ListView.separated(
                      itemCount: groupedEntries.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final item = groupedEntries[index];

                        return ListTile(
                          leading:
                          const Icon(Icons.beach_access_outlined),
                          title: Text(
                            _attendanceLabel(item.attendanceType),
                          ),
                          subtitle: Text(
                            _buildGroupSubtitle(item),
                          ),
                          trailing: Text(
                            item.daysCount == 1
                                ? '1 dzień'
                                : '${item.daysCount} dni',
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Błąd: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Błąd: $error')),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.available,
    required this.used,
    required this.remaining,
    this.highlight = false,
  });

  final String title;
  final int available;
  final int used;
  final int remaining;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 260,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(
          color: highlight ? theme.colorScheme.primary : theme.dividerColor,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.md),
          _line(theme, 'Mam', available),
          const SizedBox(height: AppSpacing.xs),
          _line(theme, 'Wykorzystałem', used),
          const SizedBox(height: AppSpacing.xs),
          _line(theme, 'Zostało', remaining),
        ],
      ),
    );
  }

  Widget _line(ThemeData theme, String label, int value) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Text(
          '$value',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _GroupedLeaveEntry {
  const _GroupedLeaveEntry({
    required this.attendanceType,
    required this.startDate,
    required this.endDate,
    required this.daysCount,
    required this.notes,
  });

  final AttendanceType attendanceType;
  final DateTime startDate;
  final DateTime endDate;
  final int daysCount;
  final List<String> notes;
}

List<_GroupedLeaveEntry> _groupLeaveEntries(List<AttendanceEntry> entries) {
  if (entries.isEmpty) return const [];

  final sorted = [...entries]
    ..sort((a, b) => a.attendanceDate.compareTo(b.attendanceDate));

  final groups = <_GroupedLeaveEntry>[];

  AttendanceEntry first = sorted.first;
  AttendanceEntry last = sorted.first;
  final notes = <String>[];
  _addNoteIfPresent(notes, sorted.first.note);

  for (var i = 1; i < sorted.length; i++) {
    final current = sorted[i];
    final sameType = current.attendanceType == last.attendanceType;
    final isNextDay = _isNextCalendarDay(last.attendanceDate, current.attendanceDate);

    if (sameType && isNextDay) {
      last = current;
      _addNoteIfPresent(notes, current.note);
      continue;
    }

    groups.add(
      _GroupedLeaveEntry(
        attendanceType: first.attendanceType,
        startDate: _normalizeDate(first.attendanceDate),
        endDate: _normalizeDate(last.attendanceDate),
        daysCount:
        _normalizeDate(last.attendanceDate).difference(_normalizeDate(first.attendanceDate)).inDays + 1,
        notes: List.unmodifiable(notes),
      ),
    );

    first = current;
    last = current;
    notes
      ..clear()
      ..addAll(_noteList(current.note));
  }

  groups.add(
    _GroupedLeaveEntry(
      attendanceType: first.attendanceType,
      startDate: _normalizeDate(first.attendanceDate),
      endDate: _normalizeDate(last.attendanceDate),
      daysCount:
      _normalizeDate(last.attendanceDate).difference(_normalizeDate(first.attendanceDate)).inDays + 1,
      notes: List.unmodifiable(notes),
    ),
  );

  return groups.reversed.toList();
}

bool _isNextCalendarDay(DateTime previous, DateTime current) {
  final a = _normalizeDate(previous);
  final b = _normalizeDate(current);
  return b.difference(a).inDays == 1;
}

DateTime _normalizeDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

void _addNoteIfPresent(List<String> notes, String? raw) {
  final normalized = raw?.trim() ?? '';
  if (normalized.isEmpty) return;
  if (!notes.contains(normalized)) {
    notes.add(normalized);
  }
}

List<String> _noteList(String? raw) {
  final notes = <String>[];
  _addNoteIfPresent(notes, raw);
  return notes;
}

String _buildGroupSubtitle(_GroupedLeaveEntry item) {
  final start = item.startDate;
  final end = item.endDate;

  final dateText = start == end
      ? '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}.${start.year}'
      : '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}.${start.year}'
      ' - '
      '${end.day.toString().padLeft(2, '0')}.${end.month.toString().padLeft(2, '0')}.${end.year}';

  if (item.notes.isEmpty) {
    return dateText;
  }

  return '$dateText • ${item.notes.join(' • ')}';
}

String _attendanceLabel(AttendanceType type) {
  switch (type) {
    case AttendanceType.urlopWypoczynkowy:
      return 'Urlop wypoczynkowy';
    case AttendanceType.urlopNagrodowy:
      return 'Urlop nagrodowy';
    case AttendanceType.urlopDodatkowy:
      return 'Urlop dodatkowy';
    case AttendanceType.sztab:
      return 'Sztab';
    case AttendanceType.loty:
      return 'Loty';
    case AttendanceType.podrozSluzbowa:
      return 'Podróż służbowa';
    case AttendanceType.inne:
      return 'Inne';
    case AttendanceType.l4:
      return 'L4';
    case AttendanceType.sluzba:
      return 'Służba';
    case AttendanceType.poSluzbie:
      return 'Po służbie';
  }
}
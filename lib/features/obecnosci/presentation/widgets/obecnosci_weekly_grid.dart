import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/attendance_entry.dart';
import '../providers/attendance_provider.dart';
import 'attendance_entry_dialog.dart';

class ObecnosciWeeklyGrid extends ConsumerWidget {
  const ObecnosciWeeklyGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final weekStart = ref.watch(attendanceWeekStartProvider);
    final entriesAsync = ref.watch(currentWeekAttendanceEntriesProvider);
    final peopleAsync = ref.watch(attendancePeopleProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.30),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: peopleAsync.when(
        data: (people) {
          return entriesAsync.when(
            data: (entries) {
              final weekDays = List.generate(
                7,
                (index) => weekStart.add(Duration(days: index)),
              );

              final entriesByPersonAndDay = <String, List<AttendanceEntry>>{};
              for (final entry in entries) {
                final key = '${entry.personId}_${_dateKey(entry.attendanceDate)}';
                entriesByPersonAndDay.putIfAbsent(key, () => []);
                entriesByPersonAndDay[key]!.add(entry);
              }

              for (final dayEntries in entriesByPersonAndDay.values) {
                dayEntries.sort((a, b) {
                  final aKey = a.isAllDay ? '00:00:00' : (a.timeFrom ?? '');
                  final bKey = b.isAllDay ? '00:00:00' : (b.timeFrom ?? '');
                  return aKey.compareTo(bKey);
                });
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 900;
                  final isVeryCompact = constraints.maxWidth < 700;

                  final leftColumnWidth = isVeryCompact
                      ? 96.0
                      : isCompact
                          ? 128.0
                          : 180.0;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kalendarz tygodniowy zespołu',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kliknij wpis w siatce, aby zobaczyć opis i edytować obecność.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Column(
                          children: [
                            _HeaderRow(
                              weekDays: weekDays,
                              leftColumnWidth: leftColumnWidth,
                              compact: isCompact,
                              veryCompact: isVeryCompact,
                            ),
                            const Divider(height: 16),
                            Expanded(
                              child: ListView.separated(
                                itemCount: people.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final person = people[index];

                                  return _PersonWeekRow(
                                    personName: person.fullName,
                                    personId: person.id,
                                    weekDays: weekDays,
                                    entriesByPersonAndDay: entriesByPersonAndDay,
                                    leftColumnWidth: leftColumnWidth,
                                    compact: isCompact,
                                    veryCompact: isVeryCompact,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Center(
              child: Text('Błąd ładowania obecności: $error'),
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('Błąd ładowania personelu: $error'),
        ),
      ),
    );
  }

  static String _dateKey(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    return normalized.toIso8601String().split('T').first;
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.weekDays,
    required this.leftColumnWidth,
    required this.compact,
    required this.veryCompact,
  });

  final List<DateTime> weekDays;
  final double leftColumnWidth;
  final bool compact;
  final bool veryCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: leftColumnWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 8,
            ),
            child: Text(
              veryCompact ? 'Os.' : 'Osoba',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        ...weekDays.map(
          (day) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 2,
              ),
              child: Column(
                children: [
                  Text(
                    _weekdayLabel(day.weekday, compact: compact),
                    style: theme.textTheme.labelLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _weekdayLabel(int weekday, {required bool compact}) {
    switch (weekday) {
      case DateTime.monday:
        return compact ? 'Pn' : 'Pn';
      case DateTime.tuesday:
        return compact ? 'Wt' : 'Wt';
      case DateTime.wednesday:
        return compact ? 'Śr' : 'Śr';
      case DateTime.thursday:
        return compact ? 'Cz' : 'Cz';
      case DateTime.friday:
        return compact ? 'Pt' : 'Pt';
      case DateTime.saturday:
        return compact ? 'Sb' : 'Sb';
      case DateTime.sunday:
        return compact ? 'Nd' : 'Nd';
      default:
        return '';
    }
  }
}

class _PersonWeekRow extends StatelessWidget {
  const _PersonWeekRow({
    required this.personName,
    required this.personId,
    required this.weekDays,
    required this.entriesByPersonAndDay,
    required this.leftColumnWidth,
    required this.compact,
    required this.veryCompact,
  });

  final String personName;
  final String personId;
  final List<DateTime> weekDays;
  final Map<String, List<AttendanceEntry>> entriesByPersonAndDay;
  final double leftColumnWidth;
  final bool compact;
  final bool veryCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: leftColumnWidth,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              veryCompact ? _shortName(personName) : personName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: veryCompact ? 3 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        ...weekDays.map((day) {
          final key = '${personId}_${_dateKey(day)}';
          final dayEntries =
              entriesByPersonAndDay[key] ?? const <AttendanceEntry>[];

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _WeekDayCell(
                personId: personId,
                personName: personName,
                entries: dayEntries,
                compact: compact,
                veryCompact: veryCompact,
              ),
            ),
          );
        }),
      ],
    );
  }

  static String _dateKey(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    return normalized.toIso8601String().split('T').first;
  }

  static String _shortName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return fullName;
    if (parts.length == 1) return parts.first;

    final first = parts.first;
    final last = parts.last;
    final initial = first.isNotEmpty ? '${first[0]}.' : '';
    return '$initial $last';
  }
}

class _WeekDayCell extends ConsumerWidget {
  const _WeekDayCell({
    required this.personId,
    required this.personName,
    required this.entries,
    required this.compact,
    required this.veryCompact,
  });

  final String personId;
  final String personName;
  final List<AttendanceEntry> entries;
  final bool compact;
  final bool veryCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(entries);

    return Container(
      constraints: BoxConstraints(
        minHeight: veryCompact ? 54 : (compact ? 64 : 72),
      ),
      padding: EdgeInsets.all(veryCompact ? 3 : (compact ? 4 : 6)),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.10),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.60),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: entries.isEmpty
          ? Center(
              child: Text(
                '—',
                style: theme.textTheme.bodySmall,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries
                  .map(
                    (entry) => InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        await _handleEntryTap(
                          context: context,
                          ref: ref,
                          entry: entry,
                        );
                      },
                      onLongPress: () async {
                        await _showEntryDetails(
                          context: context,
                          entry: entry,
                          personName: personName,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: EdgeInsets.symmetric(
                          horizontal: veryCompact ? 3 : (compact ? 4 : 6),
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _chipColor(entry.attendanceType)
                              .withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _entryLabel(
                                entry,
                                compact: compact,
                                veryCompact: veryCompact,
                              ),
                              style: veryCompact
                                  ? theme.textTheme.labelSmall
                                  : compact
                                      ? theme.textTheme.labelSmall
                                      : theme.textTheme.bodySmall,
                              maxLines: veryCompact ? 4 : (compact ? 3 : 2),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (!veryCompact &&
                                !compact &&
                                entry.note.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                entry.note,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.75),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Future<void> _handleEntryTap({
    required BuildContext context,
    required WidgetRef ref,
    required AttendanceEntry entry,
  }) async {
    final draft = await showAttendanceEntryDialog(
      context,
      existingEntry: entry,
      fixedPersonId: entry.personId,
      fixedPersonLabel: personName,
      initialDate: entry.attendanceDate,
    );
    if (draft == null) return;

    try {
      await ref.read(attendanceControllerProvider).updateEntry(
            id: entry.id,
            attendanceDate: draft.dateFrom,
            attendanceType: draft.attendanceType,
            isAllDay: draft.isAllDay,
            timeFrom: draft.timeFrom,
            timeTo: draft.timeTo,
            note: draft.note,
          );
    } catch (error) {
      final message = error is AuthException
          ? error.message
          : 'Nie udało się zapisać zmian.';
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _showEntryDetails({
    required BuildContext context,
    required AttendanceEntry entry,
    required String personName,
  }) async {
    final theme = Theme.of(context);

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              children: [
                Text(
                  personName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Typ obecności'),
                  subtitle: Text(entry.attendanceType.label),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Zakres'),
                  subtitle: Text(
                    entry.isAllDay
                        ? 'Cały dzień'
                        : '${_normalizeTime(entry.timeFrom)} - ${_normalizeTime(entry.timeTo)}',
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Opis'),
                  subtitle: Text(
                    entry.note.trim().isEmpty ? 'Brak opisu.' : entry.note,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kliknięcie wpisu w siatce otwiera edycję. Dłuższe przytrzymanie pokazuje szczegóły.',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Color _statusColor(List<AttendanceEntry> entries) {
    if (entries.isEmpty) {
      return Colors.grey;
    }

    final hasPresence = entries.any((e) => e.attendanceType.countsAsPresence);
    return hasPresence ? Colors.green : Colors.red;
  }

  static Color _chipColor(AttendanceType type) {
    switch (type) {
      case AttendanceType.sztab:
        return Colors.green;
      case AttendanceType.loty:
        return Colors.blue;
      case AttendanceType.podrozSluzbowa:
        return Colors.orange;
      case AttendanceType.inne:
        return Colors.teal;
      case AttendanceType.l4:
        return Colors.red;
      case AttendanceType.sluzba:
        return Colors.indigo;
      case AttendanceType.poSluzbie:
        return Colors.brown;
      case AttendanceType.urlopWypoczynkowy:
      case AttendanceType.urlopNagrodowy:
      case AttendanceType.urlopDodatkowy:
        return Colors.purple;
    }
  }

  static String _entryLabel(
    AttendanceEntry entry, {
    required bool compact,
    required bool veryCompact,
  }) {
    final label =
        veryCompact ? _veryShortType(entry.attendanceType) : entry.attendanceType.label;

    if (entry.isAllDay) {
      return veryCompact ? label : '$label\nCały dzień';
    }

    final from = _normalizeTime(entry.timeFrom);
    final to = _normalizeTime(entry.timeTo);
    return '$label\n$from-$to';
  }

  static String _veryShortType(AttendanceType type) {
    switch (type) {
      case AttendanceType.sztab:
        return 'SZ';
      case AttendanceType.loty:
        return 'LT';
      case AttendanceType.podrozSluzbowa:
        return 'PD';
      case AttendanceType.inne:
        return 'IN';
      case AttendanceType.l4:
        return 'L4';
      case AttendanceType.sluzba:
        return 'SL';
      case AttendanceType.poSluzbie:
        return 'PS';
      case AttendanceType.urlopWypoczynkowy:
        return 'UW';
      case AttendanceType.urlopNagrodowy:
        return 'UN';
      case AttendanceType.urlopDodatkowy:
        return 'UD';
    }
  }

  static String _normalizeTime(String? value) {
    if (value == null || value.trim().isEmpty) return '--:--';
    final parts = value.split(':');
    if (parts.length < 2) return value;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
}

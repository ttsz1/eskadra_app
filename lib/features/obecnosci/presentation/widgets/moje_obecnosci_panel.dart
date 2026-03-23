import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/supabase/supabase_client_provider.dart';
import '../../domain/models/attendance_entry.dart';
import '../providers/attendance_provider.dart';
import 'attendance_entry_dialog.dart';

class MojeObecnosciPanel extends ConsumerWidget {
  const MojeObecnosciPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final client = ref.watch(supabaseClientProvider);
    final currentUserId = client.auth.currentUser?.id;

    if (currentUserId == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.30),
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Brak aktywnej sesji Supabase.'),
        ),
      );
    }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moje zgłoszone obecności',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: peopleAsync.when(
              data: (people) {
                final me = people.where((p) => p.id == currentUserId).toList();
                final myLabel = me.isNotEmpty ? me.first.fullName : 'Ja';

                return entriesAsync.when(
                  data: (entries) {
                    final myEntries = entries
                        .where((entry) => entry.personId == currentUserId)
                        .toList();

                    final weekDays = List.generate(
                      7,
                          (index) => weekStart.add(Duration(days: index)),
                    );

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: weekDays.map((day) {
                        final dayEntries = myEntries
                            .where((entry) => _sameDay(entry.attendanceDate, day))
                            .toList()
                          ..sort((a, b) {
                            final aKey =
                            a.isAllDay ? '00:00:00' : (a.timeFrom ?? '');
                            final bKey =
                            b.isAllDay ? '00:00:00' : (b.timeFrom ?? '');
                            return aKey.compareTo(bKey);
                          });

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: _MyDayColumn(
                              day: day,
                              entries: dayEntries,
                              personId: currentUserId,
                              personLabel: myLabel,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, _) =>
                      Text('Błąd ładowania wpisów: $error'),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Text('Błąd ładowania profilu: $error'),
            ),
          ),
        ],
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MyDayColumn extends ConsumerWidget {
  const _MyDayColumn({
    required this.day,
    required this.entries,
    required this.personId,
    required this.personLabel,
  });

  final DateTime day;
  final List<AttendanceEntry> entries;
  final String personId;
  final String personLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.50),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _weekdayLabel(day.weekday),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: entries.isEmpty
                ? Center(
              child: IconButton(
                onPressed: () async {
                  final draft = await showAttendanceEntryDialog(
                    context,
                    fixedPersonId: personId,
                    fixedPersonLabel: personLabel,
                    initialDate: day,
                  );
                  if (draft == null) return;

                  try {
                    await ref.read(attendanceControllerProvider).createEntriesBatch(
                      personIds: draft.personIds,
                      dateFrom: draft.dateFrom,
                      dateTo: draft.dateTo,
                      repeatMode: draft.repeatMode,
                      applyMonday: draft.applyMonday,
                      applyTuesday: draft.applyTuesday,
                      applyWednesday: draft.applyWednesday,
                      applyThursday: draft.applyThursday,
                      applyFriday: draft.applyFriday,
                      applySaturday: draft.applySaturday,
                      applySunday: draft.applySunday,
                      attendanceType: draft.attendanceType,
                      isAllDay: draft.isAllDay,
                      timeFrom: draft.timeFrom,
                      timeTo: draft.timeTo,
                      note: draft.note,
                    );
                  } catch (error) {
                    final message = error is AuthException
                        ? error.message
                        : 'Nie udało się dodać obecności.';
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                  }
                },
                tooltip: 'Dodaj wpis',
                icon: const Icon(Icons.add),
              ),
            )
                : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _MyEntryCard(
                  entry: entry,
                  personLabel: personLabel,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Pn';
      case DateTime.tuesday:
        return 'Wt';
      case DateTime.wednesday:
        return 'Śr';
      case DateTime.thursday:
        return 'Cz';
      case DateTime.friday:
        return 'Pt';
      case DateTime.saturday:
        return 'Sb';
      case DateTime.sunday:
        return 'Nd';
      default:
        return '';
    }
  }
}

class _MyEntryCard extends ConsumerWidget {
  const _MyEntryCard({
    required this.entry,
    required this.personLabel,
  });

  final AttendanceEntry entry;
  final String personLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _chipColor(entry.attendanceType).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.attendanceType.label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            entry.isAllDay
                ? 'Cały dzień'
                : '${_normalizeTime(entry.timeFrom)} - ${_normalizeTime(entry.timeTo)}',
            style: theme.textTheme.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (entry.note.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              entry.note,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
              padding: EdgeInsets.zero,
              tooltip: 'Edytuj',
              onPressed: () async {
                final draft = await showAttendanceEntryDialog(
                  context,
                  existingEntry: entry,
                  fixedPersonId: entry.personId,
                  fixedPersonLabel: personLabel,
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
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
            ),
          ),
        ],
      ),
    );
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

  static String _normalizeTime(String? value) {
    if (value == null || value.trim().isEmpty) return '--:--';
    final parts = value.split(':');
    if (parts.length < 2) return value;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
}
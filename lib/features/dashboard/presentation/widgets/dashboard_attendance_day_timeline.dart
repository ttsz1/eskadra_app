import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/models/org_structure.dart';
import '../../../../shared/widgets/ops_panel.dart';
import '../../../../shared/widgets/ops_section_header.dart';
import '../../../obecnosci/domain/models/attendance_entry.dart';
import '../../../obecnosci/presentation/providers/attendance_provider.dart';
import '../../../obecnosci/presentation/widgets/attendance_entry_dialog.dart';
import '../../../profiles/presentation/providers/profile_directory_provider.dart';

class DashboardAttendanceDayTimeline extends ConsumerWidget {
  const DashboardAttendanceDayTimeline({super.key});

  static const double _leftColumnWidth = 140;
  static const double _hourWidth = 18;
  static const int _startHour = 0;
  static const int _endHour = 24;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(currentWeekAttendanceEntriesProvider);
    final peopleById = ref.watch(peopleByIdProvider);
    final today = DateTime.now();
    final todayKey = _dateKey(today);

    return OpsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OpsSectionHeader(
            eyebrow: 'Obecności',
            title: 'Dzisiejsza obecność zespołu',
            subtitle:
                'Timeline dnia z podziałem na godziny, pogrupowany według sekcji. Kliknij wpis, aby edytować.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: entriesAsync.when(
              data: (entries) {
                final todayEntries = entries
                    .where((e) => _dateKey(e.attendanceDate) == todayKey)
                    .toList();

                if (todayEntries.isEmpty) {
                  return const Center(
                    child: Text('Brak wpisów obecności na dzisiaj.'),
                  );
                }

                final grouped = <String, Map<String, List<AttendanceEntry>>>{};

                for (final entry in todayEntries) {
                  final person = peopleById[entry.personId];
                  final orgKey = _personOrgKey(person);
                  final personName = person?.fullName ?? 'Nieznana osoba';

                  grouped.putIfAbsent(orgKey, () => <String, List<AttendanceEntry>>{});
                  grouped[orgKey]!.putIfAbsent(personName, () => <AttendanceEntry>[]);
                  grouped[orgKey]![personName]!.add(entry);
                }

                final sortedOrgKeys = grouped.keys.toList()
                  ..sort((a, b) {
                    if (a == 'unassigned') return 1;
                    if (b == 'unassigned') return -1;
                    return _orgLabel(a)
                        .toLowerCase()
                        .compareTo(_orgLabel(b).toLowerCase());
                  });

                for (final orgKey in sortedOrgKeys) {
                  final peopleMap = grouped[orgKey]!;
                  for (final list in peopleMap.values) {
                    list.sort((a, b) {
                      final aStart = _startMinutes(a);
                      final bStart = _startMinutes(b);
                      return aStart.compareTo(bStart);
                    });
                  }
                }

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _leftColumnWidth + ((_endHour - _startHour) * _hourWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TimelineHeader(
                          leftColumnWidth: _leftColumnWidth,
                          hourWidth: _hourWidth,
                          startHour: _startHour,
                          endHour: _endHour,
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView(
                            children: sortedOrgKeys.map((orgKey) {
                              final peopleMap = grouped[orgKey]!;
                              final sortedPeople = peopleMap.keys.toList()
                                ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _SectionHeaderRow(
                                      title: _orgLabel(orgKey),
                                      count: sortedPeople.length,
                                    ),
                                    const SizedBox(height: 8),
                                    ...sortedPeople.map((personName) {
                                      final entries = peopleMap[personName]!;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: _TimelinePersonRow(
                                          personName: personName,
                                          entries: entries,
                                          leftColumnWidth: _leftColumnWidth,
                                          hourWidth: _hourWidth,
                                          startHour: _startHour,
                                          endHour: _endHour,
                                          onEdit: (entry) async {
                                            final draft = await showAttendanceEntryDialog(
                                              context,
                                              existingEntry: entry,
                                              fixedPersonId: entry.personId,
                                              fixedPersonLabel: personName,
                                              initialDate: entry.attendanceDate,
                                            );
                                            if (draft == null) return;

                                            try {
                                              await ref
                                                  .read(attendanceControllerProvider)
                                                  .updateEntry(
                                                    id: entry.id,
                                                    attendanceDate: draft.dateFrom,
                                                    attendanceType: draft.attendanceType,
                                                    isAllDay: draft.isAllDay,
                                                    timeFrom: draft.timeFrom,
                                                    timeTo: draft.timeTo,
                                                    note: draft.note,
                                                  );
                                            } catch (error) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Nie udało się zapisać zmian: $error',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Text('Błąd ładowania obecności: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _dateKey(DateTime value) {
    final normalized = DateTime(value.year, value.month, value.day);
    return normalized.toIso8601String().split('T').first;
  }

  static String _personOrgKey(AppPerson? person) {
    if (person == null) return 'unassigned';
    final raw = person.unit;
    return _normalizeOrgKey(raw);
  }

  static String _normalizeOrgKey(Object? value) {
    if (value == null) return 'unassigned';

    final raw = value.toString().trim();
    if (raw.isEmpty) return 'unassigned';

    switch (raw) {
      case 'OrgUnit.command':
      case 'command':
        return 'command';
      case 'OrgUnit.flightTrainingSection':
      case 'flightTrainingSection':
      case 'flight_training_section':
        return 'flight_training_section';
      case 'OrgUnit.standardizationAndEvaluationSection':
      case 'standardizationAndEvaluationSection':
      case 'standardization_and_evaluation_section':
        return 'standardization_and_evaluation_section';
      case 'OrgUnit.currentOperationsSection':
      case 'currentOperationsSection':
      case 'current_operations_section':
        return 'current_operations_section';
      case 'OrgUnit.wysRatSupportSection':
      case 'wysRatSupportSection':
      case 'wys_rat_support_section':
        return 'wys_rat_support_section';
      case 'OrgUnit.trainerDeviceSupport':
      case 'trainerDeviceSupport':
      case 'trainer_device_support':
        return 'trainer_device_support';
      case 'OrgUnit.flightTrainingSubunit':
      case 'flightTrainingSubunit':
      case 'flight_training_subunit':
        return 'flight_training_subunit';
      default:
        return raw;
    }
  }

  static String _orgLabel(String value) {
    switch (value) {
      case 'command':
        return 'Dowództwo';
      case 'flight_training_section':
        return 'Sekcja szkolenia lotniczego';
      case 'standardization_and_evaluation_section':
        return 'Sekcja standaryzacji i oceny';
      case 'current_operations_section':
        return 'Sekcja operacji bieżących';
      case 'wys_rat_support_section':
        return 'Sekcja wsparcia WYS/RAT';
      case 'trainer_device_support':
        return 'Wsparcie urządzeń treningowych';
      case 'flight_training_subunit':
        return 'Pododdział szkolenia lotniczego';
      case 'unassigned':
        return 'Bez przypisanej sekcji';
      default:
        return value;
    }
  }

  static int _startMinutes(AttendanceEntry entry) {
    if (entry.isAllDay) return _startHour * 60;
    return _timeToMinutes(entry.timeFrom) ?? (_startHour * 60);
  }

  static int _endMinutes(AttendanceEntry entry) {
    if (entry.isAllDay) return _endHour * 60;
    return _timeToMinutes(entry.timeTo) ?? (_endHour * 60);
  }

  static int? _timeToMinutes(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    return hour * 60 + minute;
  }

  static String _normalizeTime(String? value) {
    if (value == null || value.trim().isEmpty) return '--:--';
    final parts = value.split(':');
    if (parts.length < 2) return value;
    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
}

class _TimelineHeader extends StatelessWidget {
  const _TimelineHeader({
    required this.leftColumnWidth,
    required this.hourWidth,
    required this.startHour,
    required this.endHour,
  });

  final double leftColumnWidth;
  final double hourWidth;
  final int startHour;
  final int endHour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: leftColumnWidth,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Osoba',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        ...List.generate(endHour - startHour, (index) {
          final hour = startHour + index;
          return Container(
            width: hourWidth,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: theme.textTheme.labelSmall,
            ),
          );
        }),
      ],
    );
  }
}

class _SectionHeaderRow extends StatelessWidget {
  const _SectionHeaderRow({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.groups_2_outlined,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          '$title ($count)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TimelinePersonRow extends StatelessWidget {
  const _TimelinePersonRow({
    required this.personName,
    required this.entries,
    required this.leftColumnWidth,
    required this.hourWidth,
    required this.startHour,
    required this.endHour,
    required this.onEdit,
  });

  final String personName;
  final List<AttendanceEntry> entries;
  final double leftColumnWidth;
  final double hourWidth;
  final int startHour;
  final int endHour;
  final Future<void> Function(AttendanceEntry entry) onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timelineWidth = (endHour - startHour) * hourWidth;
    const rowHeight = 44.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: leftColumnWidth,
          child: Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Text(
              personName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        SizedBox(
          width: timelineWidth,
          height: rowHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: Row(
                  children: List.generate(endHour - startHour, (index) {
                    return Container(
                      width: hourWidth,
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: theme.dividerColor.withValues(alpha: 0.55),
                          ),
                          right: index == (endHour - startHour - 1)
                              ? BorderSide(
                                  color: theme.dividerColor.withValues(alpha: 0.55),
                                )
                              : BorderSide.none,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              ...entries.asMap().entries.map((indexed) {
                final lane = indexed.key;
                final entry = indexed.value;

                final startMin = DashboardAttendanceDayTimeline._startMinutes(entry);
                final endMin = DashboardAttendanceDayTimeline._endMinutes(entry);

                final clampedStart = startMin.clamp(startHour * 60, endHour * 60);
                final clampedEnd = endMin.clamp(startHour * 60, endHour * 60);

                final startOffsetHours = (clampedStart - (startHour * 60)) / 60.0;
                final durationHours =
                    ((clampedEnd - clampedStart) / 60.0).clamp(0.5, 24.0);

                final left = startOffsetHours * hourWidth;
                final width = durationHours * hourWidth;

                return Positioned(
                  left: left,
                  top: lane * 6.0,
                  width: width,
                  height: rowHeight - 12,
                  child: _AttendanceBlock(
                    entry: entry,
                    onTap: () => onEdit(entry),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _AttendanceBlock extends StatelessWidget {
  const _AttendanceBlock({
    required this.entry,
    required this.onTap,
  });

  final AttendanceEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _chipColor(entry.attendanceType);
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          border: Border.all(color: color.withValues(alpha: 0.45)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: DefaultTextStyle(
          style: theme.textTheme.bodySmall!.copyWith(
            height: 1,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _header(entry),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              if (entry.note.trim().isNotEmpty) ...[
                const SizedBox(height: 2),
                Expanded(
                  child: Text(
                    entry.note,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _header(AttendanceEntry entry) {
    final typeLabel = entry.attendanceType.label;
    if (entry.isAllDay) {
      return '$typeLabel • cały dzień';
    }

    final from = DashboardAttendanceDayTimeline._normalizeTime(entry.timeFrom);
    final to = DashboardAttendanceDayTimeline._normalizeTime(entry.timeTo);
    return '$typeLabel $from - $to';
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
}

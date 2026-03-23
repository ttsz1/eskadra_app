import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/ops_panel.dart';
import '../../../../shared/widgets/ops_section_header.dart';
import '../../../events/domain/models/event_item.dart';
import '../../../events/presentation/providers/upcoming_events_provider.dart';
import '../../../leave/domain/models/leave_request.dart';
import '../../../leave/presentation/providers/leave_providers.dart';
import '../../../obecnosci/domain/models/attendance_entry.dart';
import '../../../obecnosci/presentation/providers/attendance_provider.dart';
import '../../../tasks/domain/enums/task_status.dart';
import '../../../tasks/domain/models/task_item.dart';
import '../../../tasks/presentation/providers/task_module_provider.dart';
import '../../domain/models/personal_calendar_entry.dart';
import '../dialogs/personal_calendar_entry_dialog.dart';
import '../providers/my_calendar_entries_provider.dart';

class MyCalendarMonthPanel extends ConsumerStatefulWidget {
  const MyCalendarMonthPanel({
    super.key,
    this.compact = false,
    this.showOuterPanel = true,
    this.title = 'Widok miesiąca',
    this.subtitle =
    'Nałożone moje obecności, urlopy, wydarzenia, terminy i prywatne wpisy.',
  });

  final bool compact;
  final bool showOuterPanel;
  final String title;
  final String subtitle;

  @override
  ConsumerState<MyCalendarMonthPanel> createState() =>
      _MyCalendarMonthPanelState();
}

class _MyCalendarMonthPanelState extends ConsumerState<MyCalendarMonthPanel> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _visibleMonth = DateTime(now.year, now.month);
    _selectedDay = DateTime(now.year, now.month, now.day);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskState = ref.watch(taskModuleProvider);
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final personalEntries = ref.watch(myCalendarEntriesProvider);
    final plannedLeavesAsync =
    ref.watch(myPlannedLeavesForYearProvider(_visibleMonth.year));

    final attendanceRange = AttendanceRange(
      start: DateTime(_visibleMonth.year, _visibleMonth.month, 1),
      end: DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0),
    );

    final myAttendanceEntriesAsync =
    ref.watch(myAttendanceEntriesInRangeProvider(attendanceRange));

    final myTasks = _resolveMyTasks(taskState);
    final myDeadlines = myTasks.where((task) => !task.isArchived).toList();
    final myEvents = _resolveMyEvents(eventsAsync);

    final myAttendanceEntries = myAttendanceEntriesAsync.maybeWhen(
      data: (entries) => entries
          .where((entry) => entry.attendanceType.countsAsPresence)
          .toList(),
      orElse: () => const <AttendanceEntry>[],
    );

    final myLeaveEntries = myAttendanceEntriesAsync.maybeWhen(
      data: (entries) => entries
          .where((entry) => !entry.attendanceType.countsAsPresence)
          .toList(),
      orElse: () => const <AttendanceEntry>[],
    );

    final myPlannedLeaves = plannedLeavesAsync.maybeWhen(
      data: (items) => items,
      orElse: () => const <LeaveRequest>[],
    );

    final markers = _buildMarkers(
      deadlines: myDeadlines,
      events: myEvents,
      attendanceEntries: myAttendanceEntries,
      leaveEntries: myLeaveEntries,
      plannedLeaves: myPlannedLeaves,
      personalEntries: personalEntries,
    );

    final selectedItems = _buildSelectedDayItems(
      selectedDay: _selectedDay,
      deadlines: myDeadlines,
      events: myEvents,
      attendanceEntries: myAttendanceEntries,
      leaveEntries: myLeaveEntries,
      plannedLeaves: myPlannedLeaves,
      personalEntries: personalEntries,
    );

    final Widget content = widget.compact
        ? LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PanelToolbar(
                  visibleMonth: _visibleMonth,
                  compact: true,
                  onPreviousMonth: () {
                    setState(() {
                      _visibleMonth = DateTime(
                        _visibleMonth.year,
                        _visibleMonth.month - 1,
                      );
                    });
                  },
                  onNextMonth: () {
                    setState(() {
                      _visibleMonth = DateTime(
                        _visibleMonth.year,
                        _visibleMonth.month + 1,
                      );
                    });
                  },
                  onToday: () {
                    final now = DateTime.now();
                    setState(() {
                      _visibleMonth = DateTime(now.year, now.month);
                      _selectedDay = DateTime(now.year, now.month, now.day);
                    });
                  },
                  onAddEntry: () async {
                    final entry = await showPersonalCalendarEntryDialog(
                      context,
                      initialDate: _selectedDay,
                    );
                    if (entry == null) return;

                    await ref
                        .read(myCalendarEntriesProvider.notifier)
                        .addEntry(entry);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _Legend(theme: theme),
                const SizedBox(height: AppSpacing.md),
                _MonthGrid(
                  visibleMonth: _visibleMonth,
                  selectedDay: _selectedDay,
                  markers: markers,
                  compact: true,
                  onDayTap: (day) {
                    setState(() {
                      _selectedDay = day;
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  DateFormat('EEEE, dd.MM.yyyy', 'pl_PL')
                      .format(_selectedDay),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                if (selectedItems.isEmpty)
                  const Text('Brak wpisów dla wybranego dnia.')
                else
                  ...selectedItems.map(
                        (item) => Padding(
                      padding:
                      const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _SelectedDayRow(item: item),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    )
        : Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PanelToolbar(
                visibleMonth: _visibleMonth,
                onPreviousMonth: () {
                  setState(() {
                    _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month - 1,
                    );
                  });
                },
                onNextMonth: () {
                  setState(() {
                    _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month + 1,
                    );
                  });
                },
                onToday: () {
                  final now = DateTime.now();
                  setState(() {
                    _visibleMonth = DateTime(now.year, now.month);
                    _selectedDay = DateTime(now.year, now.month, now.day);
                  });
                },
                onAddEntry: () async {
                  final entry = await showPersonalCalendarEntryDialog(
                    context,
                    initialDate: _selectedDay,
                  );
                  if (entry == null) return;

                  await ref
                      .read(myCalendarEntriesProvider.notifier)
                      .addEntry(entry);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _Legend(theme: theme),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: SingleChildScrollView(
                  child: _MonthGrid(
                    visibleMonth: _visibleMonth,
                    selectedDay: _selectedDay,
                    markers: markers,
                    onDayTap: (day) {
                      setState(() {
                        _selectedDay = day;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, dd.MM.yyyy', 'pl_PL')
                    .format(_selectedDay),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Szczegóły wszystkich elementów dotyczących mnie.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: selectedItems.isEmpty
                    ? const Center(
                  child: Text('Brak wpisów dla wybranego dnia.'),
                )
                    : ListView.separated(
                  itemCount: selectedItems.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = selectedItems[index];
                    return _SelectedDayRow(item: item);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!widget.showOuterPanel) {
      return content;
    }

    return OpsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OpsSectionHeader(
            eyebrow: 'Mój kalendarz',
            title: widget.title,
            subtitle: widget.subtitle,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(child: content),
        ],
      ),
    );
  }

  List<TaskItem> _resolveMyTasks(TaskModuleState state) {
    final user = state.currentUser;
    if (user == null) return const [];

    final items = state.tasks.where((task) {
      if (task.isArchived) return false;
      if (task.status == TaskStatus.cancelled ||
          task.status == TaskStatus.completed) {
        return false;
      }

      return task.responsiblePersonId == user.id ||
          task.helperPersonIds.contains(user.id);
    }).toList();

    items.sort((a, b) => a.deadline.compareTo(b.deadline));
    return items;
  }

  List<EventItem> _resolveMyEvents(AsyncValue<List<EventItem>> eventsAsync) {
    return eventsAsync.maybeWhen(
      data: (events) => events,
      orElse: () => const [],
    );
  }

  Map<DateTime, Set<_MarkerType>> _buildMarkers({
    required List<TaskItem> deadlines,
    required List<EventItem> events,
    required List<AttendanceEntry> attendanceEntries,
    required List<AttendanceEntry> leaveEntries,
    required List<LeaveRequest> plannedLeaves,
    required List<PersonalCalendarEntry> personalEntries,
  }) {
    final markers = <DateTime, Set<_MarkerType>>{};

    void add(DateTime date, _MarkerType type) {
      final normalized = DateTime(date.year, date.month, date.day);
      markers.putIfAbsent(normalized, () => <_MarkerType>{});
      markers[normalized]!.add(type);
    }

    for (final task in deadlines) {
      add(task.deadline, _MarkerType.deadline);
    }

    for (final event in events) {
      add(event.startsAt, _MarkerType.event);
    }

    for (final entry in attendanceEntries) {
      add(entry.attendanceDate, _MarkerType.attendance);
    }

    for (final entry in leaveEntries) {
      add(entry.attendanceDate, _MarkerType.leave);
    }

    for (final entry in plannedLeaves) {
      var current = DateTime(
        entry.startDate.year,
        entry.startDate.month,
        entry.startDate.day,
      );
      final last = DateTime(
        entry.endDate.year,
        entry.endDate.month,
        entry.endDate.day,
      );

      while (!current.isAfter(last)) {
        add(current, _MarkerType.leavePlan);
        current = current.add(const Duration(days: 1));
      }
    }

    for (final entry in personalEntries) {
      var current = DateTime(
        entry.startAt.year,
        entry.startAt.month,
        entry.startAt.day,
      );
      final last = DateTime(
        entry.endAt.year,
        entry.endAt.month,
        entry.endAt.day,
      );

      while (!current.isAfter(last)) {
        add(current, _MarkerType.personal);
        current = current.add(const Duration(days: 1));
      }
    }

    return markers;
  }

  List<_SelectedDayItem> _buildSelectedDayItems({
    required DateTime selectedDay,
    required List<TaskItem> deadlines,
    required List<EventItem> events,
    required List<AttendanceEntry> attendanceEntries,
    required List<AttendanceEntry> leaveEntries,
    required List<LeaveRequest> plannedLeaves,
    required List<PersonalCalendarEntry> personalEntries,
  }) {
    final normalized = DateTime(
      selectedDay.year,
      selectedDay.month,
      selectedDay.day,
    );

    final items = <_SelectedDayItem>[];

    for (final task in deadlines) {
      final taskDay = DateTime(
        task.deadline.year,
        task.deadline.month,
        task.deadline.day,
      );

      if (taskDay == normalized) {
        items.add(
          _SelectedDayItem(
            type: _MarkerType.deadline,
            title: task.title,
            subtitle: 'Termin • ${DateFormat('HH:mm').format(task.deadline)}',
          ),
        );
      }
    }

    for (final event in events) {
      final eventDay = DateTime(
        event.startsAt.year,
        event.startsAt.month,
        event.startsAt.day,
      );

      if (eventDay == normalized) {
        items.add(
          _SelectedDayItem(
            type: _MarkerType.event,
            title: event.title,
            subtitle:
            'Wydarzenie • ${DateFormat('HH:mm').format(event.startsAt)}',
          ),
        );
      }
    }

    for (final entry in attendanceEntries) {
      final day = DateTime(
        entry.attendanceDate.year,
        entry.attendanceDate.month,
        entry.attendanceDate.day,
      );

      if (day == normalized) {
        items.add(
          _SelectedDayItem(
            type: _MarkerType.attendance,
            title: entry.attendanceType.label,
            subtitle: entry.isAllDay
                ? 'Obecność • cały dzień'
                : 'Obecność • ${_formatAttendanceTime(entry.timeFrom)} - ${_formatAttendanceTime(entry.timeTo)}',
          ),
        );
      }
    }

    for (final entry in leaveEntries) {
      final day = DateTime(
        entry.attendanceDate.year,
        entry.attendanceDate.month,
        entry.attendanceDate.day,
      );

      if (day == normalized) {
        items.add(
          _SelectedDayItem(
            type: _MarkerType.leave,
            title: entry.attendanceType.label,
            subtitle: entry.isAllDay
                ? 'Nieobecność • cały dzień'
                : 'Nieobecność • ${_formatAttendanceTime(entry.timeFrom)} - ${_formatAttendanceTime(entry.timeTo)}',
          ),
        );
      }
    }

    for (final entry in plannedLeaves) {
      final start = DateTime(
        entry.startDate.year,
        entry.startDate.month,
        entry.startDate.day,
      );
      final end = DateTime(
        entry.endDate.year,
        entry.endDate.month,
        entry.endDate.day,
      );

      final isInside =
          !normalized.isBefore(start) && !normalized.isAfter(end);

      if (isInside) {
        items.add(
          _SelectedDayItem(
            type: _MarkerType.leavePlan,
            title: (entry.title ?? '').trim().isNotEmpty
                ? entry.title!.trim()
                : 'Planowany urlop',
            subtitle:
            'Planowany urlop • ${DateFormat('dd.MM.yyyy').format(start)} - ${DateFormat('dd.MM.yyyy').format(end)}',
          ),
        );
      }
    }

    for (final entry in personalEntries) {
      if (entry.occursOn(normalized)) {
        items.add(
          _SelectedDayItem(
            type: _MarkerType.personal,
            title: entry.title,
            subtitle: entry.allDay
                ? 'Prywatny wpis • cały dzień'
                : 'Prywatny wpis • ${DateFormat('HH:mm').format(entry.startAt)} - ${DateFormat('HH:mm').format(entry.endAt)}',
            personalEntryId: entry.id,
          ),
        );
      }
    }

    items.sort((a, b) => a.title.compareTo(b.title));
    return items;
  }

  String _formatAttendanceTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '--:--';
    }

    final parts = value.split(':');
    if (parts.length < 2) {
      return value;
    }

    return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
  }
}

class _PanelToolbar extends StatelessWidget {
  const _PanelToolbar({
    required this.visibleMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.onAddEntry,
    this.compact = false,
  });

  final DateTime visibleMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final VoidCallback onAddEntry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final monthLabel = DateFormat('LLLL yyyy', 'pl_PL').format(visibleMonth);
    final fixedLabel = monthLabel[0].toUpperCase() + monthLabel.substring(1);

    return LayoutBuilder(
      builder: (context, constraints) {
        final forceStacked = compact || constraints.maxWidth < 520;
        final veryNarrow = constraints.maxWidth < 360;

        if (forceStacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: onToday,
                    child: const Text('Dzisiaj'),
                  ),
                  IconButton(
                    onPressed: onPreviousMonth,
                    icon: const Icon(Icons.chevron_left),
                    tooltip: 'Poprzedni miesiąc',
                  ),
                  Text(
                    fixedLabel,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    onPressed: onNextMonth,
                    icon: const Icon(Icons.chevron_right),
                    tooltip: 'Następny miesiąc',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              veryNarrow
                  ? SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onAddEntry,
                  icon: const Icon(Icons.add),
                  label: const Text('Dodaj prywatny wpis'),
                ),
              )
                  : FilledButton.icon(
                onPressed: onAddEntry,
                icon: const Icon(Icons.add),
                label: const Text('Dodaj prywatny wpis'),
              ),
            ],
          );
        }

        return Row(
          children: [
            OutlinedButton(
              onPressed: onToday,
              child: const Text('Dzisiaj'),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: onPreviousMonth,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Poprzedni miesiąc',
            ),
            Flexible(
              child: Text(
                fixedLabel,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              onPressed: onNextMonth,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Następny miesiąc',
            ),
            const SizedBox(width: AppSpacing.sm),
            FilledButton.icon(
              onPressed: onAddEntry,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj prywatny wpis'),
            ),
          ],
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.theme,
  });

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: const [
        _LegendItem(color: Colors.blue, label: 'Obecność'),
        _LegendItem(color: Colors.green, label: 'Nieobecność / wykorzystany'),
        _LegendItem(color: Colors.teal, label: 'Planowany urlop'),
        _LegendItem(color: Colors.orange, label: 'Wydarzenie'),
        _LegendItem(color: Colors.red, label: 'Termin'),
        _LegendItem(color: Colors.purple, label: 'Prywatny wpis'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.visibleMonth,
    required this.selectedDay,
    required this.markers,
    required this.onDayTap,
    this.compact = false,
  });

  final DateTime visibleMonth;
  final DateTime selectedDay;
  final Map<DateTime, Set<_MarkerType>> markers;
  final ValueChanged<DateTime> onDayTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month, 1);
    final lastDay = DateTime(visibleMonth.year, visibleMonth.month + 1, 0);

    final leadingEmpty = firstDay.weekday - 1;
    final daysInMonth = lastDay.day;
    final totalCells = leadingEmpty + daysInMonth;
    final trailingEmpty = (7 - (totalCells % 7)) % 7;
    final itemCount = totalCells + trailingEmpty;

    final rowCount = (itemCount / 7).ceil();
    final cellExtent = compact ? 72.0 : 102.0;
    final totalHeight = rowCount * (cellExtent + 8);

    return SizedBox(
      height: totalHeight + 40,
      child: Column(
        children: [
          const Row(
            children: [
              _WeekdayCell('Pn'),
              _WeekdayCell('Wt'),
              _WeekdayCell('Śr'),
              _WeekdayCell('Cz'),
              _WeekdayCell('Pt'),
              _WeekdayCell('Sb'),
              _WeekdayCell('Nd'),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: cellExtent,
              ),
              itemBuilder: (context, index) {
                if (index < leadingEmpty || index >= leadingEmpty + daysInMonth) {
                  return const _CalendarCell.empty();
                }

                final dayNumber = index - leadingEmpty + 1;
                final date = DateTime(
                  visibleMonth.year,
                  visibleMonth.month,
                  dayNumber,
                );

                return _CalendarCell(
                  date: date,
                  isSelected: _sameDay(date, selectedDay),
                  isToday: _sameDay(date, DateTime.now()),
                  markerTypes: markers[date] ?? const <_MarkerType>{},
                  compact: compact,
                  onTap: () => onDayTap(date),
                );
              },
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

class _WeekdayCell extends StatelessWidget {
  const _WeekdayCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.markerTypes,
    required this.onTap,
    this.compact = false,
  });

  const _CalendarCell.empty()
      : date = null,
        isSelected = false,
        isToday = false,
        markerTypes = const <_MarkerType>{},
        onTap = null,
        compact = false;

  final DateTime? date;
  final bool isSelected;
  final bool isToday;
  final Set<_MarkerType> markerTypes;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isWeekend =
        date!.weekday == DateTime.saturday || date!.weekday == DateTime.sunday;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: EdgeInsets.all(compact ? 6 : 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.10)
              : isWeekend
              ? theme.colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.18)
              : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : isToday
                ? theme.colorScheme.outline
                : theme.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${date!.day}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                fontSize: compact ? 13 : null,
              ),
            ),
            const Spacer(),
            if (markerTypes.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: markerTypes
                    .map(
                      (type) => Container(
                    width: compact ? 7 : 8,
                    height: compact ? 7 : 8,
                    decoration: BoxDecoration(
                      color: _markerColor(type),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  static Color _markerColor(_MarkerType type) {
    switch (type) {
      case _MarkerType.attendance:
        return Colors.blue;
      case _MarkerType.leave:
        return Colors.green;
      case _MarkerType.leavePlan:
        return Colors.teal;
      case _MarkerType.event:
        return Colors.orange;
      case _MarkerType.deadline:
        return Colors.red;
      case _MarkerType.personal:
        return Colors.purple;
    }
  }
}

class _SelectedDayRow extends ConsumerWidget {
  const _SelectedDayRow({
    required this.item,
  });

  final _SelectedDayItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: theme.dividerColor,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 36,
            decoration: BoxDecoration(
              color: _colorFor(item.type),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: item.type == _MarkerType.personal &&
                  item.personalEntryId != null
                  ? () async {
                final entries = ref.read(myCalendarEntriesProvider);
                PersonalCalendarEntry? existing;
                for (final entry in entries) {
                  if (entry.id == item.personalEntryId) {
                    existing = entry;
                    break;
                  }
                }

                if (existing == null) return;

                final updated = await showPersonalCalendarEntryDialog(
                  context,
                  initialDate: existing.startAt,
                  existingEntry: existing,
                );

                if (updated == null) return;

                await ref
                    .read(myCalendarEntriesProvider.notifier)
                    .updateEntry(updated);
              }
                  : null,
              child: Padding(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (item.type == _MarkerType.personal && item.personalEntryId != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () async {
                    final entries = ref.read(myCalendarEntriesProvider);
                    PersonalCalendarEntry? existing;
                    for (final entry in entries) {
                      if (entry.id == item.personalEntryId) {
                        existing = entry;
                        break;
                      }
                    }

                    if (existing == null) return;

                    final updated = await showPersonalCalendarEntryDialog(
                      context,
                      initialDate: existing.startAt,
                      existingEntry: existing,
                    );

                    if (updated == null) return;

                    await ref
                        .read(myCalendarEntriesProvider.notifier)
                        .updateEntry(updated);
                  },
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edytuj prywatny wpis',
                ),
                IconButton(
                  onPressed: () async {
                    await ref
                        .read(myCalendarEntriesProvider.notifier)
                        .removeEntry(item.personalEntryId!);
                  },
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Usuń prywatny wpis',
                ),
              ],
            ),
        ],
      ),
    );
  }

  static Color _colorFor(_MarkerType type) {
    switch (type) {
      case _MarkerType.attendance:
        return Colors.blue;
      case _MarkerType.leave:
        return Colors.green;
      case _MarkerType.leavePlan:
        return Colors.teal;
      case _MarkerType.event:
        return Colors.orange;
      case _MarkerType.deadline:
        return Colors.red;
      case _MarkerType.personal:
        return Colors.purple;
    }
  }
}

class _SelectedDayItem {
  const _SelectedDayItem({
    required this.type,
    required this.title,
    required this.subtitle,
    this.personalEntryId,
  });

  final _MarkerType type;
  final String title;
  final String subtitle;
  final String? personalEntryId;
}

enum _MarkerType {
  attendance,
  leave,
  leavePlan,
  event,
  deadline,
  personal,
}
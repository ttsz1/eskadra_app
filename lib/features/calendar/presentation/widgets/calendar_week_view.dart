import 'package:flutter/material.dart';

import '../../domain/models/calendar_item.dart';
import '../../domain/models/calendar_layer.dart';
import 'calendar_day_details_panel.dart';

class CalendarWeekView extends StatefulWidget {
  const CalendarWeekView({
    super.key,
    required this.focusedDate,
    required this.items,
    required this.selectedItemId,
    required this.onItemTap,
  });

  final DateTime focusedDate;
  final List<CalendarItem> items;
  final String? selectedItemId;
  final ValueChanged<String> onItemTap;

  @override
  State<CalendarWeekView> createState() => _CalendarWeekViewState();
}

class _CalendarWeekViewState extends State<CalendarWeekView> {
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime(
      widget.focusedDate.year,
      widget.focusedDate.month,
      widget.focusedDate.day,
    );
  }

  @override
  void didUpdateWidget(covariant CalendarWeekView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusedDate.year != widget.focusedDate.year ||
        oldWidget.focusedDate.month != widget.focusedDate.month ||
        oldWidget.focusedDate.day != widget.focusedDate.day) {
      _selectedDay = DateTime(
        widget.focusedDate.year,
        widget.focusedDate.month,
        widget.focusedDate.day,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekStart =
    widget.focusedDate.subtract(Duration(days: widget.focusedDate.weekday - 1));
    final days = List.generate(
      7,
          (index) => DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day + index,
      ),
    );

    final selectedDayItems = _itemsForDay(_selectedDay);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < days.length; i++) ...[
                  Expanded(
                    child: _WeekDayColumn(
                      day: days[i],
                      items: _itemsForDay(days[i]),
                      selectedItemId: widget.selectedItemId,
                      isDaySelected: _isSameDate(days[i], _selectedDay),
                      onDayTap: () {
                        setState(() {
                          _selectedDay = DateTime(
                            days[i].year,
                            days[i].month,
                            days[i].day,
                          );
                        });
                      },
                      onItemTap: widget.onItemTap,
                    ),
                  ),
                  if (i != days.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          CalendarDayDetailsPanel(
            day: _selectedDay,
            items: selectedDayItems,
            selectedItemId: widget.selectedItemId,
            onItemTap: widget.onItemTap,
          ),
        ],
      ),
    );
  }

  List<CalendarItem> _itemsForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final result = widget.items.where((item) {
      return item.startAt.isBefore(dayEnd) && item.endAt.isAfter(dayStart);
    }).toList()
      ..sort((a, b) {
        if (_isHoliday(a) && !_isHoliday(b)) return -1;
        if (!_isHoliday(a) && _isHoliday(b)) return 1;
        if (a.allDay != b.allDay) return a.allDay ? -1 : 1;

        final startCompare = a.startAt.compareTo(b.startAt);
        if (startCompare != 0) return startCompare;

        final personCompare =
        (a.personName ?? '').compareTo(b.personName ?? '');
        if (personCompare != 0) return personCompare;

        return a.title.compareTo(b.title);
      });

    return result;
  }

  static bool _isHoliday(CalendarItem item) => item.colorKey == 'holiday';

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _WeekDayColumn extends StatelessWidget {
  const _WeekDayColumn({
    required this.day,
    required this.items,
    required this.selectedItemId,
    required this.isDaySelected,
    required this.onDayTap,
    required this.onItemTap,
  });

  final DateTime day;
  final List<CalendarItem> items;
  final String? selectedItemId;
  final bool isDaySelected;
  final VoidCallback onDayTap;
  final ValueChanged<String> onItemTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isSameDate(day, DateTime.now());

    return InkWell(
      onTap: onDayTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDaySelected
                ? theme.colorScheme.primary
                : isToday
                ? theme.colorScheme.primary.withValues(alpha: 0.45)
                : theme.dividerColor.withValues(alpha: 0.22),
            width: isDaySelected ? 1.6 : 1,
          ),
          color: theme.colorScheme.surface,
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              decoration: BoxDecoration(
                borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
                color: isDaySelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.14)
                    : isToday
                    ? theme.colorScheme.primary.withValues(alpha: 0.10)
                    : theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.35),
              ),
              child: Column(
                children: [
                  Text(
                    _weekdayLabel(day.weekday),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${items.length} wpisów',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                child: Text(
                  'Brak',
                  style: theme.textTheme.bodySmall,
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _WeekItemTile(
                    item: item,
                    isSelected: item.id == selectedItemId,
                    onTap: () => onItemTap(item.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'PN';
      case DateTime.tuesday:
        return 'WT';
      case DateTime.wednesday:
        return 'ŚR';
      case DateTime.thursday:
        return 'CZ';
      case DateTime.friday:
        return 'PT';
      case DateTime.saturday:
        return 'SB';
      case DateTime.sunday:
        return 'ND';
      default:
        return '';
    }
  }
}

class _WeekItemTile extends StatelessWidget {
  const _WeekItemTile({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final CalendarItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorForItem(theme, item);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tinyWidth = constraints.maxWidth < 130;
        final showPerson =
            (item.personName ?? '').trim().isNotEmpty && !tinyWidth;
        final showSubtitle =
            (item.subtitle ?? '').trim().isNotEmpty && constraints.maxWidth >= 110;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              padding: EdgeInsets.all(tinyWidth ? 8 : 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? color
                      : theme.dividerColor.withValues(alpha: 0.20),
                  width: isSelected ? 1.4 : 1,
                ),
                color: color.withValues(alpha: 0.08),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showPerson) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.personName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                  Text(
                    item.title,
                    maxLines: tinyWidth ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.allDay
                        ? 'Cały dzień'
                        : '${_hhmm(item.startAt)}-${_hhmm(item.endAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (showSubtitle) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle!,
                      maxLines: tinyWidth ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _hhmm(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color _colorForItem(ThemeData theme, CalendarItem item) {
    if (item.colorKey == 'holiday') {
      return Colors.red;
    }

    switch (item.layer) {
      case CalendarLayer.events:
        return Colors.orange;
      case CalendarLayer.tasks:
      case CalendarLayer.deadlines:
        return Colors.red;
      case CalendarLayer.attendance:
        return Colors.blue;
      case CalendarLayer.plannedLeave:
      case CalendarLayer.requestedLeave:
        return Colors.green;
      case CalendarLayer.unassignedItems:
        return theme.colorScheme.secondary;
    }
  }
}
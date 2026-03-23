import 'package:flutter/material.dart';

import '../../domain/models/calendar_item.dart';
import '../../domain/models/calendar_layer.dart';
import 'calendar_day_details_panel.dart';

class CalendarMonthView extends StatefulWidget {
  const CalendarMonthView({
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
  State<CalendarMonthView> createState() => _CalendarMonthViewState();
}

class _CalendarMonthViewState extends State<CalendarMonthView> {
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
  void didUpdateWidget(covariant CalendarMonthView oldWidget) {
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
    final monthStart = DateTime(widget.focusedDate.year, widget.focusedDate.month, 1);
    final gridStart =
    monthStart.subtract(Duration(days: monthStart.weekday - 1));

    final days = List.generate(
      42,
          (index) => gridStart.add(Duration(days: index)),
    );

    final selectedDayItems = _itemsForDay(_selectedDay);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const _MonthWeekdayHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              itemCount: days.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.35,
              ),
              itemBuilder: (context, index) {
                final day = days[index];
                final dayItems = _itemsForDay(day);

                return _MonthDayCell(
                  day: day,
                  focusedMonth: widget.focusedDate.month,
                  items: dayItems,
                  selectedItemId: widget.selectedItemId,
                  isDaySelected: _isSameDate(day, _selectedDay),
                  onDayTap: () {
                    setState(() {
                      _selectedDay = DateTime(day.year, day.month, day.day);
                    });
                  },
                  onItemTap: widget.onItemTap,
                );
              },
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

    return widget.items.where((item) {
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
  }

  static bool _isHoliday(CalendarItem item) => item.colorKey == 'holiday';

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MonthWeekdayHeader extends StatelessWidget {
  const _MonthWeekdayHeader();

  @override
  Widget build(BuildContext context) {
    const labels = ['PN', 'WT', 'ŚR', 'CZ', 'PT', 'SB', 'ND'];

    return Row(
      children: [
        for (final label in labels)
          Expanded(
            child: Center(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.day,
    required this.focusedMonth,
    required this.items,
    required this.selectedItemId,
    required this.isDaySelected,
    required this.onDayTap,
    required this.onItemTap,
  });

  final DateTime day;
  final int focusedMonth;
  final List<CalendarItem> items;
  final String? selectedItemId;
  final bool isDaySelected;
  final VoidCallback onDayTap;
  final ValueChanged<String> onItemTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrentMonth = day.month == focusedMonth;
    final isToday = _isSameDate(day, DateTime.now());

    return InkWell(
      onTap: onDayTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDaySelected
                ? theme.colorScheme.primary
                : isToday
                ? theme.colorScheme.primary.withValues(alpha: 0.45)
                : theme.dividerColor.withValues(alpha: 0.20),
            width: isDaySelected ? 1.6 : 1,
          ),
          color: isCurrentMonth
              ? theme.colorScheme.surface
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${day.day}',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: isCurrentMonth ? null : theme.disabledColor,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (items.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final holidayItems = items.where(_isHoliday).toList();
                  final nonHolidayItems =
                  items.where((e) => !_isHoliday(e)).toList();

                  final compact =
                      constraints.maxHeight < 48 || constraints.maxWidth < 92;
                  final veryCompact =
                      constraints.maxHeight < 34 || constraints.maxWidth < 74;

                  final visibleNonHolidayCount = veryCompact
                      ? 0
                      : compact
                      ? 1
                      : 2;

                  final visibleNonHolidayItems =
                  nonHolidayItems.take(visibleNonHolidayCount).toList();

                  final hiddenCount =
                      nonHolidayItems.length - visibleNonHolidayItems.length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (holidayItems.isNotEmpty)
                        _HolidayMonthBlock(
                          item: holidayItems.first,
                          isSelected: holidayItems.first.id == selectedItemId,
                          onTap: () => onItemTap(holidayItems.first.id),
                        ),
                      if (holidayItems.isNotEmpty &&
                          (visibleNonHolidayItems.isNotEmpty || hiddenCount > 0))
                        const SizedBox(height: 4),
                      ...visibleNonHolidayItems.map(
                            (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: _MonthCompactItem(
                            item: item,
                            isSelected: item.id == selectedItemId,
                            onTap: () => onItemTap(item.id),
                          ),
                        ),
                      ),
                      if (hiddenCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Text(
                            '+$hiddenCount więcej',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _isHoliday(CalendarItem item) => item.colorKey == 'holiday';

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _HolidayMonthBlock extends StatelessWidget {
  const _HolidayMonthBlock({
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.red.shade700,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
      ),
    );
  }
}

class _MonthCompactItem extends StatelessWidget {
  const _MonthCompactItem({
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

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
          ),
        ),
        child: Text(
          _buildText(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 10.5,
            height: 1.05,
          ),
        ),
      ),
    );
  }

  String _buildText() {
    final person = item.personName?.trim();
    if (person != null && person.isNotEmpty) {
      return '$person • ${item.title}';
    }
    return item.title;
  }

  Color _colorForItem(ThemeData theme, CalendarItem item) {
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
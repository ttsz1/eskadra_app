import 'package:flutter/material.dart';

import '../../domain/models/calendar_item.dart';
import '../../domain/models/calendar_layer.dart';
import 'calendar_day_details_panel.dart';

class CalendarThreeDaysView extends StatefulWidget {
  const CalendarThreeDaysView({
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
  State<CalendarThreeDaysView> createState() => _CalendarThreeDaysViewState();
}

class _CalendarThreeDaysViewState extends State<CalendarThreeDaysView> {
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
  void didUpdateWidget(covariant CalendarThreeDaysView oldWidget) {
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
    final start = DateTime(
      widget.focusedDate.year,
      widget.focusedDate.month,
      widget.focusedDate.day,
    );

    final days = List.generate(
      3,
          (index) => start.add(Duration(days: index)),
    );

    final selectedDayItems = _itemsForDay(_selectedDay);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                for (int i = 0; i < days.length; i++) ...[
                  Expanded(
                    child: _ThreeDaysColumn(
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
                  if (i != days.length - 1) const SizedBox(width: 12),
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

class _ThreeDaysColumn extends StatelessWidget {
  const _ThreeDaysColumn({
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
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final dayItems = items.where((item) {
      return item.startAt.isBefore(dayEnd) && item.endAt.isAfter(dayStart);
    }).toList()
      ..sort((a, b) {
        if (_isHoliday(a) && !_isHoliday(b)) return -1;
        if (!_isHoliday(a) && _isHoliday(b)) return 1;
        if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
        return a.startAt.compareTo(b.startAt);
      });

    final theme = Theme.of(context);

    return InkWell(
      onTap: onDayTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDaySelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.20),
            width: isDaySelected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDaySelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.14)
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.35,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Text(
                '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: dayItems.isEmpty
                  ? const Center(child: Text('Brak wpisów'))
                  : ListView.separated(
                padding: const EdgeInsets.all(10),
                itemCount: dayItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = dayItems[index];
                  final isSelected = item.id == selectedItemId;
                  final color = _colorForItem(theme, item);

                  return InkWell(
                    onTap: () => onItemTap(item.id),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : theme.dividerColor.withValues(alpha: 0.20),
                        ),
                        color: color.withValues(alpha: 0.08),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((item.personName ?? '').trim().isNotEmpty) ...[
                            Text(
                              item.personName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Text(
                            item.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.allDay
                                ? 'Cały dzień'
                                : '${_hhmm(item.startAt)} - ${_hhmm(item.endAt)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          if ((item.subtitle ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
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

  String _hhmm(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color _colorForItem(ThemeData theme, CalendarItem item) {
    if (_isHoliday(item)) {
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
import 'package:flutter/material.dart';

import '../../domain/models/calendar_item.dart';
import '../../domain/models/calendar_layer.dart';

class CalendarDayView extends StatelessWidget {
  const CalendarDayView({
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
  Widget build(BuildContext context) {
    final dayStart = DateTime(
      focusedDate.year,
      focusedDate.month,
      focusedDate.day,
    );
    final dayEnd = dayStart.add(const Duration(days: 1));

    final dayItems = items.where((item) {
      return item.startAt.isBefore(dayEnd) && item.endAt.isAfter(dayStart);
    }).toList()
      ..sort((a, b) {
        if (a.allDay != b.allDay) {
          return a.allDay ? -1 : 1;
        }
        return a.startAt.compareTo(b.startAt);
      });

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${focusedDate.day.toString().padLeft(2, '0')}.${focusedDate.month.toString().padLeft(2, '0')}.${focusedDate.year}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: dayItems.isEmpty
                ? const Center(
              child: Text('Brak wpisów w tym dniu.'),
            )
                : ListView.separated(
              itemCount: dayItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = dayItems[index];
                final isSelected = item.id == selectedItemId;

                return _CalendarListTile(
                  item: item,
                  isSelected: isSelected,
                  onTap: () => onItemTap(item.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarListTile extends StatelessWidget {
  const _CalendarListTile({
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color
                  : theme.dividerColor.withValues(alpha: 0.20),
              width: isSelected ? 1.4 : 1,
            ),
            color: color.withValues(alpha: 0.08),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((item.personName ?? '').trim().isNotEmpty) ...[
                      Text(
                        item.personName!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      item.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.allDay
                          ? 'Cały dzień'
                          : '${_hhmm(item.startAt)} - ${_hhmm(item.endAt)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if ((item.subtitle ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _hhmm(DateTime value) {
    final h = value.hour.toString().padLeft(2, '0');
    final m = value.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Color _colorForItem(ThemeData theme, CalendarItem item) {
    if (item.colorKey == 'holiday') {
      return Colors.purple;
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
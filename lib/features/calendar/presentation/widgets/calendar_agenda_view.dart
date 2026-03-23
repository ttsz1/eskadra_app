import 'package:flutter/material.dart';

import '../../domain/models/calendar_item.dart';
import '../../domain/models/calendar_layer.dart';

class CalendarAgendaView extends StatelessWidget {
  const CalendarAgendaView({
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
    final start = DateTime(
      focusedDate.year,
      focusedDate.month,
      focusedDate.day,
    );
    final end = start.add(const Duration(days: 14));

    final agendaItems = items.where((item) {
      return item.startAt.isBefore(end) && item.endAt.isAfter(start);
    }).toList()
      ..sort((a, b) {
        if (a.colorKey == 'holiday' && b.colorKey != 'holiday') {
          return -1;
        }
        if (a.colorKey != 'holiday' && b.colorKey == 'holiday') {
          return 1;
        }
        if (a.allDay != b.allDay) {
          return a.allDay ? -1 : 1;
        }
        return a.startAt.compareTo(b.startAt);
      });

    final grouped = <DateTime, List<CalendarItem>>{};
    for (final item in agendaItems) {
      final key = DateTime(item.startAt.year, item.startAt.month, item.startAt.day);
      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(item);
    }

    final days = grouped.keys.toList()..sort();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: days.isEmpty
          ? const Center(
        child: Text('Brak wpisów w agendzie.'),
      )
          : ListView.separated(
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final day = days[index];
          final dayItems = grouped[day]!
            ..sort((a, b) {
              if (a.colorKey == 'holiday' && b.colorKey != 'holiday') {
                return -1;
              }
              if (a.colorKey != 'holiday' && b.colorKey == 'holiday') {
                return 1;
              }
              if (a.allDay != b.allDay) {
                return a.allDay ? -1 : 1;
              }
              return a.startAt.compareTo(b.startAt);
            });

          return _AgendaDaySection(
            day: day,
            items: dayItems,
            selectedItemId: selectedItemId,
            onItemTap: onItemTap,
          );
        },
      ),
    );
  }
}

class _AgendaDaySection extends StatelessWidget {
  const _AgendaDaySection({
    required this.day,
    required this.items,
    required this.selectedItemId,
    required this.onItemTap,
  });

  final DateTime day;
  final List<CalendarItem> items;
  final String? selectedItemId;
  final ValueChanged<String> onItemTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}.${day.year}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...items.map((item) {
            final color = _colorForItem(theme, item);
            final isSelected = item.id == selectedItemId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          item.allDay
                              ? 'Cały dzień'
                              : '${_hhmm(item.startAt)}-${_hhmm(item.endAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((item.personName ?? '').trim().isNotEmpty &&
                                item.colorKey != 'holiday') ...[
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
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
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
          }),
        ],
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
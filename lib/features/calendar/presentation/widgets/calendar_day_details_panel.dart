import 'package:flutter/material.dart';

import '../../domain/models/calendar_item.dart';
import '../../domain/models/calendar_layer.dart';

class CalendarDayDetailsPanel extends StatelessWidget {
  const CalendarDayDetailsPanel({
    super.key,
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
    final sortedItems = [...items]
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

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.22),
        ),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Szczegóły dnia • ${_formatDate(day)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: theme.colorScheme.primary.withValues(alpha: 0.10),
                  ),
                  child: Text(
                    '${sortedItems.length} wpisów',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: sortedItems.isEmpty
                ? const Center(
              child: Text('Brak wpisów w wybranym dniu'),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: sortedItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = sortedItems[index];
                final color = _colorForItem(theme, item);
                final isSelected = item.id == selectedItemId;

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
                        width: isSelected ? 1.4 : 1,
                      ),
                      color: color.withValues(alpha: 0.08),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 88,
                          child: Text(
                            item.allDay
                                ? 'Cały dzień'
                                : '${_hhmm(item.startAt)}-${_hhmm(item.endAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if ((item.personName ?? '').trim().isNotEmpty &&
                                  !_isHoliday(item)) ...[
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
                              if ((item.subtitle ?? '').trim().isNotEmpty) ...[
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static bool _isHoliday(CalendarItem item) => item.colorKey == 'holiday';

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    return '$dd.$mm.${date.year}';
  }

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
import 'package:flutter/material.dart';

import '../../domain/models/calendar_view_type.dart';

class CalendarToolbar extends StatelessWidget {
  const CalendarToolbar({
    super.key,
    required this.focusedDate,
    required this.viewType,
    required this.selectedPeopleCount,
    required this.onTodayPressed,
    required this.onPreviousPressed,
    required this.onNextPressed,
    required this.onViewChanged,
    required this.onOpenFilters,
    required this.onOpenConflicts,
  });

  final DateTime focusedDate;
  final CalendarViewType viewType;
  final int selectedPeopleCount;
  final VoidCallback onTodayPressed;
  final VoidCallback onPreviousPressed;
  final VoidCallback onNextPressed;
  final ValueChanged<CalendarViewType> onViewChanged;
  final VoidCallback onOpenFilters;
  final VoidCallback onOpenConflicts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Row(
        children: [
          FilledButton(
            onPressed: onTodayPressed,
            child: const Text('Dzisiaj'),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onPreviousPressed,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Poprzedni',
          ),
          IconButton(
            onPressed: onNextPressed,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Następny',
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _buildTitle(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selectedPeopleCount > 0) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      'Osoby: $selectedPeopleCount',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onOpenFilters,
            icon: const Icon(Icons.filter_alt_outlined),
            label: const Text('Filtry'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: onOpenConflicts,
            icon: const Icon(Icons.warning_amber_rounded),
            label: const Text('Konflikty'),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<CalendarViewType>(
              value: viewType,
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: CalendarViewType.values.map((value) {
                return DropdownMenuItem<CalendarViewType>(
                  value: value,
                  child: Text(_labelForView(value)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onViewChanged(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String _buildTitle() {
    switch (viewType) {
      case CalendarViewType.day:
        return _formatDate(focusedDate);
      case CalendarViewType.threeDays:
        final end = focusedDate.add(const Duration(days: 2));
        return '${_formatDate(focusedDate)} — ${_formatDate(end)}';
      case CalendarViewType.week:
        final weekStart =
        focusedDate.subtract(Duration(days: focusedDate.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 6));
        return '${_formatDate(weekStart)} — ${_formatDate(weekEnd)}';
      case CalendarViewType.month:
        return _formatMonth(focusedDate);
      case CalendarViewType.agenda:
        final end = focusedDate.add(const Duration(days: 13));
        return 'Agenda: ${_formatDate(focusedDate)} — ${_formatDate(end)}';
    }
  }

  String _labelForView(CalendarViewType viewType) {
    switch (viewType) {
      case CalendarViewType.day:
        return 'Dzień';
      case CalendarViewType.threeDays:
        return '3 dni';
      case CalendarViewType.week:
        return 'Tydzień';
      case CalendarViewType.month:
        return 'Miesiąc';
      case CalendarViewType.agenda:
        return 'Agenda';
    }
  }

  String _formatDate(DateTime date) {
    final month = _monthName(date.month);
    return '${date.day} $month ${date.year}';
  }

  String _formatMonth(DateTime date) {
    return '${_monthName(date.month)} ${date.year}';
  }

  String _monthName(int month) {
    switch (month) {
      case 1:
        return 'styczeń';
      case 2:
        return 'luty';
      case 3:
        return 'marzec';
      case 4:
        return 'kwiecień';
      case 5:
        return 'maj';
      case 6:
        return 'czerwiec';
      case 7:
        return 'lipiec';
      case 8:
        return 'sierpień';
      case 9:
        return 'wrzesień';
      case 10:
        return 'październik';
      case 11:
        return 'listopad';
      case 12:
        return 'grudzień';
      default:
        return '';
    }
  }
}
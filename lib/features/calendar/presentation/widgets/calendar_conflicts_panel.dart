import 'package:flutter/material.dart';

import '../../domain/models/calendar_item.dart';
import '../../domain/services/calendar_conflict_service.dart';

class CalendarConflictsPanel extends StatelessWidget {
  const CalendarConflictsPanel({
    super.key,
    required this.items,
    required this.onSelectItem,
    this.isCompact = false,
  });

  final List<CalendarItem> items;
  final ValueChanged<String> onSelectItem;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conflictService = const CalendarConflictService();
    final conflicts = conflictService.findConflicts(items);

    return Container(
      width: isCompact ? null : 340,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          left: isCompact
              ? BorderSide.none
              : BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.25),
          ),
          top: isCompact
              ? BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.25),
          )
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withValues(alpha: 0.25),
                ),
              ),
            ),
            child: Text(
              'Conflicts & Alerts',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: conflicts.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  'No conflicts in visible range.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.all(12),
              scrollDirection: isCompact ? Axis.horizontal : Axis.vertical,
              itemCount: conflicts.length,
              separatorBuilder: (_, __) => SizedBox(
                width: isCompact ? 8 : 0,
                height: isCompact ? 0 : 8,
              ),
              itemBuilder: (context, index) {
                final conflict = conflicts[index];
                final first = _findItem(conflict.firstItemId);
                final second = _findItem(conflict.secondItemId);

                final card = Container(
                  width: isCompact ? 320 : null,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.35),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _reasonLabel(conflict.reason),
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (first != null)
                        _ConflictItemRow(
                          item: first,
                          onTap: () => onSelectItem(first.id),
                        ),
                      if (first != null && second != null)
                        const SizedBox(height: 8),
                      if (second != null)
                        _ConflictItemRow(
                          item: second,
                          onTap: () => onSelectItem(second.id),
                        ),
                    ],
                  ),
                );

                return isCompact
                    ? Align(
                  alignment: Alignment.topLeft,
                  child: card,
                )
                    : card;
              },
            ),
          ),
        ],
      ),
    );
  }

  CalendarItem? _findItem(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  String _reasonLabel(String reason) {
    switch (reason) {
      case 'person_overlap':
        return 'Person overlap';
      case 'team_overlap':
        return 'Team overlap';
      default:
        return 'Conflict';
    }
  }
}

class _ConflictItemRow extends StatelessWidget {
  const _ConflictItemRow({
    required this.item,
    required this.onTap,
  });

  final CalendarItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${item.title} • ${_formatTime(item.startAt)}-${_formatTime(item.endAt)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}
import 'package:flutter/material.dart';

import '../../domain/models/calendar_item.dart';
import 'calendar_conflicts_panel.dart';

class CalendarConflictsDialog extends StatelessWidget {
  const CalendarConflictsDialog({
    super.key,
    required this.items,
    required this.onSelectItem,
  });

  final List<CalendarItem> items;
  final ValueChanged<String> onSelectItem;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
          maxHeight: 760,
        ),
        child: CalendarConflictsPanel(
          items: items,
          onSelectItem: (id) {
            onSelectItem(id);
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}
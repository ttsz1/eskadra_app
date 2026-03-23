import 'package:flutter/material.dart';

import '../../domain/models/personal_calendar_entry.dart';

Future<PersonalCalendarEntry?> showPersonalCalendarEntryDialog(
    BuildContext context, {
      required DateTime initialDate,
      PersonalCalendarEntry? existingEntry,
    }) {
  return showDialog<PersonalCalendarEntry>(
    context: context,
    builder: (_) => _PersonalCalendarEntryDialog(
      initialDate: initialDate,
      existingEntry: existingEntry,
    ),
  );
}

class _PersonalCalendarEntryDialog extends StatefulWidget {
  const _PersonalCalendarEntryDialog({
    required this.initialDate,
    this.existingEntry,
  });

  final DateTime initialDate;
  final PersonalCalendarEntry? existingEntry;

  @override
  State<_PersonalCalendarEntryDialog> createState() =>
      _PersonalCalendarEntryDialogState();
}

class _PersonalCalendarEntryDialogState
    extends State<_PersonalCalendarEntryDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _startAt;
  late DateTime _endAt;
  bool _allDay = false;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();

    if (widget.existingEntry != null) {
      final entry = widget.existingEntry!;
      _titleController.text = entry.title;
      _descriptionController.text = entry.description ?? '';
      _startAt = entry.startAt;
      _endAt = entry.endAt;
      _allDay = entry.allDay;
      return;
    }

    _startAt = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
      9,
      0,
    );
    _endAt = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
      10,
      0,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(_isEditing ? 'Edytuj prywatny wpis' : 'Dodaj prywatny wpis'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tytuł',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Opis',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Wydarzenie całodniowe'),
                value: _allDay,
                onChanged: (value) {
                  setState(() {
                    _allDay = value;

                    if (_allDay) {
                      _startAt = DateTime(
                        _startAt.year,
                        _startAt.month,
                        _startAt.day,
                      );
                      _endAt = _startAt.add(const Duration(days: 1));
                    } else {
                      _endAt = _startAt.add(const Duration(hours: 1));
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
              _DateTimeRow(
                label: 'Start',
                value: _formatDateTime(_startAt, _allDay),
                onTap: () async {
                  final picked = await _pickDateTime(context, _startAt, _allDay);
                  if (picked == null) return;

                  setState(() {
                    _startAt = picked;
                    if (!_endAt.isAfter(_startAt)) {
                      _endAt = _allDay
                          ? _startAt.add(const Duration(days: 1))
                          : _startAt.add(const Duration(hours: 1));
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
              _DateTimeRow(
                label: 'Koniec',
                value: _formatDateTime(_endAt, _allDay),
                onTap: () async {
                  final picked = await _pickDateTime(context, _endAt, _allDay);
                  if (picked == null) return;

                  setState(() {
                    _endAt = picked;
                  });
                },
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Wpis będzie widoczny tylko w „Moim kalendarzu”.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Anuluj'),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(_isEditing ? 'Zapisz' : 'Dodaj'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    if (!_endAt.isAfter(_startAt)) return;

    final description = _descriptionController.text.trim();

    final entry = PersonalCalendarEntry(
      id: widget.existingEntry?.id ?? '',
      userId: widget.existingEntry?.userId ?? '',
      ownerId: widget.existingEntry?.ownerId ?? '',
      title: title,
      description: description.isEmpty ? null : description,
      startAt: _startAt,
      endAt: _endAt,
      allDay: _allDay,
    );

    Navigator.of(context).pop(entry);
  }

  Future<DateTime?> _pickDateTime(
      BuildContext context,
      DateTime initialValue,
      bool allDay,
      ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialValue,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (date == null) return null;

    if (allDay) {
      return DateTime(date.year, date.month, date.day);
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialValue),
    );

    if (time == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  static String _formatDateTime(DateTime value, bool allDay) {
    final date =
        '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';

    if (allDay) return date;

    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$date • $hh:$mm';
  }
}

class _DateTimeRow extends StatelessWidget {
  const _DateTimeRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label),
                  const SizedBox(height: 2),
                  Text(value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
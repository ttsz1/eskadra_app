import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/announcements_providers.dart';

class AddAnnouncementDialog extends ConsumerStatefulWidget {
  const AddAnnouncementDialog({super.key});

  @override
  ConsumerState<AddAnnouncementDialog> createState() =>
      _AddAnnouncementDialogState();
}

class _AddAnnouncementDialogState extends ConsumerState<AddAnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  bool _saving = false;
  bool _enableAutoDelete = false;
  DateTime? _autoDeleteAt;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickAutoDeleteDate() async {
    final now = DateTime.now();
    final initial = _autoDeleteAt ?? now.add(const Duration(days: 1));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (pickedTime == null) return;

    setState(() {
      _autoDeleteAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_enableAutoDelete && _autoDeleteAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wybierz datę auto delete.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ref.read(announcementsActionsProvider).createAnnouncement(
        title: _titleController.text,
        content: _contentController.text,
        autoDeleteAt: _enableAutoDelete ? _autoDeleteAt : null,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się dodać komunikatu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd.MM.yyyy HH:mm');

    return AlertDialog(
      title: const Text('Dodaj komunikat'),
      content: SizedBox(
        width: 620,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Tytuł',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.length < 3) {
                    return 'Minimum 3 znaki.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                minLines: 5,
                maxLines: 10,
                decoration: const InputDecoration(
                  labelText: 'Treść komunikatu',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) {
                    return 'Treść jest wymagana.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto delete'),
                subtitle: Text(
                  _enableAutoDelete
                      ? (_autoDeleteAt == null
                      ? 'Wybierz datę usunięcia'
                      : 'Usunie się: ${formatter.format(_autoDeleteAt!)}')
                      : 'Wyłączone',
                ),
                value: _enableAutoDelete,
                onChanged: (value) {
                  setState(() {
                    _enableAutoDelete = value;
                    if (!value) {
                      _autoDeleteAt = null;
                    }
                  });
                },
              ),
              if (_enableAutoDelete)
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _pickAutoDeleteDate,
                    icon: const Icon(Icons.schedule_rounded),
                    label: const Text('Ustaw datę auto delete'),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Anuluj'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving
              ? const SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Icon(Icons.add_comment_rounded),
          label: const Text('Dodaj komunikat'),
        ),
      ],
    );
  }
}
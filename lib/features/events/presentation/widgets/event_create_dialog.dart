import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../domain/models/event_item.dart';
import '../providers/upcoming_events_provider.dart';

Future<void> showEventCreateDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const Dialog(
      insetPadding: EdgeInsets.all(24),
      child: SizedBox(
        width: 760,
        height: 560,
        child: EventCreateDialog(),
      ),
    ),
  );
}

Future<void> showEventEditDialog(
    BuildContext context, {
      required EventItem event,
    }) async {
  await showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 760,
        height: 560,
        child: EventCreateDialog(
          existingEvent: event,
        ),
      ),
    ),
  );
}

class EventCreateDialog extends ConsumerStatefulWidget {
  final EventItem? existingEvent;

  const EventCreateDialog({
    super.key,
    this.existingEvent,
  });

  @override
  ConsumerState<EventCreateDialog> createState() => _EventCreateDialogState();
}

class _EventCreateDialogState extends ConsumerState<EventCreateDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _detailsController;
  late final TextEditingController _locationController;

  late DateTime _startsAt;
  DateTime? _endsAt;
  bool _isAllDay = false;

  bool get isEditMode => widget.existingEvent != null;

  @override
  void initState() {
    super.initState();

    final event = widget.existingEvent;

    _titleController = TextEditingController(text: event?.title ?? '');
    _detailsController = TextEditingController(text: event?.details ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');

    _startsAt = event?.startsAt ?? DateTime.now().add(const Duration(hours: 2));
    _endsAt = event?.endsAt;
    _isAllDay = event?.isAllDay ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null) return;

    setState(() {
      _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickEnd() async {
    final base = _endsAt ?? _startsAt.add(const Duration(hours: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (time == null) return;

    setState(() {
      _endsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;

    final notifier = ref.read(eventCreatorProvider.notifier);

    final draft = EventDraft(
      title: _titleController.text,
      details: _detailsController.text,
      location: _locationController.text,
      startsAt: _startsAt,
      endsAt: _endsAt,
      isAllDay: _isAllDay,
    );

    if (isEditMode) {
      await notifier.updateEvent(
        eventId: widget.existingEvent!.id,
        draft: draft,
      );
    } else {
      await notifier.createEvent(draft);
    }

    final result = ref.read(eventCreatorProvider);
    if (result.hasError) return;

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final event = widget.existingEvent;
    if (event == null) return;

    await ref.read(eventCreatorProvider.notifier).deleteEvent(
      eventId: event.id,
    );

    final result = ref.read(eventCreatorProvider);
    if (result.hasError) return;

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(eventCreatorProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEditMode ? 'EDYTUJ EVENT' : 'UTWÓRZ EVENT',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            isEditMode ? 'Edycja wydarzenia' : 'Nowe wydarzenie',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Tytuł wydarzenia',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _detailsController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Opis / szczegóły',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Lokalizacja',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _isAllDay,
                    onChanged: (value) {
                      setState(() {
                        _isAllDay = value ?? false;
                      });
                    },
                    title: const Text('Całodniowe'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Start'),
                    subtitle: Text(_startsAt.toString()),
                    trailing: OutlinedButton(
                      onPressed: _pickStart,
                      child: const Text('Ustaw'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Koniec'),
                    subtitle: Text(_endsAt?.toString() ?? 'Brak'),
                    trailing: OutlinedButton(
                      onPressed: _pickEnd,
                      child: const Text('Ustaw'),
                    ),
                  ),
                  if (createState.hasError) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '${createState.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isEditMode)
                OutlinedButton.icon(
                  onPressed: createState.isLoading ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Usuń'),
                )
              else
                const SizedBox.shrink(),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: createState.isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Anuluj'),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    onPressed: createState.isLoading ? null : _submit,
                    child: createState.isLoading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Text(isEditMode ? 'Zapisz zmiany' : 'Zapisz event'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
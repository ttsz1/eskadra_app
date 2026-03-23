import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../profiles/presentation/providers/profile_directory_provider.dart';
import '../../domain/enums/task_priority.dart';
import '../../domain/enums/task_recurrence.dart';
import '../../domain/enums/task_reminder_option.dart';
import '../../domain/models/task_secret_access.dart';
import '../providers/task_module_provider.dart';
import '../../../../../shared/models/org_structure.dart';

Future<void> showTaskCreateDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const Dialog(
      insetPadding: EdgeInsets.all(24),
      child: SizedBox(
        width: 980,
        height: 760,
        child: TaskCreateDialog(),
      ),
    ),
  );
}

class TaskCreateDialog extends ConsumerStatefulWidget {
  const TaskCreateDialog({super.key});

  @override
  ConsumerState<TaskCreateDialog> createState() => _TaskCreateDialogState();
}

class _TaskCreateDialogState extends ConsumerState<TaskCreateDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _attachmentController = TextEditingController();

  DateTime _deadline = DateTime.now().add(const Duration(hours: 6));
  TaskPriority _priority = TaskPriority.normal;
  TaskRecurrence _recurrence = TaskRecurrence.none;
  TaskReminderOption _reminder = TaskReminderOption.none;
  String? _responsibleId;
  final Set<String> _helperIds = {};
  bool _isSecret = false;

  final Set<OrgUnit> _allowedUnits = {};
  final Set<String> _allowedPersonIds = {};
  final Set<PersonnelType> _allowedPersonnelTypes = {};
  final Set<RankGroup> _allowedRankGroups = {};

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _attachmentController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
    );

    if (time == null) return;

    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty) return;
    if (_descriptionController.text.trim().isEmpty) return;

    ref.read(taskModuleProvider.notifier).createTask(
      TaskDraft(
        title: _titleController.text,
        description: _descriptionController.text,
        responsiblePersonId: _responsibleId,
        helperPersonIds: _helperIds.toList(),
        deadline: _deadline,
        priority: _priority,
        isSecret: _isSecret,
        secretAccess: _isSecret
            ? TaskSecretAccess(
          allowedUnits: _allowedUnits,
          allowedPersonIds: _allowedPersonIds,
          allowedPersonnelTypes: _allowedPersonnelTypes,
          allowedRankGroups: _allowedRankGroups,
        )
            : null,
        attachmentName: _attachmentController.text.trim().isEmpty
            ? null
            : _attachmentController.text.trim(),
        reminderOption: _reminder,
        recurrence: _recurrence,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final people = ref.watch(profileDirectoryProvider).valueOrNull ?? const <AppPerson>[];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('UTWÓRZ ZADANIE', style: textTheme.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text('Nowe zadanie operacyjne', style: textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Nazwa zadania'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Opis zadania'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _attachmentController,
                          decoration: const InputDecoration(
                            labelText: 'Załącznik (nazwa pliku / placeholder)',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _responsibleId,
                          decoration: const InputDecoration(
                            labelText: 'Osoba odpowiedzialna',
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Brak przypisania'),
                            ),
                            ...people.map(
                                  (person) => DropdownMenuItem<String?>(
                                value: person.id,
                                child: Text(person.fullName),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => _responsibleId = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Osoby pomocnicze', style: textTheme.titleMedium),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: people.map((person) {
                      final selected = _helperIds.contains(person.id);

                      return FilterChip(
                        selected: selected,
                        label: Text(person.fullName),
                        onSelected: (value) {
                          setState(() {
                            if (value) {
                              _helperIds.add(person.id);
                            } else {
                              _helperIds.remove(person.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Deadline'),
                          subtitle: Text(_deadline.toString()),
                          trailing: OutlinedButton(
                            onPressed: _pickDeadline,
                            child: const Text('Ustaw'),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: DropdownButtonFormField<TaskPriority>(
                          value: _priority,
                          decoration: const InputDecoration(labelText: 'Priorytet'),
                          items: TaskPriority.values
                              .map(
                                (item) => DropdownMenuItem<TaskPriority>(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _priority = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<TaskReminderOption>(
                          value: _reminder,
                          decoration: const InputDecoration(
                            labelText: 'Powiadomienie e-mail',
                          ),
                          items: TaskReminderOption.values
                              .map(
                                (item) => DropdownMenuItem<TaskReminderOption>(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _reminder = value);
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: DropdownButtonFormField<TaskRecurrence>(
                          value: _recurrence,
                          decoration: const InputDecoration(labelText: 'Cykliczność'),
                          items: TaskRecurrence.values
                              .map(
                                (item) => DropdownMenuItem<TaskRecurrence>(
                              value: item,
                              child: Text(item.label),
                            ),
                          )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) setState(() => _recurrence = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CheckboxListTile(
                    value: _isSecret,
                    onChanged: (value) => setState(() => _isSecret = value ?? false),
                    title: const Text('Tajne'),
                    subtitle: const Text(
                      'Po zaznaczeniu konfigurujesz dostęp według struktury i tagów osobistych.',
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_isSecret) ...[
                    const SizedBox(height: AppSpacing.md),
                    _SecretAccessEditor(
                      people: people,
                      allowedUnits: _allowedUnits,
                      allowedPersonIds: _allowedPersonIds,
                      allowedPersonnelTypes: _allowedPersonnelTypes,
                      allowedRankGroups: _allowedRankGroups,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Anuluj'),
              ),
              const SizedBox(width: AppSpacing.sm),
              FilledButton(
                onPressed: _submit,
                child: const Text('Zapisz zadanie'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecretAccessEditor extends StatelessWidget {
  final List<AppPerson> people;
  final Set<OrgUnit> allowedUnits;
  final Set<String> allowedPersonIds;
  final Set<PersonnelType> allowedPersonnelTypes;
  final Set<RankGroup> allowedRankGroups;
  final VoidCallback onChanged;

  const _SecretAccessEditor({
    required this.people,
    required this.allowedUnits,
    required this.allowedPersonIds,
    required this.allowedPersonnelTypes,
    required this.allowedRankGroups,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Filtry dostępu', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.md),
        ExpansionTile(
          title: const Text('Komórki organizacyjne'),
          children: OrgUnit.values.map((unit) {
            return CheckboxListTile(
              value: allowedUnits.contains(unit),
              onChanged: (value) {
                if (value ?? false) {
                  allowedUnits.add(unit);
                } else {
                  allowedUnits.remove(unit);
                }
                onChanged();
              },
              title: Text(unit.label),
            );
          }).toList(),
        ),
        ExpansionTile(
          title: const Text('Osoby'),
          children: people.map((person) {
            return CheckboxListTile(
              value: allowedPersonIds.contains(person.id),
              onChanged: (value) {
                if (value ?? false) {
                  allowedPersonIds.add(person.id);
                } else {
                  allowedPersonIds.remove(person.id);
                }
                onChanged();
              },
              title: Text(person.fullName),
              subtitle: Text(person.unit.label),
            );
          }).toList(),
        ),
        ExpansionTile(
          title: const Text('Typ personelu'),
          children: PersonnelType.values.map((type) {
            return CheckboxListTile(
              value: allowedPersonnelTypes.contains(type),
              onChanged: (value) {
                if (value ?? false) {
                  allowedPersonnelTypes.add(type);
                } else {
                  allowedPersonnelTypes.remove(type);
                }
                onChanged();
              },
              title: Text(type.label),
            );
          }).toList(),
        ),
        ExpansionTile(
          title: const Text('Korpus'),
          children: RankGroup.values.map((group) {
            return CheckboxListTile(
              value: allowedRankGroups.contains(group),
              onChanged: (value) {
                if (value ?? false) {
                  allowedRankGroups.add(group);
                } else {
                  allowedRankGroups.remove(group);
                }
                onChanged();
              },
              title: Text(group.label),
            );
          }).toList(),
        ),
      ],
    );
  }
}
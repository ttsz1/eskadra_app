import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../profiles/presentation/providers/profile_directory_provider.dart';
import '../../domain/enums/task_recurrence.dart';
import '../../domain/enums/task_reminder_option.dart';
import '../../domain/models/task_item.dart';
import '../../presentation/providers/task_module_provider.dart';
import '../../../../../shared/models/org_structure.dart';
import '../../../../../shared/widgets/ops_panel.dart';
import '../../../../../shared/widgets/ops_section_header.dart';

class TaskDetailPanel extends ConsumerStatefulWidget {
  const TaskDetailPanel({super.key});

  @override
  ConsumerState<TaskDetailPanel> createState() => _TaskDetailPanelState();
}

class _TaskDetailPanelState extends ConsumerState<TaskDetailPanel> {
  final _noteController = TextEditingController();
  final _cancelController = TextEditingController();
  final Set<String> _mentionedIds = {};

  @override
  void dispose() {
    _noteController.dispose();
    _cancelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(taskModuleProvider);
    final notifier = ref.read(taskModuleProvider.notifier);
    final people = ref.watch(profileDirectoryProvider).valueOrNull ?? const <AppPerson>[];
    final peopleById = {for (final p in people) p.id: p};
    final task = state.selectedTask;

    if (task == null) {
      return const OpsPanel(
        child: Center(child: Text('Wybierz zadanie z listy.')),
      );
    }

    final responsibleDropdownValue = _safeDropdownValue(
      currentValue: task.responsiblePersonId,
      availableValues: people.map((p) => p.id).toList(),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useScrollLayout =
            constraints.maxWidth < 1000 || constraints.maxHeight < 720;

        final content = [
          OpsSectionHeader(
            eyebrow: 'Task detail',
            title: task.title,
            subtitle: task.description,
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _InfoBlock(
                label: 'Autor',
                value: peopleById[task.createdById]?.fullName ?? task.createdById,
              ),
              _InfoBlock(
                label: 'Odpowiedzialny',
                value: task.responsiblePersonId == null
                    ? 'Nieprzypisane'
                    : (peopleById[task.responsiblePersonId!]?.fullName ??
                    task.responsiblePersonId!),
              ),
              _InfoBlock(
                label: 'Sekcja',
                value: task.sectionUnit?.label ?? 'Brak',
              ),
              _InfoBlock(
                label: 'Deadline',
                value: task.deadline.toString(),
              ),
              _InfoBlock(
                label: 'Przypomnienie',
                value: task.reminderOption.label,
              ),
              _InfoBlock(
                label: 'Cykliczność',
                value: task.recurrence.label,
              ),
              _InfoBlock(
                label: 'Pomocniczy',
                value: task.helperPersonIds.isEmpty
                    ? 'Brak'
                    : task.helperPersonIds
                    .map((id) => peopleById[id]?.fullName ?? id)
                    .join(', '),
              ),
              if (task.completedAt != null)
                _InfoBlock(
                  label: 'Zakończono',
                  value: task.completedAt.toString(),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (task.responsiblePersonId == null)
                FilledButton(
                  onPressed: () => notifier.claimTask(task.id),
                  child: const Text('Biorę to zadanie'),
                ),
              OutlinedButton(
                onPressed: () => notifier.markInProgress(task.id),
                child: const Text('Oznacz jako w realizacji'),
              ),
              OutlinedButton(
                onPressed: () => notifier.markCompleted(task.id),
                child: const Text('Zakończ'),
              ),
              OutlinedButton(
                onPressed: () => _showHelperSelectionDialog(
                  context: context,
                  people: people,
                  currentHelperIds: task.helperPersonIds,
                  onConfirm: (ids) => notifier.addHelpers(task.id, ids),
                ),
                child: const Text('Dodaj pomocniczych'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            value: responsibleDropdownValue,
            decoration: const InputDecoration(
              labelText: 'Zmień odpowiedzialnego',
            ),
            items: people
                .map(
                  (person) => DropdownMenuItem<String>(
                value: person.id,
                child: Text(person.fullName),
              ),
            )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              notifier.assignResponsible(task.id, value);
            },
          ),
          const SizedBox(height: AppSpacing.lg),
        ];

        if (useScrollLayout) {
          return OpsPanel(
            child: ListView(
              children: [
                ...content,
                SizedBox(
                  height: 420,
                  child: _NotesSection(
                    task: task,
                    peopleById: peopleById,
                    noteController: _noteController,
                    mentionedIds: _mentionedIds,
                    people: people,
                    onSelectionChanged: () => setState(() {}),
                    onSubmit: () {
                      notifier.addNote(
                        taskId: task.id,
                        content: _noteController.text,
                        mentionedPersonIds: _mentionedIds.toList(),
                      );
                      _noteController.clear();
                      _mentionedIds.clear();
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 320,
                  child: _LogSection(
                    task: task,
                    peopleById: peopleById,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _cancelController,
                  decoration: const InputDecoration(
                    labelText: 'Anuluj zadanie z powodu',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        notifier.cancelTask(
                          taskId: task.id,
                          reason: _cancelController.text,
                        );
                        _cancelController.clear();
                      },
                      child: const Text('Anuluj zadanie'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return OpsPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...content,
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _NotesSection(
                        task: task,
                        peopleById: peopleById,
                        noteController: _noteController,
                        mentionedIds: _mentionedIds,
                        people: people,
                        onSelectionChanged: () => setState(() {}),
                        onSubmit: () {
                          notifier.addNote(
                            taskId: task.id,
                            content: _noteController.text,
                            mentionedPersonIds: _mentionedIds.toList(),
                          );
                          _noteController.clear();
                          _mentionedIds.clear();
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 4,
                      child: _LogSection(
                        task: task,
                        peopleById: peopleById,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _cancelController,
                decoration: const InputDecoration(
                  labelText: 'Anuluj zadanie z powodu',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      notifier.cancelTask(
                        taskId: task.id,
                        reason: _cancelController.text,
                      );
                      _cancelController.clear();
                    },
                    child: const Text('Anuluj zadanie'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showHelperSelectionDialog({
    required BuildContext context,
    required List<AppPerson> people,
    required List<String> currentHelperIds,
    required ValueChanged<List<String>> onConfirm,
  }) async {
    final selected = currentHelperIds.toSet();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Wybierz osoby pomocnicze'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    children: people.map((person) {
                      return CheckboxListTile(
                        value: selected.contains(person.id),
                        onChanged: (value) {
                          setLocalState(() {
                            if (value ?? false) {
                              selected.add(person.id);
                            } else {
                              selected.remove(person.id);
                            }
                          });
                        },
                        title: Text(person.fullName),
                        subtitle: Text(person.unit.label),
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Anuluj'),
                ),
                FilledButton(
                  onPressed: () {
                    onConfirm(selected.toList());
                    Navigator.of(context).pop();
                  },
                  child: const Text('Zatwierdź'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String? _safeDropdownValue({
    required String? currentValue,
    required List<String> availableValues,
  }) {
    if (currentValue == null) return null;
    return availableValues.contains(currentValue) ? currentValue : null;
  }
}

class _NotesSection extends StatelessWidget {
  final TaskItem task;
  final Map<String, AppPerson> peopleById;
  final TextEditingController noteController;
  final Set<String> mentionedIds;
  final List<AppPerson> people;
  final VoidCallback onSelectionChanged;
  final VoidCallback onSubmit;

  const _NotesSection({
    required this.task,
    required this.peopleById,
    required this.noteController,
    required this.mentionedIds,
    required this.people,
    required this.onSelectionChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notatki', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: people.map((person) {
                  return FilterChip(
                    selected: mentionedIds.contains(person.id),
                    label: Text('@${person.fullName}'),
                    onSelected: (value) {
                      if (value) {
                        mentionedIds.add(person.id);
                      } else {
                        mentionedIds.remove(person.id);
                      }
                      onSelectionChanged();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: noteController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Dodaj notatkę',
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: onSubmit,
                  child: const Text('Zapisz notatkę'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: ListView.separated(
                  itemCount: task.notes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final note = task.notes[task.notes.length - 1 - index];

                    return Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            peopleById[note.authorId]?.fullName ?? note.authorId,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            note.createdAt.toString(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(note.content),
                          if (note.mentionedPersonIds.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Oznaczono: ${note.mentionedPersonIds.map((id) => peopleById[id]?.fullName ?? id).join(', ')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LogSection extends StatelessWidget {
  final TaskItem task;
  final Map<String, AppPerson> peopleById;

  const _LogSection({
    required this.task,
    required this.peopleById,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Historia / log', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView.separated(
            itemCount: task.logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final entry = task.logs[task.logs.length - 1 - index];

              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.createdAt.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(entry.message),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Autor: ${peopleById[entry.actorId]?.fullName ?? entry.actorId}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String label;
  final String value;

  const _InfoBlock({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
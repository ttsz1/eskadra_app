import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../shared/models/org_structure.dart';
import '../../../../../shared/widgets/ops_panel.dart';
import '../../../../../shared/widgets/ops_section_header.dart';
import '../../../../../shared/widgets/ops_status_chip.dart';
import '../../../profiles/presentation/providers/profile_directory_provider.dart';
import '../../domain/enums/task_board_view.dart';
import '../../domain/enums/task_priority.dart';
import '../../domain/enums/task_status.dart';
import '../../domain/models/task_item.dart';
import '../providers/task_module_provider.dart';
import 'very_urgent_badge.dart';

class TaskListPanel extends ConsumerWidget {
  const TaskListPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(taskModuleProvider);
    final notifier = ref.read(taskModuleProvider.notifier);
    final tasks = state.tasksForCurrentBoard();
    final peopleById = ref.watch(peopleByIdProvider);

    return OpsPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 320 || constraints.maxWidth < 260;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OpsSectionHeader(
                eyebrow: 'Task board',
                title: 'Lista zadań',
                subtitle: compact
                    ? null
                    : 'Widoki: moje, nieprzypisane, mojej sekcji, wszystkie i archiwum.',
                trailing: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: TaskBoardView.values.map((view) {
                    return ChoiceChip(
                      selected: state.boardView == view,
                      label: Text(view.label),
                      onSelected: (_) => notifier.changeBoard(view),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              CheckboxListTile(
                value: state.activeOnly,
                onChanged: (value) => notifier.setActiveOnly(value ?? true),
                contentPadding: EdgeInsets.zero,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Tylko aktywne'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.error != null
                    ? SingleChildScrollView(
                  child: Text(state.error!),
                )
                    : tasks.isEmpty
                    ? const Center(
                  child: Text('Brak zadań w tym widoku.'),
                )
                    : ListView.separated(
                  itemCount: tasks.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final selected = state.selectedTaskId == task.id;

                    final responsibleLabel =
                    task.responsiblePersonId == null
                        ? 'nieprzypisane'
                        : (peopleById[task.responsiblePersonId!]
                        ?.fullName ??
                        task.responsiblePersonId!);

                    final helperLabel = task.helperPersonIds.isEmpty
                        ? null
                        : task.helperPersonIds
                        .map((id) => peopleById[id]?.fullName ?? id)
                        .join(', ');

                    return InkWell(
                      onTap: () => notifier.selectTask(task.id),
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selected
                                ? Theme.of(context)
                                .colorScheme
                                .primary
                                : Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    maxLines: 2,
                                    overflow:
                                    TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                ),
                                const SizedBox(
                                    width: AppSpacing.xs),
                                if (task.priority ==
                                    TaskPriority.veryUrgent)
                                  const VeryUrgentBadge()
                                else
                                  Flexible(
                                    child: OpsStatusChip(
                                      label: task.priority.label,
                                      type: _mapPriority(
                                          task.priority),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              _countdown(task),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [
                                OpsStatusChip(
                                  label: task.status.label,
                                  type: _mapStatus(task.status),
                                ),
                                if (task.sectionUnit != null)
                                  OpsStatusChip(
                                    label: task.sectionUnit!.label,
                                    type: OpsStatusType.info,
                                  ),
                                if (task.isSecret)
                                  const OpsStatusChip(
                                    label: 'Tajne',
                                    type: OpsStatusType.warning,
                                  ),
                                if (task.responsiblePersonId == null)
                                  const OpsStatusChip(
                                    label:
                                    'Brak odpowiedzialnego',
                                    type: OpsStatusType.error,
                                  ),
                                if (task.isArchived)
                                  const OpsStatusChip(
                                    label: 'Archiwum',
                                    type: OpsStatusType.neutral,
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Odpowiedzialny: $responsibleLabel',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                            if (helperLabel != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'Pomocniczy: $helperLabel',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static OpsStatusType _mapPriority(TaskPriority value) {
    switch (value) {
      case TaskPriority.low:
        return OpsStatusType.neutral;
      case TaskPriority.normal:
        return OpsStatusType.info;
      case TaskPriority.urgent:
        return OpsStatusType.warning;
      case TaskPriority.veryUrgent:
        return OpsStatusType.error;
    }
  }

  static OpsStatusType _mapStatus(TaskStatus value) {
    switch (value) {
      case TaskStatus.unassigned:
        return OpsStatusType.error;
      case TaskStatus.newTask:
        return OpsStatusType.info;
      case TaskStatus.inProgress:
        return OpsStatusType.warning;
      case TaskStatus.waiting:
        return OpsStatusType.neutral;
      case TaskStatus.completed:
        return OpsStatusType.success;
      case TaskStatus.cancelled:
        return OpsStatusType.error;
    }
  }

  static String _countdown(TaskItem task) {
    if (task.status == TaskStatus.completed && task.completedAt != null) {
      final archiveIn = 7 - DateTime.now().difference(task.completedAt!).inDays;
      if (archiveIn > 0) {
        return 'Archiwizacja za: $archiveIn dni';
      }
      return 'Zadanie w archiwum';
    }

    final diff = task.deadline.difference(DateTime.now());

    if (diff.isNegative) {
      final overdue = diff.abs();
      final days = overdue.inDays;
      final hours = overdue.inHours.remainder(24);
      final minutes = overdue.inMinutes.remainder(60);
      return 'Po terminie: ${days}d ${hours}h ${minutes}m';
    }

    final days = diff.inDays;
    final hours = diff.inHours.remainder(24);
    final minutes = diff.inMinutes.remainder(60);
    return 'Do deadline: ${days}d ${hours}h ${minutes}m';
  }
}
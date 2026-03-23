import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../shared/widgets/ops_panel.dart';
import '../../../../shared/widgets/ops_section_header.dart';
import '../../../../shared/widgets/ops_status_chip.dart';
import '../../../announcements/domain/models/announcement.dart';
import '../../../announcements/presentation/providers/announcements_providers.dart';
import '../../../announcements/presentation/widgets/add_announcement_dialog.dart';
import '../../../events/domain/models/event_item.dart';
import '../../../events/presentation/providers/upcoming_events_provider.dart';
import '../../../events/presentation/widgets/event_create_dialog.dart';
import '../../../my_calendar/presentation/widgets/my_calendar_month_panel.dart';
import '../../../obecnosci/presentation/providers/attendance_provider.dart';
import '../../../obecnosci/presentation/widgets/attendance_entry_dialog.dart';
import '../../../profiles/presentation/providers/profile_directory_provider.dart';
import '../../../tasks/domain/enums/task_priority.dart';
import '../../../tasks/domain/enums/task_status.dart';
import '../../../tasks/domain/models/task_item.dart';
import '../../../tasks/presentation/providers/task_module_provider.dart';
import '../../../tasks/presentation/widgets/task_create_dialog.dart';
import '../widgets/dashboard_attendance_day_timeline.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  static const String routePath = '/';

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late Timer _clockTimer;
  late Timer _dashboardRefreshTimer;

  DateTime _now = DateTime.now();
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  void initState() {
    super.initState();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _now = DateTime.now();
      });
    });

    _dashboardRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;

      ref.invalidate(attendancePeopleProvider);
      ref.invalidate(attendanceTodaySummaryProvider);
      ref.invalidate(currentWeekAttendanceEntriesProvider);
      ref.invalidate(upcomingEventsProvider);
      ref.read(announcementsActionsProvider).refresh();

      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _dashboardRefreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskModuleProvider);
    final taskNotifier = ref.read(taskModuleProvider.notifier);
    final eventsAsync = ref.watch(upcomingEventsProvider);
    final announcementsAsync = ref.watch(announcementsProvider);
    final currentUser = ref.watch(currentAppPersonProvider);

    final myTasks = _resolveMyDeadlineTasks(taskState);
    final unassignedTasks = _resolveUnassignedTasks(taskState);

    final dateLabel = DateFormat('EEEE, dd.MM.yyyy', 'pl_PL').format(_now);
    final localTimeLabel = DateFormat('HH:mm:ss').format(_now);
    final utcTimeLabel = DateFormat('HH:mm:ss').format(_now.toUtc());
    final loggedUser = currentUser?.fullName ?? 'Brak aktywnej sesji';

    return Scaffold(
      body: Column(
        children: [
          _DashboardHeader(
            dateLabel: dateLabel,
            localTimeLabel: localTimeLabel,
            utcTimeLabel: utcTimeLabel,
            loggedUser: loggedUser,
            onCreateTask: () async {
              await showTaskCreateDialog(context);
            },
            onCreateEvent: () => showEventCreateDialog(context),
            onOpenAttendance: () async {
              await showAttendanceEntryDialog(context);
            },
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 1250;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isWide)
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 1.35,
                          children: [
                            _taskTile(
                              eyebrow: 'Moje zadania',
                              title: 'Najbliższe terminy',
                              subtitle:
                                  'Zadania przypisane do mnie lub do mojej realizacji.',
                              trailing: const OpsStatusChip(
                                label: 'Moje',
                                type: OpsStatusType.info,
                              ),
                              tasks: myTasks,
                              emptyLabel: taskState.isLoading
                                  ? 'Ładowanie...'
                                  : 'Brak moich aktywnych terminów.',
                              onTaskTap: (task) {
                                taskNotifier.selectTask(task.id);
                                context.go('/tasks');
                              },
                            ),
                            _unassignedTile(
                              tasks: unassignedTasks,
                              taskState: taskState,
                              onTaskTap: (task) {
                                taskNotifier.selectTask(task.id);
                                context.go('/tasks');
                              },
                              onClaim: (task) =>
                                  taskNotifier.claimTask(task.id),
                            ),
                            _attendanceTile(),
                            _eventsTile(eventsAsync),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _taskTile(
                              eyebrow: 'Moje zadania',
                              title: 'Najbliższe terminy',
                              subtitle:
                                  'Zadania przypisane do mnie lub do mojej realizacji.',
                              trailing: const OpsStatusChip(
                                label: 'Moje',
                                type: OpsStatusType.info,
                              ),
                              tasks: myTasks,
                              emptyLabel: taskState.isLoading
                                  ? 'Ładowanie...'
                                  : 'Brak moich aktywnych terminów.',
                              onTaskTap: (task) {
                                taskNotifier.selectTask(task.id);
                                context.go('/tasks');
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _unassignedTile(
                              tasks: unassignedTasks,
                              taskState: taskState,
                              onTaskTap: (task) {
                                taskNotifier.selectTask(task.id);
                                context.go('/tasks');
                              },
                              onClaim: (task) =>
                                  taskNotifier.claimTask(task.id),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _attendanceTile(),
                            const SizedBox(height: AppSpacing.md),
                            _eventsTile(eventsAsync),
                          ],
                        ),
                      const SizedBox(height: AppSpacing.md),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: _calendarTile(),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              flex: 4,
                              child: _noticesTile(announcementsAsync),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            _calendarTile(),
                            const SizedBox(height: AppSpacing.md),
                            _noticesTile(announcementsAsync),
                          ],
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<TaskItem> _resolveMyDeadlineTasks(TaskModuleState state) {
    final user = state.currentUser;
    if (user == null) return const [];

    final items = state.tasks.where((task) {
      if (task.isArchived) return false;
      if (task.status == TaskStatus.cancelled ||
          task.status == TaskStatus.completed) {
        return false;
      }

      return task.responsiblePersonId == user.id ||
          task.helperPersonIds.contains(user.id);
    }).toList();

    items.sort((a, b) => a.deadline.compareTo(b.deadline));
    return items.take(6).toList();
  }

  List<TaskItem> _resolveUnassignedTasks(TaskModuleState state) {
    final items = state.tasks.where((task) {
      if (task.isArchived) return false;
      if (task.status == TaskStatus.cancelled ||
          task.status == TaskStatus.completed) {
        return false;
      }
      return task.isUnassigned;
    }).toList();

    items.sort((a, b) => a.deadline.compareTo(b.deadline));
    return items.take(6).toList();
  }

  Widget _taskTile({
    required String eyebrow,
    required String title,
    required String subtitle,
    required Widget trailing,
    required List<TaskItem> tasks,
    required String emptyLabel,
    required ValueChanged<TaskItem> onTaskTap,
  }) {
    return _DashboardTile(
      eyebrow: eyebrow,
      title: title,
      subtitle: subtitle,
      trailing: trailing,
      child: tasks.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(emptyLabel),
            )
          : Column(
              children: tasks
                  .map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _SupabaseTaskRow(
                        task: task,
                        onTap: () => onTaskTap(task),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _unassignedTile({
    required List<TaskItem> tasks,
    required TaskModuleState taskState,
    required ValueChanged<TaskItem> onTaskTap,
    required ValueChanged<TaskItem> onClaim,
  }) {
    return _DashboardTile(
      eyebrow: 'Zadania ogólne',
      title: 'Nieprzypisane / ogólne',
      subtitle: 'Zadania oczekujące na przypisanie odpowiedzialnego.',
      trailing: const OpsStatusChip(
        label: 'Otwarte',
        type: OpsStatusType.warning,
      ),
      child: tasks.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                taskState.isLoading
                    ? 'Ładowanie...'
                    : 'Brak zadań nieprzypisanych.',
              ),
            )
          : Column(
              children: tasks
                  .map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _UnassignedTaskRow(
                        task: task,
                        onTap: () => onTaskTap(task),
                        onClaim: () => onClaim(task),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _attendanceTile() {
    return const SizedBox(
      height: 420,
      child: DashboardAttendanceDayTimeline(),
    );
  }

  Widget _eventsTile(AsyncValue<List<EventItem>> eventsAsync) {
    final peopleById = ref.watch(peopleByIdProvider);

    return _DashboardTile(
      eyebrow: 'Wydarzenia',
      title: 'Najbliższe wydarzenia',
      subtitle: 'Najbliższe wpisy z tabeli events w Supabase.',
      trailing: const OpsStatusChip(
        label: 'Supabase',
        type: OpsStatusType.success,
      ),
      child: eventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Text('Brak nadchodzących wydarzeń.');
          }

          return Column(
            children: events
                .take(6)
                .map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _SupabaseEventRow(
                      item: event,
                      createdByLabel:
                          peopleById[event.createdBy]?.fullName ??
                              event.createdBy,
                      onEdit: () => showEventEditDialog(
                        context,
                        event: event,
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Text('Błąd wydarzeń: $error'),
      ),
    );
  }

  Widget _calendarTile() {
    return const SizedBox(
      height: 760,
      child: MyCalendarMonthPanel(
        compact: true,
        showOuterPanel: true,
        title: 'Mój kalendarz',
        subtitle:
            'Podgląd moich obecności, planowanych urlopów, wydarzeń, terminów i prywatnych wpisów.',
      ),
    );
  }

  Widget _noticesTile(AsyncValue<List<Announcement>> announcementsAsync) {
    return OpsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OpsSectionHeader(
            eyebrow: 'Informacje ogólne',
            title: 'Komunikaty wspólne',
            subtitle:
                'Miejsce na bieżące informacje organizacyjne widoczne dla całego zespołu.',
            trailing: FilledButton.icon(
              onPressed: () async {
                await showDialog<bool>(
                  context: context,
                  builder: (_) => const AddAnnouncementDialog(),
                );
              },
              icon: const Icon(
                Icons.campaign_rounded,
                size: 18,
                color: Colors.redAccent,
              ),
              label: const Text('Dodaj komunikat'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          announcementsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return const _NoticeEmptyState();
              }

              return Column(
                children: items
                    .take(10)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _AnnouncementRow(
                          item: item,
                          onTap: () {
                            context.go('/announcements?focus=${item.id}');
                          },
                          onDelete: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Usuń komunikat'),
                                content: Text(
                                  'Czy na pewno usunąć komunikat "${item.title}"?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Anuluj'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Usuń'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed != true || !mounted) return;

                            try {
                              await ref
                                  .read(announcementsActionsProvider)
                                  .deleteAnnouncement(item.id);

                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Komunikat usunięty.'),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Nie udało się usunąć komunikatu: $e',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    )
                    .toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Text('Błąd komunikatów: $error'),
          ),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String dateLabel;
  final String localTimeLabel;
  final String utcTimeLabel;
  final String loggedUser;
  final Future<void> Function() onCreateTask;
  final VoidCallback onCreateEvent;
  final Future<void> Function() onOpenAttendance;

  const _DashboardHeader({
    required this.dateLabel,
    required this.localTimeLabel,
    required this.utcTimeLabel,
    required this.loggedUser,
    required this.onCreateTask,
    required this.onCreateEvent,
    required this.onOpenAttendance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.pagePadding,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 900;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PODGLĄD OPERACYJNY',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              const SizedBox(height: 2),
              Text(
                dateLabel,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _HeaderInfoCard(label: 'Czas lokalny', value: localTimeLabel),
                  _HeaderInfoCard(label: 'UTC', value: utcTimeLabel),
                  _HeaderInfoCard(
                    label: 'Zalogowany',
                    value: loggedUser,
                    compact: !compact,
                  ),
                  FilledButton.icon(
                    onPressed: onOpenAttendance,
                    icon: const Icon(Icons.badge_outlined, size: 18),
                    label: const Text('Wprowadź obecności'),
                  ),
                  FilledButton.icon(
                    onPressed: onCreateTask,
                    icon: const Icon(Icons.add_task, size: 18),
                    label: const Text('Dodaj zadanie'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onCreateEvent,
                    icon: const Icon(Icons.event, size: 18),
                    label: const Text('Dodaj wydarzenie'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final bool compact;

  const _HeaderInfoCard({
    required this.label,
    required this.value,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: compact ? 100 : 180,
        maxWidth: compact ? 160 : 280,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DashboardTile extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final Widget child;

  const _DashboardTile({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return OpsPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OpsSectionHeader(
            eyebrow: eyebrow,
            title: title,
            subtitle: subtitle,
            trailing: trailing,
          ),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _SupabaseTaskRow extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onTap;

  const _SupabaseTaskRow({
    required this.task,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final deadlineLabel = DateFormat('dd.MM.yyyy • HH:mm').format(task.deadline);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          if (compact) {
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
                    deadlineLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OpsStatusChip(
                    label: task.priority.label,
                    type: _mapPriority(task.priority),
                  ),
                ],
              ),
            );
          }

          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 2,
                  child: Text(
                    deadlineLabel,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 5,
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: OpsStatusChip(
                    label: task.priority.label,
                    type: _mapPriority(task.priority),
                  ),
                ),
              ],
            ),
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
}

class _UnassignedTaskRow extends StatelessWidget {
  final TaskItem task;
  final VoidCallback onTap;
  final VoidCallback onClaim;

  const _UnassignedTaskRow({
    required this.task,
    required this.onTap,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final deadlineLabel = DateFormat('dd.MM.yyyy • HH:mm').format(task.deadline);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deadlineLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  OpsStatusChip(
                    label: task.priority.label,
                    type: _SupabaseTaskRow._mapPriority(task.priority),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onClaim,
              child: const Text('Biorę'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupabaseEventRow extends StatelessWidget {
  final EventItem item;
  final String createdByLabel;
  final VoidCallback onEdit;

  const _SupabaseEventRow({
    required this.item,
    required this.createdByLabel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final label = DateFormat('dd.MM.yyyy • HH:mm').format(item.startsAt);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 520;

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '$label • ${item.location ?? item.details}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Dodał: $createdByLabel',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const OpsStatusChip(
                      label: 'Wydarzenie',
                      type: OpsStatusType.info,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edytuj'),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Icon(
                Icons.event_note_outlined,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '$label • ${item.location ?? item.details}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Dodał: $createdByLabel',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const OpsStatusChip(
                label: 'Wydarzenie',
                type: OpsStatusType.info,
              ),
              const SizedBox(width: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edytuj'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NoticeEmptyState extends StatelessWidget {
  const _NoticeEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Brak aktywnych komunikatów.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _AnnouncementRow extends StatelessWidget {
  const _AnnouncementRow({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  final Announcement item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd.MM.yyyy • HH:mm');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.campaign_rounded,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      item.content,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Text(
                          'Dodał: ${item.authorName}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          '• ${formatter.format(item.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (item.autoDeleteAt != null)
                          Text(
                            '• Auto delete: ${formatter.format(item.autoDeleteAt!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: 'Usuń komunikat',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

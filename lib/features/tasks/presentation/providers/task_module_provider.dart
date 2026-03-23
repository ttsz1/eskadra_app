import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/models/org_structure.dart';
import '../../../profiles/presentation/providers/profile_directory_provider.dart';
import '../../data/repositories/task_repository_supabase.dart';
import '../../domain/enums/task_board_view.dart';
import '../../domain/enums/task_priority.dart';
import '../../domain/enums/task_recurrence.dart';
import '../../domain/enums/task_reminder_option.dart';
import '../../domain/enums/task_status.dart';
import '../../domain/models/task_item.dart';
import '../../domain/models/task_secret_access.dart';

final taskRepositoryProvider = Provider<TaskRepositorySupabase>((ref) {
  return TaskRepositorySupabase.fromClient(Supabase.instance.client);
});

final taskModuleProvider =
StateNotifierProvider<TaskModuleNotifier, TaskModuleState>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final currentUser = ref.watch(currentAppPersonProvider);

  return TaskModuleNotifier(
    repository: repository,
    initialState: TaskModuleState.initial(currentUser: currentUser),
  )..loadTasks();
});

class TaskModuleState {
  final AppPerson? currentUser;
  final List<TaskItem> tasks;
  final TaskBoardView boardView;
  final String? selectedTaskId;
  final bool isLoading;
  final String? error;
  final bool activeOnly;

  const TaskModuleState({
    required this.currentUser,
    required this.tasks,
    required this.boardView,
    required this.selectedTaskId,
    required this.isLoading,
    required this.error,
    required this.activeOnly,
  });

  factory TaskModuleState.initial({required AppPerson? currentUser}) {
    return TaskModuleState(
      currentUser: currentUser,
      tasks: const [],
      boardView: TaskBoardView.myTasks,
      selectedTaskId: null,
      isLoading: false,
      error: null,
      activeOnly: true,
    );
  }

  TaskItem? get selectedTask {
    if (selectedTaskId == null) return null;
    try {
      return tasks.firstWhere((task) => task.id == selectedTaskId);
    } catch (_) {
      return null;
    }
  }

  bool _passesActivityFilter(TaskItem task) {
    if (!activeOnly) return true;
    return task.status != TaskStatus.completed &&
        task.status != TaskStatus.cancelled;
  }

  List<TaskItem> tasksForCurrentBoard() {
    final source = tasks.where(_passesActivityFilter).toList();
    final user = currentUser;

    switch (boardView) {
      case TaskBoardView.myTasks:
        if (user == null) return const [];
        return source.where((task) {
          if (task.isArchived) return false;
          return task.responsiblePersonId == user.id ||
              task.helperPersonIds.contains(user.id);
        }).toList();

      case TaskBoardView.unassigned:
        return source.where((task) {
          if (task.isArchived) return false;
          return task.isUnassigned;
        }).toList();

      case TaskBoardView.mySection:
        if (user == null) return const [];
        return source.where((task) {
          if (task.isArchived) return false;
          return task.sectionUnit == user.unit;
        }).toList();

      case TaskBoardView.all:
        return source.where((task) => !task.isArchived).toList();

      case TaskBoardView.archive:
        return tasks.where((task) => task.isArchived).toList();
    }
  }

  TaskModuleState copyWith({
    AppPerson? currentUser,
    bool setCurrentUser = false,
    List<TaskItem>? tasks,
    TaskBoardView? boardView,
    String? selectedTaskId,
    bool clearSelectedTask = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
    bool? activeOnly,
  }) {
    return TaskModuleState(
      currentUser: setCurrentUser ? currentUser : this.currentUser,
      tasks: tasks ?? this.tasks,
      boardView: boardView ?? this.boardView,
      selectedTaskId:
      clearSelectedTask ? null : (selectedTaskId ?? this.selectedTaskId),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      activeOnly: activeOnly ?? this.activeOnly,
    );
  }
}

class TaskDraft {
  final String title;
  final String description;
  final String? responsiblePersonId;
  final List<String> helperPersonIds;
  final DateTime deadline;
  final TaskPriority priority;
  final bool isSecret;
  final TaskSecretAccess? secretAccess;
  final String? attachmentName;
  final TaskReminderOption reminderOption;
  final TaskRecurrence recurrence;

  const TaskDraft({
    required this.title,
    required this.description,
    required this.deadline,
    required this.priority,
    required this.isSecret,
    required this.reminderOption,
    required this.recurrence,
    this.responsiblePersonId,
    this.helperPersonIds = const [],
    this.secretAccess,
    this.attachmentName,
  });
}

class TaskModuleNotifier extends StateNotifier<TaskModuleState> {
  final TaskRepositorySupabase repository;

  TaskModuleNotifier({
    required this.repository,
    required TaskModuleState initialState,
  }) : super(initialState);

  Future<void> loadTasks() async {
    if (!mounted) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true);

      final tasks = await repository.fetchTasks();
      if (!mounted) return;

      state = state.copyWith(
        tasks: tasks,
        isLoading: false,
        selectedTaskId: _resolveSelectedTaskId(tasks),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Błąd ładowania zadań: $e',
      );
    }
  }

  void changeBoard(TaskBoardView view) {
    if (!mounted) return;

    final tempState = state.copyWith(boardView: view);
    final nextTasks = tempState.tasksForCurrentBoard();

    state = state.copyWith(
      boardView: view,
      selectedTaskId: nextTasks.isNotEmpty ? nextTasks.first.id : null,
      clearSelectedTask: nextTasks.isEmpty,
    );
  }

  void setActiveOnly(bool value) {
    if (!mounted) return;

    final tempState = state.copyWith(activeOnly: value);
    final nextTasks = tempState.tasksForCurrentBoard();

    state = state.copyWith(
      activeOnly: value,
      selectedTaskId: nextTasks.isNotEmpty ? nextTasks.first.id : null,
      clearSelectedTask: nextTasks.isEmpty,
    );
  }

  void selectTask(String taskId) {
    if (!mounted) return;
    state = state.copyWith(selectedTaskId: taskId);
  }

  Future<void> createTask(TaskDraft draft) async {
    final user = state.currentUser;
    final authUser = Supabase.instance.client.auth.currentUser;

    if (authUser == null) {
      state = state.copyWith(error: 'Brak aktywnej sesji auth.');
      return;
    }

    if (user == null) {
      state = state.copyWith(
        error:
        'Brak profilu w public.profiles dla auth.uid() = ${authUser.id}. Sprawdź, czy profiles.id jest dokładnie takie samo jak auth.users.id.',
      );
      return;
    }

    try {
      state = state.copyWith(isLoading: true, clearError: true);

      await repository.createTask(
        currentUserId: user.id,
        draft: draft,
      );
      if (!mounted) return;

      await loadTasks();
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Błąd tworzenia zadania: $e',
      );
    }
  }

  Future<void> claimTask(String taskId) async {
    final user = state.currentUser;
    if (user == null) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await repository.claimTask(taskId: taskId, currentUser: user);
      if (!mounted) return;

      await loadTasks();
      if (!mounted) return;

      state = state.copyWith(selectedTaskId: taskId);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Błąd przejęcia zadania: $e',
      );
    }
  }

  Future<void> assignResponsible(String taskId, String personId) async {
    final user = state.currentUser;
    if (user == null) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await repository.assignResponsible(
        taskId: taskId,
        actor: user,
        personId: personId,
      );
      if (!mounted) return;

      await loadTasks();
      if (!mounted) return;

      state = state.copyWith(selectedTaskId: taskId);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Błąd przypisania odpowiedzialnego: $e',
      );
    }
  }

  Future<void> addHelpers(String taskId, List<String> personIds) async {
    final user = state.currentUser;
    if (user == null || personIds.isEmpty) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await repository.addHelpers(
        taskId: taskId,
        actor: user,
        personIds: personIds,
      );
      if (!mounted) return;

      await loadTasks();
      if (!mounted) return;

      state = state.copyWith(selectedTaskId: taskId);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Błąd dodawania pomocniczych: $e',
      );
    }
  }

  Future<void> addNote({
    required String taskId,
    required String content,
    required List<String> mentionedPersonIds,
  }) async {
    final user = state.currentUser;
    if (user == null || content.trim().isEmpty) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await repository.addNote(
        taskId: taskId,
        author: user,
        content: content,
        mentionedIds: mentionedPersonIds,
      );
      if (!mounted) return;

      await loadTasks();
      if (!mounted) return;

      state = state.copyWith(selectedTaskId: taskId);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Błąd dodawania notatki: $e',
      );
    }
  }

  Future<void> markInProgress(String taskId) async {
    final user = state.currentUser;
    if (user == null) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await repository.markInProgress(taskId: taskId, actor: user);
      if (!mounted) return;

      await loadTasks();
      if (!mounted) return;

      state = state.copyWith(selectedTaskId: taskId);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Błąd zmiany statusu: $e',
      );
    }
  }

  Future<void> markCompleted(String taskId) async {
    final user = state.currentUser;
    if (user == null) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await repository.markCompleted(taskId: taskId, actor: user);
      if (!mounted) return;

      await loadTasks();
      if (!mounted) return;

      state = state.copyWith(selectedTaskId: taskId);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Błąd zakończenia zadania: $e',
      );
    }
  }

  Future<void> cancelTask({
    required String taskId,
    required String reason,
  }) async {
    final user = state.currentUser;
    if (user == null || reason.trim().isEmpty) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await repository.cancelTask(
        taskId: taskId,
        actor: user,
        reason: reason.trim(),
      );
      if (!mounted) return;

      await loadTasks();
      if (!mounted) return;

      state = state.copyWith(selectedTaskId: taskId);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Błąd anulowania zadania: $e',
      );
    }
  }

  String? _resolveSelectedTaskId(List<TaskItem> tasks) {
    if (tasks.isEmpty) return null;

    final existing = state.selectedTaskId;
    if (existing != null && tasks.any((task) => task.id == existing)) {
      return existing;
    }

    final boardTasks = state.copyWith(tasks: tasks).tasksForCurrentBoard();
    if (boardTasks.isNotEmpty) {
      return boardTasks.first.id;
    }

    return tasks.first.id;
  }
}
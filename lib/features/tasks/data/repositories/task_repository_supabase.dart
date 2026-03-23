import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/org_structure.dart';
import '../../domain/enums/task_status.dart';
import '../../domain/models/task_item.dart';
import '../../presentation/providers/task_module_provider.dart';
import '../datasources/task_remote_datasource.dart';

class TaskRepositorySupabase {
  final TaskRemoteDatasource remote;

  TaskRepositorySupabase(this.remote);

  factory TaskRepositorySupabase.fromClient(SupabaseClient client) {
    return TaskRepositorySupabase(TaskRemoteDatasource(client));
  }

  Future<List<TaskItem>> fetchTasks() async {
    final rows = await remote.fetchTasks();
    return rows.map((e) => e.toDomain()).toList();
  }

  Future<void> createTask({
    required String currentUserId,
    required TaskDraft draft,
  }) {
    return remote.createTask(
      currentUserId: currentUserId,
      draft: draft,
    );
  }

  Future<void> assignResponsible({
    required String taskId,
    required AppPerson actor,
    required String personId,
  }) {
    return remote.assignResponsible(
      taskId: taskId,
      actorId: actor.id,
      personId: personId,
    );
  }

  Future<void> claimTask({
    required String taskId,
    required AppPerson currentUser,
  }) {
    return remote.claimTask(
      taskId: taskId,
      currentUserId: currentUser.id,
      currentUserName: currentUser.fullName,
    );
  }

  Future<void> addHelpers({
    required String taskId,
    required AppPerson actor,
    required List<String> personIds,
  }) {
    return remote.addHelpers(
      taskId: taskId,
      actorId: actor.id,
      personIds: personIds,
    );
  }

  Future<void> addNote({
    required String taskId,
    required AppPerson author,
    required String content,
    required List<String> mentionedIds,
  }) {
    return remote.addNote(
      taskId: taskId,
      authorId: author.id,
      content: content,
      mentionedIds: mentionedIds,
      logMessage: '${author.fullName} dodał(a) notatkę.',
    );
  }

  Future<void> markInProgress({
    required String taskId,
    required AppPerson actor,
  }) {
    return remote.updateStatus(
      taskId: taskId,
      actorId: actor.id,
      status: TaskStatus.inProgress,
      logMessage: '${actor.fullName} zmienił(a) status na: W realizacji.',
    );
  }

  Future<void> markCompleted({
    required String taskId,
    required AppPerson actor,
  }) {
    return remote.updateStatus(
      taskId: taskId,
      actorId: actor.id,
      status: TaskStatus.completed,
      logMessage: '${actor.fullName} oznaczył(a) zadanie jako zakończone.',
    );
  }

  Future<void> cancelTask({
    required String taskId,
    required AppPerson actor,
    required String reason,
  }) {
    return remote.cancelTask(
      taskId: taskId,
      actorId: actor.id,
      reason: reason,
      logMessage: '${actor.fullName} anulował(a) zadanie. Powód: $reason',
    );
  }
}
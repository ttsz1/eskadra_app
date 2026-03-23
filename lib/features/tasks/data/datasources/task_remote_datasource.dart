import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/models/org_structure.dart';
import '../../domain/enums/task_priority.dart';
import '../../domain/enums/task_recurrence.dart';
import '../../domain/enums/task_reminder_option.dart';
import '../../domain/enums/task_status.dart';
import '../../domain/models/task_log_entry.dart';
import '../../domain/models/task_note.dart';
import '../../domain/models/task_secret_access.dart';
import '../../presentation/providers/task_module_provider.dart';
import '../models/task_row.dart';

class TaskRemoteDatasource {
  final SupabaseClient client;

  TaskRemoteDatasource(this.client);

  Future<List<TaskRow>> fetchTasks() async {
    final tasksResponse =
    await client.from('tasks').select().order('created_at', ascending: false);

    final taskList = List<Map<String, dynamic>>.from(tasksResponse);

    if (taskList.isEmpty) {
      return [];
    }

    final taskIds = taskList.map((e) => e['id'] as String).toList();

    final helpersResponse = await client
        .from('task_helpers')
        .select('task_id, person_id')
        .inFilter('task_id', taskIds);

    final notesResponse = await client
        .from('task_notes')
        .select('id, task_id, author_id, content, created_at')
        .inFilter('task_id', taskIds)
        .order('created_at');

    final logsResponse = await client
        .from('task_logs')
        .select('id, task_id, actor_id, message, created_at')
        .inFilter('task_id', taskIds)
        .order('created_at');

    final noteRows = List<Map<String, dynamic>>.from(notesResponse);
    final noteIds = noteRows.map((e) => e['id'] as String).toList();

    final mentionsResponse = noteIds.isEmpty
        ? <Map<String, dynamic>>[]
        : List<Map<String, dynamic>>.from(
      await client
          .from('task_note_mentions')
          .select('task_note_id, person_id')
          .inFilter('task_note_id', noteIds),
    );

    final secretUnitsResponse = List<Map<String, dynamic>>.from(
      await client
          .from('task_secret_units')
          .select('task_id, org_unit')
          .inFilter('task_id', taskIds),
    );

    final secretPeopleResponse = List<Map<String, dynamic>>.from(
      await client
          .from('task_secret_people')
          .select('task_id, person_id')
          .inFilter('task_id', taskIds),
    );

    final secretPersonnelTypesResponse = List<Map<String, dynamic>>.from(
      await client
          .from('task_secret_personnel_types')
          .select('task_id, personnel_type')
          .inFilter('task_id', taskIds),
    );

    final secretRankGroupsResponse = List<Map<String, dynamic>>.from(
      await client
          .from('task_secret_rank_groups')
          .select('task_id, rank_group')
          .inFilter('task_id', taskIds),
    );

    final helperMap = <String, List<String>>{};
    for (final row in List<Map<String, dynamic>>.from(helpersResponse)) {
      final taskId = row['task_id'] as String;
      final personId = row['person_id'] as String;
      helperMap.putIfAbsent(taskId, () => []).add(personId);
    }

    final mentionMap = <String, List<String>>{};
    for (final row in mentionsResponse) {
      final noteId = row['task_note_id'] as String;
      final personId = row['person_id'] as String;
      mentionMap.putIfAbsent(noteId, () => []).add(personId);
    }

    final notesMap = <String, List<TaskNote>>{};
    for (final row in noteRows) {
      final note = TaskNote(
        id: row['id'] as String,
        authorId: row['author_id'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        content: row['content'] as String? ?? '',
        mentionedPersonIds: mentionMap[row['id'] as String] ?? const [],
      );

      final taskId = row['task_id'] as String;
      notesMap.putIfAbsent(taskId, () => []).add(note);
    }

    final logsMap = <String, List<TaskLogEntry>>{};
    for (final row in List<Map<String, dynamic>>.from(logsResponse)) {
      final entry = TaskLogEntry(
        id: row['id'] as String,
        actorId: row['actor_id'] as String,
        message: row['message'] as String? ?? '',
        createdAt: DateTime.parse(row['created_at'] as String),
      );

      final taskId = row['task_id'] as String;
      logsMap.putIfAbsent(taskId, () => []).add(entry);
    }

    final secretUnitsMap = <String, Set<OrgUnit>>{};
    for (final row in secretUnitsResponse) {
      final taskId = row['task_id'] as String;
      final unit = _parseOrgUnit(row['org_unit'] as String?);
      if (unit != null) {
        secretUnitsMap.putIfAbsent(taskId, () => <OrgUnit>{}).add(unit);
      }
    }

    final secretPeopleMap = <String, Set<String>>{};
    for (final row in secretPeopleResponse) {
      final taskId = row['task_id'] as String;
      final personId = row['person_id'] as String;
      secretPeopleMap.putIfAbsent(taskId, () => <String>{}).add(personId);
    }

    final secretPersonnelTypesMap = <String, Set<PersonnelType>>{};
    for (final row in secretPersonnelTypesResponse) {
      final taskId = row['task_id'] as String;
      final type = _parsePersonnelType(row['personnel_type'] as String?);
      if (type != null) {
        secretPersonnelTypesMap.putIfAbsent(taskId, () => <PersonnelType>{}).add(type);
      }
    }

    final secretRankGroupsMap = <String, Set<RankGroup>>{};
    for (final row in secretRankGroupsResponse) {
      final taskId = row['task_id'] as String;
      final group = _parseRankGroup(row['rank_group'] as String?);
      if (group != null) {
        secretRankGroupsMap.putIfAbsent(taskId, () => <RankGroup>{}).add(group);
      }
    }

    return taskList.map((task) {
      final taskId = task['id'] as String;

      final secretAccess = (task['is_secret'] as bool? ?? false)
          ? TaskSecretAccess(
        allowedUnits: secretUnitsMap[taskId] ?? const <OrgUnit>{},
        allowedPersonIds: secretPeopleMap[taskId] ?? const <String>{},
        allowedPersonnelTypes:
        secretPersonnelTypesMap[taskId] ?? const <PersonnelType>{},
        allowedRankGroups:
        secretRankGroupsMap[taskId] ?? const <RankGroup>{},
      )
          : null;

      return TaskRow.fromMap(
        task: task,
        helperPersonIds: helperMap[taskId] ?? const [],
        notes: notesMap[taskId] ?? const [],
        logs: logsMap[taskId] ?? const [],
        secretAccess: secretAccess,
      );
    }).toList();
  }

  Future<void> createTask({
    required String currentUserId,
    required TaskDraft draft,
  }) async {
    await client.from('tasks').insert({
      'title': draft.title.trim(),
      'description': draft.description.trim(),
      'created_by': currentUserId,
      'responsible_person_id': draft.responsiblePersonId,
      'priority': _priorityToDb(draft.priority),
      'status': draft.responsiblePersonId == null ? 'unassigned' : 'new_task',
      'is_secret': draft.isSecret,
      'attachment_name': draft.attachmentName,
      'attachment_path': null,
      'reminder_option': _reminderToDb(draft.reminderOption),
      'recurrence': _recurrenceToDb(draft.recurrence),
      'deadline': draft.deadline.toUtc().toIso8601String(),
    });
  }

  Future<void> assignResponsible({
    required String taskId,
    required String personId,
    required String actorId,
  }) async {
    await client.from('tasks').update({
      'responsible_person_id': personId,
    }).eq('id', taskId);

    await client.from('task_logs').insert({
      'task_id': taskId,
      'actor_id': actorId,
      'message': 'Zmieniono osobę odpowiedzialną.',
    });
  }

  Future<void> claimTask({
    required String taskId,
    required String currentUserId,
    required String currentUserName,
  }) async {
    await client.from('tasks').update({
      'responsible_person_id': currentUserId,
    }).eq('id', taskId);

    await client.from('task_logs').insert({
      'task_id': taskId,
      'actor_id': currentUserId,
      'message': '$currentUserName przejął(ęła) zadanie.',
    });
  }

  Future<void> addHelpers({
    required String taskId,
    required String actorId,
    required List<String> personIds,
  }) async {
    if (personIds.isEmpty) return;

    await client.from('task_helpers').upsert(
      personIds
          .toSet()
          .map((id) => {
        'task_id': taskId,
        'person_id': id,
        'added_by': actorId,
      })
          .toList(),
      onConflict: 'task_id,person_id',
    );

    await client.from('task_logs').insert({
      'task_id': taskId,
      'actor_id': actorId,
      'message': 'Zaktualizowano osoby pomocnicze.',
    });
  }

  Future<void> addNote({
    required String taskId,
    required String authorId,
    required String content,
    required List<String> mentionedIds,
    required String logMessage,
  }) async {
    final inserted = await client
        .from('task_notes')
        .insert({
      'task_id': taskId,
      'author_id': authorId,
      'content': content.trim(),
    })
        .select('id')
        .single();

    final noteId = inserted['id'] as String;

    if (mentionedIds.isNotEmpty) {
      await client.from('task_note_mentions').insert(
        mentionedIds
            .toSet()
            .map((id) => {
          'task_note_id': noteId,
          'person_id': id,
        })
            .toList(),
      );
    }

    await client.from('task_logs').insert({
      'task_id': taskId,
      'actor_id': authorId,
      'message': logMessage,
    });
  }

  Future<void> updateStatus({
    required String taskId,
    required String actorId,
    required TaskStatus status,
    required String logMessage,
  }) async {
    await client.from('tasks').update({
      'status': _statusToDb(status),
    }).eq('id', taskId);

    await client.from('task_logs').insert({
      'task_id': taskId,
      'actor_id': actorId,
      'message': logMessage,
    });
  }

  Future<void> cancelTask({
    required String taskId,
    required String actorId,
    required String reason,
    required String logMessage,
  }) async {
    await client.from('tasks').update({
      'status': 'cancelled',
      'cancellation_reason': reason.trim(),
    }).eq('id', taskId);

    await client.from('task_logs').insert({
      'task_id': taskId,
      'actor_id': actorId,
      'message': logMessage,
    });
  }

  static String _priorityToDb(TaskPriority value) {
    switch (value) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.normal:
        return 'normal';
      case TaskPriority.urgent:
        return 'urgent';
      case TaskPriority.veryUrgent:
        return 'very_urgent';
    }
  }

  static String _statusToDb(TaskStatus value) {
    switch (value) {
      case TaskStatus.unassigned:
        return 'unassigned';
      case TaskStatus.newTask:
        return 'new_task';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.waiting:
        return 'waiting';
      case TaskStatus.completed:
        return 'completed';
      case TaskStatus.cancelled:
        return 'cancelled';
    }
  }

  static String _reminderToDb(TaskReminderOption value) {
    switch (value) {
      case TaskReminderOption.none:
        return 'none';
      case TaskReminderOption.minutes15:
        return 'minutes_15';
      case TaskReminderOption.minutes30:
        return 'minutes_30';
      case TaskReminderOption.hour1:
        return 'hour_1';
      case TaskReminderOption.hours3:
        return 'hours_3';
      case TaskReminderOption.day1:
        return 'day_1';
      case TaskReminderOption.days2:
        return 'days_2';
    }
  }

  static String _recurrenceToDb(TaskRecurrence value) {
    switch (value) {
      case TaskRecurrence.none:
        return 'none';
      case TaskRecurrence.daily:
        return 'daily';
      case TaskRecurrence.weekly:
        return 'weekly';
      case TaskRecurrence.monthly:
        return 'monthly';
      case TaskRecurrence.quarterly:
        return 'quarterly';
      case TaskRecurrence.semiAnnual:
        return 'semi_annual';
      case TaskRecurrence.yearly:
        return 'yearly';
    }
  }

  static String _orgUnitToDb(OrgUnit value) {
    switch (value) {
      case OrgUnit.command:
        return 'command';
      case OrgUnit.flightTrainingSection:
        return 'flight_training_section';
      case OrgUnit.standardizationAndEvaluationSection:
        return 'standardization_and_evaluation_section';
      case OrgUnit.currentOperationsSection:
        return 'current_operations_section';
      case OrgUnit.wysRatSupportSection:
        return 'wys_rat_support_section';
      case OrgUnit.trainerDeviceSupport:
        return 'trainer_device_support';
      case OrgUnit.flightTrainingSubunit:
        return 'flight_training_subunit';
    }
  }

  static String _personnelTypeToDb(PersonnelType value) {
    switch (value) {
      case PersonnelType.pilot:
        return 'pilot';
      case PersonnelType.groundStaff:
        return 'ground_staff';
    }
  }

  static String _rankGroupToDb(RankGroup value) {
    switch (value) {
      case RankGroup.officer:
        return 'officer';
      case RankGroup.nonCommissionedOfficer:
        return 'non_commissioned_officer';
      case RankGroup.enlisted:
        return 'enlisted';
    }
  }

  static OrgUnit? _parseOrgUnit(String? value) {
    switch (value) {
      case 'command':
        return OrgUnit.command;
      case 'flight_training_section':
        return OrgUnit.flightTrainingSection;
      case 'standardization_and_evaluation_section':
        return OrgUnit.standardizationAndEvaluationSection;
      case 'current_operations_section':
        return OrgUnit.currentOperationsSection;
      case 'wys_rat_support_section':
        return OrgUnit.wysRatSupportSection;
      case 'trainer_device_support':
        return OrgUnit.trainerDeviceSupport;
      case 'flight_training_subunit':
        return OrgUnit.flightTrainingSubunit;
      default:
        return null;
    }
  }

  static PersonnelType? _parsePersonnelType(String? value) {
    switch (value) {
      case 'pilot':
        return PersonnelType.pilot;
      case 'ground_staff':
        return PersonnelType.groundStaff;
      default:
        return null;
    }
  }

  static RankGroup? _parseRankGroup(String? value) {
    switch (value) {
      case 'officer':
        return RankGroup.officer;
      case 'non_commissioned_officer':
        return RankGroup.nonCommissionedOfficer;
      case 'enlisted':
        return RankGroup.enlisted;
      default:
        return null;
    }
  }
}
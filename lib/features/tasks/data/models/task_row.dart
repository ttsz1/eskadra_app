import '../../../../shared/models/org_structure.dart';
import '../../domain/enums/task_priority.dart';
import '../../domain/enums/task_recurrence.dart';
import '../../domain/enums/task_reminder_option.dart';
import '../../domain/enums/task_status.dart';
import '../../domain/models/task_item.dart';
import '../../domain/models/task_log_entry.dart';
import '../../domain/models/task_note.dart';
import '../../domain/models/task_secret_access.dart';

class TaskRow {
  final String id;
  final String title;
  final String description;
  final String createdById;
  final String? responsiblePersonId;
  final OrgUnit? sectionUnit;
  final TaskPriority priority;
  final TaskStatus status;
  final bool isSecret;
  final String? attachmentName;
  final String? attachmentPath;
  final TaskReminderOption reminderOption;
  final TaskRecurrence recurrence;
  final DateTime deadline;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final String? cancellationReason;

  final List<String> helperPersonIds;
  final List<TaskNote> notes;
  final List<TaskLogEntry> logs;
  final TaskSecretAccess? secretAccess;

  const TaskRow({
    required this.id,
    required this.title,
    required this.description,
    required this.createdById,
    required this.priority,
    required this.status,
    required this.isSecret,
    required this.reminderOption,
    required this.recurrence,
    required this.deadline,
    required this.createdAt,
    required this.helperPersonIds,
    required this.notes,
    required this.logs,
    this.responsiblePersonId,
    this.sectionUnit,
    this.attachmentName,
    this.attachmentPath,
    this.updatedAt,
    this.completedAt,
    this.cancellationReason,
    this.secretAccess,
  });

  factory TaskRow.fromMap({
    required Map<String, dynamic> task,
    required List<String> helperPersonIds,
    required List<TaskNote> notes,
    required List<TaskLogEntry> logs,
    required TaskSecretAccess? secretAccess,
  }) {
    return TaskRow(
      id: task['id'] as String,
      title: task['title'] as String? ?? '',
      description: task['description'] as String? ?? '',
      createdById: task['created_by'] as String,
      responsiblePersonId: task['responsible_person_id'] as String?,
      sectionUnit: _parseOrgUnit(task['section_unit'] as String?),
      priority: _parsePriority(task['priority'] as String?),
      status: _parseStatus(task['status'] as String?),
      isSecret: task['is_secret'] as bool? ?? false,
      attachmentName: task['attachment_name'] as String?,
      attachmentPath: task['attachment_path'] as String?,
      reminderOption: _parseReminder(task['reminder_option'] as String?),
      recurrence: _parseRecurrence(task['recurrence'] as String?),
      deadline: DateTime.parse(task['deadline'] as String),
      createdAt: DateTime.parse(task['created_at'] as String),
      updatedAt: task['updated_at'] != null
          ? DateTime.parse(task['updated_at'] as String)
          : null,
      completedAt: task['completed_at'] != null
          ? DateTime.parse(task['completed_at'] as String)
          : null,
      cancellationReason: task['cancellation_reason'] as String?,
      helperPersonIds: helperPersonIds,
      notes: notes,
      logs: logs,
      secretAccess: secretAccess,
    );
  }

  TaskItem toDomain() {
    return TaskItem(
      id: id,
      title: title,
      description: description,
      createdById: createdById,
      createdAt: createdAt,
      deadline: deadline,
      priority: priority,
      status: status,
      responsiblePersonId: responsiblePersonId,
      helperPersonIds: helperPersonIds,
      sectionUnit: sectionUnit,
      isSecret: isSecret,
      secretAccess: secretAccess,
      attachmentName: attachmentName,
      reminderOption: reminderOption,
      recurrence: recurrence,
      notes: notes,
      logs: logs,
      cancellationReason: cancellationReason,
      completedAt: completedAt,
    );
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

  static TaskPriority _parsePriority(String? value) {
    switch (value) {
      case 'low':
        return TaskPriority.low;
      case 'urgent':
        return TaskPriority.urgent;
      case 'very_urgent':
        return TaskPriority.veryUrgent;
      case 'normal':
      default:
        return TaskPriority.normal;
    }
  }

  static TaskStatus _parseStatus(String? value) {
    switch (value) {
      case 'unassigned':
        return TaskStatus.unassigned;
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'waiting':
        return TaskStatus.waiting;
      case 'completed':
        return TaskStatus.completed;
      case 'cancelled':
        return TaskStatus.cancelled;
      case 'new_task':
      default:
        return TaskStatus.newTask;
    }
  }

  static TaskReminderOption _parseReminder(String? value) {
    switch (value) {
      case 'minutes_15':
        return TaskReminderOption.minutes15;
      case 'minutes_30':
        return TaskReminderOption.minutes30;
      case 'hour_1':
        return TaskReminderOption.hour1;
      case 'hours_3':
        return TaskReminderOption.hours3;
      case 'day_1':
        return TaskReminderOption.day1;
      case 'days_2':
        return TaskReminderOption.days2;
      case 'none':
      default:
        return TaskReminderOption.none;
    }
  }

  static TaskRecurrence _parseRecurrence(String? value) {
    switch (value) {
      case 'daily':
        return TaskRecurrence.daily;
      case 'weekly':
        return TaskRecurrence.weekly;
      case 'monthly':
        return TaskRecurrence.monthly;
      case 'quarterly':
        return TaskRecurrence.quarterly;
      case 'semi_annual':
        return TaskRecurrence.semiAnnual;
      case 'yearly':
        return TaskRecurrence.yearly;
      case 'none':
      default:
        return TaskRecurrence.none;
    }
  }
}
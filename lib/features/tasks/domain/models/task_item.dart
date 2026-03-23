import '../../../../shared/models/org_structure.dart';
import '../enums/task_priority.dart';
import '../enums/task_recurrence.dart';
import '../enums/task_reminder_option.dart';
import '../enums/task_status.dart';
import 'task_log_entry.dart';
import 'task_note.dart';
import 'task_secret_access.dart';

class TaskItem {
  final String id;
  final String title;
  final String description;
  final String createdById;
  final DateTime createdAt;
  final DateTime deadline;
  final TaskPriority priority;
  final TaskStatus status;
  final String? responsiblePersonId;
  final List<String> helperPersonIds;
  final OrgUnit? sectionUnit;
  final bool isSecret;
  final TaskSecretAccess? secretAccess;
  final String? attachmentName;
  final TaskReminderOption reminderOption;
  final TaskRecurrence recurrence;
  final List<TaskNote> notes;
  final List<TaskLogEntry> logs;
  final String? cancellationReason;
  final DateTime? completedAt;

  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.createdById,
    required this.createdAt,
    required this.deadline,
    required this.priority,
    required this.status,
    this.responsiblePersonId,
    this.helperPersonIds = const [],
    this.sectionUnit,
    this.isSecret = false,
    this.secretAccess,
    this.attachmentName,
    this.reminderOption = TaskReminderOption.none,
    this.recurrence = TaskRecurrence.none,
    this.notes = const [],
    this.logs = const [],
    this.cancellationReason,
    this.completedAt,
  });

  bool get isUnassigned => responsiblePersonId == null;

  bool get isOverdue =>
      status != TaskStatus.completed &&
          status != TaskStatus.cancelled &&
          deadline.isBefore(DateTime.now());

  bool get isArchived {
    if (status != TaskStatus.completed || completedAt == null) {
      return false;
    }

    return DateTime.now().difference(completedAt!).inDays >= 7;
  }

  TaskItem copyWith({
    String? id,
    String? title,
    String? description,
    String? createdById,
    DateTime? createdAt,
    DateTime? deadline,
    TaskPriority? priority,
    TaskStatus? status,
    String? responsiblePersonId,
    bool clearResponsiblePerson = false,
    List<String>? helperPersonIds,
    OrgUnit? sectionUnit,
    bool clearSectionUnit = false,
    bool? isSecret,
    TaskSecretAccess? secretAccess,
    bool clearSecretAccess = false,
    String? attachmentName,
    bool clearAttachmentName = false,
    TaskReminderOption? reminderOption,
    TaskRecurrence? recurrence,
    List<TaskNote>? notes,
    List<TaskLogEntry>? logs,
    String? cancellationReason,
    bool clearCancellationReason = false,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      responsiblePersonId: clearResponsiblePerson
          ? null
          : (responsiblePersonId ?? this.responsiblePersonId),
      helperPersonIds: helperPersonIds ?? this.helperPersonIds,
      sectionUnit: clearSectionUnit ? null : (sectionUnit ?? this.sectionUnit),
      isSecret: isSecret ?? this.isSecret,
      secretAccess:
      clearSecretAccess ? null : (secretAccess ?? this.secretAccess),
      attachmentName:
      clearAttachmentName ? null : (attachmentName ?? this.attachmentName),
      reminderOption: reminderOption ?? this.reminderOption,
      recurrence: recurrence ?? this.recurrence,
      notes: notes ?? this.notes,
      logs: logs ?? this.logs,
      cancellationReason: clearCancellationReason
          ? null
          : (cancellationReason ?? this.cancellationReason),
      completedAt:
      clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }
}
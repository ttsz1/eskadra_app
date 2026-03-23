import '../../../../shared/models/org_structure.dart';
import '../../domain/enums/task_priority.dart';
import '../../domain/enums/task_recurrence.dart';
import '../../domain/enums/task_reminder_option.dart';
import '../../domain/enums/task_status.dart';
import '../../domain/models/task_item.dart';
import '../../domain/models/task_log_entry.dart';
import '../../domain/models/task_note.dart';
import '../../domain/models/task_secret_access.dart';

class MockTaskSeed {
  const MockTaskSeed._();

  static List<TaskItem> items() {
    final now = DateTime.now();

    return [
      TaskItem(
        id: 't1',
        title: 'Aktualizacja harmonogramu szkolenia lotniczego',
        description:
        'Sprawdzić zgodność planu z dostępnością pilotów i zaktualizować zakres tygodnia.',
        createdById: 'p1',
        createdAt: now.subtract(const Duration(hours: 4)),
        deadline: now.add(const Duration(hours: 5)),
        priority: TaskPriority.urgent,
        status: TaskStatus.inProgress,
        responsiblePersonId: 'p5',
        helperPersonIds: const ['p6'],
        sectionUnit: OrgUnit.flightTrainingSection,
        reminderOption: TaskReminderOption.hour1,
        recurrence: TaskRecurrence.weekly,
        notes: [
          TaskNote(
            id: 'n1',
            authorId: 'p5',
            createdAt: now.subtract(const Duration(hours: 2)),
            content: 'Wstępny plan gotowy. Czekam na potwierdzenie dostępności.',
            mentionedPersonIds: const ['p6'],
          ),
        ],
        logs: [
          TaskLogEntry(
            id: 'l1',
            createdAt: now.subtract(const Duration(hours: 4)),
            actorId: 'p1',
            message: 'Jan Kowalski utworzył zadanie.',
          ),
          TaskLogEntry(
            id: 'l2',
            createdAt: now.subtract(const Duration(hours: 3)),
            actorId: 'p1',
            message: 'Przypisano odpowiedzialną: Ewa Dąbrowska.',
          ),
        ],
      ),
      TaskItem(
        id: 't2',
        title: 'Weryfikacja obsady zmiany nocnej',
        description:
        'Sprawdzić brakujące sloty i przygotować zastępstwa na jutrzejszą noc.',
        createdById: 'p3',
        createdAt: now.subtract(const Duration(hours: 2, minutes: 30)),
        deadline: now.add(const Duration(hours: 2)),
        priority: TaskPriority.veryUrgent,
        status: TaskStatus.unassigned,
        reminderOption: TaskReminderOption.minutes30,
        recurrence: TaskRecurrence.none,
        logs: [
          TaskLogEntry(
            id: 'l3',
            createdAt: now.subtract(const Duration(hours: 2, minutes: 30)),
            actorId: 'p3',
            message: 'Anna Wiśniewska utworzyła zadanie.',
          ),
        ],
      ),
      TaskItem(
        id: 't3',
        title: 'Przegląd procedur stanowiska treningowego',
        description:
        'Przygotować checklistę przeglądu oraz listę braków technicznych.',
        createdById: 'p8',
        createdAt: now.subtract(const Duration(days: 1, hours: 1)),
        deadline: now.add(const Duration(days: 1, hours: 3)),
        priority: TaskPriority.normal,
        status: TaskStatus.newTask,
        responsiblePersonId: 'p8',
        helperPersonIds: const ['p9'],
        sectionUnit: OrgUnit.trainerDeviceSupport,
        reminderOption: TaskReminderOption.day1,
        recurrence: TaskRecurrence.monthly,
        attachmentName: 'lista-kontrolna.pdf',
        logs: [
          TaskLogEntry(
            id: 'l4',
            createdAt: now.subtract(const Duration(days: 1, hours: 1)),
            actorId: 'p8',
            message: 'Tomasz Woźniak utworzył zadanie.',
          ),
        ],
      ),
      TaskItem(
        id: 't4',
        title: 'Raport zabezpieczenia WYS-RAT',
        description:
        'Zebrać dane tygodniowe i przekazać podsumowanie do dowództwa.',
        createdById: 'p9',
        createdAt: now.subtract(const Duration(hours: 8)),
        deadline: now.add(const Duration(days: 2)),
        priority: TaskPriority.low,
        status: TaskStatus.waiting,
        responsiblePersonId: 'p9',
        helperPersonIds: const [],
        sectionUnit: OrgUnit.wysRatSupportSection,
        isSecret: true,
        secretAccess: const TaskSecretAccess(
          allowedUnits: {OrgUnit.command, OrgUnit.wysRatSupportSection},
          allowedRankGroups: {RankGroup.officer},
        ),
        reminderOption: TaskReminderOption.hours3,
        recurrence: TaskRecurrence.none,
        logs: [
          TaskLogEntry(
            id: 'l5',
            createdAt: now.subtract(const Duration(hours: 8)),
            actorId: 'p9',
            message: 'Paweł Krawiec utworzył zadanie tajne.',
          ),
        ],
      ),
      TaskItem(
        id: 't5',
        title: 'Archiwalne zadanie testowe',
        description:
        'To zadanie powinno już być widoczne tylko w archiwum.',
        createdById: 'p1',
        createdAt: now.subtract(const Duration(days: 12)),
        deadline: now.subtract(const Duration(days: 10)),
        priority: TaskPriority.low,
        status: TaskStatus.completed,
        responsiblePersonId: 'p2',
        helperPersonIds: const ['p3', 'p4'],
        sectionUnit: OrgUnit.command,
        completedAt: now.subtract(const Duration(days: 8)),
        logs: [
          TaskLogEntry(
            id: 'l6',
            createdAt: now.subtract(const Duration(days: 12)),
            actorId: 'p1',
            message: 'Jan Kowalski utworzył zadanie.',
          ),
          TaskLogEntry(
            id: 'l7',
            createdAt: now.subtract(const Duration(days: 8)),
            actorId: 'p2',
            message: 'Piotr Nowak oznaczył zadanie jako zakończone.',
          ),
        ],
      ),
    ];
  }
}
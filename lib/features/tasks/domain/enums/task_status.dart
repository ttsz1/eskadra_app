enum TaskStatus {
  unassigned,
  newTask,
  inProgress,
  waiting,
  completed,
  cancelled,
}

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.unassigned:
        return 'Nieprzypisane';
      case TaskStatus.newTask:
        return 'Nowe';
      case TaskStatus.inProgress:
        return 'W realizacji';
      case TaskStatus.waiting:
        return 'Oczekujące';
      case TaskStatus.completed:
        return 'Zakończone';
      case TaskStatus.cancelled:
        return 'Anulowane';
    }
  }
}
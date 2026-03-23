enum TaskPriority {
  low,
  normal,
  urgent,
  veryUrgent,
}

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Niski';
      case TaskPriority.normal:
        return 'Normalny';
      case TaskPriority.urgent:
        return 'Pilny';
      case TaskPriority.veryUrgent:
        return 'Bardzo pilny';
    }
  }
}
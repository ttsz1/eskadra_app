enum TaskRecurrence {
  none,
  daily,
  weekly,
  monthly,
  quarterly,
  semiAnnual,
  yearly,
}

extension TaskRecurrenceX on TaskRecurrence {
  String get label {
    switch (this) {
      case TaskRecurrence.none:
        return 'Brak';
      case TaskRecurrence.daily:
        return 'Codziennie';
      case TaskRecurrence.weekly:
        return 'Co tydzień';
      case TaskRecurrence.monthly:
        return 'Co miesiąc';
      case TaskRecurrence.quarterly:
        return 'Co kwartał';
      case TaskRecurrence.semiAnnual:
        return 'Co pół roku';
      case TaskRecurrence.yearly:
        return 'Co rok';
    }
  }
}
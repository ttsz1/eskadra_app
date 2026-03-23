enum TaskReminderOption {
  none,
  minutes15,
  minutes30,
  hour1,
  hours3,
  day1,
  days2,
}

extension TaskReminderOptionX on TaskReminderOption {
  String get label {
    switch (this) {
      case TaskReminderOption.none:
        return 'Brak';
      case TaskReminderOption.minutes15:
        return '15 minut przed';
      case TaskReminderOption.minutes30:
        return '30 minut przed';
      case TaskReminderOption.hour1:
        return '1 godzina przed';
      case TaskReminderOption.hours3:
        return '3 godziny przed';
      case TaskReminderOption.day1:
        return '1 dzień przed';
      case TaskReminderOption.days2:
        return '2 dni przed';
    }
  }
}
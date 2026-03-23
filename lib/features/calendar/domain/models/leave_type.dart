enum LeaveType {
  annual,
  reward,
  additional,
}

extension LeaveTypeX on LeaveType {
  String get code {
    switch (this) {
      case LeaveType.annual:
        return 'annual';
      case LeaveType.reward:
        return 'reward';
      case LeaveType.additional:
        return 'additional';
    }
  }

  String get label {
    switch (this) {
      case LeaveType.annual:
        return 'Urlop wypoczynkowy';
      case LeaveType.reward:
        return 'Urlop nagrodowy';
      case LeaveType.additional:
        return 'Urlop dodatkowy';
    }
  }

  static LeaveType fromCode(String value) {
    switch (value) {
      case 'annual':
        return LeaveType.annual;
      case 'reward':
        return LeaveType.reward;
      case 'additional':
        return LeaveType.additional;
      default:
        return LeaveType.annual;
    }
  }
}
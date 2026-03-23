enum LeaveRequestType {
  vacation(
    label: 'Wypoczynkowy',
    dbValue: 'vacation',
  ),
  additional(
    label: 'Dodatkowy',
    dbValue: 'additional',
  ),
  reward(
    label: 'Nagrodowy',
    dbValue: 'reward',
  );

  const LeaveRequestType({
    required this.label,
    required this.dbValue,
  });

  final String label;
  final String dbValue;

  static LeaveRequestType fromDbValue(String value) {
    for (final item in LeaveRequestType.values) {
      if (item.dbValue == value) return item;
    }
    return LeaveRequestType.vacation;
  }
}

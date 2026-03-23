class PublicHoliday {
  const PublicHoliday({
    required this.date,
    required this.name,
  });

  final DateTime date;
  final String name;

  factory PublicHoliday.fromMap(Map<String, dynamic> map) {
    return PublicHoliday(
      date: DateTime.parse(map['holiday_date'] as String),
      name: map['name'] as String,
    );
  }
}

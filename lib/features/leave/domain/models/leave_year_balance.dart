class LeaveYearBalance {
  const LeaveYearBalance({
    required this.id,
    required this.userId,
    required this.year,
    required this.vacationDays,
    required this.additionalDays,
    required this.source,
    required this.createdAt,
    required this.updatedAt,
    this.rewardDays = 0,
  });

  final String id;
  final String userId;
  final int year;
  final int vacationDays;
  final int additionalDays;
  final int rewardDays;
  final String source;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory LeaveYearBalance.fromMap(Map<String, dynamic> map) {
    return LeaveYearBalance(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      year: (map['year'] as num).toInt(),
      vacationDays: ((map['vacation_days'] ?? 0) as num).toInt(),
      additionalDays: ((map['additional_days'] ?? 0) as num).toInt(),
      rewardDays: ((map['reward_days'] ?? 0) as num).toInt(),
      source: map['source']?.toString() ?? 'manual',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  String formatCompact() {
    final w = vacationDays.toString().padLeft(2, '0');
    final d = additionalDays.toString().padLeft(2, '0');
    final n = rewardDays.toString().padLeft(2, '0');
    return '$w(w)+$d(d)+$n(N)';
  }
}

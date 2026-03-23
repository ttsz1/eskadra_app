import 'leave_year_balance.dart';

class TeamLeaveBalanceOverviewRow {
  const TeamLeaveBalanceOverviewRow({
    required this.userId,
    required this.fullName,
    required this.sectionName,
    required this.earlier,
    required this.minus3,
    required this.minus2,
    required this.minus1,
    required this.current,
  });

  final String userId;
  final String fullName;
  final String sectionName;
  final LeaveYearBalance earlier;
  final LeaveYearBalance minus3;
  final LeaveYearBalance minus2;
  final LeaveYearBalance minus1;
  final LeaveYearBalance current;
}

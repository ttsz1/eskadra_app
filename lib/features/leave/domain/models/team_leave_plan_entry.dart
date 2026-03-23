import 'leave_request.dart';

class TeamLeavePlanEntry {
  const TeamLeavePlanEntry({
    required this.userId,
    required this.fullName,
    required this.sectionName,
    required this.request,
  });

  final String userId;
  final String fullName;
  final String sectionName;
  final LeaveRequest request;
}
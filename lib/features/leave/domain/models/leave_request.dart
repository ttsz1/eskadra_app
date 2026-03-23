import '../enums/leave_request_type.dart';

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.userId,
    required this.createdBy,
    required this.leaveType,
    required this.leaveTypeEnum,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.workingDays,
    required this.title,
    required this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String createdBy;
  final String leaveType;
  final LeaveRequestType leaveTypeEnum;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final int workingDays;
  final String? title;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory LeaveRequest.fromMap(Map<String, dynamic> map) {
    final leaveType = map['leave_type']?.toString() ?? 'vacation';

    final startRaw =
        map['start_date']?.toString() ?? map['starts_on']?.toString() ?? '';
    final endRaw =
        map['end_date']?.toString() ?? map['ends_on']?.toString() ?? '';

    final startDate =
        DateTime.tryParse(startRaw) ?? DateTime.now();
    final endDate =
        DateTime.tryParse(endRaw) ?? startDate;

    final workingDaysRaw = map['working_days'];
    final computedWorkingDays =
        endDate.difference(startDate).inDays + 1;

    return LeaveRequest(
      id: map['id'].toString(),
      userId: map['user_id'].toString(),
      createdBy: map['created_by']?.toString() ?? '',
      leaveType: leaveType,
      leaveTypeEnum: LeaveRequestType.fromDbValue(leaveType),
      status: map['status']?.toString() ?? '',
      startDate: DateTime(startDate.year, startDate.month, startDate.day),
      endDate: DateTime(endDate.year, endDate.month, endDate.day),
      workingDays: workingDaysRaw is num
          ? workingDaysRaw.toInt()
          : computedWorkingDays,
      title: map['title']?.toString(),
      notes: map['notes']?.toString(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
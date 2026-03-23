enum LeaveStatus {
  requested,
  planned,
  approved,
  rejected,
  cancelled,
}

extension LeaveStatusX on LeaveStatus {
  String get code {
    switch (this) {
      case LeaveStatus.requested:
        return 'requested';
      case LeaveStatus.planned:
        return 'planned';
      case LeaveStatus.approved:
        return 'approved';
      case LeaveStatus.rejected:
        return 'rejected';
      case LeaveStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case LeaveStatus.requested:
        return 'Zarequestowany';
      case LeaveStatus.planned:
        return 'Planowany';
      case LeaveStatus.approved:
        return 'Zatwierdzony';
      case LeaveStatus.rejected:
        return 'Odrzucony';
      case LeaveStatus.cancelled:
        return 'Anulowany';
    }
  }

  static LeaveStatus fromCode(String value) {
    switch (value) {
      case 'requested':
        return LeaveStatus.requested;
      case 'planned':
        return LeaveStatus.planned;
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      case 'cancelled':
        return LeaveStatus.cancelled;
      default:
        return LeaveStatus.requested;
    }
  }
}
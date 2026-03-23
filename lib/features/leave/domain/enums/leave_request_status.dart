enum LeaveRequestStatus {
  planned,
  used,
  cancelled;

  String get dbValue => switch (this) {
    LeaveRequestStatus.planned => 'planned',
    LeaveRequestStatus.used => 'used',
    LeaveRequestStatus.cancelled => 'cancelled',
  };

  String get label => switch (this) {
    LeaveRequestStatus.planned => 'Planowany',
    LeaveRequestStatus.used => 'Wykorzystany',
    LeaveRequestStatus.cancelled => 'Anulowany',
  };

  static LeaveRequestStatus fromDb(String value) {
    switch (value) {
      case 'planned':
        return LeaveRequestStatus.planned;
      case 'used':
        return LeaveRequestStatus.used;
      case 'cancelled':
        return LeaveRequestStatus.cancelled;
      default:
        throw ArgumentError('Nieznany status: $value');
    }
  }
}
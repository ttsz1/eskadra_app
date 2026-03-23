enum AttendanceType {
  sztab,
  loty,
  podrozSluzbowa,
  inne,
  l4,
  sluzba,
  poSluzbie,
  urlopWypoczynkowy,
  urlopNagrodowy,
  urlopDodatkowy,
}

extension AttendanceTypeX on AttendanceType {
  String get dbValue {
    switch (this) {
      case AttendanceType.sztab:
        return 'sztab';
      case AttendanceType.loty:
        return 'loty';
      case AttendanceType.podrozSluzbowa:
        return 'podroz_sluzbowa';
      case AttendanceType.inne:
        return 'inne';
      case AttendanceType.l4:
        return 'l4';
      case AttendanceType.sluzba:
        return 'sluzba';
      case AttendanceType.poSluzbie:
        return 'po_sluzbie';
      case AttendanceType.urlopWypoczynkowy:
        return 'urlop_wypoczynkowy';
      case AttendanceType.urlopNagrodowy:
        return 'urlop_nagrodowy';
      case AttendanceType.urlopDodatkowy:
        return 'urlop_dodatkowy';
    }
  }

  String get label {
    switch (this) {
      case AttendanceType.sztab:
        return 'Sztab';
      case AttendanceType.loty:
        return 'Loty';
      case AttendanceType.podrozSluzbowa:
        return 'Podróż służbowa';
      case AttendanceType.inne:
        return 'Inne';
      case AttendanceType.l4:
        return 'L4';
      case AttendanceType.sluzba:
        return 'Służba';
      case AttendanceType.poSluzbie:
        return 'Po służbie';
      case AttendanceType.urlopWypoczynkowy:
        return 'Urlop wypoczynkowy';
      case AttendanceType.urlopNagrodowy:
        return 'Urlop nagrodowy';
      case AttendanceType.urlopDodatkowy:
        return 'Urlop dodatkowy';
    }
  }

  bool get countsAsAbsence {
    switch (this) {
      case AttendanceType.sztab:
      case AttendanceType.loty:
      case AttendanceType.inne:
      case AttendanceType.sluzba:
        return false;
      case AttendanceType.podrozSluzbowa:
      case AttendanceType.l4:
      case AttendanceType.poSluzbie:
      case AttendanceType.urlopWypoczynkowy:
      case AttendanceType.urlopNagrodowy:
      case AttendanceType.urlopDodatkowy:
        return true;
    }
  }

  static AttendanceType fromDb(String value) {
    switch (value) {
      case 'sztab':
        return AttendanceType.sztab;
      case 'loty':
        return AttendanceType.loty;
      case 'podroz_sluzbowa':
        return AttendanceType.podrozSluzbowa;
      case 'inne':
        return AttendanceType.inne;
      case 'l4':
        return AttendanceType.l4;
      case 'sluzba':
        return AttendanceType.sluzba;
      case 'po_sluzbie':
        return AttendanceType.poSluzbie;
      case 'urlop_wypoczynkowy':
        return AttendanceType.urlopWypoczynkowy;
      case 'urlop_nagrodowy':
        return AttendanceType.urlopNagrodowy;
      case 'urlop_dodatkowy':
        return AttendanceType.urlopDodatkowy;
      default:
        return AttendanceType.inne;
    }
  }
}

class AttendancePlan {
  const AttendancePlan({
    required this.id,
    required this.createdBy,
    required this.attendanceType,
    required this.dateFrom,
    required this.dateTo,
    required this.isAllDay,
    this.timeFrom,
    this.timeTo,
    required this.repeatMode,
    required this.applyMonday,
    required this.applyTuesday,
    required this.applyWednesday,
    required this.applyThursday,
    required this.applyFriday,
    required this.applySaturday,
    required this.applySunday,
    required this.note,
    required this.personIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String createdBy;
  final AttendanceType attendanceType;
  final DateTime dateFrom;
  final DateTime dateTo;
  final bool isAllDay;
  final String? timeFrom;
  final String? timeTo;
  final bool repeatMode;
  final bool applyMonday;
  final bool applyTuesday;
  final bool applyWednesday;
  final bool applyThursday;
  final bool applyFriday;
  final bool applySaturday;
  final bool applySunday;
  final String note;
  final List<String> personIds;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class AttendancePersonOption {
  const AttendancePersonOption({
    required this.id,
    required this.fullName,
  });

  final String id;
  final String fullName;
}
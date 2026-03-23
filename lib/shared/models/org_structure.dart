enum OrgUnit {
  command,
  flightTrainingSection,
  standardizationAndEvaluationSection,
  currentOperationsSection,
  wysRatSupportSection,
  trainerDeviceSupport,
  flightTrainingSubunit,
}

enum OrgFunction {
  commander,
  chief,
  manager,
  personnel,
}

enum PersonnelType {
  pilot,
  groundStaff,
}

enum RankGroup {
  officer,
  nonCommissionedOfficer,
  enlisted,
}

extension OrgUnitX on OrgUnit {
  String get label {
    switch (this) {
      case OrgUnit.command:
        return 'Dowództwo';
      case OrgUnit.flightTrainingSection:
        return 'Sekcja szkolenia lotniczego';
      case OrgUnit.standardizationAndEvaluationSection:
        return 'Sekcja standaryzacji i oceny';
      case OrgUnit.currentOperationsSection:
        return 'Sekcja działań bieżących';
      case OrgUnit.wysRatSupportSection:
        return 'Sekcja zabezpieczenia WYS-RAT';
      case OrgUnit.trainerDeviceSupport:
        return 'Obsługa urządzenia treningowego';
      case OrgUnit.flightTrainingSubunit:
        return 'Pododdział szkolenia lotniczego';
    }
  }
}

extension OrgFunctionX on OrgFunction {
  String get label {
    switch (this) {
      case OrgFunction.commander:
        return 'Dowódca';
      case OrgFunction.chief:
        return 'Szef';
      case OrgFunction.manager:
        return 'Kierownik';
      case OrgFunction.personnel:
        return 'Personel';
    }
  }
}

extension PersonnelTypeX on PersonnelType {
  String get label {
    switch (this) {
      case PersonnelType.pilot:
        return 'Pilot';
      case PersonnelType.groundStaff:
        return 'Personel naziemny';
    }
  }
}

extension RankGroupX on RankGroup {
  String get label {
    switch (this) {
      case RankGroup.officer:
        return 'Oficer';
      case RankGroup.nonCommissionedOfficer:
        return 'Podoficer';
      case RankGroup.enlisted:
        return 'Szeregowy';
    }
  }
}

class AppPerson {
  final String id;
  final String fullName;
  final String email;
  final OrgUnit unit;
  final OrgFunction function;
  final PersonnelType personnelType;
  final RankGroup rankGroup;

  const AppPerson({
    required this.id,
    required this.fullName,
    required this.email,
    required this.unit,
    required this.function,
    required this.personnelType,
    required this.rankGroup,
  });
}

/// Legacy fallback directory.
/// Docelowo aplikacja powinna korzystać z danych z Supabase (`profiles`),
/// ale zostawiamy to jako zgodność wsteczną i awaryjny fallback.
class OrgDirectory {
  const OrgDirectory._();

  static const List<AppPerson> people = [
    AppPerson(
      id: 'p1',
      fullName: 'Jan Kowalski',
      email: 'jan.kowalski@eskadra.local',
      unit: OrgUnit.command,
      function: OrgFunction.commander,
      personnelType: PersonnelType.pilot,
      rankGroup: RankGroup.officer,
    ),
    AppPerson(
      id: 'p2',
      fullName: 'Piotr Nowak',
      email: 'piotr.nowak@eskadra.local',
      unit: OrgUnit.command,
      function: OrgFunction.personnel,
      personnelType: PersonnelType.groundStaff,
      rankGroup: RankGroup.officer,
    ),
    AppPerson(
      id: 'p3',
      fullName: 'Anna Wiśniewska',
      email: 'anna.wisniewska@eskadra.local',
      unit: OrgUnit.currentOperationsSection,
      function: OrgFunction.chief,
      personnelType: PersonnelType.pilot,
      rankGroup: RankGroup.officer,
    ),
    AppPerson(
      id: 'p4',
      fullName: 'Marek Zieliński',
      email: 'marek.zielinski@eskadra.local',
      unit: OrgUnit.currentOperationsSection,
      function: OrgFunction.personnel,
      personnelType: PersonnelType.groundStaff,
      rankGroup: RankGroup.nonCommissionedOfficer,
    ),
    AppPerson(
      id: 'p5',
      fullName: 'Ewa Dąbrowska',
      email: 'ewa.dabrowska@eskadra.local',
      unit: OrgUnit.flightTrainingSection,
      function: OrgFunction.chief,
      personnelType: PersonnelType.pilot,
      rankGroup: RankGroup.officer,
    ),
    AppPerson(
      id: 'p6',
      fullName: 'Kamil Lewandowski',
      email: 'kamil.lewandowski@eskadra.local',
      unit: OrgUnit.flightTrainingSection,
      function: OrgFunction.personnel,
      personnelType: PersonnelType.pilot,
      rankGroup: RankGroup.enlisted,
    ),
    AppPerson(
      id: 'p7',
      fullName: 'Karolina Mazur',
      email: 'karolina.mazur@eskadra.local',
      unit: OrgUnit.standardizationAndEvaluationSection,
      function: OrgFunction.chief,
      personnelType: PersonnelType.pilot,
      rankGroup: RankGroup.officer,
    ),
    AppPerson(
      id: 'p8',
      fullName: 'Tomasz Woźniak',
      email: 'tomasz.wozniak@eskadra.local',
      unit: OrgUnit.trainerDeviceSupport,
      function: OrgFunction.manager,
      personnelType: PersonnelType.groundStaff,
      rankGroup: RankGroup.officer,
    ),
    AppPerson(
      id: 'p9',
      fullName: 'Paweł Krawiec',
      email: 'pawel.krawiec@eskadra.local',
      unit: OrgUnit.wysRatSupportSection,
      function: OrgFunction.personnel,
      personnelType: PersonnelType.groundStaff,
      rankGroup: RankGroup.nonCommissionedOfficer,
    ),
  ];

  static AppPerson get fallbackCurrentUser => people.first;

  static AppPerson currentUserFromEmail(String? email) {
    if (email == null) {
      return fallbackCurrentUser;
    }

    return people.firstWhere(
          (person) => person.email.toLowerCase() == email.toLowerCase(),
      orElse: () => fallbackCurrentUser,
    );
  }

  static AppPerson byId(String id) {
    return people.firstWhere((person) => person.id == id);
  }

  static List<AppPerson> peopleInUnit(OrgUnit unit) {
    return people.where((person) => person.unit == unit).toList();
  }
}
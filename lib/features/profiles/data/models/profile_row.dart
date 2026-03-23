import '../../../../shared/models/org_structure.dart';

class ProfileRow {
  final String id;
  final String email;
  final String fullName;
  final OrgUnit unit;
  final OrgFunction function;
  final PersonnelType personnelType;
  final RankGroup rankGroup;
  final bool isActive;

  const ProfileRow({
    required this.id,
    required this.email,
    required this.fullName,
    required this.unit,
    required this.function,
    required this.personnelType,
    required this.rankGroup,
    required this.isActive,
  });

  factory ProfileRow.fromMap(Map<String, dynamic> map) {
    return ProfileRow(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      unit: _parseOrgUnit(map['org_unit'] as String?),
      function: _parseOrgFunction(map['org_function'] as String?),
      personnelType: _parsePersonnelType(map['personnel_type'] as String?),
      rankGroup: _parseRankGroup(map['rank_group'] as String?),
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  AppPerson toDomain() {
    return AppPerson(
      id: id,
      fullName: fullName,
      email: email,
      unit: unit,
      function: function,
      personnelType: personnelType,
      rankGroup: rankGroup,
    );
  }

  static OrgUnit _parseOrgUnit(String? value) {
    switch (value) {
      case 'flight_training_section':
        return OrgUnit.flightTrainingSection;
      case 'standardization_and_evaluation_section':
        return OrgUnit.standardizationAndEvaluationSection;
      case 'current_operations_section':
        return OrgUnit.currentOperationsSection;
      case 'wys_rat_support_section':
        return OrgUnit.wysRatSupportSection;
      case 'trainer_device_support':
        return OrgUnit.trainerDeviceSupport;
      case 'flight_training_subunit':
        return OrgUnit.flightTrainingSubunit;
      case 'command':
      default:
        return OrgUnit.command;
    }
  }

  static OrgFunction _parseOrgFunction(String? value) {
    switch (value) {
      case 'chief':
        return OrgFunction.chief;
      case 'manager':
        return OrgFunction.manager;
      case 'personnel':
        return OrgFunction.personnel;
      case 'commander':
      default:
        return OrgFunction.commander;
    }
  }

  static PersonnelType _parsePersonnelType(String? value) {
    switch (value) {
      case 'pilot':
        return PersonnelType.pilot;
      case 'ground_staff':
      default:
        return PersonnelType.groundStaff;
    }
  }

  static RankGroup _parseRankGroup(String? value) {
    switch (value) {
      case 'officer':
        return RankGroup.officer;
      case 'non_commissioned_officer':
        return RankGroup.nonCommissionedOfficer;
      case 'enlisted':
      default:
        return RankGroup.enlisted;
    }
  }
}
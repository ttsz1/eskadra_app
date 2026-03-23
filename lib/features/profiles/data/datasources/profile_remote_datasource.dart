import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../shared/models/org_structure.dart';
import '../models/profile_row.dart';

class ProfileRemoteDatasource {
  final SupabaseClient client;

  ProfileRemoteDatasource(this.client);

  Future<List<ProfileRow>> fetchProfiles() async {
    final response = await client
        .from('profiles')
        .select(
      'id, email, full_name, org_unit, org_function, personnel_type, rank_group, is_active',
    )
        .eq('is_active', true)
        .order('full_name');

    return List<Map<String, dynamic>>.from(response)
        .map(ProfileRow.fromMap)
        .toList();
  }

  Future<void> updateProfile({
    required String id,
    required String fullName,
    required String email,
    required OrgUnit unit,
    required OrgFunction function,
    required PersonnelType personnelType,
    required RankGroup rankGroup,
    required bool isActive,
  }) async {
    await client.from('profiles').update({
      'full_name': fullName.trim(),
      'email': email.trim(),
      'org_unit': _orgUnitToDb(unit),
      'org_function': _orgFunctionToDb(function),
      'personnel_type': _personnelTypeToDb(personnelType),
      'rank_group': _rankGroupToDb(rankGroup),
      'is_active': isActive,
    }).eq('id', id);
  }

  static String _orgUnitToDb(OrgUnit value) {
    switch (value) {
      case OrgUnit.command:
        return 'command';
      case OrgUnit.flightTrainingSection:
        return 'flight_training_section';
      case OrgUnit.standardizationAndEvaluationSection:
        return 'standardization_and_evaluation_section';
      case OrgUnit.currentOperationsSection:
        return 'current_operations_section';
      case OrgUnit.wysRatSupportSection:
        return 'wys_rat_support_section';
      case OrgUnit.trainerDeviceSupport:
        return 'trainer_device_support';
      case OrgUnit.flightTrainingSubunit:
        return 'flight_training_subunit';
    }
  }

  static String _orgFunctionToDb(OrgFunction value) {
    switch (value) {
      case OrgFunction.commander:
        return 'commander';
      case OrgFunction.chief:
        return 'chief';
      case OrgFunction.manager:
        return 'manager';
      case OrgFunction.personnel:
        return 'personnel';
    }
  }

  static String _personnelTypeToDb(PersonnelType value) {
    switch (value) {
      case PersonnelType.pilot:
        return 'pilot';
      case PersonnelType.groundStaff:
        return 'ground_staff';
    }
  }

  static String _rankGroupToDb(RankGroup value) {
    switch (value) {
      case RankGroup.officer:
        return 'officer';
      case RankGroup.nonCommissionedOfficer:
        return 'non_commissioned_officer';
      case RankGroup.enlisted:
        return 'enlisted';
    }
  }
}
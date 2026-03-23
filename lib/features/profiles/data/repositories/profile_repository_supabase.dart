import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/org_structure.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositorySupabase {
  final ProfileRemoteDatasource remote;

  ProfileRepositorySupabase(this.remote);

  factory ProfileRepositorySupabase.fromClient(SupabaseClient client) {
    return ProfileRepositorySupabase(ProfileRemoteDatasource(client));
  }

  Future<List<AppPerson>> fetchProfiles() async {
    final rows = await remote.fetchProfiles();
    return rows.map((e) => e.toDomain()).toList();
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
  }) {
    return remote.updateProfile(
      id: id,
      fullName: fullName,
      email: email,
      unit: unit,
      function: function,
      personnelType: personnelType,
      rankGroup: rankGroup,
      isActive: isActive,
    );
  }
}
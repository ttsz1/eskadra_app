import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/admin_app_user.dart';

class AdminUserManagementRepository {
  AdminUserManagementRepository(this._supabase);

  final SupabaseClient _supabase;

  User get _currentUser {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Brak zalogowanego użytkownika.');
    }
    return user;
  }

  Future<bool> isCurrentUserAdmin() async {
    final me = _currentUser;

    final row = await _supabase
        .from('app_admins')
        .select('user_id')
        .eq('user_id', me.id)
        .maybeSingle();

    return row != null;
  }

  Future<List<AdminAppUser>> getUsers() async {
    final data = await _supabase
        .from('profiles')
        .select(
      'id, email, full_name, org_unit, org_function, personnel_type, rank_group, is_active',
    )
        .order('full_name');

    return (data as List)
        .map((e) => AdminAppUser.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    String? orgUnit,
    String? orgFunction,
    String? personnelType,
    String? rankGroup,
    required bool isActive,
  }) async {
    final response = await _supabase.functions.invoke(
      'admin-users-create',
      body: {
        'email': email.trim(),
        'password': password,
        'full_name': fullName.trim(),
        'org_unit': orgUnit?.trim().isEmpty == true ? null : orgUnit?.trim(),
        'org_function':
        orgFunction?.trim().isEmpty == true ? null : orgFunction?.trim(),
        'personnel_type':
        personnelType?.trim().isEmpty == true ? null : personnelType?.trim(),
        'rank_group':
        rankGroup?.trim().isEmpty == true ? null : rankGroup?.trim(),
        'is_active': isActive,
      },
    );

    if (response.status < 200 || response.status >= 300) {
      throw Exception(response.data?['error'] ?? 'Nie udało się utworzyć użytkownika.');
    }
  }

  Future<void> deleteUser(String userId) async {
    final response = await _supabase.functions.invoke(
      'admin-users-delete',
      body: {'user_id': userId},
    );

    if (response.status < 200 || response.status >= 300) {
      throw Exception(response.data?['error'] ?? 'Nie udało się usunąć użytkownika.');
    }
  }
}
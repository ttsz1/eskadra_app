import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/admin_user_management_repository.dart';
import '../../domain/models/admin_app_user.dart';

final adminUserManagementRepositoryProvider =
Provider<AdminUserManagementRepository>((ref) {
  return AdminUserManagementRepository(Supabase.instance.client);
});

final isCurrentUserAdminProvider = FutureProvider<bool>((ref) async {
  return ref.watch(adminUserManagementRepositoryProvider).isCurrentUserAdmin();
});

final adminUsersProvider = FutureProvider<List<AdminAppUser>>((ref) async {
  return ref.watch(adminUserManagementRepositoryProvider).getUsers();
});
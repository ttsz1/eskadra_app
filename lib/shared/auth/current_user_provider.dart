import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/security/app_role.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../supabase/supabase_client_provider.dart';

final authSessionProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

final currentUserProvider = FutureProvider<AppUser?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final authUser = client.auth.currentUser;

  if (authUser == null) {
    return null;
  }

  final response = await client
      .from('profiles')
      .select('id, email, full_name, role, is_active')
      .eq('id', authUser.id)
      .maybeSingle();

  if (response == null) {
    return AppUser(
      id: authUser.id,
      email: authUser.email ?? '',
      fullName: authUser.userMetadata?['full_name'] as String?,
      role: AppRole.viewer,
      isActive: true,
    );
  }

  return AppUser(
    id: response['id'] as String,
    email: response['email'] as String? ?? authUser.email ?? '',
    fullName: response['full_name'] as String?,
    role: AppRoleX.fromName(response['role'] as String?),
    isActive: response['is_active'] as bool? ?? true,
  );
});
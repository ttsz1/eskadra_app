import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/org_structure.dart';
import '../../data/repositories/profile_repository_supabase.dart';

final profileRepositoryProvider = Provider<ProfileRepositorySupabase>((ref) {
  return ProfileRepositorySupabase.fromClient(Supabase.instance.client);
});

final profileDirectoryProvider = FutureProvider<List<AppPerson>>((ref) async {
  final repository = ref.watch(profileRepositoryProvider);
  return repository.fetchProfiles();
});

final currentAppPersonProvider = Provider<AppPerson?>((ref) {
  final profiles = ref.watch(profileDirectoryProvider).valueOrNull;
  final authUser = Supabase.instance.client.auth.currentUser;

  if (profiles == null || authUser == null) {
    return null;
  }

  final authId = authUser.id;

  for (final person in profiles) {
    if (person.id == authId) {
      return person;
    }
  }

  return null;
});

final peopleByIdProvider = Provider<Map<String, AppPerson>>((ref) {
  final profiles =
      ref.watch(profileDirectoryProvider).valueOrNull ?? const <AppPerson>[];

  return <String, AppPerson>{
    for (final person in profiles) person.id: person,
  };
});
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profiles/data/repositories/profile_repository_supabase.dart';
import '../../../profiles/presentation/providers/profile_directory_provider.dart';
import '../../../../shared/models/org_structure.dart';

final personnelModuleProvider =
StateNotifierProvider<PersonnelModuleNotifier, PersonnelModuleState>((ref) {
  final profiles = ref.watch(profileDirectoryProvider).valueOrNull ?? const <AppPerson>[];
  final currentUser = ref.watch(currentAppPersonProvider);
  final repository = ref.watch(profileRepositoryProvider);

  return PersonnelModuleNotifier(
    repository: repository,
    ref: ref,
    initialState: PersonnelModuleState.initial(
      profiles: profiles,
      currentUser: currentUser,
    ),
  );
});

class PersonnelModuleState {
  final List<AppPerson> profiles;
  final AppPerson? currentUser;
  final String? selectedPersonId;
  final bool isSaving;
  final String? error;

  const PersonnelModuleState({
    required this.profiles,
    required this.currentUser,
    required this.selectedPersonId,
    required this.isSaving,
    required this.error,
  });

  factory PersonnelModuleState.initial({
    required List<AppPerson> profiles,
    required AppPerson? currentUser,
  }) {
    return PersonnelModuleState(
      profiles: profiles,
      currentUser: currentUser,
      selectedPersonId: profiles.isNotEmpty ? profiles.first.id : null,
      isSaving: false,
      error: null,
    );
  }

  AppPerson? get selectedPerson {
    if (selectedPersonId == null) return null;
    try {
      return profiles.firstWhere((p) => p.id == selectedPersonId);
    } catch (_) {
      return null;
    }
  }

  PersonnelModuleState copyWith({
    List<AppPerson>? profiles,
    AppPerson? currentUser,
    bool setCurrentUser = false,
    String? selectedPersonId,
    bool clearSelected = false,
    bool? isSaving,
    String? error,
    bool clearError = false,
  }) {
    return PersonnelModuleState(
      profiles: profiles ?? this.profiles,
      currentUser: setCurrentUser ? currentUser : this.currentUser,
      selectedPersonId:
      clearSelected ? null : (selectedPersonId ?? this.selectedPersonId),
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PersonnelModuleNotifier extends StateNotifier<PersonnelModuleState> {
  final ProfileRepositorySupabase repository;
  final Ref ref;

  PersonnelModuleNotifier({
    required this.repository,
    required this.ref,
    required PersonnelModuleState initialState,
  }) : super(initialState);

  void syncProfiles(List<AppPerson> profiles, AppPerson? currentUser) {
    final selectedId = state.selectedPersonId;
    final nextSelected = profiles.any((p) => p.id == selectedId)
        ? selectedId
        : (profiles.isNotEmpty ? profiles.first.id : null);

    state = state.copyWith(
      profiles: profiles,
      currentUser: currentUser,
      setCurrentUser: true,
      selectedPersonId: nextSelected,
    );
  }

  void selectPerson(String id) {
    state = state.copyWith(selectedPersonId: id);
  }

  bool get canManageProfiles {
    final user = state.currentUser;
    if (user == null) return false;

    return user.function == OrgFunction.commander ||
        user.function == OrgFunction.chief ||
        user.function == OrgFunction.manager;
  }

  Future<void> updatePerson({
    required String id,
    required String fullName,
    required String email,
    required OrgUnit unit,
    required OrgFunction function,
    required PersonnelType personnelType,
    required RankGroup rankGroup,
    required bool isActive,
  }) async {
    try {
      state = state.copyWith(isSaving: true, clearError: true);

      await repository.updateProfile(
        id: id,
        fullName: fullName,
        email: email,
        unit: unit,
        function: function,
        personnelType: personnelType,
        rankGroup: rankGroup,
        isActive: isActive,
      );

      ref.invalidate(profileDirectoryProvider);

      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: 'Błąd zapisu profilu: $e',
      );
    }
  }
}
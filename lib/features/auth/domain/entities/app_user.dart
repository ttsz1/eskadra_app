import '../../../../core/security/app_role.dart';

class AppUser {
  final String id;
  final String email;
  final String? fullName;
  final AppRole role;
  final bool isActive;

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    this.fullName,
  });

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    AppRole? role,
    bool? isActive,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
    );
  }
}
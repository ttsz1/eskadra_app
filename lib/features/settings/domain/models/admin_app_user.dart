class AdminAppUser {
  const AdminAppUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.orgUnit,
    this.orgFunction,
    this.personnelType,
    this.rankGroup,
    required this.isActive,
  });

  final String id;
  final String email;
  final String fullName;
  final String? orgUnit;
  final String? orgFunction;
  final String? personnelType;
  final String? rankGroup;
  final bool isActive;

  factory AdminAppUser.fromMap(Map<String, dynamic> map) {
    return AdminAppUser(
      id: map['id'] as String,
      email: map['email'] as String? ?? '',
      fullName: map['full_name'] as String? ?? '',
      orgUnit: map['org_unit'] as String?,
      orgFunction: map['org_function'] as String?,
      personnelType: map['personnel_type'] as String?,
      rankGroup: map['rank_group'] as String?,
      isActive: map['is_active'] as bool? ?? true,
    );
  }
}
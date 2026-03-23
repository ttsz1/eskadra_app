enum AppRole {
  admin,
  manager,
  planner,
  worker,
  viewer,
}

extension AppRoleX on AppRole {
  static AppRole fromName(String? value) {
    return AppRole.values.firstWhere(
          (role) => role.name == value,
      orElse: () => AppRole.viewer,
    );
  }

  bool get canManageStaff {
    return this == AppRole.admin || this == AppRole.manager;
  }

  bool get canManageTasks {
    return this == AppRole.admin || this == AppRole.manager || this == AppRole.planner;
  }

  bool get canManageCalendar {
    return this == AppRole.admin || this == AppRole.manager || this == AppRole.planner;
  }

  bool get canViewStaff {
    return this != AppRole.viewer ? true : true;
  }
}
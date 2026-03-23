import '../../../../shared/models/org_structure.dart';

class TaskSecretAccess {
  final Set<OrgUnit> allowedUnits;
  final Set<String> allowedPersonIds;
  final Set<PersonnelType> allowedPersonnelTypes;
  final Set<RankGroup> allowedRankGroups;

  const TaskSecretAccess({
    this.allowedUnits = const {},
    this.allowedPersonIds = const {},
    this.allowedPersonnelTypes = const {},
    this.allowedRankGroups = const {},
  });

  bool canAccess({
    required AppPerson viewer,
    required String authorId,
    required String? responsibleId,
    required List<String> helperIds,
  }) {
    final directAccess = viewer.id == authorId ||
        viewer.id == responsibleId ||
        helperIds.contains(viewer.id);

    if (directAccess) {
      return true;
    }

    final structureFilterActive =
        allowedUnits.isNotEmpty || allowedPersonIds.isNotEmpty;
    final tagFilterActive =
        allowedPersonnelTypes.isNotEmpty || allowedRankGroups.isNotEmpty;

    final structureMatch = !structureFilterActive ||
        allowedUnits.contains(viewer.unit) ||
        allowedPersonIds.contains(viewer.id);

    final tagMatch = !tagFilterActive &&
        allowedPersonnelTypes.isEmpty &&
        allowedRankGroups.isEmpty
        ? true
        : (allowedPersonnelTypes.isEmpty ||
        allowedPersonnelTypes.contains(viewer.personnelType)) &&
        (allowedRankGroups.isEmpty ||
            allowedRankGroups.contains(viewer.rankGroup));

    return structureMatch && tagMatch;
  }

  TaskSecretAccess copyWith({
    Set<OrgUnit>? allowedUnits,
    Set<String>? allowedPersonIds,
    Set<PersonnelType>? allowedPersonnelTypes,
    Set<RankGroup>? allowedRankGroups,
  }) {
    return TaskSecretAccess(
      allowedUnits: allowedUnits ?? this.allowedUnits,
      allowedPersonIds: allowedPersonIds ?? this.allowedPersonIds,
      allowedPersonnelTypes:
      allowedPersonnelTypes ?? this.allowedPersonnelTypes,
      allowedRankGroups: allowedRankGroups ?? this.allowedRankGroups,
    );
  }
}
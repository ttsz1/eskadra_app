String calendarPersonLabel({
  required String? personName,
  required String? personId,
}) {
  final normalizedName = personName?.trim();
  if (normalizedName != null && normalizedName.isNotEmpty) {
    return normalizedName;
  }

  final normalizedId = personId?.trim();
  if (normalizedId == null || normalizedId.isEmpty) {
    return 'Nieprzypisano';
  }

  final shortId =
  normalizedId.length <= 6 ? normalizedId : normalizedId.substring(0, 6);

  return 'Osoba • $shortId';
}
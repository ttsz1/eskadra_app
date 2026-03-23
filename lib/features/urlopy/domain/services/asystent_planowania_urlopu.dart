class AsystentPlanowaniaUrlopu {
  int policzPozostaleDni({
    required int przydzielone,
    required int zaplanowane,
  }) {
    return przydzielone - zaplanowane;
  }

  bool czyKolizja({
    required DateTime start,
    required DateTime end,
    required List<DateTime> inneUrlopy,
  }) {
    for (final data in inneUrlopy) {
      if (data.isAfter(start) && data.isBefore(end)) {
        return true;
      }
    }

    return false;
  }
}
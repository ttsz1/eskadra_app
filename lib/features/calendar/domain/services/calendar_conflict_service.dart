import '../models/calendar_item.dart';

class CalendarConflictService {
  const CalendarConflictService();

  List<CalendarItemConflict> findConflicts(List<CalendarItem> items) {
    final conflicts = <CalendarItemConflict>[];

    for (var i = 0; i < items.length; i++) {
      for (var j = i + 1; j < items.length; j++) {
        final first = items[i];
        final second = items[j];

        final samePerson = first.personId != null &&
            second.personId != null &&
            first.personId == second.personId;

        final sameTeam = first.teamId != null &&
            second.teamId != null &&
            first.teamId == second.teamId;

        if (!(samePerson || sameTeam)) {
          continue;
        }

        final overlaps = first.startAt.isBefore(second.endAt) &&
            first.endAt.isAfter(second.startAt);

        if (!overlaps) {
          continue;
        }

        conflicts.add(
          CalendarItemConflict(
            firstItemId: first.id,
            secondItemId: second.id,
            reason: samePerson ? 'person_overlap' : 'team_overlap',
          ),
        );
      }
    }

    return conflicts;
  }
}

class CalendarItemConflict {
  final String firstItemId;
  final String secondItemId;
  final String reason;

  const CalendarItemConflict({
    required this.firstItemId,
    required this.secondItemId,
    required this.reason,
  });
}
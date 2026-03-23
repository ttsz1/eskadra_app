import '../models/calendar_item.dart';

class CalendarLayoutService {
  const CalendarLayoutService();

  List<CalendarItem> sortForTimeline(List<CalendarItem> items) {
    final result = [...items];

    result.sort((a, b) {
      final startCompare = a.startAt.compareTo(b.startAt);
      if (startCompare != 0) return startCompare;

      final endCompare = a.endAt.compareTo(b.endAt);
      if (endCompare != 0) return endCompare;

      return a.title.compareTo(b.title);
    });

    return result;
  }
}
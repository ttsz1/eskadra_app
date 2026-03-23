class PolishHolidayService {
  const PolishHolidayService();

  bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday;
  }

  bool isPublicHoliday(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final holidays = holidaysForYear(date.year);

    return holidays.any((holiday) => _isSameDate(holiday.date, normalized));
  }

  String? holidayName(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final holidays = holidaysForYear(date.year);

    for (final holiday in holidays) {
      if (_isSameDate(holiday.date, normalized)) {
        return holiday.name;
      }
    }

    return null;
  }

  bool isNonWorkingDay(DateTime date) {
    return isWeekend(date) || isPublicHoliday(date);
  }

  List<PolishHoliday> holidaysForYear(int year) {
    final easterSunday = _calculateEasterSunday(year);
    final easterMonday = easterSunday.add(const Duration(days: 1));
    final pentecost = easterSunday.add(const Duration(days: 49));
    final corpusChristi = easterSunday.add(const Duration(days: 60));

    return [
      PolishHoliday(
        name: 'Nowy Rok',
        date: DateTime(year, 1, 1),
      ),
      PolishHoliday(
        name: 'Święto Trzech Króli',
        date: DateTime(year, 1, 6),
      ),
      PolishHoliday(
        name: 'Niedziela Wielkanocna',
        date: easterSunday,
      ),
      PolishHoliday(
        name: 'Poniedziałek Wielkanocny',
        date: easterMonday,
      ),
      PolishHoliday(
        name: 'Święto Pracy',
        date: DateTime(year, 5, 1),
      ),
      PolishHoliday(
        name: 'Święto Konstytucji 3 Maja',
        date: DateTime(year, 5, 3),
      ),
      PolishHoliday(
        name: 'Zesłanie Ducha Świętego',
        date: pentecost,
      ),
      PolishHoliday(
        name: 'Boże Ciało',
        date: corpusChristi,
      ),
      PolishHoliday(
        name: 'Wniebowzięcie Najświętszej Maryi Panny',
        date: DateTime(year, 8, 15),
      ),
      PolishHoliday(
        name: 'Wszystkich Świętych',
        date: DateTime(year, 11, 1),
      ),
      PolishHoliday(
        name: 'Narodowe Święto Niepodległości',
        date: DateTime(year, 11, 11),
      ),
      PolishHoliday(
        name: 'Boże Narodzenie (pierwszy dzień)',
        date: DateTime(year, 12, 25),
      ),
      PolishHoliday(
        name: 'Boże Narodzenie (drugi dzień)',
        date: DateTime(year, 12, 26),
      ),
    ];
  }

  DateTime _calculateEasterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;

    return DateTime(year, month, day);
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class PolishHoliday {
  final String name;
  final DateTime date;

  const PolishHoliday({
    required this.name,
    required this.date,
  });
}
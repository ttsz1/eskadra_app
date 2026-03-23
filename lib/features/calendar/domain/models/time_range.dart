class TimeRange {
  final DateTime start;
  final DateTime end;

  const TimeRange({
    required this.start,
    required this.end,
  });

  Duration get duration => end.difference(start);

  bool contains(DateTime value) {
    return !value.isBefore(start) && value.isBefore(end);
  }

  bool overlaps(TimeRange other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }

  @override
  String toString() {
    return 'TimeRange(start: $start, end: $end)';
  }
}
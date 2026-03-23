import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/calendar_repository.dart';
import '../../domain/models/calendar_filter_state.dart';
import '../../domain/models/calendar_view_type.dart';
import '../../domain/models/time_range.dart';
import 'calendar_state.dart';

class CalendarController extends StateNotifier<CalendarState> {
  CalendarController(this._repository) : super(CalendarState.initial()) {
    load();
  }

  final CalendarRepository _repository;

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final range = _buildRange(
        focusedDate: state.focusedDate,
        viewType: state.viewType,
      );

      final items = await _repository.fetchItems(
        range: range,
        filters: state.filters,
      );

      final selectedStillExists = state.selectedItemId != null &&
          items.any((item) => item.id == state.selectedItemId);

      state = state.copyWith(
        isLoading: false,
        items: items,
        clearSelection: !selectedStillExists,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    await load();
  }

  Future<void> setView(CalendarViewType viewType) async {
    if (state.viewType == viewType) return;

    state = state.copyWith(viewType: viewType);
    await load();
  }

  Future<void> goToDate(DateTime date) async {
    final normalized = DateTime(date.year, date.month, date.day);

    state = state.copyWith(focusedDate: normalized);
    await load();
  }

  Future<void> goToToday() async {
    await goToDate(DateTime.now());
  }

  Future<void> nextRange() async {
    final nextDate = switch (state.viewType) {
      CalendarViewType.day => state.focusedDate.add(const Duration(days: 1)),
      CalendarViewType.threeDays => state.focusedDate.add(const Duration(days: 3)),
      CalendarViewType.week => state.focusedDate.add(const Duration(days: 7)),
      CalendarViewType.month => DateTime(
        state.focusedDate.year,
        state.focusedDate.month + 1,
        1,
      ),
      CalendarViewType.agenda => state.focusedDate.add(const Duration(days: 14)),
    };

    await goToDate(nextDate);
  }

  Future<void> previousRange() async {
    final previousDate = switch (state.viewType) {
      CalendarViewType.day => state.focusedDate.subtract(const Duration(days: 1)),
      CalendarViewType.threeDays => state.focusedDate.subtract(const Duration(days: 3)),
      CalendarViewType.week => state.focusedDate.subtract(const Duration(days: 7)),
      CalendarViewType.month => DateTime(
        state.focusedDate.year,
        state.focusedDate.month - 1,
        1,
      ),
      CalendarViewType.agenda => state.focusedDate.subtract(const Duration(days: 14)),
    };

    await goToDate(previousDate);
  }

  Future<void> updateFilters(CalendarFilterState filters) async {
    state = state.copyWith(filters: filters);
    await load();
  }

  void selectItem(String? itemId) {
    state = state.copyWith(selectedItemId: itemId);
  }

  TimeRange visibleRange() {
    return _buildRange(
      focusedDate: state.focusedDate,
      viewType: state.viewType,
    );
  }

  TimeRange _buildRange({
    required DateTime focusedDate,
    required CalendarViewType viewType,
  }) {
    switch (viewType) {
      case CalendarViewType.day:
        final start = DateTime(
          focusedDate.year,
          focusedDate.month,
          focusedDate.day,
        );
        return TimeRange(
          start: start,
          end: start.add(const Duration(days: 1)),
        );

      case CalendarViewType.threeDays:
        final start = DateTime(
          focusedDate.year,
          focusedDate.month,
          focusedDate.day,
        );
        return TimeRange(
          start: start,
          end: start.add(const Duration(days: 3)),
        );

      case CalendarViewType.week:
        final dayStart = DateTime(
          focusedDate.year,
          focusedDate.month,
          focusedDate.day,
        );
        final weekStart = dayStart.subtract(Duration(days: dayStart.weekday - 1));
        return TimeRange(
          start: weekStart,
          end: weekStart.add(const Duration(days: 7)),
        );

      case CalendarViewType.month:
        final monthStart = DateTime(
          focusedDate.year,
          focusedDate.month,
          1,
        );
        final nextMonthStart = DateTime(
          focusedDate.year,
          focusedDate.month + 1,
          1,
        );
        return TimeRange(
          start: monthStart,
          end: nextMonthStart,
        );

      case CalendarViewType.agenda:
        final start = DateTime(
          focusedDate.year,
          focusedDate.month,
          focusedDate.day,
        );
        return TimeRange(
          start: start,
          end: start.add(const Duration(days: 14)),
        );
    }
  }
}
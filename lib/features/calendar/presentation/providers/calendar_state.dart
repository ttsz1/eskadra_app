import '../../domain/models/calendar_filter_state.dart';
import '../../domain/models/calendar_item.dart';
import '../../domain/models/calendar_view_type.dart';

class CalendarState {
  final bool isLoading;
  final CalendarViewType viewType;
  final DateTime focusedDate;
  final CalendarFilterState filters;
  final List<CalendarItem> items;
  final String? selectedItemId;
  final String? error;

  const CalendarState({
    required this.isLoading,
    required this.viewType,
    required this.focusedDate,
    required this.filters,
    required this.items,
    this.selectedItemId,
    this.error,
  });

  factory CalendarState.initial() {
    return CalendarState(
      isLoading: false,
      viewType: CalendarViewType.week,
      focusedDate: DateTime.now(),
      filters: const CalendarFilterState(),
      items: const [],
      selectedItemId: null,
      error: null,
    );
  }

  CalendarItem? get selectedItem {
    if (selectedItemId == null) return null;

    for (final item in items) {
      if (item.id == selectedItemId) {
        return item;
      }
    }

    return null;
  }

  CalendarState copyWith({
    bool? isLoading,
    CalendarViewType? viewType,
    DateTime? focusedDate,
    CalendarFilterState? filters,
    List<CalendarItem>? items,
    String? selectedItemId,
    String? error,
    bool clearError = false,
    bool clearSelection = false,
  }) {
    return CalendarState(
      isLoading: isLoading ?? this.isLoading,
      viewType: viewType ?? this.viewType,
      focusedDate: focusedDate ?? this.focusedDate,
      filters: filters ?? this.filters,
      items: items ?? this.items,
      selectedItemId:
      clearSelection ? null : (selectedItemId ?? this.selectedItemId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}
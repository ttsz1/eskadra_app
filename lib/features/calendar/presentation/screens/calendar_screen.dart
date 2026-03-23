import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/calendar_view_type.dart';
import '../providers/calendar_controller.dart';
import '../providers/calendar_providers.dart';
import '../providers/calendar_state.dart';
import '../widgets/calendar_agenda_view.dart';
import '../widgets/calendar_conflicts_dialog.dart';
import '../widgets/calendar_day_view.dart';
import '../widgets/calendar_filters_dialog.dart';
import '../widgets/calendar_month_view.dart';
import '../widgets/calendar_three_days_view.dart';
import '../widgets/calendar_toolbar.dart';
import '../widgets/calendar_week_view.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  static const String routePath = '/calendar';
  static const String routeName = 'calendar';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final CalendarState state = ref.watch(calendarControllerProvider);
    final CalendarController controller =
    ref.read(calendarControllerProvider.notifier);

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            alignment: Alignment.centerLeft,
            child: Text(
              'Kalendarz wspólny',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          CalendarToolbar(
            focusedDate: state.focusedDate,
            viewType: state.viewType,
            selectedPeopleCount: state.filters.personIds.length,
            onTodayPressed: controller.goToToday,
            onPreviousPressed: controller.previousRange,
            onNextPressed: controller.nextRange,
            onViewChanged: controller.setView,
            onOpenFilters: () {
              showDialog<void>(
                context: context,
                builder: (_) => const CalendarFiltersDialog(),
              );
            },
            onOpenConflicts: () {
              showDialog<void>(
                context: context,
                builder: (_) => CalendarConflictsDialog(
                  items: state.items,
                  onSelectItem: controller.selectItem,
                ),
              );
            },
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildMainContent(
                    state.viewType,
                    state,
                    controller,
                  ),
                ),
                if (state.isLoading)
                  const Positioned(
                    top: 16,
                    right: 16,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
      CalendarViewType viewType,
      CalendarState state,
      CalendarController controller,
      ) {
    switch (viewType) {
      case CalendarViewType.day:
        return CalendarDayView(
          focusedDate: state.focusedDate,
          items: state.items,
          selectedItemId: state.selectedItemId,
          onItemTap: controller.selectItem,
        );

      case CalendarViewType.threeDays:
        return CalendarThreeDaysView(
          focusedDate: state.focusedDate,
          items: state.items,
          selectedItemId: state.selectedItemId,
          onItemTap: controller.selectItem,
        );

      case CalendarViewType.week:
        return CalendarWeekView(
          focusedDate: state.focusedDate,
          items: state.items,
          selectedItemId: state.selectedItemId,
          onItemTap: controller.selectItem,
        );

      case CalendarViewType.month:
        return CalendarMonthView(
          focusedDate: state.focusedDate,
          items: state.items,
          selectedItemId: state.selectedItemId,
          onItemTap: controller.selectItem,
        );

      case CalendarViewType.agenda:
        return CalendarAgendaView(
          focusedDate: state.focusedDate,
          items: state.items,
          selectedItemId: state.selectedItemId,
          onItemTap: controller.selectItem,
        );
    }
  }
}
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../obecnosci/presentation/providers/attendance_provider.dart';
import '../../data/calendar_remote_datasource.dart';
import '../../data/calendar_repository.dart';
import '../../domain/models/calendar_filter_state.dart';
import 'calendar_controller.dart';
import 'calendar_state.dart';

final calendarDefaultFilters = CalendarFilterState();

final calendarRemoteDataSourceProvider =
Provider<CalendarRemoteDataSource>((ref) {
  return CalendarRemoteDataSource(Supabase.instance.client);
});

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final remote = ref.watch(calendarRemoteDataSourceProvider);
  return SupabaseCalendarRepository(remote);
});

final calendarControllerProvider =
StateNotifierProvider<CalendarController, CalendarState>((ref) {
  final repository = ref.watch(calendarRepositoryProvider);
  final controller = CalendarController(repository);

  ref.listen<int>(
    attendanceDataVersionProvider,
        (_, __) {
      controller.refresh();
    },
  );

  return controller;
});
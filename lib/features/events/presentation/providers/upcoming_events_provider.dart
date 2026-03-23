import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../profiles/presentation/providers/profile_directory_provider.dart';
import '../../data/repositories/event_repository_supabase.dart';
import '../../domain/models/event_item.dart';

final eventRepositoryProvider = Provider<EventRepositorySupabase>((ref) {
  return EventRepositorySupabase.fromClient(Supabase.instance.client);
});

final upcomingEventsProvider = FutureProvider<List<EventItem>>((ref) async {
  final repository = ref.watch(eventRepositoryProvider);
  return repository.fetchUpcomingEvents(limit: 8);
});

class EventDraft {
  final String title;
  final String details;
  final String? location;
  final DateTime startsAt;
  final DateTime? endsAt;
  final bool isAllDay;

  const EventDraft({
    required this.title,
    required this.details,
    required this.startsAt,
    this.location,
    this.endsAt,
    this.isAllDay = false,
  });
}

final eventCreatorProvider =
StateNotifierProvider<EventCreatorNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  final currentUser = ref.watch(currentAppPersonProvider);

  return EventCreatorNotifier(
    repository: repository,
    ref: ref,
    currentUserId: currentUser?.id,
  );
});

class EventCreatorNotifier extends StateNotifier<AsyncValue<void>> {
  final EventRepositorySupabase repository;
  final Ref ref;
  final String? currentUserId;

  EventCreatorNotifier({
    required this.repository,
    required this.ref,
    required this.currentUserId,
  }) : super(const AsyncData(null));

  Future<void> createEvent(EventDraft draft) async {
    final userId = currentUserId;
    if (userId == null) {
      state = AsyncError(
        'Brak profilu użytkownika w profiles.',
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();

    try {
      await repository.createEvent(
        createdBy: userId,
        title: draft.title,
        details: draft.details,
        location: draft.location,
        startsAt: draft.startsAt,
        endsAt: draft.endsAt,
        isAllDay: draft.isAllDay,
      );

      ref.invalidate(upcomingEventsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError('Błąd tworzenia eventu: $e', st);
    }
  }

  Future<void> updateEvent({
    required String eventId,
    required EventDraft draft,
  }) async {
    state = const AsyncLoading();

    try {
      await repository.updateEvent(
        eventId: eventId,
        title: draft.title,
        details: draft.details,
        location: draft.location,
        startsAt: draft.startsAt,
        endsAt: draft.endsAt,
        isAllDay: draft.isAllDay,
      );

      ref.invalidate(upcomingEventsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError('Błąd edycji eventu: $e', st);
    }
  }

  Future<void> deleteEvent({
    required String eventId,
  }) async {
    state = const AsyncLoading();

    try {
      await repository.deleteEvent(eventId: eventId);
      ref.invalidate(upcomingEventsProvider);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError('Błąd usuwania eventu: $e', st);
    }
  }
}
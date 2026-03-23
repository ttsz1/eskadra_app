import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/announcements_repository.dart';
import '../../domain/models/announcement.dart';

final announcementsRepositoryProvider = Provider<AnnouncementsRepository>((ref) {
  return AnnouncementsRepository(Supabase.instance.client);
});

final announcementsDataVersionProvider = StateProvider<int>((ref) => 0);

final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
  ref.watch(announcementsDataVersionProvider);
  final repo = ref.watch(announcementsRepositoryProvider);
  return repo.fetchAnnouncements();
});

final announcementsActionsProvider = Provider<AnnouncementsActions>((ref) {
  return AnnouncementsActions(ref);
});

class AnnouncementsActions {
  AnnouncementsActions(this.ref);

  final Ref ref;

  Future<void> createAnnouncement({
    required String title,
    required String content,
    DateTime? autoDeleteAt,
  }) async {
    final repo = ref.read(announcementsRepositoryProvider);
    await repo.createAnnouncement(
      title: title,
      content: content,
      autoDeleteAt: autoDeleteAt,
    );

    ref.read(announcementsDataVersionProvider.notifier).state++;
  }

  Future<void> deleteAnnouncement(String id) async {
    final repo = ref.read(announcementsRepositoryProvider);
    await repo.deleteAnnouncement(id);

    ref.read(announcementsDataVersionProvider.notifier).state++;
  }

  void refresh() {
    ref.read(announcementsDataVersionProvider.notifier).state++;
  }
}
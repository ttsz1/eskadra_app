import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models/announcement.dart';

class AnnouncementsRepository {
  AnnouncementsRepository(this._client);

  final SupabaseClient _client;

  Future<List<Announcement>> fetchAnnouncements() async {
    final rows = await _client
        .from('announcements')
        .select('id, title, content, created_at, created_by, auto_delete_at')
        .or(
      'auto_delete_at.is.null,auto_delete_at.gt.${DateTime.now().toUtc().toIso8601String()}',
    )
        .order('created_at', ascending: false);

    final items = (rows as List<dynamic>)
        .map((e) => Announcement.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    final authorIds = items.map((e) => e.createdBy).toSet().toList();
    if (authorIds.isEmpty) {
      return items;
    }

    final profileRows = await _client
        .from('profiles')
        .select('id, full_name')
        .inFilter('id', authorIds);

    final profilesById = <String, String>{};
    for (final row in (profileRows as List<dynamic>)) {
      final map = Map<String, dynamic>.from(row as Map);
      final id = map['id']?.toString();
      if (id == null) continue;

      final fullName = (map['full_name']?.toString().trim().isNotEmpty ?? false)
          ? map['full_name'].toString().trim()
          : 'Nieznany użytkownik';

      profilesById[id] = fullName;
    }

    return items
        .map(
          (item) => item.copyWith(
        authorName: profilesById[item.createdBy] ?? 'Nieznany użytkownik',
      ),
    )
        .toList();
  }

  Future<void> createAnnouncement({
    required String title,
    required String content,
    DateTime? autoDeleteAt,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Brak zalogowanego użytkownika.');
    }

    await _client.from('announcements').insert({
      'title': title.trim(),
      'content': content.trim(),
      'created_by': userId,
      'auto_delete_at': autoDeleteAt?.toUtc().toIso8601String(),
    });
  }

  Future<void> deleteAnnouncement(String id) async {
    await _client.from('announcements').delete().eq('id', id);
  }
}
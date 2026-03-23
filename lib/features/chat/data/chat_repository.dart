import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../domain/models/chat_attachment.dart';
import '../domain/models/chat_member.dart';
import '../domain/models/chat_message.dart';
import '../domain/models/chat_room.dart';

class ChatRepository {
  ChatRepository(this._supabase);

  final SupabaseClient _supabase;
  static const _bucket = 'chat-attachments';
  static const _uuid = Uuid();

  User get _user {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Brak zalogowanego użytkownika.');
    }
    return user;
  }

  Future<List<ChatRoom>> getRooms() async {
    final data = await _supabase
        .from('chat_rooms')
        .select()
        .order('is_global', ascending: false)
        .order('updated_at', ascending: false);

    return (data as List)
        .map((e) => ChatRoom.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<ChatRoom> getRoomById(String roomId) async {
    final row = await _supabase
        .from('chat_rooms')
        .select()
        .eq('id', roomId)
        .single();

    return ChatRoom.fromMap(row);
  }

  Future<List<ChatMember>> getAvailableUsers() async {
    final data = await _supabase
        .from('profiles')
        .select('id, full_name, email')
        .eq('is_active', true)
        .order('full_name');

    return (data as List)
        .map((e) => ChatMember.fromProfileMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMember>> getRoomMembers(String roomId) async {
    final memberRows = await _supabase
        .from('chat_room_members')
        .select('user_id')
        .eq('room_id', roomId);

    final ids = (memberRows as List)
        .map((e) => (e as Map<String, dynamic>)['user_id'] as String)
        .toSet()
        .toList();

    if (ids.isEmpty) return [];

    final profileRows = await _supabase
        .from('profiles')
        .select('id, full_name, email')
        .inFilter('id', ids)
        .order('full_name');

    return (profileRows as List)
        .map((e) => ChatMember.fromProfileMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> createRoom({
    required String name,
    required bool isPrivate,
    required List<String> userIds,
    required List<String> sectionIds,
    PlatformFile? iconFile,
  }) async {
    final roomId = await _supabase.rpc(
      'create_chat_room',
      params: {
        'p_name': name.trim(),
        'p_is_private': isPrivate,
        'p_org_units': sectionIds,
        'p_user_ids': userIds,
      },
    ) as String;

    if (iconFile != null && iconFile.bytes != null) {
      final iconMime = iconFile.extension == null
          ? 'application/octet-stream'
          : _guessMime(iconFile.extension!);
      final iconName = '${_uuid.v4()}_${iconFile.name}';
      final iconStoragePath = 'room-icons/$roomId/$iconName';

      await _supabase.storage.from(_bucket).uploadBinary(
            iconStoragePath,
            iconFile.bytes!,
            fileOptions: FileOptions(
              upsert: false,
              contentType: iconMime,
            ),
          );

      await _supabase
          .from('chat_rooms')
          .update({'icon_storage_path': iconStoragePath})
          .eq('id', roomId);
    }

    await _supabase
        .from('chat_rooms')
        .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', roomId);

    return roomId;
  }

  Future<List<Map<String, String>>> getSections() async {
    final data = await _supabase
        .from('profiles')
        .select('org_unit, is_active')
        .eq('is_active', true);

    final units = <String>{};

    for (final row in data as List) {
      final map = row as Map<String, dynamic>;
      final value = map['org_unit']?.toString().trim();
      if (value != null && value.isNotEmpty) {
        units.add(value);
      }
    }

    final sorted = units.toList()..sort();

    return sorted
        .map(
          (value) => {
            'id': value,
            'name': _formatOrgUnitLabel(value),
          },
        )
        .toList();
  }

  Future<List<ChatMessage>> getMessages(String roomId) async {
    final messageRows = await _supabase
        .from('chat_messages')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: true);

    final rows = (messageRows as List).cast<Map<String, dynamic>>();
    if (rows.isEmpty) return [];

    final senderIds = rows.map((e) => e['sender_id'] as String).toSet().toList();
    final messageIds = rows.map((e) => e['id'] as String).toList();

    final profileRows = await _supabase
        .from('profiles')
        .select('id, full_name, email')
        .inFilter('id', senderIds);

    final profileMap = <String, String>{};
    for (final row in profileRows as List) {
      final item = row as Map<String, dynamic>;
      final id = item['id'] as String;
      final name = (item['full_name'] as String?)?.trim().isNotEmpty == true
          ? item['full_name'] as String
          : (item['email'] as String? ?? 'Użytkownik');
      profileMap[id] = name;
    }

    final attachmentRows = messageIds.isEmpty
        ? <dynamic>[]
        : await _supabase
            .from('chat_attachments')
            .select()
            .inFilter('message_id', messageIds)
            .order('created_at', ascending: true);

    final attachmentMap = <String, List<ChatAttachment>>{};
    for (final row in attachmentRows as List) {
      final attachment = ChatAttachment.fromMap(row as Map<String, dynamic>);
      attachmentMap.putIfAbsent(attachment.messageId, () => []).add(attachment);
    }

    return rows
        .map(
          (row) => ChatMessage.fromMap(
            row,
            senderName: profileMap[row['sender_id'] as String] ?? 'Użytkownik',
            attachments: attachmentMap[row['id'] as String] ?? const [],
          ),
        )
        .toList();
  }

  Stream<List<ChatMessage>> watchMessages(String roomId) {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at')
        .asyncMap((_) => getMessages(roomId));
  }

  Future<void> sendMessage({
    required String roomId,
    required String content,
    List<PlatformFile> files = const [],
  }) async {
    final me = _user;

    final messageRow = await _supabase
        .from('chat_messages')
        .insert({
          'room_id': roomId,
          'sender_id': me.id,
          'content': content.trim(),
        })
        .select()
        .single();

    final messageId = messageRow['id'] as String;
    final attachmentInserts = <Map<String, dynamic>>[];

    for (final file in files) {
      final bytes = file.bytes;
      if (bytes == null) {
        throw Exception(
          'Nie udało się odczytać pliku ${file.name}. Uruchom picker z withData = true.',
        );
      }

      final mimeType =
          file.extension == null ? null : _guessMime(file.extension!);
      final safeName = '${_uuid.v4()}_${file.name}';
      final storagePath = '$roomId/$messageId/$safeName';

      await _supabase.storage.from(_bucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(
              upsert: false,
              contentType: mimeType,
            ),
          );

      attachmentInserts.add({
        'message_id': messageId,
        'room_id': roomId,
        'file_name': file.name,
        'storage_path': storagePath,
        'mime_type': mimeType,
        'file_size_bytes': file.size,
        'created_by': me.id,
      });
    }

    if (attachmentInserts.isNotEmpty) {
      await _supabase.from('chat_attachments').insert(attachmentInserts);

      await _supabase
          .from('chat_messages')
          .update({
            'edited_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', messageId);
    }

    await _supabase
        .from('chat_rooms')
        .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', roomId);
  }

  Future<void> deleteMessage({
    required String roomId,
    required ChatMessage message,
  }) async {
    for (final attachment in message.attachments) {
      try {
        await _supabase.storage.from(_bucket).remove([attachment.storagePath]);
      } catch (_) {}
    }

    await _supabase.from('chat_messages').delete().eq('id', message.id);

    await _supabase
        .from('chat_rooms')
        .update({'updated_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', roomId);
  }

  Future<String> buildAttachmentSignedUrl(String storagePath) {
    return _supabase.storage.from(_bucket).createSignedUrl(storagePath, 3600);
  }

  Future<void> addUsersToRoom({
    required String roomId,
    required List<String> userIds,
  }) async {
    final me = _user;
    if (userIds.isEmpty) return;

    await _supabase.from('chat_room_members').insert(
          userIds
              .map(
                (userId) => {
                  'room_id': roomId,
                  'user_id': userId,
                  'added_by': me.id,
                },
              )
              .toList(),
        );
  }

  Future<void> removeUserFromRoom({
    required String roomId,
    required String userId,
  }) async {
    await _supabase
        .from('chat_room_members')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', userId);
  }

  String _formatOrgUnitLabel(String value) {
    const labels = <String, String>{
      'dowodztwo': 'Dowództwo',
      'operacje': 'Operacje',
      'logistyka': 'Logistyka',
      'szkolenie': 'Szkolenie',
      'techniczna': 'Techniczna',
      'administracja': 'Administracja',
    };

    if (labels.containsKey(value)) {
      return labels[value]!;
    }

    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map(
          (part) => part[0].toUpperCase() + part.substring(1).toLowerCase(),
        )
        .join(' ');
  }

  String _guessMime(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}

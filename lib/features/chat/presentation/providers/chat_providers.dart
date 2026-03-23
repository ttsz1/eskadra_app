import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/chat_repository.dart';
import '../../domain/models/chat_member.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_room.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(Supabase.instance.client);
});

final chatRoomsProvider = FutureProvider<List<ChatRoom>>((ref) async {
  return ref.watch(chatRepositoryProvider).getRooms();
});

final chatRoomProvider =
    FutureProvider.family<ChatRoom, String>((ref, roomId) async {
  return ref.watch(chatRepositoryProvider).getRoomById(roomId);
});

final availableChatUsersProvider = FutureProvider<List<ChatMember>>((ref) async {
  return ref.watch(chatRepositoryProvider).getAvailableUsers();
});

final chatSectionsProvider =
    FutureProvider<List<Map<String, String>>>((ref) async {
  return ref.watch(chatRepositoryProvider).getSections();
});

final roomMembersProvider =
    FutureProvider.family<List<ChatMember>, String>((ref, roomId) async {
  return ref.watch(chatRepositoryProvider).getRoomMembers(roomId);
});

final roomMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, roomId) {
  return ref.watch(chatRepositoryProvider).watchMessages(roomId);
});

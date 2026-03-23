import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/chat_room.dart';
import '../providers/chat_providers.dart';
import 'chat_room_screen.dart';
import 'create_chat_screen.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.watch(chatRoomsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Czat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: roomsAsync.when(
              data: (rooms) {
                if (rooms.isEmpty) {
                  return const Center(
                    child: Text('Brak dostępnych czatów.'),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: rooms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    return _RoomTile(room: room);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Błąd ładowania czatów: $error'),
              ),
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CreateChatScreen(),
                    ),
                  );
                  ref.invalidate(chatRoomsProvider);
                },
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text('Dodaj czat'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomTile extends ConsumerWidget {
  const _RoomTile({required this.room});

  final ChatRoom room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = <String>[
      if (room.isGlobal) 'wszyscy użytkownicy',
      if (room.isPrivate) 'prywatny',
      if (!room.isPrivate && !room.isGlobal) 'grupowy',
    ].join(' • ');

    return Card(
      child: ListTile(
        leading: _RoomAvatar(room: room),
        title: Text(room.name),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatRoomScreen(room: room),
            ),
          );
          ref.invalidate(chatRoomsProvider);
        },
      ),
    );
  }
}

class _RoomAvatar extends ConsumerWidget {
  const _RoomAvatar({required this.room});

  final ChatRoom room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (room.iconStoragePath == null || room.iconStoragePath!.isEmpty) {
      return CircleAvatar(
        child: Icon(room.isPrivate ? Icons.lock_outline : Icons.forum_outlined),
      );
    }

    return FutureBuilder<String>(
      future: ref.read(chatRepositoryProvider).buildAttachmentSignedUrl(
            room.iconStoragePath!,
          ),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircleAvatar(
            child: Icon(room.isPrivate ? Icons.lock_outline : Icons.forum_outlined),
          );
        }

        return CircleAvatar(
          backgroundImage: NetworkImage(snapshot.data!),
        );
      },
    );
  }
}

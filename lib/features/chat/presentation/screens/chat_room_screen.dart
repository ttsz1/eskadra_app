import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/chat_member.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/chat_room.dart';
import '../providers/chat_providers.dart';
import '../widgets/chat_message_bubble.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  const ChatRoomScreen({
    required this.room,
    super.key,
  });

  final ChatRoom room;

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<PlatformFile> _pendingFiles = [];
  bool _sending = false;

  String get _myUserId => Supabase.instance.client.auth.currentUser!.id;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.any,
    );

    if (result == null) return;

    setState(() {
      _pendingFiles.addAll(result.files);
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty && _pendingFiles.isEmpty) return;

    setState(() => _sending = true);

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            roomId: widget.room.id,
            content: text,
            files: List.of(_pendingFiles),
          );

      _controller.clear();
      setState(() {
        _pendingFiles.clear();
      });

      ref.invalidate(roomMessagesProvider(widget.room.id));

      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się wysłać wiadomości: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  Future<void> _deleteMessage(ChatMessage message) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Usuń wiadomość'),
            content: const Text(
              'Czy na pewno chcesz usunąć tę wiadomość? Załączniki tej wiadomości też zostaną usunięte.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Anuluj'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Usuń'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    try {
      await ref.read(chatRepositoryProvider).deleteMessage(
            roomId: widget.room.id,
            message: message,
          );

      ref.invalidate(roomMessagesProvider(widget.room.id));
      ref.invalidate(chatRoomsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się usunąć wiadomości: $e')),
      );
    }
  }

  Future<void> _showMembersDialog() async {
    final currentMembers = await ref.read(roomMembersProvider(widget.room.id).future);
    final allUsers = await ref.read(availableChatUsersProvider.future);

    if (!mounted) return;

    final selected = currentMembers.map((e) => e.userId).toSet();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Uczestnicy czatu'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: allUsers.map((ChatMember user) {
                      final isSelected = selected.contains(user.userId);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (_) {
                          setLocalState(() {
                            if (isSelected) {
                              selected.remove(user.userId);
                            } else {
                              selected.add(user.userId);
                            }
                          });
                        },
                        title: Text(user.displayName),
                        subtitle: user.email != null ? Text(user.email!) : null,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Anuluj'),
                ),
                FilledButton(
                  onPressed: () async {
                    final currentSet = currentMembers.map((e) => e.userId).toSet();
                    final toAdd = selected.difference(currentSet).toList();
                    final toRemove = currentSet.difference(selected).toList();

                    await ref.read(chatRepositoryProvider).addUsersToRoom(
                          roomId: widget.room.id,
                          userIds: toAdd,
                        );

                    for (final userId in toRemove) {
                      if (userId == _myUserId && widget.room.isPrivate) {
                        continue;
                      }
                      await ref.read(chatRepositoryProvider).removeUserFromRoom(
                            roomId: widget.room.id,
                            userId: userId,
                          );
                    }

                    ref.invalidate(roomMembersProvider(widget.room.id));

                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Zapisz'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(roomMessagesProvider(widget.room.id));
    final membersAsync = ref.watch(roomMembersProvider(widget.room.id));
    final roomAsync = ref.watch(chatRoomProvider(widget.room.id));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _RoomHeaderAvatar(roomAsync: roomAsync),
            const SizedBox(width: 12),
            Expanded(child: Text(widget.room.name)),
          ],
        ),
        actions: [
          if (!widget.room.isGlobal)
            IconButton(
              tooltip: 'Uczestnicy',
              onPressed: _showMembersDialog,
              icon: const Icon(Icons.group_outlined),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(32),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: membersAsync.when(
                data: (members) => Text(
                  widget.room.isGlobal
                      ? 'Wszyscy użytkownicy aplikacji'
                      : 'Uczestnicy: ${members.map((e) => e.displayName).join(', ')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Brak wiadomości.'),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message.senderId == _myUserId;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ChatMessageBubble(
                        message: message,
                        isMine: isMine,
                        formatTime: DateFormat('dd.MM.yyyy HH:mm').format,
                        buildSignedUrl: ref.read(chatRepositoryProvider).buildAttachmentSignedUrl,
                        onDelete: isMine ? () => _deleteMessage(message) : null,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Błąd wiadomości: $error'),
              ),
            ),
          ),
          if (_pendingFiles.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _pendingFiles.map((file) {
                  return Chip(
                    label: Text(file.name),
                    onDeleted: () {
                      setState(() {
                        _pendingFiles.remove(file);
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.all(12),
            child: Row(
              children: [
                IconButton(
                  onPressed: _sending ? null : _pickFiles,
                  icon: const Icon(Icons.attach_file),
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Napisz wiadomość...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _sending ? null : _send,
                  child: Text(_sending ? '...' : 'Wyślij'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomHeaderAvatar extends ConsumerWidget {
  const _RoomHeaderAvatar({required this.roomAsync});

  final AsyncValue<ChatRoom> roomAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return roomAsync.when(
      data: (room) {
        if (room.iconStoragePath == null || room.iconStoragePath!.isEmpty) {
          return CircleAvatar(
            radius: 16,
            child: Icon(
              room.isPrivate ? Icons.lock_outline : Icons.forum_outlined,
              size: 16,
            ),
          );
        }

        return FutureBuilder<String>(
          future: ref.read(chatRepositoryProvider).buildAttachmentSignedUrl(
                room.iconStoragePath!,
              ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return CircleAvatar(
                radius: 16,
                child: Icon(
                  room.isPrivate ? Icons.lock_outline : Icons.forum_outlined,
                  size: 16,
                ),
              );
            }

            return CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(snapshot.data!),
            );
          },
        );
      },
      loading: () => const CircleAvatar(
        radius: 16,
        child: Icon(Icons.forum_outlined, size: 16),
      ),
      error: (_, __) => const CircleAvatar(
        radius: 16,
        child: Icon(Icons.forum_outlined, size: 16),
      ),
    );
  }
}

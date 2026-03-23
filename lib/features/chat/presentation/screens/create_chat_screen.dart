import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/chat_member.dart';
import '../providers/chat_providers.dart';

class CreateChatScreen extends ConsumerStatefulWidget {
  const CreateChatScreen({super.key});

  @override
  ConsumerState<CreateChatScreen> createState() => _CreateChatScreenState();
}

class _CreateChatScreenState extends ConsumerState<CreateChatScreen> {
  final _nameController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  final Set<String> _selectedSectionIds = {};
  bool _isPrivate = true;
  bool _saving = false;
  PlatformFile? _selectedIconFile;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.image,
    );

    if (result == null || result.files.isEmpty) return;

    setState(() {
      _selectedIconFile = result.files.first;
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podaj nazwę czatu.')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await ref.read(chatRepositoryProvider).createRoom(
            name: _nameController.text.trim(),
            isPrivate: _isPrivate,
            userIds: _selectedUserIds.toList(),
            sectionIds: _selectedSectionIds.toList(),
            iconFile: _selectedIconFile,
          );

      if (!mounted) return;
      ref.invalidate(chatRoomsProvider);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się utworzyć czatu: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(availableChatUsersProvider);
    final sectionsAsync = ref.watch(chatSectionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nowy czat'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _saving ? null : _pickIcon,
                  child: CircleAvatar(
                    radius: 34,
                    child: _selectedIconFile == null
                        ? const Icon(Icons.add_photo_alternate_outlined, size: 28)
                        : ClipOval(
                            child: Image.memory(
                              _selectedIconFile!.bytes!,
                              width: 68,
                              height: 68,
                              fit: BoxFit.cover,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _saving ? null : _pickIcon,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Wybierz ikonę czatu'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nazwa czatu',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: _isPrivate,
            onChanged: (value) {
              setState(() => _isPrivate = value ?? true);
            },
            title: const Text('Prywatny'),
            subtitle: const Text(
              'Po zaznaczeniu czat widzą tylko dodani użytkownicy.',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          const Text(
            'Użytkownicy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          usersAsync.when(
            data: (users) => _UserSelector(
              users: users,
              selectedIds: _selectedUserIds,
              onToggle: (id) {
                setState(() {
                  if (_selectedUserIds.contains(id)) {
                    _selectedUserIds.remove(id);
                  } else {
                    _selectedUserIds.add(id);
                  }
                });
              },
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Text('Błąd użytkowników: $error'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sekcje',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          sectionsAsync.when(
            data: (sections) {
              if (sections.isEmpty) {
                return const Text('Brak sekcji.');
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: sections.map((section) {
                  final id = section['id']!;
                  final selected = _selectedSectionIds.contains(id);

                  return FilterChip(
                    selected: selected,
                    label: Text(section['name'] ?? 'Sekcja'),
                    onSelected: (_) {
                      setState(() {
                        if (selected) {
                          _selectedSectionIds.remove(id);
                        } else {
                          _selectedSectionIds.add(id);
                        }
                      });
                    },
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
            error: (error, _) => Text('Błąd sekcji: $error'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(_saving ? 'Zapisywanie...' : 'Utwórz czat'),
          ),
        ],
      ),
    );
  }
}

class _UserSelector extends StatelessWidget {
  const _UserSelector({
    required this.users,
    required this.selectedIds,
    required this.onToggle,
  });

  final List<ChatMember> users;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: users.map((user) {
        final selected = selectedIds.contains(user.userId);

        return CheckboxListTile(
          value: selected,
          onChanged: (_) => onToggle(user.userId),
          title: Text(user.displayName),
          subtitle: user.email != null ? Text(user.email!) : null,
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }
}

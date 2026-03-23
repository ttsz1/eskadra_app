class ChatRoom {
  const ChatRoom({
    required this.id,
    required this.name,
    required this.isPrivate,
    required this.isGlobal,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.iconStoragePath,
  });

  final String id;
  final String name;
  final bool isPrivate;
  final bool isGlobal;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? iconStoragePath;

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] as String,
      name: map['name'] as String? ?? '',
      isPrivate: map['is_private'] as bool? ?? false,
      isGlobal: map['is_global'] as bool? ?? false,
      createdBy: map['created_by'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      iconStoragePath: map['icon_storage_path'] as String?,
    );
  }
}
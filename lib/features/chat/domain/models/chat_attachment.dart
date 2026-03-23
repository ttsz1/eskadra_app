class ChatAttachment {
  const ChatAttachment({
    required this.id,
    required this.messageId,
    required this.roomId,
    required this.fileName,
    required this.storagePath,
    required this.createdBy,
    required this.createdAt,
    this.mimeType,
    this.fileSizeBytes,
  });

  final String id;
  final String messageId;
  final String roomId;
  final String fileName;
  final String storagePath;
  final String? mimeType;
  final int? fileSizeBytes;
  final String createdBy;
  final DateTime createdAt;

  factory ChatAttachment.fromMap(Map<String, dynamic> map) {
    return ChatAttachment(
      id: map['id'] as String,
      messageId: map['message_id'] as String,
      roomId: map['room_id'] as String,
      fileName: map['file_name'] as String? ?? '',
      storagePath: map['storage_path'] as String? ?? '',
      mimeType: map['mime_type'] as String?,
      fileSizeBytes: (map['file_size_bytes'] as num?)?.toInt(),
      createdBy: map['created_by'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
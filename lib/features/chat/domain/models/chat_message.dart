import 'chat_attachment.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.senderName,
    required this.attachments,
    this.editedAt,
  });

  final String id;
  final String roomId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime? editedAt;
  final String senderName;
  final List<ChatAttachment> attachments;

  factory ChatMessage.fromMap(
      Map<String, dynamic> map, {
        required String senderName,
        List<ChatAttachment> attachments = const [],
      }) {
    return ChatMessage(
      id: map['id'] as String,
      roomId: map['room_id'] as String,
      senderId: map['sender_id'] as String,
      content: map['content'] as String? ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      editedAt: map['edited_at'] != null
          ? DateTime.parse(map['edited_at'] as String)
          : null,
      senderName: senderName,
      attachments: attachments,
    );
  }
}
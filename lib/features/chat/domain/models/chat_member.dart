class ChatMember {
  const ChatMember({
    required this.userId,
    required this.displayName,
    required this.email,
  });

  final String userId;
  final String displayName;
  final String? email;

  factory ChatMember.fromProfileMap(Map<String, dynamic> map) {
    return ChatMember(
      userId: map['id'] as String,
      displayName: (map['full_name'] as String?)?.trim().isNotEmpty == true
          ? map['full_name'] as String
          : (map['email'] as String? ?? 'Użytkownik'),
      email: map['email'] as String?,
    );
  }
}
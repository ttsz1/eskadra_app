class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.createdBy,
    required this.authorName,
    required this.autoDeleteAt,
  });

  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final String createdBy;
  final String authorName;
  final DateTime? autoDeleteAt;

  bool get hasAutoDelete => autoDeleteAt != null;

  Announcement copyWith({
    String? id,
    String? title,
    String? content,
    DateTime? createdAt,
    String? createdBy,
    String? authorName,
    DateTime? autoDeleteAt,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      authorName: authorName ?? this.authorName,
      autoDeleteAt: autoDeleteAt ?? this.autoDeleteAt,
    );
  }

  factory Announcement.fromMap(Map<String, dynamic> map) {
    return Announcement(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      createdBy: map['created_by'] as String,
      authorName: 'Nieznany użytkownik',
      autoDeleteAt: map['auto_delete_at'] == null
          ? null
          : DateTime.parse(map['auto_delete_at'] as String).toLocal(),
    );
  }
}
class TaskNote {
  final String id;
  final String authorId;
  final DateTime createdAt;
  final String content;
  final List<String> mentionedPersonIds;

  const TaskNote({
    required this.id,
    required this.authorId,
    required this.createdAt,
    required this.content,
    this.mentionedPersonIds = const [],
  });
}
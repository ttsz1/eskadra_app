class TaskLogEntry {
  final String id;
  final DateTime createdAt;
  final String message;
  final String actorId;

  const TaskLogEntry({
    required this.id,
    required this.createdAt,
    required this.message,
    required this.actorId,
  });
}
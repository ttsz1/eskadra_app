enum TaskBoardView {
  myTasks,
  unassigned,
  mySection,
  all,
  archive,
}

extension TaskBoardViewX on TaskBoardView {
  String get label {
    switch (this) {
      case TaskBoardView.myTasks:
        return 'Moje';
      case TaskBoardView.unassigned:
        return 'Nieprzypisane';
      case TaskBoardView.mySection:
        return 'Mojej sekcji';
      case TaskBoardView.all:
        return 'Wszystkie';
      case TaskBoardView.archive:
        return 'Archiwum';
    }
  }
}
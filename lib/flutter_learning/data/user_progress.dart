import 'package:own/flutter_learning/flutter_data.dart';

class UserProgress {
  final String userName;
  Map<String, bool> completedTasks; // key = task name, value = done or not
  final Map<String, String> notes; // optional notes for each task

  UserProgress({
    required this.userName,
    Map<String, bool>? completedTasks,
    Map<String, String>? notes,
  }) : completedTasks = completedTasks ?? {},
       notes = notes ?? {};

  // Mark a task as completed
  void markComplete(String taskName) {
    completedTasks[taskName] = true;
  }

  // Add a personal note
  void addNote(String taskName, String note) {
    notes[taskName] = note;
  }

  // Calculate overall progress %
  double getProgressPercentage(List<ChecklistItem> checklist) {
    final total = checklist.length;
    final done = completedTasks.values.where((v) => v == true).length;
    return (done / total) * 100;
  }
}

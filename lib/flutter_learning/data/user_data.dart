import 'user_progress.dart';

final UserProgress dulshanProgress = UserProgress(userName: "Dulshan");
final UserProgress kavindiProgress = UserProgress(userName: "Kavindi");

// Example usage (optional)
void main() {
  // Mark some tasks as done for Dulshan
  dulshanProgress.markComplete("Install Flutter SDK");
  dulshanProgress.markComplete("Understand widget tree");

  // Add a note for Kavindi
  kavindiProgress.addNote(
    "Functions & return types",
    "Need to practice examples.",
  );
}

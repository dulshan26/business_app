class ChecklistItem {
  final String level;
  final String task;
  String status;
  String notes;

  ChecklistItem({
    required this.level,
    required this.task,
    this.status = "Not Started",
    this.notes = "",
  });
}

final List<ChecklistItem> flutterChecklist = [
  // 🩵 LEVEL 1 — Foundation (Basics)
  ChecklistItem(
    level: "Level 1 - Foundation (Basics)",
    task: "Variables & data types",
  ),
  ChecklistItem(
    level: "Level 1 - Foundation (Basics)",
    task: "Functions & return types",
  ),
  ChecklistItem(
    level: "Level 1 - Foundation (Basics)",
    task: "Null safety (?, !, ??)",
  ),
  ChecklistItem(
    level: "Level 1 - Foundation (Basics)",
    task: "Control flow (if, for, while)",
  ),
  ChecklistItem(
    level: "Level 1 - Foundation (Basics)",
    task: "Classes, constructors, objects",
  ),
  ChecklistItem(
    level: "Level 1 - Foundation (Basics)",
    task: "Lists, Maps, Sets",
  ),
  ChecklistItem(
    level: "Level 1 - Foundation (Basics)",
    task: "Future, async/await",
  ),
  ChecklistItem(
    level: "Level 1 - Foundation (Basics)",
    task: "Install Flutter SDK",
  ),
  ChecklistItem(
    level: "Level 1 - Foundation (Basics)",
    task: "Understand widget tree",
  ),
  ChecklistItem(
    level: "Level 1 - Foundation (Basics)",
    task: "main() and runApp()",
  ),
  ChecklistItem(
    level: "Level 1 - Foundation (Basics)",
    task: "StatelessWidget vs StatefulWidget",
  ),
  ChecklistItem(
    level: "Level 1 - Foundation (Basics)",
    task: "Hot reload & hot restart",
  ),
  ChecklistItem(
    level: "Level 1 - Foundation (Basics)",
    task: "Using MaterialApp, Scaffold, AppBar, Text, Container",
  ),
  ChecklistItem(
    level: "Level 1 - Foundation (Basics)",
    task: "Layouts: Row, Column, Stack, Expanded, Padding, Center",
  ),

  // 🧡 LEVEL 2 — UI Building & State Management
  ChecklistItem(
    level: "Level 2 - UI Building & State Management",
    task: "ListView, GridView, ListTile, Card, Image, Icon, Button",
  ),
  ChecklistItem(
    level: "Level 2 - UI Building & State Management",
    task:
        "Input widgets: TextField, TextEditingController, DropdownButton, Switch, Checkbox",
  ),
  ChecklistItem(
    level: "Level 2 - UI Building & State Management",
    task: "Navigator.push / pop",
  ),
  ChecklistItem(
    level: "Level 2 - UI Building & State Management",
    task: "Named routes",
  ),
  ChecklistItem(
    level: "Level 2 - UI Building & State Management",
    task: "go_router or auto_route setup",
  ),
  ChecklistItem(
    level: "Level 2 - UI Building & State Management",
    task: "setState()",
  ),
  ChecklistItem(
    level: "Level 2 - UI Building & State Management",
    task: "InheritedWidget basics",
  ),
  ChecklistItem(
    level: "Level 2 - UI Building & State Management",
    task: "Provider / Riverpod / GetX (pick one)",
  ),
  ChecklistItem(
    level: "Level 2 - UI Building & State Management",
    task: "Understand reactive UI",
  ),

  // 💚 LEVEL 3 — Firebase & Backend
  ChecklistItem(
    level: "Level 3 - Firebase & Backend",
    task: "Setup Firebase project",
  ),
  ChecklistItem(
    level: "Level 3 - Firebase & Backend",
    task: "Connect app to Firebase (Android + iOS)",
  ),
  ChecklistItem(
    level: "Level 3 - Firebase & Backend",
    task: "Authentication (Email, Google, etc.)",
  ),
  ChecklistItem(
    level: "Level 3 - Firebase & Backend",
    task: "Firestore CRUD operations",
  ),
  ChecklistItem(
    level: "Level 3 - Firebase & Backend",
    task: "Realtime Database (optional)",
  ),
  ChecklistItem(
    level: "Level 3 - Firebase & Backend",
    task: "Cloud Storage (upload images/files)",
  ),
  ChecklistItem(
    level: "Level 3 - Firebase & Backend",
    task: "Firebase Hosting (for Flutter Web)",
  ),
  ChecklistItem(
    level: "Level 3 - Firebase & Backend",
    task: "SharedPreferences",
  ),
  ChecklistItem(level: "Level 3 - Firebase & Backend", task: "Hive"),
  ChecklistItem(level: "Level 3 - Firebase & Backend", task: "sqflite"),
  ChecklistItem(
    level: "Level 3 - Firebase & Backend",
    task: "REST API using http",
  ),
  ChecklistItem(level: "Level 3 - Firebase & Backend", task: "JSON parsing"),
  ChecklistItem(level: "Level 3 - Firebase & Backend", task: "Error handling"),

  // 💙 LEVEL 4 — Advanced Flutter
  ChecklistItem(
    level: "Level 4 - Advanced Flutter",
    task: "MVC / MVVM / Clean Architecture basics",
  ),
  ChecklistItem(
    level: "Level 4 - Advanced Flutter",
    task: "Using Repository pattern",
  ),
  ChecklistItem(
    level: "Level 4 - Advanced Flutter",
    task: "Folder structure for large apps",
  ),
  ChecklistItem(
    level: "Level 4 - Advanced Flutter",
    task: "Custom themes & colors",
  ),
  ChecklistItem(
    level: "Level 4 - Advanced Flutter",
    task: "Responsive design (MediaQuery, LayoutBuilder)",
  ),
  ChecklistItem(
    level: "Level 4 - Advanced Flutter",
    task: "Animations (AnimatedContainer, Hero, Lottie)",
  ),
  ChecklistItem(level: "Level 4 - Advanced Flutter", task: "Unit testing"),
  ChecklistItem(level: "Level 4 - Advanced Flutter", task: "Widget testing"),
  ChecklistItem(
    level: "Level 4 - Advanced Flutter",
    task: "Performance optimization",
  ),

  // 💜 LEVEL 5 — Project & Deployment
  ChecklistItem(
    level: "Level 5 - Project & Deployment",
    task: "Plan and design app",
  ),
  ChecklistItem(
    level: "Level 5 - Project & Deployment",
    task: "Use Figma mockup or UI sketch",
  ),
  ChecklistItem(
    level: "Level 5 - Project & Deployment",
    task: "Implement full flow (Auth → Data → UI → Logic)",
  ),
  ChecklistItem(
    level: "Level 5 - Project & Deployment",
    task: "Debug and optimize",
  ),
  ChecklistItem(
    level: "Level 5 - Project & Deployment",
    task: "Generate APK / AAB for Android",
  ),
  ChecklistItem(
    level: "Level 5 - Project & Deployment",
    task: "Setup iOS release build",
  ),
  ChecklistItem(
    level: "Level 5 - Project & Deployment",
    task: "Publish to Play Store / App Store",
  ),
  ChecklistItem(
    level: "Level 5 - Project & Deployment",
    task: "Version control with Git & GitHub",
  ),
  ChecklistItem(
    level: "Level 5 - Project & Deployment",
    task: "Handle user feedback",
  ),
  ChecklistItem(
    level: "Level 5 - Project & Deployment",
    task: "Add updates & features",
  ),
];

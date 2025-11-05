import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:own/flutter_learning/flutter_data.dart';
import '../data/user_data.dart';
import '../data/user_progress.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  UserProgress currentUser = dulshanProgress;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void toggleUser() {
    setState(() {
      currentUser = (currentUser.userName == "Dulshan")
          ? kavindiProgress
          : dulshanProgress;
    });
    loadProgress();
  }

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    final doc = await _firestore
        .collection("users")
        .doc(currentUser.userName)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        currentUser.completedTasks = Map<String, bool>.from(
          data["completedTasks"] ?? {},
        );
      });
    }
  }

  Future<void> saveProgress() async {
    await _firestore.collection("users").doc(currentUser.userName).set({
      "completedTasks": currentUser.completedTasks,
    });
  }

  @override
  Widget build(BuildContext context) {
    final groupedByLevel = <String, List<ChecklistItem>>{};
    for (var item in flutterChecklist) {
      groupedByLevel.putIfAbsent(item.level, () => []).add(item);
    }

    final progress = currentUser.getProgressPercentage(flutterChecklist);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter Learning Progress"),
        actions: [
          IconButton(
            icon: const Icon(Icons.switch_account),
            onPressed: toggleUser,
            tooltip: "Switch User",
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    toggleUser();
                  },
                  child: Text(
                    "👤 ${currentUser.userName}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  "Progress: ${progress.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: groupedByLevel.entries.map((entry) {
                return ExpansionTile(
                  title: Text(
                    entry.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  children: entry.value.map((item) {
                    final isDone =
                        currentUser.completedTasks[item.task] ?? false;

                    return CheckboxListTile(
                      title: Text(item.task),
                      value: isDone,
                      onChanged: (value) {
                        setState(() {
                          currentUser.completedTasks[item.task] =
                              value ?? false;
                        });
                        saveProgress();
                      },
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

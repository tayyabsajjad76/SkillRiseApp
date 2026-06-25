import 'package:flutter/material.dart';

class TaskModel {
  final String title;
  final String description;
  final String course;
  bool isCompleted;
  final String dueDate;

  TaskModel({
    required this.title,
    required this.description,
    required this.course,
    required this.isCompleted,
    required this.dueDate,
  });
}

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final List<TaskModel> tasks = [
    TaskModel(title: 'Build a Todo App', description: 'Create a Flutter todo app with CRUD operations.', course: 'App Development', isCompleted: true, dueDate: 'Today'),
    TaskModel(title: 'HTML Form Practice', description: 'Design a contact form with validation.', course: 'Web Development', isCompleted: true, dueDate: 'Yesterday'),
    TaskModel(title: 'Python Data Cleaning', description: 'Clean a CSV dataset using pandas.', course: 'Data Science', isCompleted: false, dueDate: 'Today'),
    TaskModel(title: 'CSS Flexbox Layout', description: 'Build a responsive landing page.', course: 'Web Development', isCompleted: false, dueDate: 'Tomorrow'),
    TaskModel(title: 'Linear Regression Model', description: 'Train a model on the Boston housing dataset.', course: 'AI', isCompleted: false, dueDate: 'Mar 20'),
    TaskModel(title: 'Resume Draft', description: 'Write your first professional resume.', course: 'Career', isCompleted: false, dueDate: 'Mar 22'),
  ];

  @override
  Widget build(BuildContext context) {
    final pending = tasks.where((t) => !t.isCompleted).toList();
    final completed = tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Daily Tasks',
            style: TextStyle(
                color: Color(0xFF1E1B4B), fontWeight: FontWeight.bold)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(
                    '${completed.length}/${tasks.length} Done',
                    style: const TextStyle(
                        color: Color(0xFF4F46E5),
                        fontWeight: FontWeight.w600)),
              ),
            ),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pending.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Pending',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1B4B))),
            ),
            ...pending.map((t) => _TaskTile(
                task: t, onChanged: (v) => setState(() => t.isCompleted = v!))),
            const SizedBox(height: 20),
          ],
          if (completed.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text('Completed',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1B4B))),
            ),
            ...completed.map((t) => _TaskTile(
                task: t, onChanged: (v) => setState(() => t.isCompleted = v!))),
          ],
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  final ValueChanged<bool?> onChanged;

  const _TaskTile({required this.task, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: task.isCompleted
            ? Border.all(color: Colors.green.withOpacity(0.3))
            : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: onChanged,
          activeColor: const Color(0xFF4F46E5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: task.isCompleted
                ? Colors.grey[400]
                : const Color(0xFF1E1B4B),
            decoration:
            task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(task.description,
                style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null)),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(task.course,
                      style: const TextStyle(
                          color: Color(0xFF4F46E5), fontSize: 11)),
                ),
                const SizedBox(width: 8),
                Icon(Icons.schedule, size: 12, color: Colors.grey[400]),
                const SizedBox(width: 2),
                Text(task.dueDate,
                    style:
                    TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
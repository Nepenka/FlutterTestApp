import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const TaskManagerApp());
}

class Task {
  String id;
  String title;
  String description;
  DateTime deadline;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.deadline,
    this.isCompleted = false,
  });
}

class TaskManagerApp extends StatelessWidget {
  const TaskManagerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const TaskListScreen(),
    );
  }
}

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final List<Task> tasks = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return Task(
              id: doc.id,
              title: data['title'],
              description: data['description'],
              deadline: (data['deadline'] as Timestamp).toDate(),
              isCompleted: data['isCompleted'],
            );
          }).toList();

          // Сортируем задачи так, чтобы выполненные были в начале списка
          tasks.sort((a, b) => a.isCompleted == b.isCompleted
              ? 0
              : a.isCompleted
                  ? -1
                  : 1);

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];

              // Вычисляем количество дней до завершения задачи
              final daysRemaining =
                  task.deadline.difference(DateTime.now()).inDays;

              return ListTile(
                title: Text(
                  task.title,
                  // Применяем стиль зачеркивания, если задача выполнена
                  style: TextStyle(
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.description,
                      // Применяем стиль зачеркивания, если задача выполнена
                      style: TextStyle(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    Text(
                      'Days remaining: $daysRemaining',
                      style: TextStyle(
                        color: daysRemaining > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        FirebaseFirestore.instance
                            .collection('tasks')
                            .doc(task.id)
                            .delete();
                      },
                    ),
                    Checkbox(
                      value: task.isCompleted,
                      onChanged: (value) {
                        FirebaseFirestore.instance
                            .collection('tasks')
                            .doc(task.id)
                            .update({
                          'isCompleted': value,
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskAddScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TaskAddScreen extends StatefulWidget {
  const TaskAddScreen({Key? key}) : super(key: key);

  @override
  _TaskAddScreenState createState() => _TaskAddScreenState();
}

class _TaskAddScreenState extends State<TaskAddScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  late DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Deadline: '),
                TextButton(
                  onPressed: () async {
                    final DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null && pickedDate != _selectedDate) {
                      setState(() {
                        _selectedDate = pickedDate;
                      });
                    }
                  },
                  child: Text(
                    '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                final newTask = Task(
                  id: '',
                  title: _titleController.text,
                  description: _descriptionController.text,
                  deadline: _selectedDate,
                );
                FirebaseFirestore.instance.collection('tasks').add({
                  'title': newTask.title,
                  'description': newTask.description,
                  'deadline': newTask.deadline,
                  'isCompleted': newTask.isCompleted,
                }).then((value) {
                  Navigator.pop(context);
                }).catchError((error) {
                  print("Failed to add task: $error");
                  // Handle error
                });
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

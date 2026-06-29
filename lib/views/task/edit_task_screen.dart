import 'package:flutter/material.dart';

class EditTaskScreen extends StatelessWidget {
  final String taskId;

  const EditTaskScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Task')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Edit Task: $taskId', style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Update Changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 2,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final title = index == 0 ? 'New Task Assigned' : 'Project Invitation';
          final body = index == 0
              ? 'You have been assigned to Integrate Dio Client by Hoang Manager.'
              : 'You have been added to Spring Boot REST backend project.';
          return ListTile(
            leading: Icon(
              index == 0 ? Icons.assignment_ind : Icons.group_add,
              color: Colors.indigo,
            ),
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(body),
            trailing: const Text('10m ago', style: TextStyle(fontSize: 12, color: Colors.grey)),
          );
        },
      ),
    );
  }
}

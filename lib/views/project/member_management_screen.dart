import 'package:flutter/material.dart';

class MemberManagementScreen extends StatelessWidget {
  final String projectId;

  const MemberManagementScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Members')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Team Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const CircleAvatar(child: Text('H')),
            title: const Text('Hoang Team Lead (Manager)'),
            subtitle: const Text('owner_id'),
            trailing: Chip(
              label: const Text('Owner'),
              backgroundColor: Colors.blue.shade100,
            ),
          ),
          ListTile(
            leading: const CircleAvatar(child: Text('N')),
            title: const Text('Nguyen Van B (Member)'),
            subtitle: const Text('member@example.com'),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }
}

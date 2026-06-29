import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProjectListScreen extends StatelessWidget {
  const ProjectListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 2,
        itemBuilder: (context, index) {
          final title = index == 0 ? 'Smart Task App' : 'Spring Boot REST backend';
          return Card(
            child: ListTile(
              title: Text(title),
              subtitle: const Text('Tap to view project details'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/projects/proj_$index'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/projects/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

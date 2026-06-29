import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks list'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SearchBar(
                    hintText: 'Search tasks...',
                    elevation: WidgetStateProperty.all(1),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          final title = index == 0
              ? 'Integrate Dio Client'
              : index == 1
                  ? 'Implement Database Helper'
                  : 'Design Figma UI Wireframes';
          final priority = index == 0
              ? 'HIGH'
              : index == 1
                  ? 'MEDIUM'
                  : 'LOW';
          final status = index == 0
              ? 'TODO'
              : index == 1
                  ? 'IN_PROGRESS'
                  : 'DONE';

          return Card(
            child: ListTile(
              title: Text(title),
              subtitle: Text('Priority: $priority | Status: $status'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => context.push('/tasks/task_$index'),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/tasks/create'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

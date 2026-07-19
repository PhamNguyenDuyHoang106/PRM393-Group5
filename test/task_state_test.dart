import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_management/models/task.dart';
import 'package:smart_task_management/viewmodels/task_viewmodel.dart';

void main() {
  final tasks = [
    Task(
      id: '1',
      projectId: 'project-1',
      title: 'Design database schema',
      description: 'Create the local tables',
      priority: 'HIGH',
      status: 'TODO',
      createdAt: DateTime(2026),
    ),
    Task(
      id: '2',
      projectId: 'project-1',
      title: 'Build task screens',
      description: 'Implement Flutter views',
      priority: 'MEDIUM',
      status: 'DONE',
      createdAt: DateTime(2026),
    ),
  ];

  test('filters tasks by search query and status', () {
    final state = TaskState(
      tasks: tasks,
      searchQuery: 'screen',
      statusFilter: 'DONE',
    );

    expect(state.filteredTasks.map((task) => task.id), ['2']);
  });

  test('task JSON round-trip preserves nullable metadata', () {
    final source = tasks.first.copyWith(
      assignedTo: 'member-1',
      dueDate: DateTime.utc(2026, 7, 20),
    );

    final restored = Task.fromJson(source.toJson());

    expect(restored.id, source.id);
    expect(restored.assignedTo, 'member-1');
    expect(restored.dueDate, DateTime.utc(2026, 7, 20));
  });
}

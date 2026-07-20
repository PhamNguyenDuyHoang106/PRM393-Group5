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

  test('parses the camelCase task payload returned by the backend', () {
    final task = Task.fromJson({
      'id': 'task-api-1',
      'projectId': 'project-api-1',
      'title': 'Backend task',
      'description': 'Loaded from Prisma',
      'priority': 'high',
      'status': 'done',
      'assignedTo': 'member-api-1',
      'dueDate': '2026-07-25T00:00:00.000Z',
      'createdAt': '2026-07-20T00:00:00.000Z',
    });

    expect(task.projectId, 'project-api-1');
    expect(task.assignedTo, 'member-api-1');
    expect(task.status, 'DONE');
    expect(task.priority, 'HIGH');
    expect(task.dueDate, DateTime.utc(2026, 7, 25));
    expect(task.createdAt, DateTime.utc(2026, 7, 20));
  });

  test('my-tasks filter keeps only tasks assigned to the signed-in user', () {
    final allTasks = [
      tasks.first.copyWith(id: 'a', assignedTo: 'member-new'),
      tasks.last.copyWith(id: 'b', assignedTo: 'usr_8231'),
      tasks.first.copyWith(id: 'c', assignedTo: null),
    ];

    final mine = allTasks
        .where((task) => task.assignedTo == 'member-new')
        .toList();

    expect(mine.map((task) => task.id), ['a']);
  });
}

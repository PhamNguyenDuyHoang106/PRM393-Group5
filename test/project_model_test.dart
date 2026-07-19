import 'package:flutter_test/flutter_test.dart';
import 'package:smart_task_management/models/project.dart';

void main() {
  group('Project API parsing', () {
    test('accepts Prisma camelCase project fields', () {
      final project = Project.fromJson({
        'id': 'project-1',
        'name': 'Mobile App',
        'description': 'PRM393 project',
        'ownerId': 'owner-1',
        'createdAt': '2026-07-19T10:00:00.000Z',
      });

      expect(project.ownerId, 'owner-1');
      expect(project.createdAt, DateTime.utc(2026, 7, 19, 10));
    });

    test('normalizes nested Prisma members and includes the owner', () {
      final details = ProjectDetails.fromJson({
        'id': 'project-1',
        'name': 'Mobile App',
        'description': '',
        'ownerId': 'owner-1',
        'createdAt': '2026-07-19T10:00:00.000Z',
        'owner': {
          'id': 'owner-1',
          'name': 'Project Owner',
          'email': 'owner@example.com',
          'role': 'manager',
        },
        'members': [
          {
            'projectId': 'project-1',
            'userId': 'member-1',
            'user': {
              'id': 'member-1',
              'name': 'Team Member',
              'email': 'member@example.com',
              'role': 'member',
            },
          },
        ],
      });

      expect(details.members, hasLength(2));
      expect(details.members.first.id, 'owner-1');
      expect(details.members.last.email, 'member@example.com');
    });
  });
}

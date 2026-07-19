import '../../models/user.dart';
import '../../models/task.dart';

class PermissionDeniedException implements Exception {
  final String message;
  const PermissionDeniedException(this.message);

  @override
  String toString() => 'PermissionDeniedException: $message';
}

class PermissionService {
  PermissionService._();

  static void requireManager(User? user, {String action = 'perform this action'}) {
    if (user == null || !user.isManager) {
      throw PermissionDeniedException('Permission Denied: Only managers can $action.');
    }
  }

  static void requireTaskAccess(User? user, Task task, {String action = 'access this task'}) {
    if (user == null) {
      throw PermissionDeniedException('Permission Denied: You must be logged in.');
    }
    if (user.isManager) {
      return; // Manager can access/modify any task
    }
    if (task.assignedTo != user.id) {
      throw PermissionDeniedException('Permission Denied: You can only $action if it is assigned to you.');
    }
  }
}

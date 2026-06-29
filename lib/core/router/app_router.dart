import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import Screens (we will create these file skeletons in the next step)
import '../../views/auth/login_screen.dart';
import '../../views/auth/register_screen.dart';
import '../../views/auth/forgot_password_screen.dart';
import '../../views/auth/profile_screen.dart';
import '../../views/project/project_list_screen.dart';
import '../../views/project/create_project_screen.dart';
import '../../views/project/project_detail_screen.dart';
import '../../views/project/member_management_screen.dart';
import '../../views/task/task_list_screen.dart';
import '../../views/task/create_task_screen.dart';
import '../../views/task/task_detail_screen.dart';
import '../../views/task/edit_task_screen.dart';
import '../../views/dashboard/dashboard_screen.dart';
import '../../views/dashboard/statistics_screen.dart';
import '../../views/dashboard/notification_center_screen.dart';
import '../../views/dashboard/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    routes: [
      // Authentication Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main Scaffold Shell Routes (Using bottom navigation bar)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectListScreen(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TaskListScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationCenterScreen(),
          ),
        ],
      ),

      // Sub-screens routed on root navigator (push on top of bottom bar)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/stats',
        builder: (context, state) => const StatisticsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/projects/create',
        builder: (context, state) => const CreateProjectScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/projects/:projectId',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId'] ?? '';
          return ProjectDetailScreen(projectId: projectId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/projects/:projectId/members',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId'] ?? '';
          return MemberManagementScreen(projectId: projectId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/tasks/create',
        builder: (context, state) => const CreateTaskScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/tasks/:taskId',
        builder: (context, state) {
          final taskId = state.pathParameters['taskId'] ?? '';
          return TaskDetailScreen(taskId: taskId);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/tasks/:taskId/edit',
        builder: (context, state) {
          final taskId = state.pathParameters['taskId'] ?? '';
          return EditTaskScreen(taskId: taskId);
        },
      ),
    ],
  );
}

// Shell scaffold holding BottomNavigationBar
class AppShellScaffold extends StatelessWidget {
  final Widget child;

  const AppShellScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/projects')) return 1;
    if (location.startsWith('/tasks')) return 2;
    if (location.startsWith('/notifications')) return 3;
    return 0; // default '/'
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/');
        break;
      case 1:
        GoRouter.of(context).go('/projects');
        break;
      case 2:
        GoRouter.of(context).go('/tasks');
        break;
      case 3:
        GoRouter.of(context).go('/notifications');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open_outlined),
            activeIcon: Icon(Icons.folder),
            label: 'Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt_outlined),
            activeIcon: Icon(Icons.task_alt),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none_outlined),
            activeIcon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
        ],
      ),
    );
  }
}

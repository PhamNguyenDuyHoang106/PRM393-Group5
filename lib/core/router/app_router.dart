import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/providers.dart';

// Import Screens
import '../../views/auth/login_screen.dart';
import '../../views/auth/register_screen.dart';
import '../../views/auth/forgot_password_screen.dart';
import '../../views/auth/profile_screen.dart';
import '../../views/project/project_list_screen.dart';
import '../../views/project/create_project_screen.dart';
import '../../views/project/project_detail_screen.dart';
import '../../views/project/member_management_screen.dart';
import '../../views/project/edit_project_screen.dart';
import '../../views/task/task_list_screen.dart';
import '../../views/task/create_task_screen.dart';
import '../../views/task/task_detail_screen.dart';
import '../../views/task/edit_task_screen.dart';
import '../../views/dashboard/manager_dashboard_screen.dart';
import '../../views/dashboard/member_home_screen.dart';
import '../../views/dashboard/statistics_screen.dart';
import '../../views/dashboard/notification_center_screen.dart';
import '../../views/dashboard/settings_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

class RouterTransitionNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterTransitionNotifier(this._ref) {
    _ref.listen(authViewModelProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id ||
          previous?.isLoading != next.isLoading) {
        notifyListeners();
      }
    });
  }
}

final routerTransitionNotifierProvider = Provider<RouterTransitionNotifier>((
  ref,
) {
  return RouterTransitionNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerTransitionNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authViewModelProvider);
      final path = state.uri.path;
      final loggedIn = authState.user != null;

      debugPrint(
        '[Router] Redirect check: path = $path, loggedIn = $loggedIn, isLoading = ${authState.isLoading}',
      );

      // If auth state is loading on startup, do not redirect yet
      if (authState.isLoading) {
        debugPrint('[Router] AuthState is loading, holding redirect');
        return null;
      }

      final isAuthRoute =
          path == '/login' || path == '/register' || path == '/forgot-password';

      if (!loggedIn && !isAuthRoute) {
        debugPrint('[Router] Not logged in, redirecting to /login');
        return '/login';
      }
      if (loggedIn && isAuthRoute) {
        final isManager = authState.user!.isManager;
        final target = isManager ? '/manager/dashboard' : '/member/home';
        debugPrint('[Router] Logged in on auth route, redirecting to $target');
        return target;
      }

      if (loggedIn) {
        final isManager = authState.user!.isManager;

        // Define manager-only paths
        final isManagerOnlyPath =
            path.startsWith('/manager/dashboard') ||
            path.startsWith('/projects/create') ||
            (path.startsWith('/projects/') && path.endsWith('/members')) ||
            path.startsWith('/tasks/create') ||
            path.contains('/edit') ||
            path.startsWith('/stats');

        if (isManagerOnlyPath && !isManager) {
          debugPrint('[Router] Redirecting Member from Manager path: $path');
          return '/member/home';
        }

        // Define member-only paths
        if (path == '/member/home' && isManager) {
          debugPrint('[Router] Redirecting Manager from Member path: $path');
          return '/manager/dashboard';
        }

        // Redirect root '/' based on role
        if (path == '/') {
          final target = isManager ? '/manager/dashboard' : '/member/home';
          debugPrint('[Router] Redirecting root / to $target');
          return target;
        }
      }

      debugPrint('[Router] No redirect needed for path: $path');
      return null;
    },
    routes: [
      // Authentication Routes
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
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
            path: '/manager/dashboard',
            builder: (context, state) => const ManagerDashboardScreen(),
          ),
          GoRoute(
            path: '/member/home',
            builder: (context, state) => const MemberHomeScreen(),
          ),
          GoRoute(
            path: '/projects',
            builder: (context, state) => const ProjectListScreen(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => TaskListScreen(
              projectId: state.uri.queryParameters['projectId'],
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Sub-screens routed on root navigator (push on top of bottom bar)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/notifications',
        builder: (context, state) => const NotificationCenterScreen(),
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
        path: '/projects/:projectId/edit',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId'] ?? '';
          return EditProjectScreen(projectId: projectId);
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
});

// Shell scaffold holding BottomNavigationBar
class AppShellScaffold extends StatelessWidget {
  final Widget child;

  const AppShellScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/projects')) return 1;
    if (location.startsWith('/tasks')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0; // default represents dashboard routes
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
        GoRouter.of(context).go('/profile');
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
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

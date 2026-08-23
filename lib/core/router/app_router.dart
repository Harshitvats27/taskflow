import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/auth_notifier.dart';
import '../../presentation/providers/auth_state.dart';
import '../../presentation/screens/splash_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/register_screen.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/projects_screen.dart';
import '../../presentation/screens/project_details_screen.dart';
import '../../presentation/screens/create_edit_project_screen.dart';
import '../../presentation/screens/task_list_screen.dart';
import '../../presentation/screens/task_details_screen.dart';
import '../../presentation/screens/create_edit_task_screen.dart';
import '../../presentation/screens/profile_screen.dart';
import '../../presentation/screens/notifications_screen.dart';

// ─────────────────────────────────────────────
// Bridge: Riverpod → GoRouter refreshListenable
// ─────────────────────────────────────────────

/// A [ChangeNotifier] that GoRouter uses via [refreshListenable].
/// It is kept alive for the lifetime of [routerProvider] and notifies
/// GoRouter every time the Riverpod auth state changes, causing the router
/// to re-evaluate its [redirect] callback.
class _AuthChangeNotifier extends ChangeNotifier {
  void update() => notifyListeners();
}

// ─────────────────────────────────────────────
// Router provider
// ─────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthChangeNotifier();

  // Forward every auth state change to GoRouter so it re-checks redirect.
  ref.listen<AuthState>(authNotifierProvider, (_, __) => authNotifier.update());
  ref.onDispose(authNotifier.dispose);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: authNotifier,

    // ─── Route Guard ───────────────────────────────────────────────
    // Returns a redirect path or null (allow navigation).
    // Evaluated on every navigation AND every time [authNotifier] fires.
    redirect: (BuildContext context, GoRouterState routerState) {
      final auth = ref.read(authNotifierProvider);
      final loc = routerState.uri.path;

      final isLoading = auth.isLoading; // initial or loading
      final isAuthenticated = auth.isAuthenticated;

      final onSplash = loc == '/';
      final onAuthRoute = loc == '/login' || loc == '/register';

      // 1. During startup (initial/loading) stay on splash — don't redirect
      //    anything else yet; wait for checkSession to finish.
      if (isLoading) return onSplash ? null : '/';

      // 2. Unauthenticated: only /login and /register are accessible.
      if (!isAuthenticated && !onAuthRoute) return '/login';

      // 3. Authenticated: skip splash/login/register.
      if (isAuthenticated && (onAuthRoute || onSplash)) return '/home';

      return null; // no redirect needed
    },

    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, state) => LoginScreen(
          registrationSuccess: state.extra == 'registration_success',
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectsScreen(),
      ),
      GoRoute(
        path: '/projects/create',
        builder: (context, state) => const CreateEditProjectScreen(),
      ),
      GoRoute(
        path: '/projects/:projectId',
        builder: (_, state) => ProjectDetailsScreen(
          projectId: state.pathParameters['projectId']!,
        ),
      ),
      GoRoute(
        path: '/projects/:projectId/tasks',
        builder: (_, state) => TaskListScreen(
          projectId: state.pathParameters['projectId'],
        ),
      ),
      GoRoute(
        path: '/tasks',
        builder: (_, __) => const TaskListScreen(),
      ),
      GoRoute(
        path: '/tasks/:taskId',
        builder: (_, state) => TaskDetailsScreen(
          taskId: state.pathParameters['taskId']!,
        ),
      ),
      GoRoute(
        path: '/task/create',
        builder: (_, __) => const CreateEditTaskScreen(),
      ),
      GoRoute(
        path: '/tasks/:taskId/edit',
        builder: (_, state) => CreateEditTaskScreen(
          taskId: state.pathParameters['taskId'],
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'providers/admin_auth_provider.dart';
import 'shared/theme/admin_theme.dart';
import 'shared/widgets/sidebar_nav.dart';

// Screens
import 'features/auth/login_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/providers/pending_providers_screen.dart';
import 'features/providers/all_providers_screen.dart';
import 'features/users/users_screen.dart';
import 'features/chats/chats_monitor_screen.dart';
import 'features/notifications/broadcast_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/categories/screens/category_management_screen.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AdminAuthProvider>(context);

    final GoRouter router = GoRouter(
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isLoggedIn = authProvider.isAuthenticated;
        final isLoginRoute = state.matchedLocation == '/login';

        if (!isLoggedIn && !isLoginRoute) return '/login';
        if (isLoggedIn && isLoginRoute) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => SidebarNav(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: '/pending-providers',
              builder: (context, state) => const PendingProvidersScreen(),
            ),
            GoRoute(
              path: '/providers',
              builder: (context, state) => const AllProvidersScreen(),
            ),
            GoRoute(
              path: '/users',
              builder: (context, state) => const UsersScreen(),
            ),
            GoRoute(
              path: '/chats',
              builder: (context, state) => const ChatsMonitorScreen(),
            ),
            GoRoute(
              path: '/broadcast',
              builder: (context, state) => const BroadcastScreen(),
            ),
            GoRoute(
              path: '/reports',
              builder: (context, state) => const ReportsScreen(),
            ),
            GoRoute(
              path: '/categories',
              builder: (context, state) => const CategoryManagementScreen(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Khuzdar Admin',
      theme: AdminTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

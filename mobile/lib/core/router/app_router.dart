import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/auth/presentation/auth_state.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/technicians/presentation/screens/categories_screen.dart';
import '../../features/technicians/presentation/screens/home_screen.dart';
import '../../features/technicians/presentation/screens/technician_directory_screen.dart';
import '../../features/technicians/presentation/screens/technician_profile_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/requests/presentation/screens/request_list_screen.dart';
import '../../features/requests/presentation/screens/request_detail_screen.dart';
import '../../features/requests/presentation/screens/create_request_screen.dart';
import '../../features/technician_dashboard/presentation/screens/technician_dashboard_screen.dart';
import '../../features/client_dashboard/presentation/screens/client_dashboard_screen.dart';
import '../../features/technicians/presentation/screens/technician_onboarding_screen.dart';
import '../../features/reviews/presentation/screens/create_review_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/admin/presentation/screens/admin_categories_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_reports_screen.dart';
import '../../features/admin/presentation/screens/admin_technicians_screen.dart';
import '../../features/admin/presentation/screens/admin_users_screen.dart';
import '../../features/admin/presentation/screens/pending_verifications_screen.dart';
import '../../features/auth/domain/user_role.dart';
import '../../shared/widgets/admin_shell.dart';
import '../../shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _RiverpodRefreshStream(
      ref.watch(authNotifierProvider.notifier).stream,
    ),
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final loc = state.matchedLocation;
      final isAuthPage = loc == '/login' || loc == '/register';
      final isSplash = loc == '/';

      // Stay on splash while loading
      if (authState.isLoading || authState.status == AuthStatus.initial) {
        return null;
      }

      if (authState.isAuthenticated) {
        final role = authState.user?.role;
        final isAdmin = role == UserRole.admin;
        final isTechnician = role == UserRole.technician;

        // Redirect away from auth/splash after login
        if (isAuthPage || isSplash) {
          if (isAdmin) return '/admin/dashboard';
          if (isTechnician) return '/technician/dashboard';
          return '/home';
        }
        
        // Enforce role boundaries
        if (loc.startsWith('/admin') && !isAdmin) return '/home';
        if (loc.startsWith('/technician/dashboard') && !isTechnician) return '/home';
        if (loc == '/home' && (isTechnician || isAdmin)) {
          return isAdmin ? '/admin/dashboard' : '/technician/dashboard';
        }
      } else {
        // Unauthenticated: allow public-access routes
        const publicPrefixes = [
          '/login',
          '/register',
          '/home',
          '/directory',
          '/technicians/',
        ];
        if (isSplash) return null;
        final isPublic = publicPrefixes.any((p) => loc.startsWith(p));
        if (!isPublic) return '/login';
      }
      return null;
    },
    routes: [
      // ─── Splash & Auth ─────────────────────────────────────────────────────
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ─── Technician Onboarding (full-screen, outside shell) ────────────────
      GoRoute(
        path: '/technician/onboarding',
        builder: (context, state) => const TechnicianOnboardingScreen(),
      ),

      // ─── Full-screen overlay routes (no shell needed) ──────────────────────
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/requests/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RequestDetailScreen(requestId: id);
        },
        routes: [
          GoRoute(
            path: 'review',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return CreateReviewScreen(requestId: id);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/technicians/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TechnicianProfileScreen(technicianId: id);
        },
      ),
      GoRoute(
        path: '/technicians/:id/request',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CreateRequestScreen(technicianId: id);
        },
      ),

      // ─── Client Shell — 4-tab bottom nav ──────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          // Tab 0: Home (search / directory)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/categories',
              builder: (context, state) => const CategoriesScreen(),
            ),
            GoRoute(
              path: '/directory',
              builder: (context, state) => const TechnicianDirectoryScreen(),
            ),
            GoRoute(
              path: '/client/dashboard',
              builder: (context, state) => const ClientDashboardScreen(),
            ),
          ]),
          // Tab 1: Requests
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/requests',
              builder: (context, state) => const RequestListScreen(),
            ),
          ]),
          // Tab 2: Favorites
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/favorites',
              builder: (context, state) => const FavoritesScreen(),
            ),
          ]),
          // Tab 3: Profile
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => const EditProfileScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),

      // ─── Technician Shell — 4-tab bottom nav ──────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) =>
            TechnicianShell(navigationShell: shell),
        branches: [
          // Tab 0: Dashboard
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/technician/dashboard',
              builder: (context, state) => const TechnicianDashboardScreen(),
            ),
          ]),
          // Tab 1: Incoming Requests (reuses RequestListScreen)
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/technician/requests',
              builder: (context, state) => const RequestListScreen(),
            ),
          ]),
          // Tab 2: Notifications
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/technician/notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
          ]),
          // Tab 3: Profile
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/technician/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (context, state) => const TechnicianOnboardingScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),

      // ─── Admin Shell — 3-tab bottom nav ─────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AdminShell(navigationShell: shell),
        branches: [
          // Tab 0: Admin Dashboard
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/dashboard',
              builder: (context, state) => const AdminDashboardScreen(),
              routes: [
                GoRoute(
                  path: 'users',
                  builder: (context, state) => const AdminUsersScreen(),
                ),
                GoRoute(
                  path: 'technicians',
                  builder: (context, state) => const AdminTechniciansScreen(),
                ),
                GoRoute(
                  path: 'categories',
                  builder: (context, state) => const AdminCategoriesScreen(),
                ),
                GoRoute(
                  path: 'reports',
                  builder: (context, state) => const AdminReportsScreen(),
                ),
              ],
            ),
          ]),
          // Tab 1: Pending Verifications
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/verifications',
              builder: (context, state) => const PendingVerificationsScreen(),
            ),
          ]),
          // Tab 2: Profile
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/admin/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              const Text(
                'Page introuvable',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                state.matchedLocation,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    ),
  );
});

class _RiverpodRefreshStream extends ChangeNotifier {
  _RiverpodRefreshStream(Stream stream) {
    stream.listen((_) => notifyListeners());
  }
}

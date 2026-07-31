import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';

/// The persistent bottom navigation shell wrapping all main screens.
/// Uses [StatefulShellRoute] from go_router so each tab maintains its own
/// navigation stack and scroll position.
class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);

    // Determine which tab set to render based on the current branch
    // Branch 0 → Home/Dashboard, Branch 1 → Requests, Branch 2 → Notifications,
    // Branch 3 → Profile  (client gets Favorites as branch 3, Profile as 4)
    // We use a single shell for both roles; the router controls which screens
    // each branch maps to per role.

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _buildBottomNav(context, unreadCount),
    );
  }

  Widget _buildBottomNav(BuildContext context, int unreadCount) {
    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) {
        navigationShell.goBranch(
          index,
          // Stay on the current page if re-tapping the active tab
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Accueil',
        ),
        const NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          selectedIcon: Icon(Icons.assignment_rounded),
          label: 'Demandes',
        ),
        const NavigationDestination(
          icon: Icon(Icons.favorite_border_rounded),
          selectedIcon: Icon(Icons.favorite_rounded),
          label: 'Favoris',
        ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profil',
        ),
      ],
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primarySubtle,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    );
  }
}

/// Technician variant with 3 tabs: Dashboard / Requests / Profile
class TechnicianShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const TechnicianShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Tableau',
          ),
          const NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Demandes',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(fontSize: 10),
              ),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: unreadCount > 0,
              label: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(fontSize: 10),
              ),
              child: const Icon(Icons.notifications_rounded),
            ),
            label: 'Notifs',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primarySubtle,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}

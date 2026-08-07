import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import '../../features/notifications/presentation/providers/notifications_provider.dart';

/// The persistent bottom navigation shell wrapping all main screens.
class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _buildBottomNav(context, unreadCount),
    );
  }

  Widget _buildBottomNav(BuildContext context, int unreadCount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NavigationBar(
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: (index) {
        navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        );
      },
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: const Icon(Icons.home_rounded),
          label: context.tr('nav_home'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.assignment_outlined),
          selectedIcon: const Icon(Icons.assignment_rounded),
          label: context.tr('nav_requests'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.favorite_border_rounded),
          selectedIcon: const Icon(Icons.favorite_rounded),
          label: context.tr('nav_favorites'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline_rounded),
          selectedIcon: const Icon(Icons.person_rounded),
          label: context.tr('nav_profile'),
        ),
      ],
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      indicatorColor: isDark ? AppColors.darkPrimarySubtle : AppColors.primarySubtle,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    );
  }
}

/// Technician variant with 4 tabs: Dashboard / Requests / Notifications / Profile
class TechnicianShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const TechnicianShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: context.tr('nav_dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.assignment_outlined),
            selectedIcon: const Icon(Icons.assignment_rounded),
            label: context.tr('nav_requests'),
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
            label: context.tr('nav_notifs'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: const Icon(Icons.person_rounded),
            label: context.tr('nav_profile'),
          ),
        ],
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        indicatorColor: isDark ? AppColors.darkPrimarySubtle : AppColors.primarySubtle,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}

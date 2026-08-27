import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../../../requests/presentation/providers/requests_providers.dart';
import '../../../../shared/models/service_request.dart';

class ClientDashboardScreen extends ConsumerWidget {
  const ClientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final requestsAsync = ref.watch(requestListProvider);
    final favoritesAsync = ref.watch(favoriteTechniciansProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Compute active request count (unassigned + assigned + in_progress)
    final activeRequests = requestsAsync.valueOrNull?.where((r) {
          return r.status == RequestStatus.unassigned ||
              r.status == RequestStatus.assigned ||
              r.status == RequestStatus.inProgress;
        }).length ??
        0;
    final completedRequests =
        requestsAsync.valueOrNull?.where((r) => r.status == RequestStatus.completed).length ?? 0;
    final favoritesCount = favoritesAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('dashboard_title')),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        unreadCount > 9 ? '9+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              ref.read(requestListProvider.notifier).fetchRequests(),
              ref.read(favoriteTechniciansProvider.notifier).fetchFavorites(),
              ref.read(notificationsNotifierProvider.notifier).fetch(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Greeting ─────────────────────────────────────────────
                Text(
                  user != null
                      ? '${context.tr('hello_user')}${user.fullName.split(' ').first} 👋'
                      : context.tr('hello_default'),
                  style: AppTypography.heading2,
                ),
                const SizedBox(height: 4),
                Text(
                  context.tr('login_welcome'),
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 24),

                // ─── Stats row ────────────────────────────────────────────
                Text(context.tr('dashboard_title'), style: AppTypography.heading3),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: Icons.assignment_outlined,
                        label: context.tr('status_unassigned'),
                        value: '$activeRequests',
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: Icons.check_circle_outline_rounded,
                        label: context.tr('completed_requests'),
                        value: '$completedRequests',
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context: context,
                        icon: Icons.favorite_border_rounded,
                        label: context.tr('nav_favorites'),
                        value: '$favoritesCount',
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ─── Quick actions ────────────────────────────────────────
                Text(context.tr('app_title'), style: AppTypography.heading3),
                const SizedBox(height: 12),

                _buildActionCard(
                  context: context,
                  title: context.tr('directory_title'),
                  subtitle: context.tr('search_placeholder'),
                  icon: Icons.search_rounded,
                  color: AppColors.primary,
                  onTap: () => context.go('/home'),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  context: context,
                  title: context.tr('my_requests'),
                  subtitle: context.tr('incoming_requests'),
                  icon: Icons.assignment_outlined,
                  color: AppColors.accent,
                  badge: activeRequests > 0 ? '$activeRequests ${context.tr('status_in_progress')}' : null,
                  onTap: () => context.push('/requests'),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  context: context,
                  title: context.tr('nav_favorites'),
                  subtitle: context.tr('recommended_artisans'),
                  icon: Icons.favorite_border_rounded,
                  color: AppColors.error,
                  badge: favoritesCount > 0 ? '$favoritesCount' : null,
                  onTap: () => context.push('/favorites'),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  context: context,
                  title: context.tr('notifications_title'),
                  subtitle: context.tr('no_notifications_desc'),
                  icon: Icons.notifications_outlined,
                  color: unreadCount > 0 ? AppColors.warning : AppColors.textSecondary,
                  badge: unreadCount > 0 ? '$unreadCount' : null,
                  onTap: () => context.push('/notifications'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? badge,
  }) {
    return Card(
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

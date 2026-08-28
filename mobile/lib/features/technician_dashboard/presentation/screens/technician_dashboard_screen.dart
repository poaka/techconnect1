import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../../../notifications/presentation/providers/notifications_provider.dart';
import '../providers/technician_stats_provider.dart';

class TechnicianDashboardScreen extends ConsumerStatefulWidget {
  const TechnicianDashboardScreen({super.key});

  @override
  ConsumerState<TechnicianDashboardScreen> createState() =>
      _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState
    extends ConsumerState<TechnicianDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final statsAsync = ref.watch(technicianStatsProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final profile = user?.technicianProfile;
    final isProfileIncomplete = profile == null ||
        profile.cityId == null ||
        profile.categories.isEmpty;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          context.tr('dashboard_title'),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => context.push('/technician/notifications'),
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
            onPressed: () => context.push('/technician/profile'),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(technicianStatsProvider);
            await ref.read(technicianStatsProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Greeting ──────────────────────────────────────────────
                Text(
                  user != null
                      ? '${context.tr('hello_user')}${user.fullName.split(' ').first} 👋'
                      : context.tr('dashboard_greeting'),
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('overview'),
                  style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // ─── Profile incomplete banner ─────────────────────────────
                if (isProfileIncomplete) ...[
                  _buildIncompleteProfileBanner(context),
                  const SizedBox(height: 20),
                ],

                // ─── Verification status ───────────────────────────────────
                statsAsync.when(
                  loading: () => _buildStatsLoading(),
                  error: (_, __) => _buildStatsError(
                    () => ref.invalidate(technicianStatsProvider),
                  ),
                  data: (stats) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Verified + Availability chip row
                      Row(
                        children: [
                          _buildBadge(
                            icon: stats.verified
                                ? Icons.verified_rounded
                                : Icons.pending_outlined,
                            label: stats.verified ? context.tr('verified_profile') : context.tr('pending_requests'),
                            color: stats.verified ? AppColors.success : AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            icon: Icons.circle,
                            label: _availabilityLabel(context, stats.availability),
                            color: _availabilityColor(stats.availability),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ─── Stats grid ───────────────────────────────────────
                      Text(context.tr('dashboard_title'), style: AppTypography.heading3),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.25,
                        children: [
                          _buildStatCard(
                            icon: Icons.schedule_rounded,
                            label: context.tr('pending_requests'),
                            value: '${stats.pendingRequestsCount}',
                            color: Colors.orange,
                          ),
                          _buildStatCard(
                            icon: Icons.check_circle_outline_rounded,
                            label: context.tr('completed_requests'),
                            value: '${stats.completedJobsCount}',
                            color: AppColors.success,
                          ),
                          _buildStatCard(
                            icon: Icons.star_rounded,
                            label: context.tr('average_rating'),
                            value: stats.ratingCount > 0
                                ? stats.ratingAvg.toStringAsFixed(1)
                                : '—',
                            color: AppColors.accentGold,
                          ),
                          _buildStatCard(
                            icon: Icons.assignment_outlined,
                            label: context.tr('total_requests'),
                            value: '${stats.totalRequestsCount}',
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ─── Quick actions ─────────────────────────────────────────
                Text(context.tr('quick_actions'), style: AppTypography.heading3),
                const SizedBox(height: 12),

                _buildActionCard(
                  context: context,
                  title: context.tr('new_offers'),
                  subtitle: context.tr('new_offers_desc'),
                  icon: Icons.new_releases_outlined,
                  color: Colors.orange,
                  onTap: () => context.push('/technician/offers'),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  context: context,
                  title: context.tr('my_jobs'),
                  subtitle: context.tr('my_jobs_desc'),
                  icon: Icons.assignment_outlined,
                  color: AppColors.primary,
                  onTap: () => context.push('/technician/requests'),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  context: context,
                  title: context.tr('profile_settings'),
                  subtitle: context.tr('profile_settings_desc'),
                  icon: Icons.settings_outlined,
                  color: Colors.grey.shade600,
                  onTap: () => context.push('/technician/profile'),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  context: context,
                  title: context.tr('technician_profile'),
                  subtitle: context.tr('update_info'),
                  icon: Icons.person_search_outlined,
                  color: AppColors.accent,
                  onTap: () => context.push('/technician/onboarding'),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  context: context,
                  title: context.tr('availability_status'),
                  subtitle: context.tr('availability_desc'),
                  icon: Icons.toggle_on_outlined,
                  color: AppColors.success,
                  onTap: () => _showAvailabilityDialog(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  String _availabilityLabel(BuildContext context, String availability) {
    switch (availability) {
      case 'available':
        return context.tr('availability_available');
      case 'busy':
        return context.tr('availability_busy');
      case 'offline':
      default:
        return context.tr('availability_offline');
    }
  }

  Color _availabilityColor(String availability) {
    switch (availability) {
      case 'available':
        return AppColors.success;
      case 'busy':
        return AppColors.warning;
      case 'offline':
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.08), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsLoading() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.25,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: AppColors.border.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }

  Widget _buildStatsError(VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('loading_error'),
              style: const TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(context.tr('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildIncompleteProfileBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.tr('incomplete_profile_title'),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('incomplete_profile_desc'),
            style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => context.push('/technician/onboarding'),
              child: Text(
                context.tr('complete_now'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
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
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 24, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAvailabilityDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AvailabilitySheet(onChanged: () {
        ref.invalidate(technicianStatsProvider);
      }),
    );
  }
}

// ─── Availability bottom sheet ────────────────────────────────────────────────

class _AvailabilitySheet extends ConsumerStatefulWidget {
  final VoidCallback onChanged;
  const _AvailabilitySheet({required this.onChanged});

  @override
  ConsumerState<_AvailabilitySheet> createState() => _AvailabilitySheetState();
}

class _AvailabilitySheetState extends ConsumerState<_AvailabilitySheet> {
  bool _isLoading = false;

  Future<void> _setAvailability(String value) async {
    setState(() => _isLoading = true);
    try {
      final dioClient = ref.read(dioClientProvider);
      await dioClient.put(
        '/technicians/me/availability',
        data: {'availability': value},
      );
      widget.onChanged();
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour de la disponibilité.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      (
        value: 'available',
        label: context.tr('availability_available'),
        subtitle: context.tr('avail_sub_available'),
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
      ),
      (
        value: 'busy',
        label: context.tr('availability_busy'),
        subtitle: context.tr('avail_sub_busy'),
        color: AppColors.warning,
        icon: Icons.pending_rounded,
      ),
      (
        value: 'offline',
        label: context.tr('availability_offline'),
        subtitle: context.tr('avail_sub_offline'),
        color: AppColors.textSecondary,
        icon: Icons.cancel_rounded,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('availability_status'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else
            ...options.map(
              (opt) => ListTile(
                leading: Icon(opt.icon, color: opt.color),
                title: Text(opt.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(opt.subtitle),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onTap: () => _setAvailability(opt.value),
              ),
            ),
        ],
      ),
    );
  }
}

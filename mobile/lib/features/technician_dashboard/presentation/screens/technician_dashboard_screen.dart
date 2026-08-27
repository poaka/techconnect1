import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
        title: const Text('Tableau de Bord'),
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
                      ? 'Bonjour, ${user.fullName.split(' ').first} 👋'
                      : 'Bonjour ! 👋',
                  style: AppTypography.heading2,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Voici un résumé de votre activité.',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: 20),

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
                            label: stats.verified ? 'Vérifié' : 'En attente de vérification',
                            color: stats.verified ? AppColors.success : AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            icon: Icons.circle,
                            label: _availabilityLabel(stats.availability),
                            color: _availabilityColor(stats.availability),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ─── Stats grid ───────────────────────────────────────
                      Text('Statistiques', style: AppTypography.heading3),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard(
                            icon: Icons.schedule_rounded,
                            label: 'En attente',
                            value: '${stats.pendingRequestsCount}',
                            color: Colors.orange,
                          ),
                          _buildStatCard(
                            icon: Icons.check_circle_outline_rounded,
                            label: 'Terminées',
                            value: '${stats.completedJobsCount}',
                            color: AppColors.success,
                          ),
                          _buildStatCard(
                            icon: Icons.star_rounded,
                            label: 'Note moyenne',
                            value: stats.ratingCount > 0
                                ? stats.ratingAvg.toStringAsFixed(1)
                                : '—',
                            color: AppColors.accentGold,
                          ),
                          _buildStatCard(
                            icon: Icons.assignment_outlined,
                            label: 'Total demandes',
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
                Text('Actions rapides', style: AppTypography.heading3),
                const SizedBox(height: 12),

                _buildActionCard(
                  context: context,
                  title: 'Nouvelles missions',
                  subtitle: 'Voir les offres disponibles',
                  icon: Icons.new_releases_outlined,
                  color: Colors.orange,
                  onTap: () => context.push('/technician/offers'),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  context: context,
                  title: 'Demandes en cours',
                  subtitle: 'Gérer vos chantiers acceptés',
                  icon: Icons.assignment_outlined,
                  color: AppColors.primary,
                  onTap: () => context.push('/technician/requests'),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  context: context,
                  title: 'Mon Profil Artisan',
                  subtitle: 'Mettre à jour vos informations',
                  icon: Icons.person_search_outlined,
                  color: AppColors.accent,
                  onTap: () => context.push('/technician/onboarding'),
                ),
                const SizedBox(height: 12),
                _buildActionCard(
                  context: context,
                  title: 'Changer ma disponibilité',
                  subtitle: 'Indiquer si vous êtes disponible',
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

  String _availabilityLabel(String availability) {
    switch (availability) {
      case 'available':
        return 'Disponible';
      case 'busy':
        return 'Occupé';
      case 'offline':
      default:
        return 'Hors ligne';
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
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
      childAspectRatio: 1.5,
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
          const Expanded(
            child: Text(
              'Impossible de charger les statistiques.',
              style: TextStyle(color: AppColors.error, fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildIncompleteProfileBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
              SizedBox(width: 8),
              Text(
                'Action requise',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Votre profil est incomplet. Renseignez votre métier et votre ville pour apparaître dans l\'annuaire.',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => context.push('/technician/onboarding'),
              child: const Text('Compléter mon profil'),
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
                child: Icon(icon, size: 26, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
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
        label: 'Disponible',
        subtitle: 'Je peux recevoir de nouvelles demandes',
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
      ),
      (
        value: 'busy',
        label: 'Occupé',
        subtitle: 'Je suis en mission actuellement',
        color: AppColors.warning,
        icon: Icons.pending_rounded,
      ),
      (
        value: 'offline',
        label: 'Hors ligne',
        subtitle: 'Je ne reçois pas de demandes',
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
          const Text(
            'Changer ma disponibilité',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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

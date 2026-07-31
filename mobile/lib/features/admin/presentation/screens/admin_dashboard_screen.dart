import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(platformStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord Administrateur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            tooltip: 'Gérer les catégories',
            onPressed: () => context.go('/admin/dashboard/categories'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: () => ref.invalidate(platformStatsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(platformStatsProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                const Text('Vue d\'ensemble', style: AppTypography.heading2),
                const SizedBox(height: 16),
                _buildStatGrid(context, [
                  _StatItem('Utilisateurs', stats.usersCount, Icons.people_alt_outlined, Colors.blue, () => context.go('/admin/dashboard/users')),
                  _StatItem('Techniciens', stats.techniciansCount, Icons.engineering_outlined, Colors.orange, () => context.go('/admin/dashboard/technicians')),
                  _StatItem('Vérifiés', stats.verifiedTechniciansCount, Icons.verified_user_outlined, Colors.green, () => context.go('/admin/dashboard/technicians')),
                  _StatItem('Vérifications en attente', stats.pendingVerificationsCount, Icons.fact_check_outlined, Colors.red, () => context.go('/admin/dashboard/pending-verifications')),
                  _StatItem('Demandes', stats.serviceRequestsCount, Icons.assignment_outlined, Colors.purple, null),
                  _StatItem('Terminées', stats.completedRequestsCount, Icons.task_alt, Colors.teal, null),
                  _StatItem('Signalements', stats.reportsCount, Icons.report_problem, Colors.redAccent, () => context.go('/admin/dashboard/reports')),
                  _StatItem('Avis', stats.reviewsCount, Icons.star_border_outlined, Colors.amber, null),
                ]),
                const SizedBox(height: 32),
                const Text('Gestion', style: AppTypography.heading2),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.map_outlined, color: AppColors.primary),
                  title: const Text('Régions'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/admin/dashboard/regions'),
                  tileColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.location_city_outlined, color: AppColors.primary),
                  title: const Text('Villes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/admin/dashboard/cities'),
                  tileColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.category_outlined, color: AppColors.primary),
                  title: const Text('Catégories de services'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/admin/dashboard/categories'),
                  tileColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              const Text('Erreur lors du chargement des statistiques'),
              TextButton(
                onPressed: () => ref.invalidate(platformStatsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context, List<_StatItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: item.color, size: 24),
                  ),
                  const Spacer(),
                  Text(
                    item.value.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  _StatItem(this.label, this.value, this.icon, this.color, this.onTap);
}

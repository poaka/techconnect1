import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../auth/presentation/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: AppColors.primarySubtle,
                    backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                        ? Text(
                            user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: () {
                          if (user.role.name == 'technician') {
                            context.go('/technician/profile/edit');
                          } else {
                            context.go('/profile/edit');
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                user.fullName,
                style: AppTypography.heading2,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  user.role.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Informations personnelles
              Align(
                alignment: Alignment.centerLeft,
                child: _buildSectionHeader('Informations Personnelles'),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildListTile(Icons.email_outlined, 'Email', user.email),
                    const Divider(height: 1, color: AppColors.border),
                    _buildListTile(Icons.phone_outlined, 'Téléphone', user.phone ?? 'Non renseigné'),
                    if (user.createdAt != null) ...[
                      const Divider(height: 1, color: AppColors.border),
                      _buildListTile(Icons.calendar_today_outlined, 'Membre depuis', DateFormat('dd MMM yyyy').format(user.createdAt!)),
                    ],
                  ],
                ),
              ),

              if (user.technicianProfile != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildSectionHeader('Profil Professionnel'),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildListTile(Icons.location_on_outlined, 'Ville', user.technicianProfile!.cityName ?? 'Non renseignée'),
                      const Divider(height: 1, color: AppColors.border),
                      _buildListTile(Icons.chat_rounded, 'WhatsApp', user.technicianProfile!.whatsapp ?? 'Non renseigné'),
                      const Divider(height: 1, color: AppColors.border),
                      _buildListTile(Icons.work_outline_rounded, 'Années d\'expérience', '${user.technicianProfile!.yearsExperience} ans'),
                      const Divider(height: 1, color: AppColors.border),
                      _buildListTile(Icons.payments_outlined, 'Fourchette de prix', '${user.technicianProfile!.priceMin.toStringAsFixed(0)} - ${user.technicianProfile!.priceMax.toStringAsFixed(0)} XAF'),
                    ],
                  ),
                ),
              ],
              
              // Paramètres & Support
              Align(
                alignment: Alignment.centerLeft,
                child: _buildSectionHeader('Paramètres & Support'),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildActionTile(Icons.lock_outline_rounded, 'Changer de mot de passe', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Modification du mot de passe (bientôt disponible)')),
                      );
                    }),
                    const Divider(height: 1, color: AppColors.border),
                    _buildActionTile(Icons.notifications_outlined, 'Préférences de notifications', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Préférences de notifications (bientôt disponible)')),
                      );
                    }),
                    const Divider(height: 1, color: AppColors.border),
                    _buildActionTile(Icons.help_outline_rounded, 'Centre d\'aide', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ouverture du centre d\'aide...')),
                      );
                    }),
                    const Divider(height: 1, color: AppColors.border),
                    _buildActionTile(Icons.privacy_tip_outlined, 'Politique de confidentialité', () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ouverture de la politique de confidentialité...')),
                      );
                    }),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: AppColors.error),
                  label: const Text('Se déconnecter', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    ref.read(authNotifierProvider.notifier).logout();
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 24, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

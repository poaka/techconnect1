import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/technicians_providers.dart';
import '../widgets/star_rating_widget.dart';
import '../../../favorites/presentation/providers/favorites_provider.dart';

class TechnicianProfileScreen extends ConsumerWidget {
  final String technicianId;

  const TechnicianProfileScreen({
    super.key,
    required this.technicianId,
  });

  Future<void> _openWhatsApp(BuildContext context, String? rawPhone) async {
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone non renseigné pour cet artisan.')),
      );
      return;
    }
    String digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');

    // Auto-formatting for Cameroonian numbers (+237)
    if (digits.startsWith('0') && digits.length == 10) {
      digits = '237${digits.substring(1)}';
    } else if (digits.length == 9 && (digits.startsWith('6') || digits.startsWith('2'))) {
      digits = '237$digits';
    }

    final url = 'https://wa.me/$digits?text=Bonjour,%20je%20vous%20contacte%20depuis%20l\'application%20FixerPro237%20Cameroun.';

    try {
      final launched = await launchUrlString(url, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de l\'ouverture de WhatsApp.')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String? rawPhone) async {
    if (rawPhone == null || rawPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Numéro de téléphone non disponible.')),
      );
      return;
    }
    final url = 'tel:$rawPhone';
    try {
      await launchUrlString(url);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de lancer l\'appel téléphonique.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(technicianDetailProvider(technicianId));
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 360 ? 14.0 : 18.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil de l\'Artisan'),
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(favoriteTechniciansProvider.notifier).isFavorite(technicianId)
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: ref.watch(favoriteTechniciansProvider.notifier).isFavorite(technicianId)
                  ? AppColors.error
                  : null,
            ),
            onPressed: () {
              final profileAsyncVal = ref.read(technicianDetailProvider(technicianId));
              if (profileAsyncVal.hasValue) {
                ref.read(favoriteTechniciansProvider.notifier).toggleFavorite(profileAsyncVal.value!);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.report_problem_outlined, color: Colors.orange),
            tooltip: 'Signaler cet artisan',
            onPressed: () => _showReportDialog(context, ref),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          final primaryCategory = profile.categories.isNotEmpty ? profile.categories.first.name : 'Artisan / Technicien';
          final locationText = [profile.cityName, profile.regionName].where((e) => e != null && e.isNotEmpty).join(', ');

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Top Header Card
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Center(
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: AppColors.primarySubtle,
                            backgroundImage: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                                ? CachedNetworkImageProvider(profile.avatarUrl!)
                                : null,
                            child: profile.avatarUrl == null || profile.avatarUrl!.isEmpty
                                ? Text(
                                    profile.fullName.isNotEmpty ? profile.fullName[0].toUpperCase() : 'T',
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                profile.fullName,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (profile.isVerified) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),

                        Text(
                          primaryCategory,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        if (locationText.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textSecondary),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  locationText,
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),

                        // Rating & Availability Chips
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          runSpacing: 6,
                          children: [
                            StarRatingWidget(
                              rating: profile.ratingAvg,
                              count: profile.ratingCount,
                              size: 15,
                            ),
                            Chip(
                              label: Text(
                                profile.availabilityLabel,
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              backgroundColor: profile.availabilityStatus.toLowerCase() == 'available'
                                  ? AppColors.success
                                  : AppColors.accent,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contact Action Buttons (WhatsApp & Call)
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'WhatsApp',
                          icon: Icons.chat_rounded,
                          color: const Color(0xFF25D366),
                          onPressed: () => _openWhatsApp(context, profile.whatsapp ?? profile.phone),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: AppButton(
                          text: 'Appeler',
                          icon: Icons.phone_rounded,
                          isOutlined: true,
                          onPressed: () => _makePhoneCall(context, profile.phone),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Bio / Description
                  const Text('À propos', style: AppTypography.heading3),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      profile.bio != null && profile.bio!.isNotEmpty
                          ? profile.bio!
                          : 'Aucune description rédigée pour le moment.',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pricing & Rates
                  if (profile.priceMin > 0 || profile.priceMax > 0) ...[
                    const Text('Tarifs indicatifs', style: AppTypography.heading3),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Fourchette de prix', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          Text(
                            '${profile.priceMin.toStringAsFixed(0)} - ${profile.priceMax.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Skills & Categories List
                  if (profile.categories.isNotEmpty) ...[
                    const Text('Compétences & Métiers', style: AppTypography.heading3),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: profile.categories
                          .map(
                            (c) => Chip(
                              label: Text(c.name, style: const TextStyle(fontSize: 12)),
                              backgroundColor: AppColors.surface,
                              side: const BorderSide(color: AppColors.border),
                              visualDensity: VisualDensity.compact,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Customer Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Avis des clients', style: AppTypography.heading3),
                      Text('${profile.reviews.length} avis', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 10),

                  if (profile.reviews.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Text('Aucun avis client pour l\'instant.', style: AppTypography.bodyMedium),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: profile.reviews.length,
                      itemBuilder: (context, index) {
                        final rev = profile.reviews[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      rev.clientName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  StarRatingWidget(rating: rev.rating, size: 13, showText: false),
                                ],
                              ),
                              if (rev.comment != null && rev.comment!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(rev.comment!, style: AppTypography.bodyMedium),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, stack) => Scaffold(
          appBar: AppBar(
            title: const Text('Erreur'),
            actions: [
              IconButton(
                icon: const Icon(Icons.flag_outlined),
                onPressed: () => _showReportDialog(context, ref),
              ),
            ],
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                  const SizedBox(height: 12),
                  const Text('Impossible de charger le profil de l\'artisan'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.refresh(technicianDetailProvider(technicianId)),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: AppButton(
            text: 'Demander un service',
            onPressed: () {
              context.push('/create-request');
            },
          ),
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context, WidgetRef ref) {
    final reasonController = TextEditingController();
    final detailsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Signaler l\'artisan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text('Veuillez expliquer pourquoi vous signalez cet artisan. Notre équipe examinera votre demande.'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Raison (ex: Arnaque, Comportement inapproprié)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(
                  labelText: 'Détails supplémentaires...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      onPressed: () async {
                        final reason = reasonController.text.trim();
                        if (reason.isEmpty) return;
                        
                        final reportFn = ref.read(reportTechnicianProvider);
                        try {
                          await reportFn(technicianId, reason, detailsController.text.trim());
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Signalement envoyé avec succès. Merci.')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Erreur: $e')),
                            );
                          }
                        }
                      },
                      child: const Text('Signaler'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:image_picker/image_picker.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/language_selector.dart';
import '../../../../shared/widgets/theme_toggle_button.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../auth/presentation/auth_state.dart';
import '../../technicians/presentation/providers/technician_documents_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _pickAndUploadAvatar(BuildContext context, WidgetRef ref) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Photo de profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final file = await picker.pickImage(source: source);
    if (file == null) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mise à jour de la photo...')),
      );
    }
    
    await ref.read(authNotifierProvider.notifier).uploadAvatar(file.path);
    
    if (context.mounted) {
      final authState = ref.read(authNotifierProvider);
      if (authState.status == AuthStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authState.errorMessage ?? 'Erreur'), backgroundColor: AppColors.error),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo mise à jour'), backgroundColor: AppColors.success),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Utilisateur non connecté')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile_title')),
        actions: [
          const ThemeToggleButton(),
          const Padding(
            padding: EdgeInsets.only(right: 4.0),
            child: LanguageSelector(),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              if (user.role.name == 'technician') {
                context.go('/technician/profile/edit');
              } else {
                context.go('/profile/edit');
              }
            },
          ),
        ],
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
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                        onPressed: () => _pickAndUploadAvatar(context, ref),
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
                child: _buildSectionHeader(context, context.tr('personal_info')),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildListTile(context, Icons.email_outlined, context.tr('email'), user.email),
                    Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
                    _buildListTile(context, Icons.phone_outlined, context.tr('phone'), user.phone ?? context.tr('not_provided')),
                    if (user.createdAt != null) ...[
                      Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
                      _buildListTile(context, Icons.calendar_today_outlined, context.tr('member_since'), DateFormat('dd MMM yyyy').format(user.createdAt!)),
                    ],
                  ],
                ),
              ),

              if (user.technicianProfile != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildSectionHeader(context, context.tr('pro_profile')),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _buildListTile(context, Icons.location_on_outlined, context.tr('city'), user.technicianProfile!.cityName ?? context.tr('not_provided')),
                      Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
                      _buildListTile(context, Icons.chat_rounded, context.tr('whatsapp'), user.technicianProfile!.whatsapp ?? context.tr('not_provided')),
                      Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
                      _buildListTile(context, Icons.work_outline_rounded, context.tr('years_exp'), '${user.technicianProfile!.yearsExperience} ${context.tr('years')}'),
                      Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
                      _buildListTile(context, Icons.payments_outlined, context.tr('price_range'), '${user.technicianProfile!.priceMin.toStringAsFixed(0)} - ${user.technicianProfile!.priceMax.toStringAsFixed(0)} XAF'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const _TechnicianDocumentsSection(),
              ],
              
              // Paramètres & Support
              Align(
                alignment: Alignment.centerLeft,
                child: _buildSectionHeader(context, context.tr('settings_support')),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildActionTile(context, Icons.lock_outline_rounded, context.tr('change_password'), () async {
                      final result = await showModalBottomSheet<bool>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const _ChangePasswordSheet(),
                      );
                      if (result == true) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mot de passe modifié avec succès'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      }
                    }),
                    Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
                    _buildActionTile(context, Icons.notifications_outlined, context.tr('notification_prefs'), () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Préférences de notifications')),
                      );
                    }),
                    Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
                    _buildActionTile(context, Icons.help_outline_rounded, context.tr('help_center'), () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Centre d\'aide')),
                      );
                    }),
                    Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.border),
                    _buildActionTile(context, Icons.privacy_tip_outlined, context.tr('privacy_policy'), () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Politique de confidentialité')),
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
                  label: Text(context.tr('logout'), style: const TextStyle(color: AppColors.error)),
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

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 24, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: isDark ? AppColors.primaryLight : AppColors.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      await ref.read(authNotifierProvider.notifier).changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final inputBg = isDark ? AppColors.darkInputBg : AppColors.inputBg;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final iconColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Changer de mot de passe', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    IconButton(
                      icon: Icon(Icons.close, color: iconColor),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _oldPasswordController,
                  obscureText: _obscureOld,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Ancien mot de passe',
                    labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureOld ? Icons.visibility_off : Icons.visibility, color: iconColor),
                      onPressed: () => setState(() => _obscureOld = !_obscureOld),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Requis';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: iconColor),
                      onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Requis';
                    if (val.length < 6) return 'Minimum 6 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    labelStyle: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                    filled: true,
                    fillColor: inputBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: iconColor),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Requis';
                    if (val != _newPasswordController.text) return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                    : const Text('Valider'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TechnicianDocumentsSection extends ConsumerWidget {
  const _TechnicianDocumentsSection();

  Future<void> _uploadDocument(BuildContext context, WidgetRef ref, String documentType) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement en cours...')),
      );
    }

    try {
      await ref.read(uploadDocumentProvider)(file.path, documentType, file.name);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document téléchargé avec succès'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors du téléchargement'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(technicianDocumentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12, left: 4),
          child: Text(
            'MES DOCUMENTS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: docsAsync.when(
            data: (docs) {
              if (docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text('Aucun document fourni', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.border),
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  Color statusColor = AppColors.textSecondary;
                  IconData statusIcon = Icons.hourglass_empty;
                  if (doc.status == 'approved') {
                    statusColor = AppColors.success;
                    statusIcon = Icons.check_circle;
                  } else if (doc.status == 'rejected') {
                    statusColor = AppColors.error;
                    statusIcon = Icons.cancel;
                  }

                  return ListTile(
                    leading: const Icon(Icons.description_outlined, color: AppColors.primary),
                    title: Text(doc.documentTypeLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('dd MMM yyyy').format(doc.uploadedAt), style: const TextStyle(fontSize: 12)),
                        if (doc.rejectionReason != null && doc.status == 'rejected')
                          Text('Motif: ${doc.rejectionReason}', style: const TextStyle(color: AppColors.error, fontSize: 12)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(doc.statusLabel, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 4),
                        Icon(statusIcon, color: statusColor, size: 16),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) => const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Erreur de chargement', style: TextStyle(color: AppColors.error))),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.badge_outlined),
              label: const Text('CNI / Passeport'),
              onPressed: () => _uploadDocument(context, ref, 'id_card'),
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.school_outlined),
              label: const Text('Certificat'),
              onPressed: () => _uploadDocument(context, ref, 'certificate'),
            ),
          ],
        ),
      ],
    );
  }
}


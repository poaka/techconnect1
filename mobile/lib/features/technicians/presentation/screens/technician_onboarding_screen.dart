import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../providers/technicians_providers.dart';

class TechnicianOnboardingScreen extends ConsumerStatefulWidget {
  const TechnicianOnboardingScreen({super.key});

  @override
  ConsumerState<TechnicianOnboardingScreen> createState() => _TechnicianOnboardingScreenState();
}

class _TechnicianOnboardingScreenState extends ConsumerState<TechnicianOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _bioController = TextEditingController();
  final _yearsController = TextEditingController();
  final _priceMinController = TextEditingController();
  final _priceMaxController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _selectedCityId;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    // Load categories and cities if not loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(categoriesProvider);
      ref.invalidate(citiesProvider);
      
      // Pre-fill existing data if any
      final user = ref.read(authNotifierProvider).user;
      final profile = user?.technicianProfile;
      if (profile != null) {
        _bioController.text = profile.bio ?? '';
        _yearsController.text = profile.yearsExperience.toString();
        _priceMinController.text = profile.priceMin.toString();
        _priceMaxController.text = profile.priceMax.toString();
        _whatsappController.text = profile.whatsapp ?? '';
        _selectedCityId = profile.cityId;
        if (profile.categories.isNotEmpty) {
          _selectedCategoryId = profile.categories.first.id;
        }
      }
      if (user != null) {
        _fullNameController.text = user.fullName;
        _phoneController.text = user.phone ?? '';
      }
    });
  }

  @override
  void dispose() {
    _bioController.dispose();
    _yearsController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    _whatsappController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCityId == null || _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une ville et un métier.')),
      );
      return;
    }

    final data = {
      'bio': _bioController.text.trim(),
      'yearsExperience': int.tryParse(_yearsController.text) ?? 0,
      'priceMin': double.tryParse(_priceMinController.text) ?? 0.0,
      'priceMax': double.tryParse(_priceMaxController.text) ?? 0.0,
      'whatsapp': _whatsappController.text.trim(),
      'cityId': _selectedCityId,
      'categoryIds': [_selectedCategoryId],
      'fullName': _fullNameController.text.trim(),
      'phone': _phoneController.text.trim(),
    };

    final profile = await ref.read(updateProfileProvider.notifier).updateProfile(data);
    
    if (profile != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès !', style: TextStyle(color: Colors.white)), backgroundColor: AppColors.success),
        );
        // Refresh auth state to get updated user with profile
        ref.read(authNotifierProvider.notifier).checkAuthStatus();
        ref.invalidate(technicianListNotifierProvider);
        context.pop();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.read(updateProfileProvider).error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final updateState = ref.watch(updateProfileProvider);
    final categoriesState = ref.watch(categoriesProvider);
    final citiesState = ref.watch(citiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Compléter mon profil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              
              const Text(
                'Informations Personnelles',
                style: AppTypography.heading3,
              ),
              const SizedBox(height: 16),
              
              AppTextField(
                controller: _fullNameController,
                label: 'Nom complet',
                hint: 'Entrez votre nom',
                validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              
              AppTextField(
                controller: _phoneController,
                label: 'Numéro de téléphone principal',
                hint: 'Ex: +237 6XX XX XX XX',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              
              const Text(
                'Informations Professionnelles',
                style: AppTypography.heading3,
              ),
              const SizedBox(height: 8),
              const Text(
                'Ces informations seront visibles par les clients pour vous contacter.',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 24),
              
              AppTextField(
                controller: _bioController,
                label: 'Biographie / Description',
                hint: 'Parlez de votre expérience et vos spécialités...',
                maxLines: 4,
                validator: (val) => val == null || val.isEmpty ? 'Champ requis' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _yearsController,
                      label: 'Années d\'expérience',
                      hint: 'Ex: 5',
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _whatsappController,
                      label: 'Numéro WhatsApp',
                      hint: 'Ex: 6XXXXXXXX',
                      keyboardType: TextInputType.phone,
                      validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              const Text('Tarifs habituels (FCFA)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _priceMinController,
                      label: 'Minimum',
                      hint: 'Ex: 5000',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _priceMaxController,
                      label: 'Maximum',
                      hint: 'Ex: 25000',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text('Métier Principal', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              categoriesState.isLoading
                  ? const CircularProgressIndicator()
                  : categoriesState.hasError
                      ? Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            const Text('Erreur de chargement'),
                            TextButton(
                              onPressed: () => ref.invalidate(categoriesProvider),
                              child: const Text('Réessayer'),
                            )
                          ],
                        )
                      : DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          hint: const Text('Sélectionnez votre métier'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: categoriesState.value?.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            );
                          }).toList() ?? [],
                          onChanged: (val) => setState(() => _selectedCategoryId = val),
                        ),
                    
              const SizedBox(height: 24),

              const Text('Ville d\'intervention', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              citiesState.isLoading
                  ? const CircularProgressIndicator()
                  : citiesState.hasError
                      ? Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            const Text('Erreur de chargement'),
                            TextButton(
                              onPressed: () => ref.invalidate(citiesProvider),
                              child: const Text('Réessayer'),
                            )
                          ],
                        )
                      : DropdownButtonFormField<String>(
                          value: _selectedCityId,
                          hint: const Text('Sélectionnez votre ville'),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: citiesState.value?.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            );
                          }).toList() ?? [],
                          onChanged: (val) => setState(() => _selectedCityId = val),
                        ),

              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Enregistrer mon profil',
                  onPressed: _submit,
                  isLoading: updateState.isLoading,
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

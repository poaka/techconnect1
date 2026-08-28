import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
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
        SnackBar(content: Text(context.tr('select_city_profession_error'))),
      );
      return;
    }

    String cleanPhoneNumber(String input) {
      if (input.trim().isEmpty) return '';
      String digits = input.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.startsWith('0') && digits.length == 10) {
        return '+237${digits.substring(1)}';
      } else if (digits.length == 9 && (digits.startsWith('6') || digits.startsWith('2'))) {
        return '+237$digits';
      } else if (digits.startsWith('237')) {
        return '+$digits';
      }
      return input.trim();
    }

    final data = {
      'bio': _bioController.text.trim(),
      'yearsExperience': int.tryParse(_yearsController.text) ?? 0,
      'priceMin': double.tryParse(_priceMinController.text) ?? 0.0,
      'priceMax': double.tryParse(_priceMaxController.text) ?? 0.0,
      'whatsapp': cleanPhoneNumber(_whatsappController.text),
      'cityId': _selectedCityId,
      'categoryIds': [_selectedCategoryId],
      'fullName': _fullNameController.text.trim(),
      'phone': cleanPhoneNumber(_phoneController.text),
    };

    final profile = await ref.read(updateProfileProvider.notifier).updateProfile(data);
    
    if (profile != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('profile_updated_success'), style: const TextStyle(color: Colors.white)), backgroundColor: AppColors.success),
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
        title: Text(context.tr('complete_profile_title')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              
              Text(
                context.tr('personal_info_section'),
                style: AppTypography.heading3,
              ),
              const SizedBox(height: 16),
              
              AppTextField(
                controller: _fullNameController,
                label: context.tr('full_name_label'),
                hint: context.tr('full_name_hint'),
                validator: (val) => val == null || val.isEmpty ? context.tr('field_required') : null,
              ),
              const SizedBox(height: 16),
              
              AppTextField(
                controller: _phoneController,
                label: context.tr('main_phone_label'),
                hint: context.tr('main_phone_hint'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 32),
              
              Text(
                context.tr('pro_info_section'),
                style: AppTypography.heading3,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('pro_info_desc'),
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 24),
              
              AppTextField(
                controller: _bioController,
                label: context.tr('bio_label'),
                hint: context.tr('bio_hint'),
                maxLines: 4,
                validator: (val) => val == null || val.isEmpty ? context.tr('field_required') : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _yearsController,
                      label: context.tr('years_exp_label'),
                      hint: context.tr('years_exp_hint'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? context.tr('field_required_short') : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _whatsappController,
                      label: context.tr('whatsapp_label'),
                      hint: context.tr('whatsapp_hint'),
                      keyboardType: TextInputType.phone,
                      validator: (val) => val == null || val.isEmpty ? context.tr('field_required_short') : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              Text(context.tr('usual_rates'), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _priceMinController,
                      label: context.tr('rate_min'),
                      hint: '5000',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppTextField(
                      controller: _priceMaxController,
                      label: context.tr('rate_max'),
                      hint: '25000',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(context.tr('main_profession'), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              categoriesState.isLoading
                  ? const CircularProgressIndicator()
                  : categoriesState.hasError
                      ? Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(context.tr('loading_error')),
                            TextButton(
                              onPressed: () => ref.invalidate(categoriesProvider),
                              child: Text(context.tr('retry')),
                            )
                          ],
                        )
                      : DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedCategoryId,
                          hint: Text(context.tr('select_profession'), overflow: TextOverflow.ellipsis),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: categoriesState.value?.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name, overflow: TextOverflow.ellipsis),
                            );
                          }).toList() ?? [],
                          onChanged: (val) => setState(() => _selectedCategoryId = val),
                        ),
                    
              const SizedBox(height: 24),

              Text(context.tr('intervention_city'), style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              citiesState.isLoading
                  ? const CircularProgressIndicator()
                  : citiesState.hasError
                      ? Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(context.tr('loading_error')),
                            TextButton(
                              onPressed: () => ref.invalidate(citiesProvider),
                              child: Text(context.tr('retry')),
                            )
                          ],
                        )
                      : DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedCityId,
                          hint: Text(context.tr('select_city'), overflow: TextOverflow.ellipsis),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          items: citiesState.value?.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name, overflow: TextOverflow.ellipsis),
                            );
                          }).toList() ?? [],
                          onChanged: (val) => setState(() => _selectedCityId = val),
                        ),

              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: context.tr('save'),
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

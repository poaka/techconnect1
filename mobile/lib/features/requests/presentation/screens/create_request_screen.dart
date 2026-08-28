import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../technicians/presentation/providers/technicians_providers.dart';
import '../providers/requests_providers.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  ConsumerState<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends ConsumerState<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  
  String? _selectedCategoryId;
  String? _selectedCityId;
  bool _isLoading = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sélection de l\'image: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une catégorie'), backgroundColor: AppColors.error),
      );
      return;
    }
    
    if (_selectedCityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une ville'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(requestListProvider.notifier).createRequest(
            categoryId: _selectedCategoryId!,
            cityId: _selectedCityId!,
            description: _descriptionController.text.trim(),
            address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
            imagePath: _imageFile?.path,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Demande envoyée ! Recherche de techniciens en cours...'), backgroundColor: AppColors.success),
        );
        context.go('/requests');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final citiesAsync = ref.watch(citiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une demande'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'De quoi avez-vous besoin ?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Décrivez votre problème et nous trouverons le meilleur technicien disponible pour vous.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Category Dropdown
                const Text('Catégorie de service', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    hint: const Text('Ex: Plomberie, Électricité...', overflow: TextOverflow.ellipsis),
                    value: _selectedCategoryId,
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    validator: (val) => val == null ? 'Requis' : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Erreur de chargement des catégories', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 20),

                // City Dropdown
                const Text('Votre ville', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                citiesAsync.when(
                  data: (cities) => DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    hint: const Text('Sélectionnez votre ville', overflow: TextOverflow.ellipsis),
                    value: _selectedCityId,
                    items: cities.map((city) {
                      return DropdownMenuItem(
                        value: city.id,
                        child: Text(city.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCityId = val),
                    validator: (val) => val == null ? 'Requis' : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => const Text('Erreur de chargement des villes', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 20),

                // Description Field
                const Text('Description du problème', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Soyez le plus précis possible pour aider le technicien à comprendre votre besoin...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Veuillez décrire votre besoin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Address Field
                const Text('Adresse exacte (optionnel)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: 'Quartier, repère, numéro de porte...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),

                // Image Picker Field
                const Text('Photo (optionnel)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_imageFile != null)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _imageFile!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _imageFile = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, size: 20),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Caméra'),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library, size: 20),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Galerie'),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    text: 'Trouver un technicien',
                    isLoading: _isLoading,
                    onPressed: _submitRequest,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

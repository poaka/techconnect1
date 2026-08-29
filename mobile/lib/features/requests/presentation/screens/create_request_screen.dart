import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../technicians/presentation/providers/technicians_providers.dart';
import '../providers/requests_providers.dart';

class CreateRequestScreen extends ConsumerStatefulWidget {
  final String? initialCategoryId;

  const CreateRequestScreen({super.key, this.initialCategoryId});

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
  bool _isDetectingLocation = false;
  double? _latitude;
  double? _longitude;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
  }

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
          SnackBar(content: Text('${context.tr('error_prefix')}$e')),
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

  Future<void> _detectCurrentLocation() async {
    setState(() => _isDetectingLocation = true);
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        if (_addressController.text.trim().isEmpty) {
          _addressController.text = 'Position GPS (${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})';
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('location_detected')), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error_prefix')}$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isDetectingLocation = false);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('select_category_error')), backgroundColor: AppColors.error),
      );
      return;
    }
    
    if (_selectedCityId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('select_city_error')), backgroundColor: AppColors.error),
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
            latitude: _latitude,
            longitude: _longitude,
            imagePath: _imageFile?.path,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('request_sent')), backgroundColor: AppColors.success),
        );
        context.go('/requests');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error_prefix')}$e'), backgroundColor: AppColors.error),
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
        title: Text(context.tr('create_request_title')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('what_do_you_need'),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr('describe_problem'),
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Category Dropdown
                Text(context.tr('service_category'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  data: (categories) => DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    hint: Text(context.tr('category_hint'), overflow: TextOverflow.ellipsis),
                    initialValue: categories.any((cat) => cat.id == _selectedCategoryId) ? _selectedCategoryId : null,
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Text(cat.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                    validator: (val) => val == null ? context.tr('field_required_short') : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => Text(context.tr('error_loading_categories'), style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 20),

                // City Dropdown
                Text(context.tr('your_city'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                citiesAsync.when(
                  data: (cities) => DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    hint: Text(context.tr('city_hint'), overflow: TextOverflow.ellipsis),
                    initialValue: _selectedCityId,
                    items: cities.map((city) {
                      return DropdownMenuItem(
                        value: city.id,
                        child: Text(city.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedCityId = val),
                    validator: (val) => val == null ? context.tr('field_required_short') : null,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, __) => Text(context.tr('error_loading_cities'), style: const TextStyle(color: Colors.red)),
                ),
                const SizedBox(height: 20),

                // Description Field
                Text(context.tr('problem_description'), style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: context.tr('description_hint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return context.tr('please_describe_need');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Address Field
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.tr('exact_address'), style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _isDetectingLocation ? null : _detectCurrentLocation,
                      icon: _isDetectingLocation
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location, size: 16),
                      label: Text(
                        _isDetectingLocation ? context.tr('detecting_location') : context.tr('use_my_location'),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: context.tr('address_hint'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (_latitude != null && _longitude != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'GPS: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() {
                            _latitude = null;
                            _longitude = null;
                          }),
                          child: const Icon(Icons.close, size: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Image Picker Field
                Text(context.tr('photo_optional'), style: const TextStyle(fontWeight: FontWeight.bold)),
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
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(context.tr('camera')),
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
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(context.tr('gallery')),
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
                    text: context.tr('find_technician'),
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

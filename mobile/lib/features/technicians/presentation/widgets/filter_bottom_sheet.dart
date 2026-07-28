import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/technicians_providers.dart';

class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  String? _selectedCategory;
  String? _selectedRegion;
  String? _selectedCity;
  String? _selectedAvailability;
  double? _selectedMinRating;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(technicianFilterProvider);
    _selectedCategory = filter.categoryId;
    _selectedRegion = filter.regionId;
    _selectedCity = filter.cityId;
    _selectedAvailability = filter.availabilityStatus;
    _selectedMinRating = filter.minRating;
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final citiesAsync = ref.watch(citiesProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sheet Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filtres de recherche',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedCategory = null;
                      _selectedRegion = null;
                      _selectedCity = null;
                      _selectedAvailability = null;
                      _selectedMinRating = null;
                    });
                  },
                  child: const Text('Réinitialiser'),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Category Dropdown
            const Text(
              'Métier / Catégorie',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            categoriesAsync.when(
              data: (categories) => DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                decoration: const InputDecoration(hintText: 'Toutes les catégories'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toutes les catégories')),
                  ...categories.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Erreur de chargement des catégories'),
            ),
            const SizedBox(height: 16),

            // Region Dropdown
            const Text(
              'Région',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ref.watch(regionsProvider).when(
              data: (regions) => DropdownButtonFormField<String>(
                initialValue: _selectedRegion,
                isExpanded: true,
                decoration: const InputDecoration(hintText: 'Toutes les régions'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Toutes les régions')),
                  ...regions.map(
                    (r) => DropdownMenuItem(value: r.id, child: Text(r.name)),
                  ),
                ],
                onChanged: (val) {
                  setState(() {
                    _selectedRegion = val;
                    // When region changes, optionally reset city or let the backend handle it
                    _selectedCity = null; 
                  });
                },
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Erreur de chargement des régions'),
            ),
            const SizedBox(height: 16),

            // City Dropdown
            const Text(
              'Ville / Localisation',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            citiesAsync.when(
              data: (cities) {
                // If a region is selected, we can optionally filter the cities dropdown too
                final filteredCities = _selectedRegion != null
                    ? cities.where((c) => c.regionId == _selectedRegion).toList()
                    : cities;
                
                // Ensure selectedCity is valid
                if (_selectedCity != null && !filteredCities.any((c) => c.id == _selectedCity)) {
                  // We do this silently so the UI handles the mismatch, but we don't reset state here to avoid rebuild loops during render
                }
                
                return DropdownButtonFormField<String>(
                  value: filteredCities.any((c) => c.id == _selectedCity) ? _selectedCity : null,
                  isExpanded: true,
                  decoration: const InputDecoration(hintText: 'Toutes les villes'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Toutes les villes')),
                    ...filteredCities.map(
                      (c) => DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.regionName ?? 'Cameroun'})')),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedCity = val),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Erreur de chargement des villes'),
            ),
            const SizedBox(height: 16),

            // Availability Status Toggle
            const Text(
              'Disponibilité',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FilterChip(
                    label: 'Tous',
                    isSelected: _selectedAvailability == null,
                    onTap: () => setState(() => _selectedAvailability = null),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterChip(
                    label: 'Disponible',
                    isSelected: _selectedAvailability == 'available',
                    onTap: () => setState(() => _selectedAvailability = 'available'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Minimum Rating Choice
            const Text(
              'Note minimale',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _RatingChip(
                  label: 'Toutes',
                  isSelected: _selectedMinRating == null,
                  onTap: () => setState(() => _selectedMinRating = null),
                ),
                const SizedBox(width: 8),
                _RatingChip(
                  label: '3.0★ +',
                  isSelected: _selectedMinRating == 3.0,
                  onTap: () => setState(() => _selectedMinRating = 3.0),
                ),
                const SizedBox(width: 8),
                _RatingChip(
                  label: '4.0★ +',
                  isSelected: _selectedMinRating == 4.0,
                  onTap: () => setState(() => _selectedMinRating = 4.0),
                ),
                const SizedBox(width: 8),
                _RatingChip(
                  label: '4.5★ +',
                  isSelected: _selectedMinRating == 4.5,
                  onTap: () => setState(() => _selectedMinRating = 4.5),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Apply Button
            AppButton(
              text: 'Appliquer les filtres',
              onPressed: () {
                final filterNotifier = ref.read(technicianFilterProvider.notifier);
                filterNotifier.setCategory(_selectedCategory);
                filterNotifier.setRegion(_selectedRegion);
                filterNotifier.setCity(_selectedCity);
                filterNotifier.setAvailability(_selectedAvailability);
                filterNotifier.setMinRating(_selectedMinRating);

                final newFilter = ref.read(technicianFilterProvider);
                ref.read(technicianListNotifierProvider.notifier).fetchTechnicians(filter: newFilter, isRefresh: true);

                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySubtle : AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _RatingChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent.withValues(alpha: 0.2) : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.orange.shade900 : AppColors.textPrimary,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

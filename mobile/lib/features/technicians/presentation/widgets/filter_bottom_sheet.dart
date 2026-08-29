import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
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
                Text(
                  context.tr('search_filters'),
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
                  child: Text(context.tr('reset')),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),

            // Category Dropdown
            Text(
              context.tr('profession_category'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            categoriesAsync.when(
              data: (categories) => DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                isExpanded: true,
                decoration: InputDecoration(hintText: context.tr('all_categories')),
                items: [
                  DropdownMenuItem(value: null, child: Text(context.tr('all_categories'))),
                  ...categories.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedCategory = val),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(context.tr('error_loading_categories')),
            ),
            const SizedBox(height: 16),

            // Region Dropdown
            Text(
              context.tr('region'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            ref.watch(regionsProvider).when(
              data: (regions) => DropdownButtonFormField<String>(
                initialValue: _selectedRegion,
                isExpanded: true,
                decoration: InputDecoration(hintText: context.tr('all_regions')),
                items: [
                  DropdownMenuItem(value: null, child: Text(context.tr('all_regions'))),
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
              error: (_, __) => Text(context.tr('error_loading_regions')),
            ),
            const SizedBox(height: 16),

            // City Dropdown
            Text(
              context.tr('city_location'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            citiesAsync.when(
              data: (cities) {
                // If a region is selected, we can optionally filter the cities dropdown too
                final filteredCities = _selectedRegion != null
                    ? cities.where((c) => c.regionId == _selectedRegion).toList()
                    : cities;
                
                return DropdownButtonFormField<String>(
                  initialValue: filteredCities.any((c) => c.id == _selectedCity) ? _selectedCity : null,
                  isExpanded: true,
                  decoration: InputDecoration(hintText: context.tr('all_cities')),
                  items: [
                    DropdownMenuItem(value: null, child: Text(context.tr('all_cities'))),
                    ...filteredCities.map(
                      (c) => DropdownMenuItem(value: c.id, child: Text('${c.name} (${c.regionName ?? 'Cameroun'})')),
                    ),
                  ],
                  onChanged: (val) => setState(() => _selectedCity = val),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Text(context.tr('error_loading_cities')),
            ),
            const SizedBox(height: 16),

            // Availability Filter
            Text(
              context.tr('availability'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _FilterChip(
                    label: context.tr('all'),
                    isSelected: _selectedAvailability == null,
                    onTap: () => setState(() => _selectedAvailability = null),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FilterChip(
                    label: context.tr('available'),
                    isSelected: _selectedAvailability == 'available',
                    onTap: () => setState(() => _selectedAvailability = 'available'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Minimum Rating Choice
            Text(
              context.tr('minimum_rating'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _RatingChip(
                  label: context.tr('all_feminine'),
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
              text: context.tr('apply_filters'),
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

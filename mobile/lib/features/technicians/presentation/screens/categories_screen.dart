import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/technicians_providers.dart';
import '../widgets/category_item.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('all_categories')),
      ),
      body: SafeArea(
        child: categoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                const SizedBox(height: 16),
                Text(context.tr('error_loading_categories')),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(categoriesProvider),
                  child: Text(context.tr('retry')),
                ),
              ],
            ),
          ),
          data: (categories) {
            if (categories.isEmpty) {
              return Center(child: Text(context.tr('no_category_found')));
            }

            return GridView.builder(
              padding: const EdgeInsets.all(20.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 24,
                childAspectRatio: 0.8,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return CategoryItem(
                  category: category,
                  onTap: () {
                    final filterNotifier = ref.read(technicianFilterProvider.notifier);
                    filterNotifier.resetFilters();
                    filterNotifier.setCategory(category.id);
                    
                    // Fetch directly inside the GoRouter push or here?
                    // We just navigate, Directory screen will load it automatically
                    // because the Provider is watched! Wait, Directory screen
                    // uses TechnicianListNotifier which needs fetchTechnicians manually or on init.
                    // Directory screen's initState or watch triggers fetch if needed?
                    // Better to fetch manually just like HomeScreen does.
                    final newFilter = ref.read(technicianFilterProvider);
                    ref.read(technicianListNotifierProvider.notifier).fetchTechnicians(filter: newFilter, isRefresh: true);
                    
                    context.push('/directory');
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

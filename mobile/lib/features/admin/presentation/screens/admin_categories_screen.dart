import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../technicians/domain/category.dart';
import '../providers/admin_providers.dart';

class AdminCategoriesScreen extends ConsumerWidget {
  const AdminCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(adminCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catégories de Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminCategoriesProvider),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          if (categories.isEmpty) {
            return const Center(child: Text('Aucune catégorie trouvée.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminCategoriesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: categories.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primarySubtle.withOpacity(0.2),
                    child: category.iconName != null
                        ? Text(category.iconName!, style: const TextStyle(fontSize: 24))
                        : const Icon(Icons.category, color: AppColors.primary),
                  ),
                  title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(category.description ?? 'Pas de description'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showCategoryDialog(context, ref, category: category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppColors.error),
                        onPressed: () => _confirmDelete(context, ref, category),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erreur: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCategoryDialog(context, ref),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, WidgetRef ref, {Category? category}) {
    final isEditing = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final descController = TextEditingController(text: category?.description ?? '');
    final iconController = TextEditingController(text: category?.iconName ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Modifier la catégorie' : 'Nouvelle catégorie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nom de la catégorie'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(labelText: 'Emoji (ex: 🔧)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final data = {
                  'name': nameController.text.trim(),
                  'description': descController.text.trim(),
                  'icon_name': iconController.text.trim(),
                };
                if (data['name']!.isEmpty) return;
                
                if (isEditing) {
                  ref.read(categoryActionsProvider.notifier).updateCategory(category.id, data);
                } else {
                  ref.read(categoryActionsProvider.notifier).createCategory(data);
                }
                Navigator.pop(context);
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Category category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la catégorie ?'),
        content: Text('Voulez-vous vraiment supprimer "${category.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              ref.read(categoryActionsProvider.notifier).deleteCategory(category.id);
              Navigator.pop(context);
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

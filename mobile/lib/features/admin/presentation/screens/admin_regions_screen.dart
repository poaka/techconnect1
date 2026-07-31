import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../technicians/presentation/providers/technicians_providers.dart';
import '../providers/admin_providers.dart';

class AdminRegionsScreen extends ConsumerWidget {
  const AdminRegionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regionsAsync = ref.watch(regionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Régions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(regionsProvider),
          ),
        ],
      ),
      body: regionsAsync.when(
        data: (regions) {
          if (regions.isEmpty) {
            return const Center(child: Text('Aucune région trouvée.'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(regionsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: regions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final region = regions[index];
                return ListTile(
                  title: Text(region.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primary),
                        onPressed: () {
                          _showRegionDialog(context, ref, regionId: region.id, initialName: region.name);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Supprimer la région'),
                              content: Text('Êtes-vous sûr de vouloir supprimer ${region.name} ? Toutes les villes associées pourraient être affectées.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Annuler'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    ref.read(regionActionsProvider.notifier).deleteRegion(region.id);
                                  },
                                  child: const Text('Supprimer'),
                                ),
                              ],
                            ),
                          );
                        },
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
        onPressed: () => _showRegionDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showRegionDialog(BuildContext context, WidgetRef ref, {String? regionId, String? initialName}) {
    final controller = TextEditingController(text: initialName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(regionId == null ? 'Nouvelle région' : 'Modifier la région'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Nom de la région'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                if (regionId == null) {
                  ref.read(regionActionsProvider.notifier).createRegion({'name': controller.text});
                } else {
                  ref.read(regionActionsProvider.notifier).updateRegion(regionId, {'name': controller.text});
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}

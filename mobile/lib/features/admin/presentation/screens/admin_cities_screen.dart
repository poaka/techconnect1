import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../technicians/domain/region.dart';
import '../../../technicians/presentation/providers/technicians_providers.dart';
import '../providers/admin_providers.dart';

class AdminCitiesScreen extends ConsumerWidget {
  const AdminCitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final citiesAsync = ref.watch(citiesProvider);
    final regionsAsync = ref.watch(regionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Villes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(citiesProvider);
              ref.invalidate(regionsProvider);
            },
          ),
        ],
      ),
      body: citiesAsync.when(
        data: (cities) {
          if (cities.isEmpty) {
            return const Center(child: Text('Aucune ville trouvée.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(citiesProvider);
              ref.invalidate(regionsProvider);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cities.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final city = cities[index];
                return ListTile(
                  title: Text(city.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Région: ${city.regionName ?? 'Inconnue'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: AppColors.primary),
                        onPressed: () {
                          if (regionsAsync.value != null) {
                            _showCityDialog(
                              context, 
                              ref, 
                              regions: regionsAsync.value!, 
                              cityId: city.id, 
                              initialName: city.name,
                              initialRegionId: city.regionId,
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Supprimer la ville'),
                              content: Text('Êtes-vous sûr de vouloir supprimer ${city.name} ?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Annuler'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    ref.read(cityActionsProvider.notifier).deleteCity(city.id);
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
        onPressed: () {
          if (regionsAsync.value != null) {
            _showCityDialog(context, ref, regions: regionsAsync.value!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Veuillez patienter, chargement des régions en cours...')),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCityDialog(BuildContext context, WidgetRef ref, {
    required List<Region> regions, 
    String? cityId, 
    String? initialName,
    String? initialRegionId,
  }) {
    final controller = TextEditingController(text: initialName);
    String? selectedRegionId = initialRegionId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(cityId == null ? 'Nouvelle ville' : 'Modifier la ville'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Nom de la ville'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Région'),
                  value: selectedRegionId,
                  items: regions.map((r) => DropdownMenuItem(
                    value: r.id,
                    child: Text(r.name),
                  )).toList(),
                  onChanged: (val) {
                    setState(() {
                      selectedRegionId = val;
                    });
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () {
                  if (controller.text.isNotEmpty && selectedRegionId != null) {
                    if (cityId == null) {
                      ref.read(cityActionsProvider.notifier).createCity({
                        'name': controller.text,
                        'regionId': selectedRegionId,
                      });
                    } else {
                      ref.read(cityActionsProvider.notifier).updateCity(cityId, {
                        'name': controller.text,
                        'regionId': selectedRegionId,
                      });
                    }
                    Navigator.pop(ctx);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez remplir tous les champs')),
                    );
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          );
        }
      ),
    );
  }
}

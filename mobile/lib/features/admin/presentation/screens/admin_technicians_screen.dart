import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/admin_providers.dart';

class AdminTechniciansScreen extends ConsumerWidget {
  final bool filterVerified;

  const AdminTechniciansScreen({super.key, this.filterVerified = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final techniciansAsync = ref.watch(adminTechniciansProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(filterVerified ? 'Techniciens Vérifiés' : 'Techniciens'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminTechniciansProvider),
          ),
        ],
      ),
      body: techniciansAsync.when(
        data: (allTechnicians) {
          final technicians = filterVerified 
              ? allTechnicians.where((t) => t.isVerified).toList() 
              : allTechnicians;
              
          if (technicians.isEmpty) {
            return Center(
              child: Text(filterVerified 
                  ? 'Aucun technicien vérifié trouvé.' 
                  : 'Aucun technicien trouvé.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminTechniciansProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: technicians.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final tech = technicians[index];
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: tech.isVerified ? AppColors.success.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                    child: Icon(
                      tech.isVerified ? Icons.verified : Icons.pending_actions,
                      color: tech.isVerified ? AppColors.success : Colors.orange,
                    ),
                  ),
                  title: Text(tech.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tech.email ?? 'Pas d\'email'),
                      Text('${tech.cityName ?? "Ville inconnue"} • ${tech.yearsExperience} ans d\'exp.'),
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(tech.ratingAvg.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/admin_providers.dart';

class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We fetch all users by passing null as role
    final usersAsync = ref.watch(adminUsersProvider(null));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminUsersProvider),
          ),
        ],
      ),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return const Center(child: Text('Aucun utilisateur trouvé.'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminUsersProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final user = users[index];
                final dateFormatted = user.createdAt != null 
                    ? DateFormat('dd MMM yyyy').format(user.createdAt!)
                    : 'Inconnu';
                
                IconData roleIcon = Icons.person;
                Color roleColor = Colors.grey;
                if (user.role.name == 'technician') {
                  roleIcon = Icons.engineering;
                  roleColor = Colors.orange;
                } else if (user.role.name == 'admin') {
                  roleIcon = Icons.admin_panel_settings;
                  roleColor = Colors.red;
                }

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: roleColor.withOpacity(0.2),
                    child: Icon(roleIcon, color: roleColor),
                  ),
                  title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email),
                      if (user.phone != null) Text(user.phone!),
                      const SizedBox(height: 4),
                      Text('Inscrit le: $dateFormatted', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: Chip(
                    label: Text(
                      user.role.name.toUpperCase(),
                      style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: roleColor.withOpacity(0.1),
                    side: BorderSide.none,
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

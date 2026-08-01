import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/admin_providers.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(_selectedRole));

    return Scaffold(
      appBar: AppBar(
        title: usersAsync.when(
          data: (users) {
            if (_selectedRole == 'client') {
              return Text('Clients (${users.length})');
            } else if (_selectedRole == 'technician') {
              return Text('Techniciens (${users.length})');
            }
            return Text('Utilisateurs (${users.length})');
          },
          loading: () => const Text('Utilisateurs'),
          error: (_, __) => const Text('Utilisateurs'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminUsersProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SegmentedButton<String?>(
              segments: const [
                ButtonSegment<String?>(value: null, label: Text('Tous')),
                ButtonSegment<String?>(value: 'client', label: Text('Clients')),
                ButtonSegment<String?>(value: 'technician', label: Text('Techniciens')),
              ],
              selected: {_selectedRole},
              onSelectionChanged: (Set<String?> newSelection) {
                setState(() {
                  _selectedRole = newSelection.first;
                });
              },
            ),
          ),
        ),
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(
                          user.role.name.toUpperCase(),
                          style: TextStyle(color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: roleColor.withOpacity(0.1),
                        side: BorderSide.none,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            builder: (ctx) => Container(
                              padding: const EdgeInsets.all(24),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Supprimer l\'utilisateur',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Êtes-vous sûr de vouloir supprimer ${user.fullName} ? Cette action est irréversible.',
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => Navigator.pop(ctx),
                                          child: const Text('Annuler'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            ref.read(userActionsProvider.notifier).deleteUser(user.id);
                                          },
                                          child: const Text('Supprimer'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
    );
  }
}

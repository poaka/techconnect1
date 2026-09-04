import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/service_request.dart';
import '../providers/admin_providers.dart';

class AdminServiceRequestsScreen extends ConsumerStatefulWidget {
  const AdminServiceRequestsScreen({super.key});

  @override
  ConsumerState<AdminServiceRequestsScreen> createState() => _AdminServiceRequestsScreenState();
}

class _AdminServiceRequestsScreenState extends ConsumerState<AdminServiceRequestsScreen> {
  String? _selectedStatus;

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.unassigned:
        return Colors.orange;
      case RequestStatus.assigned:
      case RequestStatus.inProgress:
        return AppColors.primary;
      case RequestStatus.completed:
        return AppColors.success;
      case RequestStatus.cancelled:
        return AppColors.error;
    }
  }

  void _showRequestDetailsModal(BuildContext context, ServiceRequest request) {
    final clientName = request.client?.fullName ?? 'Client inconnu';
    final clientEmail = request.client?.email ?? 'N/A';
    final clientPhone = request.client?.phone ?? 'N/A';

    final techName = request.technician?.fullName ?? 'Technicien inconnu';
    final techEmail = request.technician?.email ?? 'N/A';

    final categoryName = request.category?.name ?? 'Non spécifiée';
    final dateFormatted = DateFormat('dd MMM yyyy, HH:mm').format(request.createdAt);
    final completedFormatted = request.completedAt != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(request.completedAt!)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Détails de la demande', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(request.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  request.status.label.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(request.status),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Category
              Row(
                children: [
                  const Icon(Icons.category_outlined, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text('Catégorie: $categoryName', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              const Text('Description:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(request.description ?? 'Aucune description fournie.'),
              ),
              const SizedBox(height: 16),

              // Address
              if (request.address != null && request.address!.isNotEmpty) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Adresse: ${request.address}')),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              const Divider(),
              const SizedBox(height: 12),

              // Client Details
              const Text('Information Client', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 6),
              Text('Nom: $clientName'),
              Text('Email: $clientEmail'),
              Text('Téléphone: $clientPhone'),
              const SizedBox(height: 16),

              // Technician Details
              const Text('Information Technicien', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 6),
              Text('Nom: $techName'),
              Text('Email: $techEmail'),
              const SizedBox(height: 16),

              const Divider(),
              const SizedBox(height: 12),

              // Dates
              Text('Créée le: $dateFormatted', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (completedFormatted != null)
                Text('Terminée le: $completedFormatted', style: const TextStyle(fontSize: 12, color: AppColors.success)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(adminServiceRequestsProvider(_selectedStatus));

    return Scaffold(
      appBar: AppBar(
        title: requestsAsync.when(
          data: (list) => Text('Demandes (${list.length})'),
          loading: () => const Text('Demandes'),
          error: (_, __) => const Text('Demandes'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminServiceRequestsProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Toutes'),
                  selected: _selectedStatus == null,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedStatus = null);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('En attente'),
                  selected: _selectedStatus == 'pending',
                  onSelected: (selected) {
                    setState(() => _selectedStatus = selected ? 'pending' : null);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('En cours'),
                  selected: _selectedStatus == 'in_progress',
                  onSelected: (selected) {
                    setState(() => _selectedStatus = selected ? 'in_progress' : null);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Terminées'),
                  selected: _selectedStatus == 'completed',
                  onSelected: (selected) {
                    setState(() => _selectedStatus = selected ? 'completed' : null);
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Annulées'),
                  selected: _selectedStatus == 'cancelled',
                  onSelected: (selected) {
                    setState(() => _selectedStatus = selected ? 'cancelled' : null);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: requestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(adminServiceRequestsProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Aucune demande de service trouvée.', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminServiceRequestsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final req = requests[index];
                final clientName = req.client?.fullName ?? 'Client inconnu';
                final techName = req.technician?.fullName ?? 'Technicien inconnu';
                final catName = req.category?.name ?? 'Service';
                final dateStr = DateFormat('dd MMM yyyy').format(req.createdAt);
                final statusColor = _getStatusColor(req.status);

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.assignment_outlined, color: statusColor),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '$clientName ➔ $techName',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            req.status.label,
                            style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Catégorie: $catName', style: const TextStyle(fontWeight: FontWeight.w500)),
                          if (req.description != null)
                            Text(
                              req.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          const SizedBox(height: 4),
                          Text('Créée le: $dateStr', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showRequestDetailsModal(context, req),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text('Erreur: $err'),
              TextButton(
                onPressed: () => ref.invalidate(adminServiceRequestsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

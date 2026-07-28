import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/service_request.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/auth_provider.dart';
import '../providers/requests_providers.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  bool _isUpdating = false;

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending:
        return Colors.orange;
      case RequestStatus.accepted:
      case RequestStatus.inProgress:
        return AppColors.primary;
      case RequestStatus.completed:
        return AppColors.success;
      case RequestStatus.rejected:
      case RequestStatus.cancelled:
        return AppColors.error;
    }
  }

  Future<void> _updateStatus(RequestStatus newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await ref.read(requestListProvider.notifier).updateStatus(widget.requestId, newStatus);
      if (mounted) {
        ref.invalidate(requestDetailProvider(widget.requestId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statut mis à jour avec succès'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Widget _buildActionButtons(ServiceRequest request, bool isTechnician) {
    if (isTechnician) {
      if (request.status == RequestStatus.pending) {
        return Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Refuser',
                isOutlined: true,
                onPressed: _isUpdating ? null : () => _updateStatus(RequestStatus.rejected),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: 'Accepter',
                onPressed: _isUpdating ? null : () => _updateStatus(RequestStatus.accepted),
              ),
            ),
          ],
        );
      } else if (request.status == RequestStatus.accepted) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'Démarrer l\'intervention',
            onPressed: _isUpdating ? null : () => _updateStatus(RequestStatus.inProgress),
          ),
        );
      } else if (request.status == RequestStatus.inProgress) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'Marquer comme terminée',
            onPressed: _isUpdating ? null : () => _updateStatus(RequestStatus.completed),
          ),
        );
      }
    } else { // Client
      if (request.status == RequestStatus.pending || request.status == RequestStatus.accepted) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            text: 'Annuler la demande',
            isOutlined: true,
            color: AppColors.error,
            onPressed: _isUpdating ? null : () => _updateStatus(RequestStatus.cancelled),
          ),
        );
      } else if (request.status == RequestStatus.completed) {
        if (!request.hasReview) {
          return SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Évaluer ce service',
              onPressed: () => context.push('/requests/${request.id}/review'),
            ),
          );
        } else {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.successBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                SizedBox(width: 8),
                Text(
                  'Vous avez évalué ce service',
                  style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }
      }
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(requestDetailProvider(widget.requestId));
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final isTechnician = user?.role.name.toLowerCase() == 'technician';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la demande'),
      ),
      body: detailAsync.when(
        data: (request) {
          final statusColor = _getStatusColor(request.status);
          final formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(request.createdAt);
          
          final otherPartyName = isTechnician
              ? (request.client?.fullName ?? 'Client')
              : (request.technician?.fullName ?? 'Artisan');
          
          final otherPartyPhone = isTechnician
              ? request.client?.phone
              : request.technician?.phone;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: statusColor, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Statut : ${request.status.label}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Cards
                  _buildSectionHeader('À propos'),
                  _buildInfoCard([
                    _buildInfoRow('Demande du', formattedDate),
                    if (request.category != null) ...[
                      const Divider(),
                      _buildInfoRow('Catégorie', request.category!.name),
                    ]
                  ]),
                  
                  const SizedBox(height: 20),
                  _buildSectionHeader(isTechnician ? 'Client' : 'Artisan'),
                  _buildInfoCard([
                    _buildInfoRow('Nom', otherPartyName),
                    const Divider(),
                    _buildInfoRow('Contact', otherPartyPhone ?? 'Non renseigné'),
                  ]),

                  const SizedBox(height: 20),
                  _buildSectionHeader('Description du besoin'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      request.description ?? 'Aucune description fournie.',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),

                  if (request.address != null && request.address!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader('Adresse'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              request.address!,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  
                  if (_isUpdating)
                    const Center(child: CircularProgressIndicator())
                  else
                    _buildActionButtons(request, isTechnician),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Erreur: $error')),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

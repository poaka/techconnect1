import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/location_service.dart';
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

  Future<void> _updateStatus(Future<ServiceRequest> Function() updateAction) async {
    setState(() => _isUpdating = true);
    try {
      await updateAction();
      if (mounted) {
        ref.invalidate(requestDetailProvider(widget.requestId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action effectuée avec succès'), backgroundColor: AppColors.success),
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

  Future<void> _shareLocation() async {
    setState(() => _isUpdating = true);
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      
      final repository = ref.read(requestsRepositoryProvider);
      await repository.updateLocation(widget.requestId, position.latitude, position.longitude);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Position partagée avec succès !'), backgroundColor: AppColors.success),
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

  Widget _buildActionButtons(BuildContext context, ServiceRequest request, bool isTechnician) {
    if (isTechnician) {
      // In Phase 8+, technician no longer accepts/rejects directly in detail screen (they do it via offers API).
      // They can only mark inProgress -> completed.
      // Or assigned -> inProgress (if implemented). Currently backend just has completeRequest.
      if (request.status == RequestStatus.inProgress || request.status == RequestStatus.assigned) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            text: context.tr('mark_completed'),
            onPressed: _isUpdating ? null : () => _updateStatus(() => ref.read(requestListProvider.notifier).completeRequest(widget.requestId)),
          ),
        );
      }
    } else { // Client
      if (request.status == RequestStatus.unassigned || request.status == RequestStatus.assigned) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            text: context.tr('cancel_request'),
            isOutlined: true,
            color: AppColors.error,
            onPressed: _isUpdating ? null : () => _updateStatus(() => ref.read(requestListProvider.notifier).cancelRequest(widget.requestId)),
          ),
        );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.border;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('request_detail_title')),
      ),
      body: detailAsync.when(
        data: (request) {
          final statusColor = _getStatusColor(request.status);
          final formattedDate = DateFormat('dd/MM/yyyy à HH:mm').format(request.createdAt);
          
          final otherPartyName = isTechnician
              ? (request.client?.fullName ?? context.tr('unknown_client'))
              : (request.technician?.fullName ?? context.tr('unknown_tech'));
          
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
                          '${context.tr('request_info')} : ${request.status.getLocalizedLabel(context)}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Info Cards
                  _buildSectionHeader(context.tr('request_info'), secondaryTextColor),
                  _buildInfoCard(cardBg, cardBorder, [
                    _buildInfoRow(context.tr('date'), formattedDate, secondaryTextColor, textColor),
                    if (request.category != null) ...[
                      Divider(color: cardBorder),
                      _buildInfoRow('Catégorie', request.category!.name, secondaryTextColor, textColor),
                    ]
                  ]),
                  
                  const SizedBox(height: 20),
                  _buildSectionHeader(isTechnician ? context.tr('client_info') : context.tr('technician_info'), secondaryTextColor),
                  _buildInfoCard(cardBg, cardBorder, [
                    _buildInfoRow('Nom', otherPartyName, secondaryTextColor, textColor),
                    Divider(color: cardBorder),
                    _buildInfoRow(context.tr('phone'), otherPartyPhone ?? context.tr('not_provided'), secondaryTextColor, textColor),
                  ]),

                  const SizedBox(height: 20),
                  _buildSectionHeader(context.tr('description'), secondaryTextColor),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Text(
                      request.description ?? context.tr('no_description'),
                      style: TextStyle(fontSize: 15, color: textColor),
                    ),
                  ),

                  if (request.imageUrl != null) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader('Photo', secondaryTextColor),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        request.imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, color: Colors.grey, size: 48),
                        ),
                      ),
                    ),
                  ],

                  if (request.address != null && request.address!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(context.tr('address'), secondaryTextColor),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on_outlined, color: isDark ? AppColors.primaryLight : AppColors.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              request.address!,
                              style: TextStyle(fontSize: 15, color: textColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (request.status == RequestStatus.inProgress || request.status == RequestStatus.assigned) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader('Suivi GPS', secondaryTextColor),
                    if (isTechnician)
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: 'Partager ma position',
                          icon: Icons.my_location,
                          onPressed: _isUpdating ? null : _shareLocation,
                        ),
                      )
                    else
                      _buildClientLocationTracker(cardBg, cardBorder, request.id),
                  ],

                  const SizedBox(height: 32),
                  
                  if (_isUpdating)
                    const Center(child: CircularProgressIndicator())
                  else
                    _buildActionButtons(context, request, isTechnician),
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

  Widget _buildSectionHeader(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }

  Widget _buildInfoCard(Color cardBg, Color cardBorder, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: labelColor, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: valueColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientLocationTracker(Color cardBg, Color cardBorder, String requestId) {
    final locationAsync = ref.watch(requestLocationProvider(requestId));
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: locationAsync.when(
        data: (location) {
          if (location == null) {
            return Column(
              children: [
                const Icon(Icons.location_off_outlined, color: Colors.grey, size: 32),
                const SizedBox(height: 8),
                const Text(
                  'Le technicien n\'a pas encore partagé sa position.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => ref.refresh(requestLocationProvider(requestId)),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser'),
                )
              ],
            );
          }

          final lat = location['latitude'];
          final lng = location['longitude'];
          final updatedAt = DateTime.parse(location['updated_at']).toLocal();
          final formattedTime = DateFormat('HH:mm').format(updatedAt);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.my_location, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Position mise à jour à $formattedTime',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: () => ref.refresh(requestLocationProvider(requestId)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Ouvrir dans Maps',
                  icon: Icons.map_outlined,
                  isOutlined: true,
                  onPressed: () async {
                    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Impossible d\'ouvrir la carte.')),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
      ),
    );
  }
}

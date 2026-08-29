import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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

  Future<void> _shareLocation() async {
    setState(() => _isUpdating = true);
    try {
      final locationService = ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();
      
      final repository = ref.read(requestsRepositoryProvider);
      await repository.updateLocation(widget.requestId, position.latitude, position.longitude);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('position_shared')), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error_prefix')}$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _confirmStartJob() async {
    final messenger = ScaffoldMessenger.of(context);
    final startedText = context.tr('job_started');
    final errPrefix = context.tr('error_prefix');
    final startJobText = context.tr('start_job');
    final confirmStartJobText = context.tr('confirm_start_job');
    final cancelText = context.tr('cancel');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(startJobText),
        content: Text(confirmStartJobText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(startJobText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isUpdating = true);
      try {
        await ref.read(requestListProvider.notifier).startRequest(widget.requestId);
        ref.invalidate(requestDetailProvider(widget.requestId));
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(startedText), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('$errPrefix$e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _confirmCompleteJob() async {
    final messenger = ScaffoldMessenger.of(context);
    final completedText = context.tr('action_success');
    final errPrefix = context.tr('error_prefix');
    final markCompletedText = context.tr('mark_completed');
    final confirmCompleteText = context.tr('confirm_complete_job');
    final cancelText = context.tr('cancel');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(markCompletedText),
        content: Text(confirmCompleteText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(markCompletedText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isUpdating = true);
      try {
        await ref.read(requestListProvider.notifier).completeRequest(widget.requestId);
        ref.invalidate(requestDetailProvider(widget.requestId));
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(completedText), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('$errPrefix$e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _confirmCancelRequest() async {
    final messenger = ScaffoldMessenger.of(context);
    final cancelledText = context.tr('action_success');
    final errPrefix = context.tr('error_prefix');
    final cancelReqText = context.tr('cancel_request');
    final confirmCancelText = context.tr('confirm_cancel_request');
    final cancelText = context.tr('cancel');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(cancelReqText),
        content: Text(confirmCancelText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(cancelReqText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isUpdating = true);
      try {
        await ref.read(requestListProvider.notifier).cancelRequest(widget.requestId);
        ref.invalidate(requestDetailProvider(widget.requestId));
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(cancelledText), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('$errPrefix$e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _confirmDelete(ServiceRequest request) async {
    // Extract text before async gap to fix use_build_context_synchronously
    final deleteTitle = context.tr('delete_request_title');
    final deleteConfirm = context.tr('confirm_delete_request');
    final cancelText = context.tr('cancel');
    final deleteText = context.tr('delete_request');
    final deletedText = context.tr('request_deleted');
    final errPrefix = context.tr('error_prefix');
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(deleteTitle),
        content: Text(deleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(deleteText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _isUpdating = true);
      try {
        await ref.read(requestListProvider.notifier).deleteRequest(request.id);
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(deletedText), backgroundColor: AppColors.success),
          );
          if (mounted && Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('$errPrefix$e'), backgroundColor: AppColors.error),
          );
        }
      } finally {
        if (mounted) setState(() => _isUpdating = false);
      }
    }
  }

  void _showEditBottomSheet(BuildContext ctx, ServiceRequest request) {
    final descController = TextEditingController(text: request.description);
    final addressController = TextEditingController(text: request.address);
    File? newImageFile;
    final picker = ImagePicker();

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetCtx) => StatefulBuilder(
        builder: (context, setModalState) {
          Future<void> pickPhoto(ImageSource source) async {
            final messenger = ScaffoldMessenger.of(context);
            final errPrefix = context.tr('error_prefix');
            try {
              final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
              if (pickedFile != null) {
                setModalState(() {
                  newImageFile = File(pickedFile.path);
                });
              }
            } catch (e) {
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text('$errPrefix$e')),
                );
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(bottomSheetCtx).viewInsets.bottom + 20,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    ctx.tr('edit_request_title'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: ctx.tr('description'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: addressController,
                    decoration: InputDecoration(
                      labelText: ctx.tr('address'),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Photo preview / selector
                  Text(
                    ctx.tr('photo_label'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  if (newImageFile != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            newImageFile!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setModalState(() => newImageFile = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (request.imageUrl != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            request.imageUrl!,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            onPressed: () => pickPhoto(ImageSource.gallery),
                            icon: const Icon(Icons.edit, size: 16),
                            label: Text(ctx.tr('change_photo')),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickPhoto(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: Text(ctx.tr('camera')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickPhoto(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: Text(ctx.tr('gallery')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: ctx.tr('update_request'),
                    onPressed: () async {
                      final newDesc = descController.text.trim();
                      final newAddr = addressController.text.trim();
                      final messenger = ScaffoldMessenger.of(context);
                      final updatedText = context.tr('request_updated');
                      final errPrefix = context.tr('error_prefix');

                      Navigator.of(bottomSheetCtx).pop();
                      
                      setState(() => _isUpdating = true);
                      try {
                        await ref.read(requestListProvider.notifier).updateRequest(
                          request.id,
                          {
                            'description': newDesc,
                            'address': newAddr,
                          },
                          imagePath: newImageFile?.path,
                        );
                        ref.invalidate(requestDetailProvider(widget.requestId));
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(updatedText), backgroundColor: AppColors.success),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text('$errPrefix$e'), backgroundColor: AppColors.error),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _isUpdating = false);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  Future<void> _acceptRequestAsTech() async {
    final messenger = ScaffoldMessenger.of(context);
    final acceptedText = context.tr('offer_accepted');
    final errPrefix = context.tr('error_prefix');

    setState(() => _isUpdating = true);
    try {
      await ref.read(requestListProvider.notifier).acceptRequest(widget.requestId);
      ref.invalidate(requestDetailProvider(widget.requestId));
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(acceptedText), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('$errPrefix$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Widget _buildActionButtons(BuildContext context, ServiceRequest request, bool isTechnician) {
    if (isTechnician) {
      // Technician sees Accept/Reject for unassigned incoming requests
      if (request.status == RequestStatus.unassigned) {
        return Row(
          children: [
            Expanded(
              child: AppButton(
                text: context.tr('reject'),
                isOutlined: true,
                color: AppColors.error,
                onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppButton(
                text: context.tr('accept'),
                color: AppColors.success,
                onPressed: _isUpdating ? null : _acceptRequestAsTech,
              ),
            ),
          ],
        );
      }
      // Technician sees Start Job when assigned
      if (request.status == RequestStatus.assigned) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: context.tr('start_job'),
                icon: Icons.play_arrow_rounded,
                onPressed: _isUpdating ? null : _confirmStartJob,
              ),
            ),
          ],
        );
      }
      // Technician sees Complete Job when in_progress
      if (request.status == RequestStatus.inProgress) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            text: context.tr('mark_completed'),
            onPressed: _isUpdating ? null : _confirmCompleteJob,
          ),
        );
      }
    } else {
      // Client: edit/cancel/delete for unassigned
      if (request.status == RequestStatus.unassigned) {
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: AppButton(
                text: context.tr('edit_request'),
                onPressed: _isUpdating ? null : () => _showEditBottomSheet(context, request),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: context.tr('cancel_request'),
                    isOutlined: true,
                    color: Colors.orange,
                    onPressed: _isUpdating ? null : _confirmCancelRequest,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: context.tr('delete_request'),
                    isOutlined: true,
                    color: AppColors.error,
                    onPressed: _isUpdating ? null : () => _confirmDelete(request),
                  ),
                ),
              ],
            ),
          ],
        );
      }
      // Client can cancel when assigned (job not started yet)
      if (request.status == RequestStatus.assigned) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            text: context.tr('cancel_request'),
            isOutlined: true,
            color: Colors.orange,
            onPressed: _isUpdating ? null : _confirmCancelRequest,
          ),
        );
      }
      // Client can leave review after completion (if no review yet)
      if (request.status == RequestStatus.completed && !request.hasReview) {
        return SizedBox(
          width: double.infinity,
          child: AppButton(
            text: context.tr('leave_review'),
            icon: Icons.star_rounded,
            onPressed: () {
              context.push('/requests/${request.id}/review');
            },
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
                      _buildInfoRow(context.tr('category'), request.category!.name, secondaryTextColor, textColor),
                    ]
                  ]),
                  
                  const SizedBox(height: 20),
                  _buildSectionHeader(context.tr('client_information'), secondaryTextColor),
                  _buildInfoCard(cardBg, cardBorder, [
                    _buildInfoRow(context.tr('name_label'), request.client?.fullName ?? user?.fullName ?? context.tr('not_provided'), secondaryTextColor, textColor),
                    Divider(color: cardBorder),
                    _buildInfoRow(context.tr('phone'), request.client?.phone ?? user?.phone ?? context.tr('not_provided'), secondaryTextColor, textColor),
                    if ((request.client?.email ?? user?.email) != null && (request.client?.email ?? user?.email)!.isNotEmpty) ...[
                      Divider(color: cardBorder),
                      _buildInfoRow(context.tr('email_label'), request.client?.email ?? user?.email ?? '', secondaryTextColor, textColor),
                    ]
                  ]),

                  if (request.technician != null) ...[
                    const SizedBox(height: 20),
                    _buildSectionHeader(context.tr('technician_info'), secondaryTextColor),
                    _buildInfoCard(cardBg, cardBorder, [
                      _buildInfoRow(context.tr('name_label'), request.technician!.fullName, secondaryTextColor, textColor),
                      if (request.technician!.phone != null && request.technician!.phone!.isNotEmpty) ...[
                        Divider(color: cardBorder),
                        _buildInfoRow(context.tr('phone'), request.technician!.phone!, secondaryTextColor, textColor),
                      ]
                    ]),
                  ],

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
                    _buildSectionHeader(context.tr('photo_label'), secondaryTextColor),
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
                    _buildSectionHeader(context.tr('gps_tracking'), secondaryTextColor),
                    if (isTechnician)
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: context.tr('share_location'),
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
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text(
                  '${context.tr('error_prefix')}$error',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(requestDetailProvider(widget.requestId)),
                  child: Text(context.tr('retry')),
                ),
              ],
            ),
          ),
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
                Text(
                  context.tr('location_not_shared'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => ref.refresh(requestLocationProvider(requestId)),
                  icon: const Icon(Icons.refresh),
                  label: Text(context.tr('refresh')),
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
                      '${context.tr('location_updated_at')}$formattedTime',
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
                  text: context.tr('open_maps'),
                  icon: Icons.map_outlined,
                  isOutlined: true,
                  onPressed: () async {
                    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(context.tr('cannot_open_maps'))),
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
        error: (err, _) => Center(child: Text('${context.tr('error_prefix')}$err')),
      ),
    );
  }
}

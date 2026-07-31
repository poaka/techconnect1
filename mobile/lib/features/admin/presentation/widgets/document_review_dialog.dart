import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/technician_document.dart';
import '../providers/admin_providers.dart';

class DocumentReviewDialog extends ConsumerStatefulWidget {
  final TechnicianDocument document;

  const DocumentReviewDialog({super.key, required this.document});

  @override
  ConsumerState<DocumentReviewDialog> createState() => _DocumentReviewDialogState();
}

class _DocumentReviewDialogState extends ConsumerState<DocumentReviewDialog> {
  final _reasonController = TextEditingController();
  bool _isRejecting = false;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _approve() {
    ref.read(reviewDocumentProvider.notifier).reviewDocument(
      documentId: widget.document.id,
      status: 'approved',
    );
    Navigator.of(context).pop();
  }

  void _reject() {
    if (!_isRejecting) {
      setState(() => _isRejecting = true);
      return;
    }
    
    final reason = _reasonController.text.trim();
    if (reason.isEmpty) return;

    ref.read(reviewDocumentProvider.notifier).reviewDocument(
      documentId: widget.document.id,
      status: 'rejected',
      rejectionReason: reason,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Vérification: ${widget.document.documentType.toUpperCase()}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              if (widget.document.technician != null) ...[
                Text(
                  'Technicien: ${widget.document.technician!.fullName}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text('Email: ${widget.document.technician!.email ?? "N/A"}'),
                Text('Ville: ${widget.document.technician!.cityName ?? "N/A"}'),
                const SizedBox(height: 16),
              ],

              // Document Preview
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: widget.document.fileUrl.toLowerCase().endsWith('.pdf')
                  ? const Center(child: Icon(Icons.picture_as_pdf, size: 64, color: Colors.red))
                  : CachedNetworkImage(
                      imageUrl: widget.document.fileUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                    ),
              ),

              const SizedBox(height: 24),

              if (_isRejecting) ...[
                TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: 'Motif de rejet',
                    hintText: 'Ex: Document flou, expiré, etc.',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
              ],

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      child: const Text('Rejeter'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (!_isRejecting)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _approve,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Approuver'),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

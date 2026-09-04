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

  String _resolveUrl(String rawUrl) {
    if (rawUrl.isEmpty) return '';
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    const base = 'https://fixerpro2371-api.onrender.com';
    final cleanPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
    return '$base$cleanPath';
  }

  void _openFullScreenViewer(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                  errorWidget: (context, url, error) => const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.broken_image, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Impossible de charger le document en haute résolution.', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
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
    final fullUrl = _resolveUrl(widget.document.fileUrl);
    final isPdf = widget.document.fileUrl.toLowerCase().endsWith('.pdf');

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Vérification: ${widget.document.documentType.toUpperCase()}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              if (widget.document.technician != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Technicien: ${widget.document.technician!.fullName}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('Email: ${widget.document.technician!.email ?? "N/A"}'),
                      Text('Ville: ${widget.document.technician!.cityName ?? "N/A"}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Document Preview Card
              GestureDetector(
                onTap: (!isPdf && fullUrl.isNotEmpty) ? () => _openFullScreenViewer(context, fullUrl) : null,
                child: Container(
                  height: 250,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: isPdf
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                              SizedBox(height: 8),
                              Text('Document PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : fullUrl.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.file_present_outlined, size: 64, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Aucun fichier joint'),
                                ],
                              ),
                            )
                          : Stack(
                              children: [
                                InteractiveViewer(
                                  minScale: 1.0,
                                  maxScale: 3.0,
                                  child: Center(
                                    child: CachedNetworkImage(
                                      imageUrl: fullUrl,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: double.infinity,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) => Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.broken_image, size: 56, color: Colors.grey),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Aperçu indisponible',
                                            style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            fullUrl,
                                            style: const TextStyle(fontSize: 10, color: Colors.grey),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.6),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.fullscreen, color: Colors.white, size: 16),
                                        SizedBox(width: 4),
                                        Text('Toucher pour agrandir', style: TextStyle(color: Colors.white, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
                      child: Text(_isRejecting ? 'Confirmer le rejet' : 'Rejeter'),
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

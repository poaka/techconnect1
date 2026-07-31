import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/admin_providers.dart';
import '../widgets/document_review_dialog.dart';

class PendingVerificationsScreen extends ConsumerWidget {
  const PendingVerificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docsAsync = ref.watch(pendingVerificationsProvider);
    final reviewState = ref.watch(reviewDocumentProvider);

    // Show loading overlay if a review is in progress
    if (reviewState.isLoading) {
      // In a real app we might use a full-screen overlay, but we can rely on UI blocking
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérifications en attente'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(pendingVerificationsProvider),
          ),
        ],
      ),
      body: docsAsync.when(
        data: (docs) {
          if (docs.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(pendingVerificationsProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: AppColors.success),
                          SizedBox(height: 16),
                          Text('Aucune vérification en attente.', style: TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(pendingVerificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final techName = doc.technician?.fullName ?? 'Inconnu';
                final dateFormatted = DateFormat('dd MMM yyyy, HH:mm').format(doc.uploadedAt);

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primarySubtle.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.description_outlined, color: AppColors.primary),
                    ),
                    title: Text(techName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Type: ${doc.documentType.toUpperCase()}'),
                          Text('Soumis le: $dateFormatted', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => DocumentReviewDialog(document: doc),
                      );
                    },
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
              const Text('Erreur lors du chargement des documents'),
              TextButton(
                onPressed: () => ref.invalidate(pendingVerificationsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

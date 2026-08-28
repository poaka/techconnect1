import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/offers_providers.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(offersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('new_offers_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(offersListProvider.notifier).fetchOffers(),
          ),
        ],
      ),
      body: offersAsync.when(
        data: (offers) {
          if (offers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('no_offers'),
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(offersListProvider.notifier).fetchOffers(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: offers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final offer = offers[index];
                return _OfferCard(offer: offer);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('${context.tr('error_prefix')}$err')),
      ),
    );
  }
}

class _OfferCard extends ConsumerStatefulWidget {
  final dynamic offer;
  const _OfferCard({required this.offer});

  @override
  ConsumerState<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends ConsumerState<_OfferCard> {
  bool _isLoading = false;

  Future<void> _acceptOffer() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(offersListProvider.notifier).acceptOffer(widget.offer['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('offer_accepted')), backgroundColor: AppColors.success),
        );
        context.push('/technician/requests');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error_prefix')}$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectOffer() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(offersListProvider.notifier).rejectOffer(widget.offer['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('offer_rejected'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.tr('error_prefix')}$e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer as Map<String, dynamic>;
    final request = offer['request'] as Map<String, dynamic>?;
    if (request == null) return const SizedBox.shrink();

    final expiresAtStr = offer['created_at'] as String?; // Assuming created_at + some time = expires_at if there is no expires_at
    final createdAt = expiresAtStr != null ? DateTime.parse(expiresAtStr) : DateTime.now();
    final expiresAt = createdAt.add(const Duration(hours: 24)); // Example logic for expiration
    final timeRemaining = expiresAt.difference(DateTime.now());
    final minutesLeft = timeRemaining.inMinutes;
    final isUrgent = minutesLeft <= 60;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request['category']?['name'] ?? context.tr('service'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUrgent ? AppColors.error.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: isUrgent ? AppColors.error : Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        minutesLeft > 0 ? '$minutesLeft${context.tr('mins_left')}' : context.tr('expires_soon'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isUrgent ? AppColors.error : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(request['client']?['full_name'] ?? context.tr('client'), style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
            if (request['address'] != null && request['address'].toString().isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(child: Text(request['address'], maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            if (request['description'] != null && request['description'].toString().isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  request['description'],
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: context.tr('reject'),
                      isOutlined: true,
                      color: AppColors.error,
                      onPressed: _rejectOffer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: context.tr('accept'),
                      color: AppColors.success,
                      onPressed: _acceptOffer,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

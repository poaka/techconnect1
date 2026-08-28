import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_button.dart';
import '../providers/reviews_providers.dart';
import '../../../requests/presentation/providers/requests_providers.dart';

class CreateReviewScreen extends ConsumerStatefulWidget {
  final String requestId;

  const CreateReviewScreen({super.key, required this.requestId});

  @override
  ConsumerState<CreateReviewScreen> createState() => _CreateReviewScreenState();
}

class _CreateReviewScreenState extends ConsumerState<CreateReviewScreen> {
  final _commentController = TextEditingController();
  int _rating = 0;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('rating_required'))),
      );
      return;
    }

    await ref.read(submitReviewProvider.notifier).submit(
      requestId: widget.requestId,
      rating: _rating.toDouble(),
      comment: _commentController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue>(submitReviewProvider, (previous, next) {
      if (next is AsyncData && next.value != null) {
        // Success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('thanks_for_review')),
            backgroundColor: AppColors.success,
          ),
        );
        // Refresh the requests list so it shows 'hasReview = true'
        ref.invalidate(requestListProvider);
        if (context.canPop()) {
          context.pop();
        }
      } else if (next is AsyncError) {
        final error = next.error;
        String msg = context.tr('error_sending_review');
        if (error is Failure) {
          msg = error.message;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.error),
        );
      }
    });

    final submitState = ref.watch(submitReviewProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('rate_service'))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('rate_prompt'),
                style: AppTypography.heading2,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('rate_desc'),
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 32),
              
              // Star Rating
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    final starIndex = index + 1;
                    return IconButton(
                      iconSize: 48,
                      onPressed: () {
                        setState(() {
                          _rating = starIndex;
                        });
                      },
                      icon: Icon(
                        _rating >= starIndex ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: AppColors.accentGold,
                      ),
                    );
                  }),
                ),
              ),
              if (_rating > 0)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _getRatingText(_rating),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                    ),
                  ),
                ),

              const SizedBox(height: 32),
              Text(
                context.tr('leave_comment'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: context.tr('comment_hint'),
                  filled: true,
                  fillColor: AppColors.inputBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: context.tr('submit_review'),
                  isLoading: submitState.isLoading,
                  onPressed: submitState.isLoading ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1: return context.tr('rating_1');
      case 2: return context.tr('rating_2');
      case 3: return context.tr('rating_3');
      case 4: return context.tr('rating_4');
      case 5: return context.tr('rating_5');
      default: return '';
    }
  }
}

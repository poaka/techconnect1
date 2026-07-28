import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/error/failures.dart';
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
        const SnackBar(content: Text('Veuillez donner une note de 1 à 5 étoiles.')),
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
          const SnackBar(
            content: Text('Merci pour votre avis !'),
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
        String msg = 'Erreur lors de l\'envoi de l\'avis';
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
      appBar: AppBar(title: const Text('Évaluer ce service')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Comment s\'est passée l\'intervention ?',
                style: AppTypography.heading2,
              ),
              const SizedBox(height: 8),
              const Text(
                'Votre avis aide les autres utilisateurs à choisir les meilleurs artisans.',
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
              const Text(
                'Laissez un commentaire (optionnel)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _commentController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Partagez les détails de votre expérience...',
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
                  text: 'Envoyer l\'avis',
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
      case 1: return 'Très déçu';
      case 2: return 'Déçu';
      case 3: return 'Correct';
      case 4: return 'Très bien';
      case 5: return 'Parfait, je recommande !';
      default: return '';
    }
  }
}

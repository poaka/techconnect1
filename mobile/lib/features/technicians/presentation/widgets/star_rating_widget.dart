import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class StarRatingWidget extends StatelessWidget {
  final double rating;
  final double size;
  final int count;
  final bool showText;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.size = 16,
    this.count = 0,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starValue = index + 1;
            if (rating >= starValue) {
              return Icon(Icons.star, color: AppColors.accent, size: size);
            } else if (rating >= starValue - 0.5) {
              return Icon(Icons.star_half, color: AppColors.accent, size: size);
            } else {
              return Icon(Icons.star_border, color: AppColors.border, size: size);
            }
          }),
        ),
        if (showText) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: size * 0.85,
              color: AppColors.textPrimary,
            ),
          ),
          if (count > 0) ...[
            Text(
              ' ($count)',
              style: TextStyle(
                fontSize: size * 0.75,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ],
    );
  }
}

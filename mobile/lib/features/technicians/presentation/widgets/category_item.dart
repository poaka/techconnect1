import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/category.dart';

class CategoryItem extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryItem({
    super.key,
    required this.category,
    this.isSelected = false,
    required this.onTap,
  });

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('électri')) return Icons.electric_bolt_rounded;
    if (lower.contains('plomb')) return Icons.plumbing_rounded;
    if (lower.contains('froid') || lower.contains('climat')) return Icons.ac_unit_rounded;
    if (lower.contains('menuis')) return Icons.carpenter_rounded;
    if (lower.contains('maçon')) return Icons.foundation_rounded;
    if (lower.contains('peint')) return Icons.format_paint_rounded;
    if (lower.contains('mécan')) return Icons.build_rounded;
    if (lower.contains('soud')) return Icons.hardware_rounded;
    if (lower.contains('électron') || lower.contains('télé')) return Icons.tv_rounded;
    if (lower.contains('coiff')) return Icons.content_cut_rounded;
    if (lower.contains('coutur')) return Icons.dry_cleaning_rounded;
    if (lower.contains('jardin')) return Icons.grass_rounded;
    return Icons.handyman_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getCategoryIcon(category.name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 84,
        margin: const EdgeInsets.only(right: 10.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.primarySubtle,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primaryDark : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 32, // Controlled height for max 2 lines of text
              child: Text(
                category.name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

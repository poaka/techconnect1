import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool isPassword;
  final IconData? prefixIcon;
  final int maxLines;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.prefixIcon,
    this.maxLines = 1,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final hintColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final iconColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final fillColor = isDark ? AppColors.darkInputBg : AppColors.inputBg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.caption.copyWith(
            color: labelColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          obscureText: widget.isPassword ? _obscureText : false,
          style: AppTypography.bodyLarge.copyWith(
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.bodyMedium.copyWith(color: hintColor),
            fillColor: fillColor,
            filled: true,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: iconColor, size: 20)
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility,
                      color: iconColor,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

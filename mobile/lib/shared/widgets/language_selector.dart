import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/locale_provider.dart';
import '../../core/theme/app_colors.dart';

class LanguageSelector extends ConsumerWidget {
  final bool isCompact;

  const LanguageSelector({
    super.key,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);

    return PopupMenuButton<String>(
      tooltip: 'Changer la langue / Change Language',
      icon: isCompact
          ? Text(
              currentLocale.languageCode.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.primary,
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(20),
                color: AppColors.surface,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentLocale.languageCode == 'fr' ? '🇫🇷 FR' : '🇬🇧 EN',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_drop_down,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
      onSelected: (String code) {
        ref.read(localeProvider.notifier).changeLanguage(code);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'fr',
          child: Row(
            children: [
              const Text('🇫🇷 ', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Français',
                style: TextStyle(
                  fontWeight: currentLocale.languageCode == 'fr'
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: currentLocale.languageCode == 'fr'
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
              if (currentLocale.languageCode == 'fr') ...[
                const Spacer(),
                const Icon(Icons.check, size: 18, color: AppColors.primary),
              ],
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'en',
          child: Row(
            children: [
              const Text('🇬🇧 ', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'English',
                style: TextStyle(
                  fontWeight: currentLocale.languageCode == 'en'
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: currentLocale.languageCode == 'en'
                      ? AppColors.primary
                      : AppColors.textPrimary,
                ),
              ),
              if (currentLocale.languageCode == 'en') ...[
                const Spacer(),
                const Icon(Icons.check, size: 18, color: AppColors.primary),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

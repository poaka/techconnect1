import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';
import '../../features/auth/presentation/auth_provider.dart';

class LocaleNotifier extends StateNotifier<Locale> {
  final StorageService _storageService;

  LocaleNotifier(this._storageService)
      : super(Locale(_storageService.getSavedLanguage()));

  /// Changes active language immediately and persists selection to GetStorage.
  Future<void> changeLanguage(String languageCode) async {
    if (state.languageCode == languageCode) return;
    final newLocale = Locale(languageCode);
    state = newLocale;
    await _storageService.saveLanguage(languageCode);
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return LocaleNotifier(storage);
});

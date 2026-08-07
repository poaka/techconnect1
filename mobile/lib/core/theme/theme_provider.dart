import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/storage_service.dart';
import '../../features/auth/presentation/auth_provider.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storageService;

  ThemeNotifier(this._storageService)
      : super(_storageService.isDarkMode() ? ThemeMode.dark : ThemeMode.light);

  /// Returns true if currently in dark mode.
  bool get isDarkMode => state == ThemeMode.dark;

  /// Toggles between light and dark theme mode, updating UI immediately and persisting to GetStorage.
  Future<void> toggleTheme() async {
    final isDark = state == ThemeMode.dark;
    final newMode = isDark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    await _storageService.saveThemeMode(newMode == ThemeMode.dark);
  }

  /// Sets theme explicitly.
  Future<void> setThemeMode(bool isDark) async {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
    if (state == newMode) return;
    state = newMode;
    await _storageService.saveThemeMode(isDark);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ThemeNotifier(storage);
});

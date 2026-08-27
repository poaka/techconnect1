import 'package:flutter/material.dart';

/// FixerPro237 Cameroun — Design Token System: Color Palette
abstract class AppColors {
  // Brand Primary System (Royal Blue)
  static const Color primary = Color(0xFF1D4ED8);       // Royal Deep Blue
  static const Color primaryLight = Color(0xFF3B82F6);  // Electric Blue
  static const Color primaryDark = Color(0xFF1E3A8A);   // Midnight Navy
  static const Color primarySubtle = Color(0xFFEFF6FF); // Soft Blue Tint

  // Accent & Reputation
  static const Color accentGold = Color(0xFFF59E0B);    // Amber Gold (Ratings & Badges)
  static const Color accent = Color(0xFFF59E0B);        // Alias for rating gold

  // Light Neutral System
  static const Color background = Color(0xFFF8FAFC);    // Slate 50 Background
  static const Color surface = Color(0xFFFFFFFF);       // Card Surface White
  static const Color textPrimary = Color(0xFF0F172A);   // Slate 900 High Contrast Text
  static const Color textSecondary = Color(0xFF64748B); // Slate 500 Subtitles & Meta
  static const Color border = Color(0xFFE2E8F0);        // Slate 200 Card Borders
  static const Color inputBg = Color(0xFFF1F5F9);       // Slate 100 Input Fields

  // Dark Neutral System
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900 Dark Background
  static const Color darkSurface = Color(0xFF1E293B);    // Slate 800 Dark Surface Card
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50 Light Text
  static const Color darkTextSecondary = Color(0xFF94A3B8); // Slate 400 Muted Text
  static const Color darkBorder = Color(0xFF334155);     // Slate 700 Dark Border
  static const Color darkInputBg = Color(0xFF1E293B);    // Slate 800 Input Field
  static const Color darkPrimarySubtle = Color(0xFF1E3A8A); // Deep Navy Tint

  // Semantic Status Colors
  static const Color success = Color(0xFF10B981);       // Emerald Green (Completed, Verified)
  static const Color warning = Color(0xFFF59E0B);       // Amber (Pending, In Progress)
  static const Color error = Color(0xFFEF4444);         // Rose Red (Rejected, Cancelled, Errors)

  // Status Chip Backgrounds
  static const Color successBg = Color(0xFFD1FAE5);
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color errorBg = Color(0xFFFEE2E2);
}

import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Palette
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color primaryDark = Color(0xFF0EA5E9); // Sky 500
  static const Color accentDark = Color(0xFF6366F1); // Indigo 500
  static const Color textPrimaryDark = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondaryDark = Color(0xFF94A3B8); // Slate 400

  // Light Theme Palette
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color surfaceLight = Color(0xFFFFFFFF); // White
  static const Color primaryLight = Color(0xFF0284C7); // Sky 600
  static const Color accentLight = Color(0xFF4F46E5); // Indigo 600
  static const Color textPrimaryLight = Color(0xFF0F172A); // Slate 900
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500

  // Functional Colors
  static const Color success = Color(0xFF10B981); // Emerald 500
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color error = Color(0xFFEF4444); // Red 500

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, accentDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientDark = LinearGradient(
    colors: [
      Color(0x1FFFFFFF), // White 12%
      Color(0x05FFFFFF), // White 2%
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientLight = LinearGradient(
    colors: [
      Color(0x99FFFFFF), // White 60%
      Color(0x4DFFFFFF), // White 30%
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient borderGradient = LinearGradient(
    colors: [
      Color(0x4DFFFFFF), // White 30%
      Color(0x1AFFFFFF), // White 10%
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

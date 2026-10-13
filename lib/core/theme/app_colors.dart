import 'package:flutter/material.dart';

/// Minimalist, restrained color palette adhering to the Product Requirements Document:
/// - Light foundation: warm white / subtle neutral
/// - Dark foundation: clean deep neutral
/// - Status colors reserved strictly for meaningful conditions (Normal, Warning, Critical, Offline)
/// - One restrained slate/teal accent
class AppColors {
  AppColors._();

  // Light Palette
  static const Color lightBackground = Color(0xFFFBFBFB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF4F4F6);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightBorderSubtle = Color(0xFFF0F1F3);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextTertiary = Color(0xFF9CA3AF);

  // Dark Palette
  static const Color darkBackground = Color(0xFF0F1115);
  static const Color darkSurface = Color(0xFF181A20);
  static const Color darkSurfaceElevated = Color(0xFF22252D);
  static const Color darkBorder = Color(0xFF2B2F3A);
  static const Color darkBorderSubtle = Color(0xFF1E212A);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);
  static const Color darkTextTertiary = Color(0xFF6B7280);

  // Restrained Accent (Slate / Mineral Teal)
  static const Color accent = Color(0xFF0284C7); // Restrained Sky/Slate Blue
  static const Color accentDark = Color(0xFF38BDF8);

  // Semantic Status Colors
  static const Color statusNormal = Color(0xFF16A34A);       // Forest Green
  static const Color statusNormalBgLight = Color(0xFFDCFCE7);
  static const Color statusNormalBgDark = Color(0xFF14532D);

  static const Color statusWarning = Color(0xFFD97706);      // Muted Amber
  static const Color statusWarningBgLight = Color(0xFFFEF3C7);
  static const Color statusWarningBgDark = Color(0xFF78350F);

  static const Color statusCritical = Color(0xFFDC2626);     // Muted Carmine Red
  static const Color statusCriticalBgLight = Color(0xFFFEE2E2);
  static const Color statusCriticalBgDark = Color(0xFF7F1D1D);

  static const Color statusOffline = Color(0xFF6B7280);      // Neutral Slate Grey
  static const Color statusOfflineBgLight = Color(0xFFF3F4F6);
  static const Color statusOfflineBgDark = Color(0xFF1F2937);

  // Sensor Specific Subtle Accents for identification
  static const Color mq2Color = Color(0xFFEA580C);   // Combustible/Smoke (Tamed Orange)
  static const Color mq7Color = Color(0xFFDC2626);   // Carbon Monoxide (Red)
  static const Color mq135Color = Color(0xFF2563EB); // Air Quality (Blue)
}

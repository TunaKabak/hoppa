import 'dart:ui';
import 'package:flutter/material.dart';

/// Hoppa Design System v2.0 — Canonical Cross-Platform Design Tokens
class HoppaDesignTokens {
  HoppaDesignTokens._();

  // Brand Core
  static const Color brandOrange = Color(0xFFFF6B00);
  static const Color brandOrangeHover = Color(0xFFE55A00);
  static const Color brandOrangeTint = Color(0xFFFFF4EC);
  static const Color brandOrangeTintDark = Color(0x24FF6B00);

  static const Color brandGreen = Color(0xFF00A651);
  static const Color brandGreenHover = Color(0xFF008C44);
  static const Color brandGreenTint = Color(0xFFECFDF5);
  static const Color brandGreenTintDark = Color(0x2010B981);

  // Light Surfaces & Text
  static const Color canvasLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceSubtleLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderOutdoorLight = Color(0xFF94A3B8);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textMutedLight = Color(0xFF64748B);

  // Dark Surfaces & Text
  static const Color canvasDark = Color(0xFF0B0F17);
  static const Color surfaceDark = Color(0xFF111827);
  static const Color surfaceSubtleDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF1E293B);
  static const Color borderOutdoorDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF94A3B8);

  // Semantic Status
  static const Color statusSuccess = Color(0xFF00A651);
  static const Color statusSuccessDark = Color(0xFF10B981);
  static const Color statusWarning = Color(0xFFD97706);
  static const Color statusWarningDark = Color(0xFFF59E0B);
  static const Color statusDanger = Color(0xFFE11D48);
  static const Color statusDangerDark = Color(0xFFFB7185);
  static const Color statusInfo = Color(0xFF4F46E5);

  // Radii
  static const double radiusXs = 6.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // Spacing Scale (4pt/8pt Grid)
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;

  // Field Ergonomics & Accessibility
  static const double minTouchTarget = 48.0;

  // Typography Feature for Financial & KPI Alignment
  static const List<FontFeature> tabularFigures = [
    FontFeature.tabularFigures(),
  ];
}

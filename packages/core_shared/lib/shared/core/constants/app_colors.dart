import 'package:flutter/material.dart';
import '../theme/hoppa_design_tokens.dart';

class AppColors {
  // Canonical Brand Colors (Hoppa Design System v2.0)
  static const Color primary = HoppaDesignTokens.brandGreen;
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primaryDark = HoppaDesignTokens.brandGreenHover;

  // Secondary / Brand Action Orange
  static const Color secondary = HoppaDesignTokens.brandOrange;
  static const Color secondaryLight = Color(0xFFFF9248);
  static const Color secondaryDark = HoppaDesignTokens.brandOrangeHover;

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = HoppaDesignTokens.textSecondaryLight;
  static const Color greyLight = HoppaDesignTokens.borderLight;
  static const Color greyDark = HoppaDesignTokens.textPrimaryLight;

  // Semantic Colors
  static const Color success = HoppaDesignTokens.statusSuccess;
  static const Color warning = HoppaDesignTokens.statusWarning;
  static const Color error = HoppaDesignTokens.statusDanger;
  static const Color info = HoppaDesignTokens.statusInfo;

  // Status Colors
  static const Color pendingStatus = HoppaDesignTokens.statusWarning;
  static const Color preparingStatus = HoppaDesignTokens.statusInfo;
  static const Color onWayStatus = HoppaDesignTokens.brandOrange;
  static const Color deliveredStatus = HoppaDesignTokens.statusSuccess;
  static const Color cancelledStatus = HoppaDesignTokens.statusDanger;

  // Background Colors
  static const Color background = HoppaDesignTokens.canvasLight;
  static const Color surface = HoppaDesignTokens.surfaceLight;
  static const Color surfaceVariant = HoppaDesignTokens.surfaceSubtleLight;
}

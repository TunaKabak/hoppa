import 'package:flutter/material.dart';
import 'package:core_ui/core_ui.dart';

class AppTheme {
  static const _consumerPrimary = HoppaDesignTokens.brandGreen;
  static const _consumerSecondary = HoppaDesignTokens.brandOrange;
  static const _merchantPrimary = HoppaDesignTokens.brandOrange;
  static const _merchantSecondary = HoppaDesignTokens.brandGreen;
  static const _merchantAccent = HoppaDesignTokens.brandGreen;

  static ThemeData get consumerTheme => HoppaTheme.consumerLight;
  static ThemeData get consumerDarkTheme => HoppaTheme.consumerDark;
  static ThemeData get merchantTheme => HoppaTheme.merchantLight;
  static ThemeData get merchantDarkTheme => HoppaTheme.merchantDark;
  static ThemeData get lightTheme => consumerTheme;

  static const Color consumerPrimary = _consumerPrimary;
  static const Color consumerSecondary = _consumerSecondary;
  static const Color merchantPrimary = _merchantPrimary;
  static const Color merchantSecondary = _merchantSecondary;
  static const Color merchantAccent = _merchantAccent;
}

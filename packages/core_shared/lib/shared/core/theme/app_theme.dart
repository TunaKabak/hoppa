import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'hoppa_design_tokens.dart';

class AppTheme {
  // ─────────────────────────────────────────────
  // CONSUMER THEME — Hoppa Turuncu & Güven Yeşili
  // ─────────────────────────────────────────────
  static const _consumerPrimary = HoppaDesignTokens.brandGreen;
  static const _consumerSecondary = HoppaDesignTokens.brandOrange;
  static const _consumerBackground = HoppaDesignTokens.canvasLight;
  static const _consumerSurface = HoppaDesignTokens.surfaceLight;
  static const _consumerText = HoppaDesignTokens.textPrimaryLight;
  static const _consumerBorder = HoppaDesignTokens.borderLight;
  static const _consumerRadius = HoppaDesignTokens.radiusLg;

  // ─────────────────────────────────────────────
  // MERCHANT THEME — Kurumsal Hoppa Turuncu & Slate (Web Portal ile Birebir)
  // ─────────────────────────────────────────────
  static const _merchantPrimary = HoppaDesignTokens.brandOrange;
  static const _merchantSecondary = HoppaDesignTokens.brandGreen;
  static const _merchantAccent = HoppaDesignTokens.brandGreen;
  static const _merchantBackground = HoppaDesignTokens.canvasLight;
  static const _merchantSurface = HoppaDesignTokens.surfaceLight;
  static const _merchantText = HoppaDesignTokens.textPrimaryLight;
  static const _merchantBorder = HoppaDesignTokens.borderLight;
  static const _merchantRadius = HoppaDesignTokens.radiusMd;

  // Unified Cross-Platform Typography (Plus Jakarta Sans)
  static final _textTheme = GoogleFonts.plusJakartaSansTextTheme();

  // ═══════════════════════════════════════════
  // CONSUMER LIGHT THEME
  // ═══════════════════════════════════════════
  static ThemeData get consumerTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _consumerBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _consumerPrimary,
        brightness: Brightness.light,
        primary: _consumerPrimary,
        secondary: _consumerSecondary,
        surface: _consumerSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: _textTheme.apply(
        bodyColor: _consumerText,
        displayColor: _consumerText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _consumerSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _consumerText),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: _consumerText,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: _consumerSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_consumerRadius),
          side: const BorderSide(color: _consumerBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _consumerPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_consumerRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _consumerPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_consumerRadius),
          ),
          side: const BorderSide(color: _consumerPrimary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _consumerSurface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_consumerRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_consumerRadius),
          borderSide: const BorderSide(color: _consumerBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_consumerRadius),
          borderSide: const BorderSide(color: _consumerPrimary, width: 1.8),
        ),
        hintStyle: const TextStyle(color: HoppaDesignTokens.textMutedLight),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _consumerPrimary.withValues(alpha: 0.1),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: _consumerPrimary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_consumerRadius),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _consumerPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _consumerPrimary,
        unselectedItemColor: HoppaDesignTokens.textMutedLight,
      ),
      dividerTheme: const DividerThemeData(
        color: _consumerBorder,
        thickness: 1,
      ),
    );
  }

  // ═══════════════════════════════════════════
  // CONSUMER DARK THEME
  // ═══════════════════════════════════════════
  static ThemeData get consumerDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: HoppaDesignTokens.canvasDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: HoppaDesignTokens.statusSuccessDark,
        brightness: Brightness.dark,
        primary: HoppaDesignTokens.statusSuccessDark,
        secondary: HoppaDesignTokens.brandOrange,
        surface: HoppaDesignTokens.surfaceDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: _textTheme.apply(
        bodyColor: HoppaDesignTokens.textPrimaryDark,
        displayColor: HoppaDesignTokens.textPrimaryDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: HoppaDesignTokens.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: HoppaDesignTokens.textPrimaryDark),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: HoppaDesignTokens.textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: HoppaDesignTokens.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_consumerRadius),
          side: const BorderSide(color: HoppaDesignTokens.borderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: HoppaDesignTokens.borderDark,
        thickness: 1,
      ),
    );
  }

  // ═══════════════════════════════════════════
  // MERCHANT LIGHT THEME (Hoppa Orange + Clean Corporate Slate)
  // ═══════════════════════════════════════════
  static ThemeData get merchantTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _merchantBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _merchantPrimary,
        brightness: Brightness.light,
        primary: _merchantPrimary,
        secondary: _merchantSecondary,
        tertiary: _merchantAccent,
        surface: _merchantSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: _textTheme.apply(
        bodyColor: _merchantText,
        displayColor: _merchantText,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: _merchantText),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: _merchantText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_merchantRadius),
          side: const BorderSide(color: _merchantBorder, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _merchantPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_merchantRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _merchantPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_merchantRadius),
          ),
          side: const BorderSide(color: _merchantPrimary, width: 1.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_merchantRadius),
          borderSide: const BorderSide(color: _merchantBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_merchantRadius),
          borderSide: const BorderSide(color: _merchantBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_merchantRadius),
          borderSide: const BorderSide(color: _merchantPrimary, width: 1.8),
        ),
        hintStyle: const TextStyle(color: HoppaDesignTokens.textMutedLight),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: HoppaDesignTokens.brandOrangeTint,
        labelStyle: GoogleFonts.plusJakartaSans(
          color: HoppaDesignTokens.brandOrangeHover,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_merchantRadius),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_merchantRadius),
        ),
        selectedTileColor: HoppaDesignTokens.brandOrangeTint,
        selectedColor: _merchantPrimary,
        iconColor: _merchantText,
      ),
      dividerTheme: const DividerThemeData(
        color: _merchantBorder,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _merchantAccent;
          return HoppaDesignTokens.textMutedLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _merchantAccent.withValues(alpha: 0.3);
          }
          return _merchantBorder;
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // MERCHANT DARK THEME
  // ═══════════════════════════════════════════
  static ThemeData get merchantDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: HoppaDesignTokens.canvasDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _merchantPrimary,
        brightness: Brightness.dark,
        primary: _merchantPrimary,
        secondary: HoppaDesignTokens.statusSuccessDark,
        surface: HoppaDesignTokens.surfaceDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: _textTheme.apply(
        bodyColor: HoppaDesignTokens.textPrimaryDark,
        displayColor: HoppaDesignTokens.textPrimaryDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: HoppaDesignTokens.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: HoppaDesignTokens.textPrimaryDark),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: HoppaDesignTokens.textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: HoppaDesignTokens.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_merchantRadius),
          side: const BorderSide(color: HoppaDesignTokens.borderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: HoppaDesignTokens.borderDark,
        thickness: 1,
      ),
    );
  }

  // Legacy getters
  static ThemeData get lightTheme => consumerTheme;

  static const Color consumerPrimary = _consumerPrimary;
  static const Color consumerSecondary = _consumerSecondary;
  static const Color merchantPrimary = _merchantPrimary;
  static const Color merchantSecondary = _merchantSecondary;
  static const Color merchantAccent = _merchantAccent;
}

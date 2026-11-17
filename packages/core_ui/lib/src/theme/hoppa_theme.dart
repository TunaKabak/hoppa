import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'hoppa_design_tokens.dart';

/// Shared theme definitions for Consumer, Merchant, and Courier Hoppa apps.
class HoppaTheme {
  HoppaTheme._();

  static final TextTheme _baseTextTheme =
      GoogleFonts.plusJakartaSansTextTheme();

  static ThemeData get consumerLight {
    const primary = HoppaDesignTokens.brandGreen;
    const secondary = HoppaDesignTokens.brandOrange;
    const radius = HoppaDesignTokens.radiusLg;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: HoppaDesignTokens.canvasLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: HoppaDesignTokens.surfaceLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: _baseTextTheme.apply(
        bodyColor: HoppaDesignTokens.textPrimaryLight,
        displayColor: HoppaDesignTokens.textPrimaryLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: HoppaDesignTokens.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme:
            const IconThemeData(color: HoppaDesignTokens.textPrimaryLight),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: HoppaDesignTokens.textPrimaryLight,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: HoppaDesignTokens.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: HoppaDesignTokens.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
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
          foregroundColor: primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HoppaDesignTokens.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: HoppaDesignTokens.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
        hintStyle: const TextStyle(color: HoppaDesignTokens.textMutedLight),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: primary.withValues(alpha: 0.1),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: HoppaDesignTokens.textMutedLight,
      ),
      dividerTheme: const DividerThemeData(
        color: HoppaDesignTokens.borderLight,
        thickness: 1,
      ),
    );
  }

  static ThemeData get consumerDark {
    const primary = HoppaDesignTokens.statusSuccessDark;
    const radius = HoppaDesignTokens.radiusLg;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: HoppaDesignTokens.canvasDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: HoppaDesignTokens.brandOrange,
        surface: HoppaDesignTokens.surfaceDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: _baseTextTheme.apply(
        bodyColor: HoppaDesignTokens.textPrimaryDark,
        displayColor: HoppaDesignTokens.textPrimaryDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: HoppaDesignTokens.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme:
            const IconThemeData(color: HoppaDesignTokens.textPrimaryDark),
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
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: HoppaDesignTokens.borderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HoppaDesignTokens.surfaceDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: HoppaDesignTokens.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: HoppaDesignTokens.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: HoppaDesignTokens.borderDark,
        thickness: 1,
      ),
    );
  }

  static ThemeData get merchantLight {
    const primary = HoppaDesignTokens.brandOrange;
    const secondary = HoppaDesignTokens.brandGreen;
    const radius = HoppaDesignTokens.radiusMd;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: HoppaDesignTokens.canvasLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        tertiary: secondary,
        surface: HoppaDesignTokens.surfaceLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: _baseTextTheme.apply(
        bodyColor: HoppaDesignTokens.textPrimaryLight,
        displayColor: HoppaDesignTokens.textPrimaryLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme:
            const IconThemeData(color: HoppaDesignTokens.textPrimaryLight),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: HoppaDesignTokens.textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: HoppaDesignTokens.borderLight, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(
            HoppaDesignTokens.minTouchTarget,
            HoppaDesignTokens.minTouchTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
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
          foregroundColor: primary,
          minimumSize: const Size(
            HoppaDesignTokens.minTouchTarget,
            HoppaDesignTokens.minTouchTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          side: const BorderSide(color: primary, width: 1.4),
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
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: HoppaDesignTokens.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: HoppaDesignTokens.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: primary, width: 1.8),
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
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: HoppaDesignTokens.brandOrangeTint,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? primary
                : HoppaDesignTokens.textSecondaryLight,
          );
        }),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        selectedTileColor: HoppaDesignTokens.brandOrangeTint,
        selectedColor: primary,
        iconColor: HoppaDesignTokens.textPrimaryLight,
      ),
      dividerTheme: const DividerThemeData(
        color: HoppaDesignTokens.borderLight,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return secondary;
          return HoppaDesignTokens.textMutedLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return secondary.withValues(alpha: 0.3);
          }
          return HoppaDesignTokens.borderLight;
        }),
      ),
    );
  }

  static ThemeData get merchantDark {
    const primary = HoppaDesignTokens.brandOrange;
    const secondary = HoppaDesignTokens.statusSuccessDark;
    const radius = HoppaDesignTokens.radiusMd;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: HoppaDesignTokens.canvasDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: secondary,
        surface: HoppaDesignTokens.surfaceDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
      textTheme: _baseTextTheme.apply(
        bodyColor: HoppaDesignTokens.textPrimaryDark,
        displayColor: HoppaDesignTokens.textPrimaryDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: HoppaDesignTokens.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme:
            const IconThemeData(color: HoppaDesignTokens.textPrimaryDark),
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
          borderRadius: BorderRadius.circular(radius),
          side: const BorderSide(color: HoppaDesignTokens.borderDark, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: HoppaDesignTokens.surfaceDark,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: HoppaDesignTokens.surfaceDark,
        indicatorColor: HoppaDesignTokens.brandOrangeTintDark,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected
                ? primary
                : HoppaDesignTokens.textSecondaryDark,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HoppaDesignTokens.surfaceSubtleDark,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: HoppaDesignTokens.borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: HoppaDesignTokens.borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: const BorderSide(color: primary, width: 1.8),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(
            HoppaDesignTokens.minTouchTarget,
            HoppaDesignTokens.minTouchTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: HoppaDesignTokens.borderDark,
        thickness: 1,
      ),
    );
  }

  /// High-contrast KKTC daylight theme engineered for one-handed courier use.
  static ThemeData get courierLight {
    const primary = HoppaDesignTokens.brandOrange;
    const secondary = HoppaDesignTokens.brandGreen;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: HoppaDesignTokens.canvasLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
        primary: primary,
        secondary: secondary,
        surface: HoppaDesignTokens.surfaceLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: HoppaDesignTokens.textPrimaryLight,
      ),
      textTheme: _baseTextTheme.apply(
        bodyColor: HoppaDesignTokens.textPrimaryLight,
        displayColor: HoppaDesignTokens.textPrimaryLight,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: HoppaDesignTokens.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: HoppaDesignTokens.textPrimaryLight,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: HoppaDesignTokens.textPrimaryLight,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: HoppaDesignTokens.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoppaDesignTokens.radiusLg),
          side: const BorderSide(
            color: HoppaDesignTokens.borderOutdoorLight,
            width: 1.5,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HoppaDesignTokens.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoppaDesignTokens.radiusMd),
          borderSide: const BorderSide(
            color: HoppaDesignTokens.borderOutdoorLight,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoppaDesignTokens.radiusMd),
          borderSide: const BorderSide(
            color: HoppaDesignTokens.borderOutdoorLight,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoppaDesignTokens.radiusMd),
          borderSide: const BorderSide(color: primary, width: 2.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(
            HoppaDesignTokens.minTouchTarget,
            HoppaDesignTokens.minTouchTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HoppaDesignTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HoppaDesignTokens.textPrimaryLight,
          minimumSize: const Size(
            HoppaDesignTokens.minTouchTarget,
            HoppaDesignTokens.minTouchTarget,
          ),
          side: const BorderSide(
            color: HoppaDesignTokens.borderOutdoorLight,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HoppaDesignTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: HoppaDesignTokens.surfaceLight,
        indicatorColor: primary.withValues(alpha: 0.16),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? primary
                : HoppaDesignTokens.textSecondaryLight,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: HoppaDesignTokens.borderLight,
        thickness: 1.2,
      ),
    );
  }

  /// High-contrast night-shift theme for evening courier shifts.
  static ThemeData get courierDark {
    const primary = HoppaDesignTokens.brandOrange;
    const secondary = HoppaDesignTokens.statusSuccessDark;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: HoppaDesignTokens.canvasDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: secondary,
        surface: HoppaDesignTokens.surfaceDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: HoppaDesignTokens.textPrimaryDark,
      ),
      textTheme: _baseTextTheme.apply(
        bodyColor: HoppaDesignTokens.textPrimaryDark,
        displayColor: HoppaDesignTokens.textPrimaryDark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: HoppaDesignTokens.surfaceDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: HoppaDesignTokens.textPrimaryDark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: HoppaDesignTokens.textPrimaryDark,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: HoppaDesignTokens.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HoppaDesignTokens.radiusLg),
          side: const BorderSide(
            color: HoppaDesignTokens.borderOutdoorDark,
            width: 1.5,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: HoppaDesignTokens.surfaceSubtleDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoppaDesignTokens.radiusMd),
          borderSide: const BorderSide(
            color: HoppaDesignTokens.borderOutdoorDark,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoppaDesignTokens.radiusMd),
          borderSide: const BorderSide(
            color: HoppaDesignTokens.borderOutdoorDark,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HoppaDesignTokens.radiusMd),
          borderSide: const BorderSide(color: primary, width: 2.0),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(
            HoppaDesignTokens.minTouchTarget,
            HoppaDesignTokens.minTouchTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HoppaDesignTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: HoppaDesignTokens.textPrimaryDark,
          minimumSize: const Size(
            HoppaDesignTokens.minTouchTarget,
            HoppaDesignTokens.minTouchTarget,
          ),
          side: const BorderSide(
            color: HoppaDesignTokens.borderOutdoorDark,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HoppaDesignTokens.radiusMd),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: HoppaDesignTokens.surfaceDark,
        indicatorColor: HoppaDesignTokens.brandOrangeTintDark,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? primary
                : HoppaDesignTokens.textSecondaryDark,
          );
        }),
      ),
      dividerTheme: const DividerThemeData(
        color: HoppaDesignTokens.borderOutdoorDark,
        thickness: 1.2,
      ),
    );
  }
}

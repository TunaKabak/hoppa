import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─────────────────────────────────────────────
  // CONSUMER THEME — Taze, Güvenilir, Yeşil
  // ─────────────────────────────────────────────
  static const _consumerPrimary = Color(0xFF00A651); // Orijinal Hoppa Yeşili
  static const _consumerSecondary = Color(0xFFFF6B00); // Turuncu (Vurgu)
  static const _consumerBackground = Color(0xFFF9FAFB); // Açık gri/beyazımsı
  static const _consumerSurface = Colors.white;
  static const _consumerText = Color(0xFF1F2937); // Koyu gri metin
  static const _consumerBorder = Color(0xFFE5E7EB); // İnce gri kenarlık
  static const _consumerRadius = 16.0;

  // ─────────────────────────────────────────────
  // MERCHANT THEME — Profesyonel, veri odaklı, keskin
  // ─────────────────────────────────────────────
  static const _merchantPrimary = Color(0xFF1B2A4A);
  static const _merchantSecondary = Color(0xFF3B82F6);
  static const _merchantAccent = Color(0xFF10B981);
  static const _merchantBackground = Color(0xFFF1F5F9);
  static const _merchantSurface = Color(0xFFF8FAFC);
  static const _merchantText = Color(0xFF0F172A);
  static const _merchantBorder = Color(0xFFE2E8F0);
  static const _merchantRadius = 8.0;

  // Shared text theme
  static final _textTheme = GoogleFonts.interTextTheme();

  // ═══════════════════════════════════════════
  // CONSUMER LIGHT THEME
  // ═══════════════════════════════════════════
  static ThemeData get consumerTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _consumerBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _consumerPrimary,
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
        titleTextStyle: GoogleFonts.inter(
          color: _consumerText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
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
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 16,
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
          horizontal: 20,
          vertical: 16,
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
          borderSide: const BorderSide(color: _consumerPrimary, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _consumerPrimary.withValues(alpha: 0.1),
        labelStyle: GoogleFonts.inter(
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
        unselectedItemColor: Colors.grey,
      ),
      dividerTheme: const DividerThemeData(
        color: _consumerBorder,
        thickness: 1,
      ),
    );
  }

  // ═══════════════════════════════════════════
  // MERCHANT LIGHT THEME
  // ═══════════════════════════════════════════
  static ThemeData get merchantTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: _merchantBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _merchantPrimary,
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
        backgroundColor: _merchantPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white,
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
          backgroundColor: _merchantSecondary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_merchantRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _merchantSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_merchantRadius),
          ),
          side: const BorderSide(color: _merchantSecondary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          borderSide: const BorderSide(color: _merchantSecondary, width: 2),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade400),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _merchantSecondary.withValues(alpha: 0.1),
        labelStyle: GoogleFonts.inter(
          color: _merchantSecondary,
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
        selectedTileColor: _merchantSecondary.withValues(alpha: 0.08),
        selectedColor: _merchantSecondary,
        iconColor: _merchantText,
      ),
      dividerTheme: const DividerThemeData(
        color: _merchantBorder,
        thickness: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _merchantAccent;
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return _merchantAccent.withValues(alpha: 0.3);
          }
          return Colors.grey.shade300;
        }),
      ),
    );
  }

  // Legacy getter — konsumer uyumu için
  static ThemeData get lightTheme => consumerTheme;

  // Yardımcı renk getirme (widget'larda kullanım için)
  static Color consumerPrimary = _consumerPrimary;
  static Color consumerSecondary = _consumerSecondary;
  static Color merchantPrimary = _merchantPrimary;
  static Color merchantSecondary = _merchantSecondary;
  static Color merchantAccent = _merchantAccent;
}

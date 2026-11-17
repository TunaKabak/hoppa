import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/hoppa_design_tokens.dart';

/// Unified light/dark-aware confirmation dialog with 48dp touch targets.
class HoppaUnifiedDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String content;
  final String cancelText;
  final String confirmText;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  final bool isDestructive;

  const HoppaUnifiedDialog({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.content,
    required this.cancelText,
    required this.confirmText,
    required this.onCancel,
    required this.onConfirm,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark
        ? HoppaDesignTokens.surfaceDark
        : HoppaDesignTokens.surfaceLight;
    final titleColor = isDark
        ? HoppaDesignTokens.textPrimaryDark
        : HoppaDesignTokens.textPrimaryLight;
    final bodyColor = isDark
        ? HoppaDesignTokens.textSecondaryDark
        : HoppaDesignTokens.textSecondaryLight;
    final cancelBg = isDark
        ? HoppaDesignTokens.surfaceSubtleDark
        : HoppaDesignTokens.surfaceSubtleLight;
    final cancelBorder = isDark
        ? HoppaDesignTokens.borderOutdoorDark
        : HoppaDesignTokens.borderLight;
    final confirmBg = isDestructive
        ? HoppaDesignTokens.statusDanger
        : theme.colorScheme.primary;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HoppaDesignTokens.radiusXl),
        side: BorderSide(color: cancelBorder),
      ),
      backgroundColor: surface,
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 32),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              content,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: bodyColor,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: HoppaDesignTokens.minTouchTarget,
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: cancelBg,
                        foregroundColor: titleColor,
                        side: BorderSide(color: cancelBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        cancelText,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: HoppaDesignTokens.minTouchTarget,
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmBg,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        confirmText,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Presents an accessible confirmation dialog and returns `true` only if confirmed.
Future<bool> showHoppaConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'Onayla',
  String cancelText = 'Vazgeç',
  IconData icon = Icons.help_outline_rounded,
  bool isDestructive = false,
  Color? accentColor,
}) async {
  final effectiveAccent = accentColor ??
      (isDestructive
          ? HoppaDesignTokens.statusDanger
          : Theme.of(context).colorScheme.primary);

  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => HoppaUnifiedDialog(
      icon: icon,
      iconColor: effectiveAccent,
      title: title,
      content: message,
      cancelText: cancelText,
      confirmText: confirmText,
      isDestructive: isDestructive,
      onCancel: () => Navigator.pop(dialogContext, false),
      onConfirm: () => Navigator.pop(dialogContext, true),
    ),
  );
  return result == true;
}

enum HoppaToastTone { success, error, warning, info }

/// Standardized floating toast feedback across Hoppa mobile apps.
class HoppaToast {
  HoppaToast._();

  static void show(
    BuildContext context,
    String message, {
    HoppaToastTone tone = HoppaToastTone.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final Color bg;
    final IconData icon;
    switch (tone) {
      case HoppaToastTone.success:
        bg = HoppaDesignTokens.brandGreen;
        icon = Icons.check_circle_rounded;
        break;
      case HoppaToastTone.error:
        bg = HoppaDesignTokens.statusDanger;
        icon = Icons.error_outline_rounded;
        break;
      case HoppaToastTone.warning:
        bg = HoppaDesignTokens.statusWarning;
        icon = Icons.warning_amber_rounded;
        break;
      case HoppaToastTone.info:
        bg = const Color(0xFF0F172A);
        icon = Icons.info_outline_rounded;
        break;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: duration,
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          action: action,
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}

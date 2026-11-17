import 'dart:ui';
import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class _CountryCodeOption {
  final String code;
  final String iso;
  final String label;

  const _CountryCodeOption({
    required this.code,
    required this.iso,
    required this.label,
  });
}

const List<_CountryCodeOption> _countryOptions = [
  _CountryCodeOption(code: '+90', iso: 'TR/KKTC', label: 'Türkiye / KKTC'),
  _CountryCodeOption(code: '+357', iso: 'CY', label: 'Güney Kıbrıs'),
  _CountryCodeOption(code: '+44', iso: 'UK', label: 'Birleşik Krallık'),
];

/// Yapıştırılan `+905...` veya baştaki `05...` numaralarını 10 haneli ulusal biçime indirger.
class _SmartPhoneFormatter extends TextInputFormatter {
  final String countryCode;
  const _SmartPhoneFormatter(this.countryCode);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (countryCode == '+90') {
      if (digits.startsWith('90') && digits.length > 10) {
        digits = digits.substring(2);
      }
      if (digits.startsWith('0') && digits.length > 1) {
        digits = digits.substring(1);
      }
      if (digits.length > 10) {
        digits = digits.substring(0, 10);
      }
    } else if (digits.length > 12) {
      digits = digits.substring(0, 12);
    }

    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPhone;
  final Color? primaryColor;
  final String selectedCode;
  final ValueChanged<String>? onCodeChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPhone = false,
    this.primaryColor,
    this.selectedCode = '+90',
    this.onCodeChanged,
    this.textInputAction,
    this.onSubmitted,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeColor = primaryColor ?? theme.colorScheme.primary;
    final textPrimary = isDark
        ? HoppaDesignTokens.textPrimaryDark
        : HoppaDesignTokens.textPrimaryLight;
    final textMuted = isDark
        ? HoppaDesignTokens.textMutedDark
        : HoppaDesignTokens.textMutedLight;
    final fieldBg = isDark
        ? HoppaDesignTokens.surfaceSubtleDark
        : HoppaDesignTokens.surfaceSubtleLight;
    final fieldBorder =
        isDark ? HoppaDesignTokens.borderDark : HoppaDesignTokens.borderLight;

    final effectiveFormatters = inputFormatters ??
        (isPhone ? <TextInputFormatter>[_SmartPhoneFormatter(selectedCode)] : null);

    return TextField(
      controller: controller,
      keyboardType: keyboardType ?? (isPhone ? TextInputType.phone : TextInputType.text),
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      inputFormatters: effectiveFormatters,
      autofillHints: isPhone
          ? const [AutofillHints.telephoneNumberNational]
          : null,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        fontFeatures: isPhone ? const [FontFeature.tabularFigures()] : null,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: textMuted,
          fontWeight: FontWeight.w400,
          fontSize: 15,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: fieldBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: fieldBorder, width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: fieldBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: activeColor, width: 1.8),
        ),
        prefixIcon: isPhone
            ? Padding(
                padding: const EdgeInsets.only(left: 10, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PopupMenuButton<String>(
                      initialValue: selectedCode,
                      onSelected: onCodeChanged,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? HoppaDesignTokens.surfaceDark
                              : HoppaDesignTokens.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: fieldBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedCode,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                                fontSize: 14,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: textMuted,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => _countryOptions
                          .map(
                            (opt) => PopupMenuItem<String>(
                              value: opt.code,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: activeColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      opt.iso,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: activeColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${opt.code}  •  ${opt.label}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              )
            : Icon(icon, color: activeColor, size: 20),
        prefixIconConstraints: isPhone
            ? const BoxConstraints(minWidth: 0, minHeight: 0)
            : null,
      ),
    );
  }
}

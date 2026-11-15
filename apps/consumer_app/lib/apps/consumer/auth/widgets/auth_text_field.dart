import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPhone;
  final Color primaryColor;
  final String selectedCode;
  final ValueChanged<String>? onCodeChanged;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final List<TextInputFormatter>? inputFormatters;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPhone = false,
    this.primaryColor = const Color(0xFF00A651),
    this.selectedCode = "+90",
    this.onCodeChanged,
    this.textInputAction,
    this.onSubmitted,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveFormatters = inputFormatters ??
        (isPhone
            ? <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ]
            : null);

    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      inputFormatters: effectiveFormatters,
      autofillHints:
          isPhone ? const [AutofillHints.telephoneNumberNational] : null,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2937),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: Color(0xFF9CA3AF),
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: primaryColor, width: 1.8),
        ),
        prefixIcon: isPhone
            ? Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: primaryColor, size: 20),
                    const SizedBox(width: 6),
                    PopupMenuButton<String>(
                      initialValue: selectedCode,
                      onSelected: onCodeChanged,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              selectedCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2937),
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Color(0xFF6B7280),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: "+90",
                          child: Text("🇹🇷 +90"),
                        ),
                        PopupMenuItem(
                          value: "+357",
                          child: Text("🇨🇾 +357"),
                        ),
                        PopupMenuItem(
                          value: "+44",
                          child: Text("🇬🇧 +44"),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 1,
                      height: 22,
                      color: const Color(0xFFE5E7EB),
                    ),
                  ],
                ),
              )
            : Icon(icon, color: primaryColor, size: 20),
        prefixIconConstraints: isPhone
            ? const BoxConstraints(minWidth: 0, minHeight: 0)
            : null,
      ),
    );
  }
}

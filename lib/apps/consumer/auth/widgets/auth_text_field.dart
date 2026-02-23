import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPhone;
  final Color primaryColor;
  final String selectedCode;
  final ValueChanged<String>? onCodeChanged;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPhone = false,
    this.primaryColor = const Color(0xFF00A651),
    this.selectedCode = "+90",
    this.onCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        prefixIcon: isPhone
            ? Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: primaryColor),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      initialValue: selectedCode,
                      onSelected: onCodeChanged,
                      child: Row(
                        children: [
                          Text(
                            selectedCode,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: "+90",
                          child: Text("🇹🇷 +90"),
                        ),
                        const PopupMenuItem(
                          value: "+357",
                          child: Text("🇨🇾 +357"),
                        ),
                        const PopupMenuItem(
                          value: "+44",
                          child: Text("🇬🇧 +44"),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : Icon(icon, color: primaryColor),
        prefixIconConstraints: isPhone
            ? const BoxConstraints(minWidth: 0, minHeight: 0)
            : null,
      ),
    );
  }
}

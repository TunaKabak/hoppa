import 'package:flutter/material.dart';

/// Merchant'a özel Açık/Kapalı durum toggle'ı.
/// Mağaza durumu, ürün aktifliği gibi işlemlerde kullanılır.
class StatusToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? activeText;
  final String? inactiveText;
  final IconData? icon;

  const StatusToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.activeText,
    this.inactiveText,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentGreen = colorScheme.tertiary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value
              ? accentGreen.withValues(alpha: 0.4)
              : Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: value ? accentGreen : Colors.grey.shade500,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (activeText != null || inactiveText != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    value ? (activeText ?? 'Aktif') : (inactiveText ?? 'Pasif'),
                    style: TextStyle(
                      fontSize: 12,
                      color: value ? accentGreen : Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

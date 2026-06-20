import 'package:flutter/material.dart';

/// Merchant'a özel veri tablosu.
/// Sipariş listesi, ürün stok durumu gibi tablo gösterimlerinde kullanılır.
class MerchantDataTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final String? title;
  final Widget? trailing;

  const MerchantDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title!,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Tablo Başlıkları
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.04),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: columns.map((col) {
                return Expanded(
                  child: Text(
                    col,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Satırlar
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'Veri bulunamadı',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ),
            )
          else
            ...rows.asMap().entries.map((entry) {
              final index = entry.key;
              final cells = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: index.isOdd ? Colors.grey.shade50 : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
                child: Row(
                  children: cells.map((cell) {
                    return Expanded(child: cell);
                  }).toList(),
                ),
              );
            }),
        ],
      ),
    );
  }
}

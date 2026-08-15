import 'package:flutter/material.dart';
import 'package:core_shared/shared/models/product.dart';
import 'package:core_shared/shared/core/utils/quantity_formatter.dart';

/// Opsiyonel ve yan ürünlerin (ekstralar, soslar, malzemeler, boyutlar)
/// parantezli ham metinler yerine hesaplanmış, şeffaf ve modern bir
/// hiyerarşi ile gösterilmesini sağlayan ortak UI bileşeni.
class SelectedOptionsBreakdown extends StatefulWidget {
  final List<SelectedProductOption> options;
  final double quantity;
  final double? basePrice;
  final bool isCompact;
  final bool showBackground;
  final bool showSummary;
  final bool isCollapsible;
  final bool initiallyExpanded;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const SelectedOptionsBreakdown({
    super.key,
    required this.options,
    this.quantity = 1.0,
    this.basePrice,
    this.isCompact = false,
    this.showBackground = true,
    this.showSummary = false,
    this.isCollapsible = false,
    this.initiallyExpanded = false,
    this.margin,
    this.padding,
  });

  @override
  State<SelectedOptionsBreakdown> createState() => _SelectedOptionsBreakdownState();
}

class _SelectedOptionsBreakdownState extends State<SelectedOptionsBreakdown> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  double get extrasUnitTotal {
    double total = 0.0;
    for (var opt in widget.options) {
      if (opt.actionType != 'REMOVE') {
        total += opt.price * opt.quantity;
      }
    }
    return total;
  }

  double get extrasCalculatedTotal => extrasUnitTotal * widget.quantity;

  @override
  Widget build(BuildContext context) {
    if (widget.options.isEmpty) return const SizedBox.shrink();

    if (widget.isCollapsible) {
      return _buildCollapsibleView(context);
    }

    if (widget.isCompact) {
      return _buildCompactView(context);
    }

    return _buildDetailedView(context);
  }

  /// Katlanabilir (Detay Gör / Gizle) Görünümü
  Widget _buildCollapsibleView(BuildContext context) {
    return Container(
      margin: widget.margin ?? const EdgeInsets.only(top: 4, bottom: 4),
      decoration: widget.showBackground
          ? BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Katlanabilir Başlık Çubuğu
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0EB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      size: 12,
                      color: Color(0xFFE95D22),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "${widget.options.length} Özelleştirme",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                    ),
                  ),
                  if (extrasUnitTotal > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      "(+${extrasCalculatedTotal.toStringAsFixed(2)} ₺)",
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00A651),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _isExpanded ? "Gizle" : "Detay Gör",
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE95D22),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: const Color(0xFFE95D22),
                  ),
                ],
              ),
            ),
          ),

          // Açılan Detay Bölümü
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _isExpanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, bottom: 8, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 6),
                  ...widget.options.map((opt) => _buildDetailedOptionRow(context, opt)),
                  if (widget.showSummary && widget.basePrice != null && extrasUnitTotal > 0) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.0),
                      child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                    ),
                    _buildSummaryRow(context),
                  ],
                ],
              ),
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Sepet kartları (ModernProductCard) ve küçük alanlar için kompakt görünüm
  Widget _buildCompactView(BuildContext context) {
    return Container(
      margin: widget.margin ?? const EdgeInsets.only(top: 4, bottom: 4),
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: widget.showBackground
          ? BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFF0F2F5)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...widget.options.map((opt) => _buildCompactOptionRow(context, opt)),
        ],
      ),
    );
  }

  Widget _buildCompactOptionRow(BuildContext context, SelectedProductOption opt) {
    final bool isRemove = opt.actionType == 'REMOVE';
    final double optUnitPrice = opt.price * opt.quantity;
    final double optCalculatedTotal = optUnitPrice * widget.quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isRemove
                ? Icons.remove_circle_outline_rounded
                : (opt.price > 0
                    ? Icons.add_circle_outline_rounded
                    : Icons.check_circle_outline_rounded),
            size: 13,
            color: isRemove
                ? const Color(0xFFE53935)
                : (opt.price > 0 ? const Color(0xFF00A651) : const Color(0xFFE95D22)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              opt.quantity > 1 ? "${opt.name} (${opt.quantity}x)" : opt.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isRemove ? const Color(0xFFE53935) : const Color(0xFF2D3748),
                decoration: isRemove ? TextDecoration.lineThrough : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          if (isRemove)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "Çıkarıldı",
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (opt.price == 0)
            const Text(
              "Dahil",
              style: TextStyle(
                color: Color(0xFF718096),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            )
          else
            Text(
              widget.quantity > 1
                  ? "+${optCalculatedTotal.toStringAsFixed(2)} ₺"
                  : "+${optUnitPrice.toStringAsFixed(2)} ₺",
              style: const TextStyle(
                color: Color(0xFF00A651),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  /// Ödeme sayfası, Sipariş Detayı ve Restoran mutfağı için detaylı ve hesaplanmış görünüm
  Widget _buildDetailedView(BuildContext context) {
    return Container(
      margin: widget.margin ?? const EdgeInsets.only(top: 6, bottom: 4),
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: widget.showBackground
          ? BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ...widget.options.map((opt) => _buildDetailedOptionRow(context, opt)),
          if (widget.showSummary && widget.basePrice != null && extrasUnitTotal > 0) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Divider(height: 1, color: Color(0xFFE2E8F0)),
            ),
            _buildSummaryRow(context),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailedOptionRow(BuildContext context, SelectedProductOption opt) {
    final bool isRemove = opt.actionType == 'REMOVE';
    final double optUnitPrice = opt.price * opt.quantity;
    final double optCalculatedTotal = optUnitPrice * widget.quantity;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Sol İkon / İşaretçi
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isRemove
                  ? const Color(0xFFFFECEC)
                  : (opt.price > 0
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFF0EB)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRemove
                  ? Icons.remove
                  : (opt.price > 0 ? Icons.add : Icons.check),
              size: 11,
              color: isRemove
                  ? const Color(0xFFE53935)
                  : (opt.price > 0
                      ? const Color(0xFF00A651)
                      : const Color(0xFFE95D22)),
            ),
          ),
          const SizedBox(width: 8),

          // Opsiyon İsmi ve Grup Etiketi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  opt.quantity > 1 ? "${opt.name} (${opt.quantity} adet)" : opt.name,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isRemove ? const Color(0xFFE53935) : const Color(0xFF1A202C),
                    decoration: isRemove ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (opt.groupName.isNotEmpty)
                  Text(
                    opt.groupName,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF718096),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Tutar / Durum Rozeti
          if (isRemove)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFECEC),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: const Text(
                "Çıkarıldı",
                style: TextStyle(
                  color: Color(0xFFE53935),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (opt.price == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                "Dahil",
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.quantity > 1
                      ? "+${optCalculatedTotal.toStringAsFixed(2)} ₺"
                      : "+${optUnitPrice.toStringAsFixed(2)} ₺",
                  style: const TextStyle(
                    color: Color(0xFF00A651),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.quantity > 1)
                  Text(
                    "${QuantityFormatter.formatValue(widget.quantity)} × ${optUnitPrice.toStringAsFixed(2)} ₺",
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context) {
    final double unitPrice = (widget.basePrice ?? 0.0) + extrasUnitTotal;
    final double grandTotal = unitPrice * widget.quantity;

    return Padding(
      padding: const EdgeInsets.only(top: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Birim: ${unitPrice.toStringAsFixed(2)} ₺ (Baz: ${(widget.basePrice ?? 0.0).toStringAsFixed(2)} ₺ + Ek: ${extrasUnitTotal.toStringAsFixed(2)} ₺)",
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.quantity > 1)
            Text(
              "Toplam: ${grandTotal.toStringAsFixed(2)} ₺",
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

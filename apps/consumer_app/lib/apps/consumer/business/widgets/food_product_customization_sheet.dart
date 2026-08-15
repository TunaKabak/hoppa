import 'package:flutter/material.dart';
import 'package:core_shared/shared/models/product.dart';

class FoodProductCustomizationSheet extends StatefulWidget {
  final Product product;
  final Function(Product product, List<SelectedProductOption> options, int quantity) onAddToCart;

  const FoodProductCustomizationSheet({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  @override
  State<FoodProductCustomizationSheet> createState() => _FoodProductCustomizationSheetState();
}

class _FoodProductCustomizationSheetState extends State<FoodProductCustomizationSheet> {
  int _quantity = 1;
  // Map of groupId -> Map of optionId -> SelectedProductOption
  final Map<String, Map<String, SelectedProductOption>> _selections = {};

  @override
  void initState() {
    super.initState();
    _initializeDefaultSelections();
  }

  void _initializeDefaultSelections() {
    for (var group in widget.product.optionGroups) {
      _selections[group.id] = {};
      for (var opt in group.options) {
        if (opt.isDefault) {
          _selections[group.id]![opt.id] = SelectedProductOption(
            optionId: opt.id,
            groupName: group.name,
            name: opt.name,
            price: opt.price,
            quantity: 1,
            actionType: opt.isRemovable ? 'REMOVE' : 'ADD',
          );
        }
      }
    }
  }

  double get _basePrice => widget.product.shownPrice ?? widget.product.regularPrice ?? 0.0;

  double get _extrasUnitTotal {
    double extrasTotal = 0.0;

    for (var group in widget.product.optionGroups) {
      final groupSelections = _selections[group.id] ?? {};
      final selectedOpts = groupSelections.values.toList();
      
      int freeQuota = group.freeSelectionsCount;
      int paidIndex = 0;

      for (var sel in selectedOpts) {
        if (sel.actionType == 'REMOVE') continue;

        if (freeQuota > 0) {
          paidIndex++;
          if (paidIndex <= freeQuota) {
            continue;
          }
        }
        extrasTotal += sel.price * sel.quantity;
      }
    }

    return extrasTotal;
  }

  double get _calculatedUnitPrice => _basePrice + _extrasUnitTotal;

  double get _totalPrice => _calculatedUnitPrice * _quantity;

  String? get _validationError {
    for (var group in widget.product.optionGroups) {
      if (group.minSelections > 0) {
        final count = (_selections[group.id] ?? {}).length;
        if (count < group.minSelections) {
          return "Lütfen '${group.name}' alanından en az ${group.minSelections} seçim yapınız.";
        }
      }
    }
    return null;
  }

  List<SelectedProductOption> get _flattenedSelectedOptions {
    final List<SelectedProductOption> result = [];
    for (var group in widget.product.optionGroups) {
      final groupSelections = _selections[group.id] ?? {};
      final selectedOpts = groupSelections.values.toList();

      int freeQuota = group.freeSelectionsCount;
      int paidIndex = 0;

      for (var sel in selectedOpts) {
        double finalPrice = sel.price;
        if (sel.actionType != 'REMOVE' && freeQuota > 0) {
          paidIndex++;
          if (paidIndex <= freeQuota) {
            finalPrice = 0.0; // Free snapshot
          }
        }

        result.add(SelectedProductOption(
          optionId: sel.optionId,
          groupName: sel.groupName,
          name: sel.name,
          price: finalPrice,
          quantity: sel.quantity,
          actionType: sel.actionType,
        ));
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validationErr = _validationError;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle bar
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.product.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.product.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Option Groups List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: widget.product.optionGroups.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final group = widget.product.optionGroups[index];
                return _buildOptionGroupSection(group);
              },
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  offset: const Offset(0, -3),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Canlı Hesaplama ve Birim Fiyat Şeridi
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calculate_outlined, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            "Baz: ${_basePrice.toStringAsFixed(2)} ₺",
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_extrasUnitTotal > 0) ...[
                            const Text(" + ", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            Text(
                              "Ekstralar: +${_extrasUnitTotal.toStringAsFixed(2)} ₺",
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF00A651),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        "Birim: ${_calculatedUnitPrice.toStringAsFixed(2)} ₺",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Validation error chip if mandatory choices missing
                if (validationErr != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            validationErr,
                            style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                Row(
                  children: [
                    // Quantity Stepper
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                          ),
                          Text(
                            "$_quantity",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Add To Cart Button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: validationErr == null ? const Color(0xFFE95D22) : Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: validationErr == null ? 3 : 0,
                        ),
                        onPressed: validationErr == null
                            ? () {
                                widget.onAddToCart(
                                  widget.product,
                                  _flattenedSelectedOptions,
                                  _quantity,
                                );
                                Navigator.pop(context);
                              }
                            : null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "SEPETE EKLE",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "• ₺${_totalPrice.toStringAsFixed(2)}",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            if (_quantity > 1) ...[
                              const SizedBox(width: 4),
                              Text(
                                "(${_quantity} adet)",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionGroupSection(ProductOptionGroup group) {
    final groupSelections = _selections[group.id] ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Group Title & Badges
        Row(
          children: [
            Expanded(
              child: Text(
                group.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            if (group.minSelections > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text(
                  "ZORUNLU",
                  style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              )
            else
              const Text(
                "İsteğe Bağlı",
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
          ],
        ),
        if (group.description != null && group.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
            child: Text(
              group.description!,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        const SizedBox(height: 8),

        // Radio / Variation Pills
        if (group.type == 'VARIATION' || group.selectionType == 'RADIO')
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.options.map((opt) {
              final isSelected = groupSelections.containsKey(opt.id);
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      opt.name,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                    if (opt.price > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.25)
                              : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "+${opt.price.toStringAsFixed(2)} ₺",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF00A651),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                selectedColor: const Color(0xFFE95D22),
                backgroundColor: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFFE95D22) : Colors.grey.shade300,
                  ),
                ),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _selections[group.id] = {
                        opt.id: SelectedProductOption(
                          optionId: opt.id,
                          groupName: group.name,
                          name: opt.name,
                          price: opt.price,
                          actionType: 'ADD',
                        ),
                      };
                    }
                  });
                },
              );
            }).toList(),
          )
        else
          // Checkbox / Ingredient List
          Column(
            children: group.options.map((opt) {
              final isSelected = groupSelections.containsKey(opt.id);
              final bool isRemovable = opt.isRemovable;

              return InkWell(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selections[group.id]?.remove(opt.id);
                    } else {
                      if (group.maxSelections > 1 && groupSelections.length >= group.maxSelections) {
                        return;
                      }
                      _selections[group.id] ??= {};
                      _selections[group.id]![opt.id] = SelectedProductOption(
                        optionId: opt.id,
                        groupName: group.name,
                        name: opt.name,
                        price: opt.price,
                        actionType: isRemovable ? 'REMOVE' : 'ADD',
                      );
                    }
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 10.0),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isRemovable ? const Color(0xFFFFF5F5) : const Color(0xFFFFF9F6))
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? (isRemovable ? const Color(0xFFFFCDD2) : const Color(0xFFFFCCBC))
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? (isRemovable ? Icons.cancel : Icons.check_circle)
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? (isRemovable ? const Color(0xFFE53935) : const Color(0xFFE95D22))
                            : Colors.grey.shade400,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          opt.name,
                          style: TextStyle(
                            fontSize: 13.5,
                            decoration: (isSelected && isRemovable) ? TextDecoration.lineThrough : null,
                            color: (isSelected && isRemovable) ? const Color(0xFFE53935) : Colors.black87,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isRemovable && isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFECEC),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "ÇIKARILDI",
                            style: TextStyle(color: Color(0xFFE53935), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        )
                      else if (opt.price > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "+${opt.price.toStringAsFixed(2)} ₺",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00A651),
                            ),
                          ),
                        )
                      else
                        const Text(
                          "Ücretsiz",
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF718096),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

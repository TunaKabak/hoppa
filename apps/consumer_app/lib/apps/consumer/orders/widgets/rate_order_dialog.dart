import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_shared/shared/models/order.dart';
import 'package:consumer_app/apps/consumer/repositories/consumer_review_repository.dart';
import 'package:consumer_app/apps/consumer/repositories/consumer_order_repository.dart';

class RateOrderDialog extends ConsumerStatefulWidget {
  final Order order;

  const RateOrderDialog({super.key, required this.order});

  @override
  ConsumerState<RateOrderDialog> createState() => _RateOrderDialogState();
}

class _RateOrderDialogState extends ConsumerState<RateOrderDialog> {
  int _selectedRating = 0;
  int _selectedServiceRating = 0;
  int _selectedSpeedRating = 0;
  int _selectedTasteRating = 0;
  
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _hasTasteRating {
    final type = widget.order.businessType?.toUpperCase() ?? 'RESTAURANT';
    return type == 'RESTAURANT' || type == 'CAFE' || type == 'FOOD';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_selectedRating < 1 || _selectedRating > 5) {
      setState(() {
        _errorMessage = "Lütfen genel bir değerlendirme puanı seçin.";
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(consumerReviewRepositoryProvider);
      await repository.submitReview(
        orderId: widget.order.id,
        rating: _selectedRating,
        comment: _commentController.text.trim().isEmpty 
            ? null 
            : _commentController.text.trim(),
        serviceRating: _selectedServiceRating > 0 ? _selectedServiceRating : null,
        speedRating: _selectedSpeedRating > 0 ? _selectedSpeedRating : null,
        tasteRating: _hasTasteRating && _selectedTasteRating > 0 ? _selectedTasteRating : null,
      );

      // Refresh order list so order.review is no longer null
      ref.invalidate(consumerOrdersProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Değerlendirmeniz başarıyla kaydedildi! Teşekkür ederiz. 🎉"),
            backgroundColor: Color(0xFF00A651),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceAll("Exception:", "").trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF00A651);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24.0),
        ),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 24,
        right: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: brandGreen.withAlpha(26), // equivalent to withOpacity(0.1) but avoids precision warnings
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rate_review_outlined,
                  color: brandGreen,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Siparişi Değerlendir",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Deneyiminizi detaylı olarak puanlayarak bize yardımcı olabilirsiniz.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              "Genel Deneyiminiz",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final isSelected = starIndex <= _selectedRating;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = starIndex;
                    });
                  },
                  child: AnimatedScale(
                    scale: isSelected ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeOutBack,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(
                        isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isSelected ? Colors.amber[600] : Colors.grey[400],
                        size: 40,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            _buildSubRatingRow("Servis Kalitesi", _selectedServiceRating, (val) {
              setState(() => _selectedServiceRating = val);
            }),
            _buildSubRatingRow("Teslimat Hızı", _selectedSpeedRating, (val) {
              setState(() => _selectedSpeedRating = val);
            }),
            if (_hasTasteRating)
              _buildSubRatingRow("Lezzet", _selectedTasteRating, (val) {
                setState(() => _selectedTasteRating = val);
              }),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            TextField(
              controller: _commentController,
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Yorumunuzu buraya yazabilirsiniz (İsteğe bağlı)...",
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: brandGreen, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      "Kapat",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_selectedRating == 0 || _isSubmitting)
                        ? null
                        : _submitReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Gönder",
                            style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildSubRatingRow(String label, int currentRating, Function(int) onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87),
          ),
          Row(
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isSelected = starIndex <= currentRating;
              return GestureDetector(
                onTap: () => onTap(starIndex),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: Icon(
                    isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: isSelected ? Colors.amber[600] : Colors.grey[350],
                    size: 28,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

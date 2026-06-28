import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoppa/shared/models/order.dart';
import 'package:hoppa/apps/consumer/repositories/consumer_review_repository.dart';
import 'package:hoppa/apps/consumer/repositories/consumer_order_repository.dart';

class RateOrderDialog extends ConsumerStatefulWidget {
  final Order order;

  const RateOrderDialog({super.key, required this.order});

  @override
  ConsumerState<RateOrderDialog> createState() => _RateOrderDialogState();
}

class _RateOrderDialogState extends ConsumerState<RateOrderDialog> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_selectedRating < 1 || _selectedRating > 5) {
      setState(() {
        _errorMessage = "Lütfen 1 ile 5 arasında bir puan seçin.";
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

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      elevation: 8,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon & Text
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: brandGreen.withOpacity(0.1),
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
                "Siparişiniz teslim edildi. Deneyiminizi puanlayarak bize yardımcı olabilirsiniz.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Interactive Stars Row
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
              const SizedBox(height: 24),

              // Comment Field
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

              // Action Buttons
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
      ),
    );
  }
}

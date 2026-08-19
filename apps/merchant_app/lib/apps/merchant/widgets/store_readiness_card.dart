import 'package:flutter/material.dart';
import 'package:merchant_app/apps/merchant/merchant_product_list_page.dart';

class StoreReadinessCard extends StatelessWidget {
  final String businessId;
  final bool isShopActive;
  final int activeProductCount;

  const StoreReadinessCard({
    super.key,
    required this.businessId,
    required this.isShopActive,
    required this.activeProductCount,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasProducts = activeProductCount >= 1;
    final int score = (hasProducts ? 100 : 80);

    if (isShopActive && hasProducts) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFA5D6A7)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Mağazanız Canlıda & Hazır 🎉",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1B5E20),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Profil doluluk oranı %100. Otomatik sipariş kabul edebilirsiniz.",
                    style: TextStyle(fontSize: 11, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD5C2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Color(0xFFFF6B00), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Mağaza Hazırlık Durumu",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        "Profil Doluluğu: %$score",
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFF6B00),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Aktivasyon Bekliyor",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF6B00),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: score / 100.0,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF6B00)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          if (!hasProducts)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFE0B2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Zorunlu Adım: Sipariş alabilmek için en az 1 aktif ürün eklenmelidir.",
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFE65100)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MerchantProductListPage(businessId: businessId),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text("Ürün Ekle"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:hoppa/shared/models/campaign.dart';
import 'package:hoppa/shared/models/business_product.dart';
import 'package:hoppa/apps/consumer/business/campaign_products_page.dart';

class CampaignCarousel extends StatelessWidget {
  final List<Campaign> campaigns; // API'den çekilen aktif kampanyalar listesi
  final List<BusinessProduct> allShopProducts;

  const CampaignCarousel({
    Key? key,
    required this.campaigns,
    this.allShopProducts = const [],
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (campaigns.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 160,
      child: PageView.builder(
        itemCount: campaigns.length,
        controller: PageController(viewportFraction: 0.9), // Sağdan soldan hafif taşırarak derinlik hissi verir
        itemBuilder: (context, index) {
          final campaign = campaigns[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CampaignProductsPage(
                    campaign: campaign,
                    allShopProducts: allShopProducts,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  campaign.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.grey.shade100,
                    alignment: Alignment.center,
                    child: const Icon(Icons.campaign_outlined, size: 40),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

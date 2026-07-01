import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoppa/shared/models/campaign.dart';
import 'package:hoppa/shared/models/business_product.dart';
import 'package:hoppa/apps/consumer/home/widgets/modern_product_card.dart';
import 'package:hoppa/apps/consumer/product/product_detail_page.dart';

class CampaignProductsPage extends ConsumerWidget {
  final Campaign campaign;
  final List<BusinessProduct> allShopProducts;

  const CampaignProductsPage({
    super.key,
    required this.campaign,
    required this.allShopProducts,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // Filter products that belong to this campaign using explicit matching or smart name matching fallback
    final campaignProducts = allShopProducts.where((bp) {
      // 1. Explicit target products list match
      if (campaign.targetProducts.contains(bp.id) || 
          campaign.targetProducts.contains(bp.product.barcode)) {
        return true;
      }
      
      // 2. Dynamic matching fallback based on campaign name & product properties
      final name = campaign.name.toLowerCase();
      final pName = bp.product.name.toLowerCase();
      final pBrand = bp.product.brand.toLowerCase();
      final pCategory = bp.product.category.toLowerCase();
      
      if (name.contains("çay") || name.contains("tea") || name.contains("doğadan") || name.contains("herby")) {
        return pCategory.contains("çay") || pName.contains("çay") || pName.contains("tea") || pBrand.contains("ahmad");
      }
      if (name.contains("cilt") || name.contains("bakım") || name.contains("neutrogena") || 
          name.contains("bepanthol") || name.contains("vaseline") || name.contains("old spice") || 
          name.contains("garnier") || name.contains("clear") || name.contains("axe") || name.contains("kozmetik")) {
        return pCategory.contains("bakım") || pCategory.contains("kozmetik") || 
               pName.contains("krem") || pName.contains("şampuan") || pName.contains("macun") ||
               pBrand.contains("nivea") || pBrand.contains("ipana");
      }
      if (name.contains("et") || name.contains("sucuk")) {
        return pCategory.contains("et") || pCategory.contains("kasap") || pName.contains("sucuk");
      }
      if (name.contains("süt") || name.contains("peynir") || name.contains("kahvaltı")) {
        return pCategory.contains("süt") || pCategory.contains("kahvaltı");
      }
      if (name.contains("ekmek") || name.contains("fırın") || name.contains("unlu")) {
        return pCategory.contains("ekmek") || pCategory.contains("fırın") || pCategory.contains("unlu");
      }
      if (name.contains("atıştırmalık") || name.contains("bisküvi") || name.contains("çikolata")) {
        return pCategory.contains("atıştırmalık") || pCategory.contains("bisküvi");
      }
      
      // If it's a general campaign with a discount (e.g. Seç Al), display products that have discounts
      if (campaign.discountValue > 0) {
        return bp.discountRate > 0;
      }
      
      return false;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(campaign.name),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Banner Area
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(campaign.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: Colors.black.withOpacity(0.4),
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomLeft,
              child: Text(
                campaign.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Products Grid
          Expanded(
            child: campaignProducts.isEmpty
                ? const Center(
                    child: Text(
                      "Bu kampanyaya ait aktif ürün bulunamadı.",
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: campaignProducts.length,
                    itemBuilder: (context, index) {
                      final product = campaignProducts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailPage(businessProduct: product),
                            ),
                          );
                        },
                        child: ModernProductCard(
                          businessProduct: product,
                          campaign: campaign, // Pass campaign so correct discount shows
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

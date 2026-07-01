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

    String formatDate(DateTime date) {
      final months = ["Oca", "Şub", "Mar", "Nis", "May", "Haz", "Tem", "Ağu", "Eyl", "Eki", "Kas", "Ara"];
      return "${date.day} ${months[date.month - 1]} ${date.year}";
    }
    final dateString = "${formatDate(campaign.startDate)} - ${formatDate(campaign.endDate)}";

    return Scaffold(
      appBar: AppBar(
        title: Text(campaign.name),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Campaign Image Banner (No text overlay)
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(campaign.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          // 2. Campaign Details Card
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    campaign.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (campaign.description.isNotEmpty) ...[
                    Text(
                      campaign.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 16, color: theme.primaryColor),
                      const SizedBox(width: 6),
                      Text(
                        "Kampanya Dönemi:",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateString,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // 3. Grid Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                "Kampanyalı Ürünler (${campaignProducts.length})",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          // 4. Products Grid or Empty Info
          if (campaignProducts.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  "Bu kampanyaya ait aktif ürün bulunamadı.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
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
                        campaign: campaign,
                      ),
                    );
                  },
                  childCount: campaignProducts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoppa/shared/models/campaign.dart';
import 'package:hoppa/shared/models/business_product.dart';
import 'package:hoppa/apps/consumer/home/widgets/modern_product_card.dart';
import 'package:hoppa/apps/consumer/product/product_detail_page.dart';
import 'package:hoppa/apps/consumer/cart/widgets/cart_price_badge.dart';

class CampaignDetailPage extends StatefulWidget {
  final Campaign campaign;

  const CampaignDetailPage({super.key, required this.campaign});

  @override
  State<CampaignDetailPage> createState() => _CampaignDetailPageState();
}

class _CampaignDetailPageState extends State<CampaignDetailPage> {
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<BusinessProduct> _products = [];
  bool _isLoading = true;
  bool _hasMore = true;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _fetchProducts();
      }
    }
  }

  Future<void> _fetchProducts() async {
    if (widget.campaign.targetProducts.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Split targetProducts into chunks of 30 due to Firestore 'in' query limit
      List<String> remainingTargets = widget.campaign.targetProducts
          .skip(_products.length)
          .take(_limit)
          .toList();

      if (remainingTargets.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      Query query = _db
          .collection('business_products')
          .where('businessId', isEqualTo: widget.campaign.vendorId)
          .where('productBarcode', whereIn: remainingTargets);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        List<BusinessProduct> newProducts = snapshot.docs.map((doc) {
          return BusinessProduct.fromMap(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        setState(() {
          _products.addAll(newProducts);
          if (remainingTargets.length < _limit ||
              snapshot.docs.length < remainingTargets.length) {
            // Depending on how we chunk, if we fetched less than 20, we might or might not have more overall.
            // But since we query by specific barcodes, we can just check if _products.length == targetProducts.length
          }
        });
      }

      setState(() {
        _hasMore = _products.length < widget.campaign.targetProducts.length;
      });
    } catch (e) {
      debugPrint("Kampanya ürünleri çekme hatası: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            expandedHeight: 240.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.campaign.imageUrl.isNotEmpty)
                    Image.network(
                      widget.campaign.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: theme.primaryColor),
                    )
                  else
                    Container(color: theme.primaryColor),
                  // Gradient Overlay for Text Readability
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.campaign.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.campaign.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.campaign.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.campaign.type == CampaignType.percentage
                                ? "%${widget.campaign.discountValue.toStringAsFixed(0)} İndirim"
                                : "${widget.campaign.discountValue.toStringAsFixed(2)} ₺ Özel Fiyat",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [const CartPriceBadge(), const SizedBox(width: 8)],
          ),
          if (_products.isEmpty && !_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.discount_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Bu kampanyaya ait ürün bulunamadı.",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final product = _products[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailPage(businessProduct: product),
                        ),
                      );
                    },
                    child: ModernProductCard(
                      businessProduct: product,
                      campaign: widget.campaign,
                    ),
                  );
                }, childCount: _products.length),
              ),
            ),
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

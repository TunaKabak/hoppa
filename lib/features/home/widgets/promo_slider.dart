import 'dart:async';
import 'package:flutter/material.dart';

import 'package:hoppa/models/campaign.dart';
import 'package:provider/provider.dart';
import 'package:hoppa/features/home/product_provider.dart';

class PromoSlider extends StatefulWidget {
  final List<Campaign> campaigns;
  const PromoSlider({super.key, required this.campaigns});

  @override
  State<PromoSlider> createState() => _PromoSliderState();
}

class _PromoSliderState extends State<PromoSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Color> _fallbackColors = [
    const Color(0xFF00A651),
    const Color(0xFFFF6B00),
    const Color(0xFF5D3FD3),
    const Color(0xFFD32F2F),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    if (widget.campaigns.isEmpty) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (!mounted) return;
      if (_currentPage < widget.campaigns.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.campaigns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 180, // Slightly taller for better visual
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: widget.campaigns.length,
            itemBuilder: (context, index) {
              final campaign = widget.campaigns[index];
              return _buildPromoCard(campaign, index);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Pagination Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.campaigns.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? _fallbackColors[index % _fallbackColors.length]
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Color _getFallbackColor(int index) {
    if (widget.campaigns.isEmpty) return Colors.green;
    return _fallbackColors[index % _fallbackColors.length];
  }

  Widget _buildPromoCard(Campaign campaign, int index) {
    final fallbackColor = _fallbackColors[index % _fallbackColors.length];

    return GestureDetector(
      onTap: () {
        // Find the provider and trigger filter
        Provider.of<ProductProvider>(
          context,
          listen: false,
        ).setCampaignFilter(campaign);
        // Refresh products
        // (Fetch needs businessId, but setCampaignFilter zeroes out the list
        //  and the Home page scroll handles infinite logic, but we must force load)
        final businessId = campaign.vendorId; // or get from prov..
        Provider.of<ProductProvider>(
          context,
          listen: false,
        ).fetchProducts(businessId: businessId);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: fallbackColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: fallbackColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              if (campaign.imageUrl.isNotEmpty)
                Positioned.fill(
                  child: Image.network(
                    campaign.imageUrl,
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(
                      0.3,
                    ), // Darken for readability
                    colorBlendMode: BlendMode.darken,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: fallbackColor);
                    },
                  ),
                ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      campaign.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      campaign.type == CampaignType.percentage
                          ? "%${campaign.discountValue.toStringAsFixed(0)} İndirim Kampanyası!"
                          : "${campaign.discountValue.toStringAsFixed(2)} ₺ Özel Fiyat!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

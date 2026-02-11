import 'dart:async';
import 'package:flutter/material.dart';

class PromoSlider extends StatefulWidget {
  const PromoSlider({super.key});

  @override
  State<PromoSlider> createState() => _PromoSliderState();
}

class _PromoSliderState extends State<PromoSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _promos = [
    {
      'color': const Color(0xFF00A651),
      'title': "Taze Teslimat",
      'subtitle': "30 Dakikada Kapında!",
      'icon': Icons.local_shipping,
      'image': "https://placehold.co/600x300/00A651/ffffff?text=Hizli+Teslimat",
    },
    {
      'color': const Color(0xFFFF6B00),
      'title': "Öğrenci Fırsatı",
      'subtitle': "%10 İndirim Kampanyası",
      'icon': Icons.school,
      'image':
          "https://placehold.co/600x300/FF6B00/ffffff?text=Ogrenci+Indirimi",
    },
    {
      'color': const Color(0xFF5D3FD3),
      'title': "Haftanın Yıldızı",
      'subtitle': "Seçili ürünlerde %20",
      'icon': Icons.star,
      'image': "https://placehold.co/600x300/5D3FD3/ffffff?text=Yildiz+Urunler",
    },
    {
      'color': const Color(0xFFD32F2F),
      'title': "Büyük İndirim",
      'subtitle': "Sepette %50'ye varan!",
      'icon': Icons.percent,
      'image': "https://placehold.co/600x300/D32F2F/ffffff?text=Buyuk+Indirim",
    },
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
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < _promos.length - 1) {
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
            itemCount: _promos.length,
            itemBuilder: (context, index) {
              final promo = _promos[index];
              return _buildPromoCard(promo);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Pagination Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_promos.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? (promoColor(index))
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Color promoColor(int index) {
    if (index < _promos.length) {
      return _promos[index]['color'] as Color;
    }
    return Colors.green;
  }

  Widget _buildPromoCard(Map<String, dynamic> promo) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: promo['color'],
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (promo['color'] as Color).withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background Image (Mock)
            Positioned.fill(
              child: Image.network(
                promo['image'],
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.3), // Darken for readability
                colorBlendMode: BlendMode.darken,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: promo['color']);
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
                    child: Icon(promo['icon'], color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    promo['title'],
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
                    promo['subtitle'],
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
    );
  }
}

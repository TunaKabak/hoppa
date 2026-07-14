import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CampaignItem {
  final String imagePath;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  CampaignItem({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
}

class HoppaCampaignSlider extends StatefulWidget {
  const HoppaCampaignSlider({super.key});

  @override
  State<HoppaCampaignSlider> createState() => _HoppaCampaignSliderState();
}

class _HoppaCampaignSliderState extends State<HoppaCampaignSlider> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;
  Timer? _timer;

  late final List<CampaignItem> _campaigns = [
    CampaignItem(
      imagePath: 'assets/images/campaign_free_delivery.png',
      title: 'Teslimat Ücreti Hoppadan! 🏍️',
      subtitle: 'İlk 5 siparişinizde teslimat ücreti ödemeyin.',
      onTap: () {
        // Can route to a specific page or show dialog
      },
    ),
    CampaignItem(
      imagePath: 'assets/images/campaign_welcome_coupon.png',
      title: 'Hoppa\'ya Hoş Geldin! 🎉',
      subtitle: 'İlk siparişinize özel 100 TL hediye kuponu.',
      onTap: () {
        // Can route to coupon wallet
      },
    ),
    CampaignItem(
      imagePath: 'assets/images/campaign_everything_at_door.png',
      title: 'Aradığın Her Şey Kapında! 🛒',
      subtitle: 'Market, yemek, su veya çiçek... İste hemen gelsin.',
      onTap: () {
        // Can open search or highlight categories
      },
    ),
    CampaignItem(
      imagePath: 'assets/images/campaign_invite_friend.png',
      title: 'Arkadaşını Davet Et Kazan! 🤝',
      subtitle: 'Davet et, ikiniz de 100 TL Hoppa Puan kazanın.',
      onTap: () {
        // Can route to invite page
      },
    ),
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
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % _campaigns.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 156,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              // Reset timer to prevent premature slide after user manual swipe
              _startAutoPlay();
            },
            itemCount: _campaigns.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final item = _campaigns[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  return child!;
                },
                child: GestureDetector(
                  onTap: item.onTap,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Background Image
                          Image.asset(
                            item.imagePath,
                            fit: BoxFit.cover,
                          ),
                          // Premium Gradient Overlay for readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withValues(alpha: 0.75),
                                  Colors.black.withValues(alpha: 0.2),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.6, 1.0],
                              ),
                            ),
                          ),
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  item.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black38,
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.subtitle,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                    shadows: const [
                                      Shadow(
                                        color: Colors.black38,
                                        offset: Offset(0, 1),
                                        blurRadius: 2,
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
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _campaigns.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentPage == index ? 16 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? const Color(0xFF00A651) // Hoppa primary green
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

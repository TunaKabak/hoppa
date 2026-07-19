import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as p;
import 'package:consumer_app/apps/consumer/business/business_provider.dart';
import 'package:consumer_app/apps/consumer/repositories/consumer_shop_repository.dart';
import 'package:core_shared/shared/models/campaign.dart';
import 'package:consumer_app/apps/consumer/campaigns/campaign_detail_page.dart';

class CampaignItem {
  final String imagePath;
  final String title;
  final String subtitle;
  final String badgeText;
  final List<Color> gradientColors;
  final Color accentColor;
  final Color textColor;
  final Color subtitleColor;
  final VoidCallback? onTap;

  CampaignItem({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    required this.gradientColors,
    required this.accentColor,
    required this.textColor,
    required this.subtitleColor,
    this.onTap,
  });
}

class HoppaCampaignSlider extends ConsumerStatefulWidget {
  const HoppaCampaignSlider({super.key});

  @override
  ConsumerState<HoppaCampaignSlider> createState() => _HoppaCampaignSliderState();
}

class _HoppaCampaignSliderState extends ConsumerState<HoppaCampaignSlider> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;
  Timer? _timer;

  late final List<CampaignItem> _staticCampaigns = [
    CampaignItem(
      imagePath: 'assets/images/campaign_free_delivery.png',
      title: 'Teslimat Ücreti\nHoppa\'dan! 🏍️',
      subtitle: 'İlk 5 siparişinizde teslimat ödemeyin.',
      badgeText: 'ÜCRETSİZ TESLİMAT',
      gradientColors: const [Color(0xFFFFF8F2), Color(0xFFFFECE1)],
      accentColor: const Color(0xFFE95D22), // Hoppa Orange
      textColor: Colors.black87,
      subtitleColor: Colors.black54,
      onTap: () {},
    ),
    CampaignItem(
      imagePath: 'assets/images/campaign_welcome_coupon.png',
      title: 'Hoppa\'ya\nHoş Geldin! 🎉',
      subtitle: 'İlk siparişinize özel 100 TL hediye.',
      badgeText: 'HOŞ GELDİN KUPONU',
      gradientColors: const [Color(0xFFFFF2F6), Color(0xFFFFE1EC)],
      accentColor: const Color(0xFF00A651), // Hoppa Green
      textColor: Colors.white,
      subtitleColor: Colors.white70,
      onTap: () {},
    ),
    CampaignItem(
      imagePath: 'assets/images/campaign_everything_at_door.png',
      title: 'Aradığın Her Şey\nKapında! 🛒',
      subtitle: 'Market, yemek, su... İste gelsin.',
      badgeText: 'KOLAY SİPARİŞ',
      gradientColors: const [Color(0xFFF2FBF6), Color(0xFFE1F7EB)],
      accentColor: const Color(0xFFE95D22), // Hoppa Orange
      textColor: Colors.black87,
      subtitleColor: Colors.black54,
      onTap: () {},
    ),
    CampaignItem(
      imagePath: 'assets/images/campaign_invite_friend.png',
      title: 'Arkadaşını\nDavet Et Kazan! 🤝',
      subtitle: 'Davet et, ikiniz de 100 TL kazanın.',
      badgeText: 'DAVET ET KAZAN',
      gradientColors: const [Color(0xFFF2F9FF), Color(0xFFE1F0FF)],
      accentColor: const Color(0xFF00A651), // Hoppa Green
      textColor: Colors.white,
      subtitleColor: Colors.white70,
      onTap: () {},
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay(4);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay(int count) {
    _timer?.cancel();
    if (count <= 1) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % count;
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
    final activeCampaignsAsync = ref.watch(activeShopCampaignsProvider);
    final shops = ref.watch(consumerShopsProvider).value ?? [];

    return activeCampaignsAsync.when(
      loading: () => const SizedBox(height: 156, child: Center(child: CircularProgressIndicator())),
      error: (err, stack) => _buildStaticSlider(),
      data: (shopCampaigns) {
        // Yalnızca APPROVED ve MAIN_SLIDER hedeflenen kampanyaları filtrele
        final mainSliders = shopCampaigns.where((c) => c['targetArea'] == 'MAIN_SLIDER' && c['status'] == 'APPROVED').toList();

        if (mainSliders.isEmpty) {
          return _buildStaticSlider();
        }

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
                  _startAutoPlay(mainSliders.length);
                },
                itemCount: mainSliders.length,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  final c = mainSliders[index];
                  final imageUrl = c['imageUrl'] as String;
                  final title = c['title'] as String;
                  final description = c['description'] as String;
                  final shopId = c['shopId'] as String?;

                  return GestureDetector(
                    onTap: () {
                      if (shopId != null && shopId.isNotEmpty) {
                        final shop = shops.firstWhere(
                          (s) => s.id == shopId,
                          orElse: () => throw Exception('Shop not found'),
                        );
                        
                        // Set attribution states
                        ref.read(activeReferringSourceProvider.notifier).state = 'MAIN_SLIDER';
                        ref.read(activeShopCampaignIdProvider.notifier).state = c['id'];

                        final businessProvider = p.Provider.of<BusinessProvider>(context, listen: false);
                        businessProvider.setCategory(shop.type.label);
                        businessProvider.selectBusiness(shop);
                      } else {
                        // Sistemsel kampanya veya genel reklam ise detay sayfasını aç
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CampaignDetailPage(
                              campaign: Campaign.fromMap(Map<String, dynamic>.from(c), c['id'] ?? ''),
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFFF5200).withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
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
                            if (imageUrl.isNotEmpty)
                              Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade200),
                              )
                            else
                              Container(color: Colors.grey.shade200),
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.6),
                                      Colors.black.withOpacity(0.1),
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                              ),
                            ),
                            // Header Hoppa Logo
                            Positioned(
                              left: 16,
                              top: 16,
                              child: Image.asset(
                                'assets/images/hoppa_logo.png',
                                height: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 16,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF5200),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "ÖNE ÇIKAN KAMPANYA",
                                      style: GoogleFonts.poppins(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    title,
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    description,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: Colors.white70,
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
                },
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                mainSliders.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: _currentPage == index ? 16 : 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? const Color(0xFFFF5200) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStaticSlider() {
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
              _startAutoPlay(_staticCampaigns.length);
            },
            itemCount: _staticCampaigns.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final item = _staticCampaigns[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) => child!,
                child: GestureDetector(
                  onTap: item.onTap,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: item.accentColor.withOpacity(0.2),
                        width: 1.5,
                      ),
                      image: DecorationImage(
                        image: AssetImage(item.imagePath),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: item.accentColor.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 16,
                            top: 16,
                            child: Image.asset(
                              'assets/images/hoppa_logo.png',
                              height: 14,
                              color: item.textColor.withOpacity(0.8),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: item.textColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: item.textColor.withOpacity(0.25),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    item.badgeText,
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: item.textColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: item.textColor,
                                        height: 1.25,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.52,
                                      child: Text(
                                        item.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          color: item.subtitleColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _staticCampaigns.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentPage == index ? 16 : 6,
              decoration: BoxDecoration(
                color: _currentPage == index ? const Color(0xFF00A651) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

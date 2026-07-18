import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/merchant_api_providers.dart';
import 'merchant_main_layout.dart';
import 'widgets/merchant_dialog.dart';
import 'package:intl/intl.dart';

class MerchantSponsorshipPage extends ConsumerWidget {
  final String businessId;

  const MerchantSponsorshipPage({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shopState = ref.watch(shopControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        title: const Text(
          "Öne Çıkarma ve Sponsorluk",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => merchantDrawerKey.currentState?.openDrawer(),
        ),
      ),
      body: shopState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text("Hata oluştu: $err", style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(shopControllerProvider),
                child: const Text("Yeniden Dene"),
              ),
            ],
          ),
        ),
        data: (shop) {
          if (shop == null) {
            return const Center(child: Text("Dükkan bilgisi bulunamadı."));
          }

          final ratePercent = ((shop.activeCommissionRate ?? 0.05) * 100).round();
          
          // Get promotions list
          final promotions = shop.activePromotions ?? [];
          final mainPromo = promotions.firstWhere(
            (p) => p['promoType'] == 'MAIN_SCREEN',
            orElse: () => null,
          );
          final catPromo = promotions.firstWhere(
            (p) => p['promoType'] == 'CATEGORY',
            orElse: () => null,
          );

          final hasMainScreen = mainPromo != null;
          final hasCategory = catPromo != null;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // ─── DEVASE KOMİSYON ORANI KARTININ GÖSTERİMİ ───
              _buildCommissionHeaderCard(ratePercent, hasMainScreen || hasCategory, colorScheme),
              const SizedBox(height: 24),

              Text(
                "Sponsorluk Seçenekleri",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Dükkanınızı platformda öne çıkararak siparişlerinizi katlayın. Reklam ücretleri peşin alınmaz, haftalık hakedişlerinizden komisyon oranına yansıtılarak mahsup edilir.",
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),

              // ─── SPONSORLUK SEÇENEKLERİ KARTLARI (MUTUAL EXCLUSION & UPGRADE PATH) ───
              _SponsorshipCard(
                title: "Hoppa Ana Sayfa Tepe Slider",
                description: "Dükkanınız 1 hafta boyunca ana sayfanın en üstünde parıldar. Bu reklam etkinken kategori içi öne çıkarma satın alınamaz.",
                promoType: "MAIN_SCREEN",
                isActive: hasMainScreen,
                isDisabled: false, // upgrades allowed!
                isUpgrade: hasCategory, // true if CATEGORY is active
                disabledWarning: null,
                commissionRateLabel: "%15 Komisyon",
                activePromoData: mainPromo,
                gradient: const LinearGradient(
                  colors: [Color(0xFF512DA8), Color(0xFF311B92)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                icon: Icons.auto_awesome_rounded,
                onActivate: () => _confirmAndActivate(context, ref, "MAIN_SCREEN", isUpgrade: hasCategory),
                onCancel: () => _confirmAndCancel(context, ref, "MAIN_SCREEN"),
              ),
              const SizedBox(height: 16),

              _SponsorshipCard(
                title: "Kategori İçi Öne Çıkarma",
                description: "Kendi kategorinizde rakiplerinizin en üstünde yer edin. Bu reklam etkinken ana sayfa tepe slider sponsorluğu satın alınamaz.",
                promoType: "CATEGORY",
                isActive: hasCategory,
                isDisabled: hasMainScreen, // strictly disabled if MAIN_SCREEN is active
                isUpgrade: false,
                disabledWarning: "Ana Sayfa Reklamınız Aktif",
                commissionRateLabel: "%10 Komisyon",
                activePromoData: catPromo,
                gradient: const LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFBF360C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                icon: Icons.category_rounded,
                onActivate: () => _confirmAndActivate(context, ref, "CATEGORY", isUpgrade: false),
                onCancel: () => _confirmAndCancel(context, ref, "CATEGORY"),
              ),
              const SizedBox(height: 32),

              // ─── TÜKETİCİ UYGULAMASI ÖNİZLEMESİ (SLIDING PREVIEW) ───
              _LivePreviewsSection(shop: shop),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommissionHeaderCard(int ratePercent, bool hasActivePromo, ColorScheme colorScheme) {
    final gradient = hasActivePromo
        ? const LinearGradient(
            colors: [Color(0xFFFFD54F), Color(0xFFFFA000)], // Premium Altın/Turuncu Gradyan
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : LinearGradient(
            colors: [colorScheme.primary, colorScheme.primary.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (hasActivePromo ? Colors.orange : colorScheme.primary).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                hasActivePromo ? "🔥 Premium Mağaza Oranı" : "🛡️ Standart Mağaza Oranı",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              if (hasActivePromo)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Sponsorlu Aktif",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                "Aktif Komisyon Oranınız:",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                "%$ratePercent",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 8),
          Text(
            hasActivePromo
                ? "Dükkanınız şu an platformda öncelikli gösterilmektedir. Sipariş başı komisyon oranınız güncellendi."
                : "Sponsorluk bulunmuyor. Gelen siparişlerden standart %5 komisyon alınmaktadır.",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmAndActivate(BuildContext context, WidgetRef ref, String promoType, {bool isUpgrade = false}) {
    final title = promoType == "MAIN_SCREEN"
        ? (isUpgrade ? "Ana Sayfa Slider Yükseltmesi" : "Ana Sayfa Tepe Slider")
        : "Kategori İçi Öne Çıkarma";

    final rateText = promoType == "MAIN_SCREEN" ? "%15" : "%10";

    final content = isUpgrade
        ? "Kategori sponsorluğunuz sonlandırılarak Ana Sayfa Tepe Slider sponsorluğuna yükseltilecektir. Bu işlem onaylandıktan sonra bu hafta gelen siparişlerden %15 komisyon kesilecektir. Emin misiniz?"
        : "Dükkanınızı 1 hafta boyunca öne çıkarmak istediğinize emin misiniz? Bu işlem onaylandıktan sonra peşin ücret alınmaz, bu hafta gelen siparişlerden $rateText komisyon kesilir.";

    final confirmText = isUpgrade ? "Evet, Yükselt" : "Evet, Başlat";

    showDialog(
      context: context,
      builder: (ctx) => MerchantDialog(
        icon: promoType == "MAIN_SCREEN" ? Icons.auto_awesome_rounded : Icons.category_rounded,
        iconColor: const Color(0xFFE95D22),
        title: isUpgrade ? "Sponsorluk Yükseltme" : "$title Aktivasyonu",
        content: content,
        cancelText: "Vazgeç",
        confirmText: confirmText,
        onCancel: () => Navigator.pop(ctx),
        onConfirm: () async {
          Navigator.pop(ctx); // Close dialog
          try {
            // Show loading HUD using dialog
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );

            await ref.read(sponsorshipNotifierProvider.notifier).activateSponsorship(promoType);

            if (context.mounted) {
              Navigator.pop(context); // Close loading dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(isUpgrade ? "Sponsorluğunuz başarıyla yükseltildi!" : "Sponsorluk başarıyla aktif edildi!"),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context); // Close loading dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Aktivasyon başarısız: $e"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _confirmAndCancel(BuildContext context, WidgetRef ref, String promoType) {
    final title = promoType == "MAIN_SCREEN"
        ? "Ana Sayfa Tepe Slider"
        : "Kategori İçi Öne Çıkarma";

    showDialog(
      context: context,
      builder: (ctx) => MerchantDialog(
        icon: Icons.cancel_outlined,
        iconColor: Colors.red,
        title: "Sponsorluk İptali",
        content: "$title sponsorluğunu iptal etmek istediğinize emin misiniz? Dükkanınız platformda öncelikli gösterilmekten kaldırılacak ve komisyon oranınız standart %5'e düşecektir.",
        cancelText: "Vazgeç",
        confirmText: "Evet, İptal Et",
        isDestructive: true,
        onCancel: () => Navigator.pop(ctx),
        onConfirm: () async {
          Navigator.pop(ctx); // Close dialog
          try {
            // Show loading HUD
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => const Center(child: CircularProgressIndicator()),
            );

            await ref.read(sponsorshipNotifierProvider.notifier).cancelSponsorship(promoType);

            if (context.mounted) {
              Navigator.pop(context); // Close loading dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Sponsorluğunuz iptal edildi."),
                  backgroundColor: Colors.blueGrey,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context); // Close loading dialog
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("İptal işlemi başarısız: $e"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }
}

// ─── TÜKETİCİ ÖNİZLEME ALANI BİLEŞENİ ───
class _LivePreviewsSection extends StatefulWidget {
  final dynamic shop;

  const _LivePreviewsSection({required this.shop});

  @override
  State<_LivePreviewsSection> createState() => _LivePreviewsSectionState();
}

class _LivePreviewsSectionState extends State<_LivePreviewsSection> {
  int _selectedTabIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedTabIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String shopName = widget.shop.name ?? "Dükkanım";
    final String? logoUrl = widget.shop.imageUrl;
    final String? headerUrl = widget.shop.headerImageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.remove_red_eye_rounded, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Text(
              "Canlı Tüketici Arayüz Önizlemesi",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey.shade800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          "Sponsorluğunuz aktif olduğunda dükkanınızın tüketici uygulamasında nasıl görüneceğini aşağıdan inceleyebilirsiniz.",
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),
        
        // Custom Segmented Switcher (Segmented Control style with sliding feel)
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth / 2;
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    left: _selectedTabIndex * width,
                    top: 0,
                    bottom: 0,
                    width: width,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedTabIndex = 0);
                            _pageController.animateToPage(
                              0,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            color: Colors.transparent,
                            alignment: Alignment.center,
                            child: Text(
                              "Tepe Slider (Ana Sayfa)",
                              style: TextStyle(
                                color: _selectedTabIndex == 0 ? const Color(0xFFE95D22) : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedTabIndex = 1);
                            _pageController.animateToPage(
                              1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Container(
                            color: Colors.transparent,
                            alignment: Alignment.center,
                            child: Text(
                              "Liste Kartı (Kategori)",
                              style: TextStyle(
                                color: _selectedTabIndex == 1 ? const Color(0xFFE95D22) : Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }
          ),
        ),
        const SizedBox(height: 16),

        // Horizontal sliding PageView transition (Exactly like consumer app)
        SizedBox(
          height: 200,
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _selectedTabIndex = index;
              });
            },
            children: [
              _buildSliderMockup(shopName, logoUrl, headerUrl),
              _buildCardMockup(shopName, logoUrl, headerUrl, widget.shop),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSliderMockup(String shopName, String? logoUrl, String? headerUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Smartphone mock status bar indicator
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(4)),
                child: Row(
                  children: [
                    Icon(Icons.bolt_rounded, size: 10, color: Colors.green.shade700),
                    const SizedBox(width: 2),
                    Text("ANA SAYFADA EN ÜSTTE", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz, size: 14, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          // Banner Mockup
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE95D22), Color(0xFFFF8C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    if (headerUrl != null && headerUrl.startsWith('http'))
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.4,
                          child: Image.network(headerUrl, fit: BoxFit.cover),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                                  child: const Text(
                                    "SPONSORLU",
                                    style: TextStyle(color: Color(0xFFE95D22), fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  shopName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "Haftanın Öne Çıkan Lezzeti",
                                  style: TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Shop Circle Logo
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                            ),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage: (logoUrl != null && logoUrl.startsWith('http'))
                                  ? NetworkImage(logoUrl)
                                  : null,
                              child: (logoUrl == null || !logoUrl.startsWith('http'))
                                  ? const Icon(Icons.store_rounded, color: Color(0xFFE95D22), size: 30)
                                  : null,
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
        ],
      ),
    );
  }

  Widget _buildCardMockup(String shopName, String? logoUrl, String? headerUrl, dynamic shop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Smartphone mock category title bar
          const Row(
            children: [
              Text("KATEGORİ LİSTESİNDE EN ÜSTTE", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
              Spacer(),
              Icon(Icons.tune_rounded, size: 12, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          // Shop Card Mockup (Hoppa style)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                // Logo mockup
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: (logoUrl != null && logoUrl.startsWith('http'))
                        ? Image.network(logoUrl, fit: BoxFit.cover)
                        : const Icon(Icons.store_rounded, color: Colors.grey, size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shopName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          const Text("4.9", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                          const SizedBox(width: 8),
                          Icon(Icons.access_time_rounded, color: Colors.grey.shade600, size: 13),
                          const SizedBox(width: 2),
                          Text(shop.deliveryTime ?? "30-40 dk", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Badges
                      Wrap(
                        spacing: 6,
                        children: [
                          // Dynamic highlighted Öne Çıkan badge!
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00A651).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFF00A651).withValues(alpha: 0.3)),
                            ),
                            child: const Text(
                              "Öne Çıkan",
                              style: TextStyle(color: Color(0xFF00A651), fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "Gel-Al",
                              style: TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
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
        ],
      ),
    );
  }
}

class _SponsorshipCard extends StatelessWidget {
  final String title;
  final String description;
  final String promoType;
  final bool isActive;
  final bool isDisabled;
  final bool isUpgrade;
  final String? disabledWarning;
  final String commissionRateLabel;
  final dynamic activePromoData;
  final Gradient gradient;
  final IconData icon;
  final VoidCallback onActivate;
  final VoidCallback? onCancel;

  const _SponsorshipCard({
    required this.title,
    required this.description,
    required this.promoType,
    required this.isActive,
    required this.isDisabled,
    this.isUpgrade = false,
    this.disabledWarning,
    required this.commissionRateLabel,
    required this.activePromoData,
    required this.gradient,
    required this.icon,
    required this.onActivate,
    this.onCancel,
  });

  String _getPromoDurationDetails() {
    if (activePromoData == null) return "";
    final endDateStr = activePromoData['endDate'];
    if (endDateStr == null) return "";
    final endDate = DateTime.tryParse(endDateStr.toString());
    if (endDate == null) return "";

    final format = DateFormat('dd.MM.yyyy HH:mm');
    final diff = endDate.difference(DateTime.now());

    String timeText = "";
    if (diff.isNegative) {
      timeText = "Süresi doldu";
    } else {
      final days = diff.inDays;
      final hours = diff.inHours % 24;
      final minutes = diff.inMinutes % 60;
      if (days > 0) {
        timeText = "$days gün $hours saat kaldı";
      } else if (hours > 0) {
        timeText = "$hours saat $minutes dakika kaldı";
      } else {
        timeText = "$minutes dakika kaldı";
      }
    }
    return "Sona Erme Tarihi: ${format.format(endDate)}\n($timeText)";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey.shade200,
            width: isActive ? 0 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header of card (with background color gradient if active)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isActive ? gradient : null,
                color: isActive ? null : Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    color: isActive ? Colors.white : theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      commissionRateLabel,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isActive)
                    Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.green.shade700, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Sponsorluk Yayında",
                                    style: TextStyle(
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getPromoDurationDetails(),
                                style: TextStyle(
                                  color: Colors.green.shade900,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (onCancel != null)
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red.shade200),
                              foregroundColor: Colors.red,
                              minimumSize: const Size.fromHeight(46),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: onCancel,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cancel_outlined, size: 18),
                                SizedBox(width: 8),
                                Text("Sponsorluğu İptal Et", style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    )
                  else if (isDisabled && disabledWarning != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded, color: Colors.grey.shade500, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            disabledWarning!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    if (isUpgrade) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.upgrade_rounded, color: Colors.purple.shade700, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "Aktif kategori reklamınız sonlandırılarak bu reklama yükseltilir.",
                                style: TextStyle(
                                  color: Colors.purple.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: gradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onActivate,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isUpgrade ? Icons.upgrade_rounded : icon, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              isUpgrade ? "Hemen Yükselt" : "Hemen Aktif Et",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

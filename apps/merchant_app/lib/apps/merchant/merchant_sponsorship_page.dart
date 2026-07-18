import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/merchant_api_providers.dart';
import 'merchant_main_layout.dart';

class MerchantSponsorshipPage extends ConsumerWidget {
  final String businessId;

  const MerchantSponsorshipPage({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final shopState = ref.watch(shopControllerProvider);

    return Scaffold(
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
          final hasMainScreen = shop.activePromotions?.any((p) => p['promoType'] == 'MAIN_SCREEN') ?? false;
          final hasCategory = shop.activePromotions?.any((p) => p['promoType'] == 'CATEGORY') ?? false;

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

              // ─── SPONSORLUK SEÇENEKLERİ KARTLARI ───
              _SponsorshipCard(
                title: "Hoppa Ana Sayfa Tepe Slider",
                description: "Dükkanınız 1 hafta boyunca ana sayfanın en üstünde parıldar. Peşin ücret yok! Sadece bu hafta gelen siparişlerden standart %5 yerine %15 komisyon tahsil edilir.",
                promoType: "MAIN_SCREEN",
                isActive: hasMainScreen,
                commissionRateLabel: "%15 Komisyon",
                gradient: const LinearGradient(
                  colors: [Color(0xFF512DA8), Color(0xFF311B92)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                icon: Icons.auto_awesome_rounded,
                onActivate: () => _confirmAndActivate(context, ref, "MAIN_SCREEN"),
              ),
              const SizedBox(height: 16),

              _SponsorshipCard(
                title: "Kategori İçi Öne Çıkarma",
                description: "Kendi kategorinizde (Örn: Kebap) rakiplerinizin en üstünde yer alın. Sadece bu hafta gelen siparişlerden %10 komisyon alınır.",
                promoType: "CATEGORY",
                isActive: hasCategory,
                commissionRateLabel: "%10 Komisyon",
                gradient: const LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFBF360C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                icon: Icons.category_rounded,
                onActivate: () => _confirmAndActivate(context, ref, "CATEGORY"),
              ),
              const SizedBox(height: 24),
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

  void _confirmAndActivate(BuildContext context, WidgetRef ref, String promoType) {
    final title = promoType == "MAIN_SCREEN"
        ? "Ana Sayfa Tepe Slider Sponsorluğu"
        : "Kategori İçi Öne Çıkarma";

    showCupertinoDialog(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text("$title Aktivasyonu"),
        content: const Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Text(
            "Emin misiniz? Bu işlem onaylandıktan sonra haftalık hakedişlerinizden otomatik mahsup edilecektir.",
            style: TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text("Vazgeç"),
            onPressed: () => Navigator.pop(ctx),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              Navigator.pop(ctx);
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
                    const SnackBar(
                      content: Text("Sponsorluk başarıyla aktif edildi!"),
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
            child: const Text("Evet, Aktif Et"),
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
  final String commissionRateLabel;
  final Gradient gradient;
  final IconData icon;
  final VoidCallback onActivate;

  const _SponsorshipCard({
    required this.title,
    required this.description,
    required this.promoType,
    required this.isActive,
    required this.commissionRateLabel,
    required this.gradient,
    required this.icon,
    required this.onActivate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
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
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                  )
                else
                  _SwipeToConfirmButton(
                    onConfirm: onActivate,
                    label: "Hemen Aktif Et",
                    gradient: gradient,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeToConfirmButton extends StatefulWidget {
  final VoidCallback onConfirm;
  final String label;
  final Gradient gradient;

  const _SwipeToConfirmButton({
    required this.onConfirm,
    required this.label,
    required this.gradient,
  });

  @override
  State<_SwipeToConfirmButton> createState() => _SwipeToConfirmButtonState();
}

class _SwipeToConfirmButtonState extends State<_SwipeToConfirmButton> {
  double _dragPosition = 0.0;
  bool _isConfirmed = false;
  final double _buttonHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDragWidth = constraints.maxWidth - _buttonHeight;

        return Container(
          width: double.infinity,
          height: _buttonHeight,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
          ),
          child: Stack(
            children: [
              // Sliding background highlight
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _dragPosition + _buttonHeight,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(10),
                      bottomLeft: const Radius.circular(10),
                      topRight: _dragPosition > maxDragWidth - 10
                          ? const Radius.circular(10)
                          : Radius.zero,
                      bottomRight: _dragPosition > maxDragWidth - 10
                          ? const Radius.circular(10)
                          : Radius.zero,
                    ),
                  ),
                ),
              ),

              // Button Label Text
              Center(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  opacity: _dragPosition > (maxDragWidth * 0.4) ? 0.3 : 1.0,
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: _dragPosition > (maxDragWidth * 0.4)
                          ? Colors.white
                          : Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

              // Draggable Slide Handle
              Positioned(
                left: _dragPosition,
                top: 2,
                bottom: 2,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_isConfirmed) return;
                    setState(() {
                      _dragPosition += details.delta.dx;
                      if (_dragPosition < 0.0) _dragPosition = 0.0;
                      if (_dragPosition > maxDragWidth) _dragPosition = maxDragWidth;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_isConfirmed) return;
                    if (_dragPosition >= maxDragWidth * 0.85) {
                      // Trigger Confirmation!
                      setState(() {
                        _dragPosition = maxDragWidth;
                        _isConfirmed = true;
                      });
                      widget.onConfirm();
                      // Reset button after confirmation trigger (so it's not locked if they cancel)
                      Future.delayed(const Duration(milliseconds: 800), () {
                        if (mounted) {
                          setState(() {
                            _dragPosition = 0.0;
                            _isConfirmed = false;
                          });
                        }
                      });
                    } else {
                      // Smooth snapback animation
                      setState(() {
                        _dragPosition = 0.0;
                      });
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 50),
                    width: _buttonHeight - 4,
                    height: _buttonHeight - 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.grey.shade700,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

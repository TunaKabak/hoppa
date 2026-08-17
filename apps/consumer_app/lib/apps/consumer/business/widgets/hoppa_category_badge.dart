import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Hoppa'ya Özel 32 Kategori Tasarım Sistemi ve Renk Profili
class CategoryDesignProfile {
  final String svgPath;
  final List<Color> backgroundGradient;
  final Color accentColor;
  final Color glowColor;

  const CategoryDesignProfile({
    required this.svgPath,
    required this.backgroundGradient,
    required this.accentColor,
    required this.glowColor,
  });
}

class HoppaCategoryDesignSystem {
  static CategoryDesignProfile getProfile(String name) {
    final lower = name.toLowerCase().trim();

    // 1. Tümü / All
    if (lower == 'tümü' || lower == 'all' || lower == 'grid_view' || lower.isEmpty) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_tumu.svg',
        backgroundGradient: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
        accentColor: Color(0xFFFF6B00),
        glowColor: Color(0xFFFF6B00),
      );
    }

    // 2. MARKET KATEGORİLERİ
    if (lower.contains('meyve') || lower.contains('sebze') || lower.contains('yeşillik') || lower.contains('manav')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_meyve_sebze.svg',
        backgroundGradient: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
        accentColor: Color(0xFF2E7D32),
        glowColor: Color(0xFF4CAF50),
      );
    }
    if (lower.contains('süt') || lower.contains('kahvaltı') || lower.contains('peynir') || lower.contains('yumurta') || lower.contains('yoğurt')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_sut_kahvalti.svg',
        backgroundGradient: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
        accentColor: Color(0xFFF57F17),
        glowColor: Color(0xFFFFCA28),
      );
    }
    if (lower.contains('fırın') || lower.contains('unlu') || lower.contains('ekmek') || lower.contains('simit') || lower.contains('poğaça')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_firin.svg',
        backgroundGradient: [Color(0xFFEFEBE9), Color(0xFFD7CCC8)],
        accentColor: Color(0xFF6D4C41),
        glowColor: Color(0xFF8D6E63),
      );
    }
    if (lower.contains('et') || lower.contains('tavuk') || lower.contains('şarküteri') || lower.contains('sucuk') || lower.contains('salam') || lower.contains('balık') || lower.contains('kasap')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_et_tavuk.svg',
        backgroundGradient: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
        accentColor: Color(0xFFC62828),
        glowColor: Color(0xFFEF5350),
      );
    }
    if (lower.contains('temel gıda') || lower.contains('bakliyat') || lower.contains('yağ') || lower.contains('makarna') || lower.contains('pirinç') || lower.contains('un')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_temel_gida.svg',
        backgroundGradient: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
        accentColor: Color(0xFFE65100),
        glowColor: Color(0xFFFB8C00),
      );
    }
    if (lower.contains('atıştırmalık') || lower.contains('tatlı') || lower.contains('çikolata') || lower.contains('bisküvi') || lower.contains('cips') || lower.contains('gofret')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_atistirmalik.svg',
        backgroundGradient: [Color(0xFFFCE4EC), Color(0xFFF8BBD0)],
        accentColor: Color(0xFFAD1457),
        glowColor: Color(0xFFEC407A),
      );
    }
    if (lower.contains('i̇çecekler') || lower.contains('meşrubat') || lower.contains('gazoz') || lower.contains('meyve suyu')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_icecekler.svg',
        backgroundGradient: [Color(0xFFE0F7FA), Color(0xFFB2EBF2)],
        accentColor: Color(0xFF00838F),
        glowColor: Color(0xFF26C6DA),
      );
    }
    if (lower.contains('donuk') || lower.contains('hazır gıda') || lower.contains('dondurulmuş') || lower.contains('dondurma')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_donuk_gida.svg',
        backgroundGradient: [Color(0xFFE1F5FE), Color(0xFFB3E5FC)],
        accentColor: Color(0xFF0277BD),
        glowColor: Color(0xFF29B6F6),
      );
    }
    if (lower.contains('deterjan') || lower.contains('temizlik') || lower.contains('hijyen') || lower.contains('çamaşır') || lower.contains('bulaşık')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_temizlik.svg',
        backgroundGradient: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
        accentColor: Color(0xFF512DA8),
        glowColor: Color(0xFF7E57C2),
      );
    }
    if (lower.contains('kişisel bakım') || lower.contains('kozmetik') || lower.contains('şampuan') || lower.contains('sabun') || lower.contains('cilt')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_kisisel_bakim.svg',
        backgroundGradient: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
        accentColor: Color(0xFF8E24AA),
        glowColor: Color(0xFFAB47BC),
      );
    }
    if (lower.contains('bebek') || lower.contains('çocuk') || lower.contains('mama')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_bebek.svg',
        backgroundGradient: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
        accentColor: Color(0xFF3949AB),
        glowColor: Color(0xFF5C6BC0),
      );
    }
    if (lower.contains('evcil') || lower.contains('kedi') || lower.contains('köpek') || lower.contains('pet')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_evcil_hayvan.svg',
        backgroundGradient: [Color(0xFFF1F8E9), Color(0xFFDCEDC8)],
        accentColor: Color(0xFF558B2F),
        glowColor: Color(0xFF7CB342),
      );
    }

    // 3. RESTORAN / YEMEK KATEGORİLERİ
    if (lower.contains('burger') || lower.contains('sandviç') || lower.contains('tost')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_burger.svg',
        backgroundGradient: [Color(0xFFFFF3E0), Color(0xFFFFCC80)],
        accentColor: Color(0xFFE65100),
        glowColor: Color(0xFFFFA726),
      );
    }
    if (lower.contains('pizza') || lower.contains('i̇talyan') || lower.contains('makarna') || lower.contains('calzone')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_pizza.svg',
        backgroundGradient: [Color(0xFFFFEBEE), Color(0xFFEF9A9A)],
        accentColor: Color(0xFFC62828),
        glowColor: Color(0xFFE53935),
      );
    }
    if (lower.contains('kebap') || lower.contains('döner') || lower.contains('ızgara') || lower.contains('şiş') || lower.contains('köfte')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_kebap_doner.svg',
        backgroundGradient: [Color(0xFFFBE9E7), Color(0xFFFFAB91)],
        accentColor: Color(0xFFD84315),
        glowColor: Color(0xFFFF7043),
      );
    }
    if (lower.contains('pide') || lower.contains('lahmacun')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_pide_lahmacun.svg',
        backgroundGradient: [Color(0xFFEFEBE9), Color(0xFFBCAAA4)],
        accentColor: Color(0xFF5D4037),
        glowColor: Color(0xFF8D6E63),
      );
    }
    if (lower.contains('ev yemek') || lower.contains('çorba') || lower.contains('sulu') || lower.contains('zeytinyağlı')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_ev_yemekleri.svg',
        backgroundGradient: [Color(0xFFFFF8E1), Color(0xFFFFE082)],
        accentColor: Color(0xFFF57C00),
        glowColor: Color(0xFFFFB74D),
      );
    }
    if (lower.contains('salata') || lower.contains('sağlıklı') || lower.contains('diyet') || lower.contains('fit') || lower.contains('bowl')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_salata.svg',
        backgroundGradient: [Color(0xFFE8F5E9), Color(0xFFA5D6A7)],
        accentColor: Color(0xFF2E7D32),
        glowColor: Color(0xFF66BB6A),
      );
    }
    if (lower.contains('dünya mutfağı') || lower.contains('sokak') || lower.contains('taco') || lower.contains('noodle') || lower.contains('asya') || lower.contains('çiğ köfte')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_dunya_mutfagi.svg',
        backgroundGradient: [Color(0xFFEDE7F6), Color(0xFFB39DDB)],
        accentColor: Color(0xFF512DA8),
        glowColor: Color(0xFF7E57C2),
      );
    }
    if (lower.contains('waffle') || lower.contains('pasta') || lower.contains('künefe') || lower.contains('baklava') || lower.contains('cheesecake') || lower.contains('sufle')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_tatlilar.svg',
        backgroundGradient: [Color(0xFFFCE4EC), Color(0xFFF48FB1)],
        accentColor: Color(0xFFC2185B),
        glowColor: Color(0xFFEC407A),
      );
    }
    if (lower.contains('kafe') || lower.contains('kahve') || lower.contains('coffee') || lower.contains('çay') || lower.contains('milkshake') || lower.contains('smoothie')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_kafe_kahve.svg',
        backgroundGradient: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
        accentColor: Color(0xFF00695C),
        glowColor: Color(0xFF26A69A),
      );
    }

    // 4. SU & İÇECEK KATEGORİLERİ
    if (lower.contains('damacana') || lower.contains('19l') || lower.contains('cam damacana')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_damacana_su.svg',
        backgroundGradient: [Color(0xFFE1F5FE), Color(0xFF81D4FA)],
        accentColor: Color(0xFF0277BD),
        glowColor: Color(0xFF29B6F6),
      );
    }
    if (lower.contains('pet şişe') || lower.contains('koli su') || lower.contains('paket su') || lower.contains('0.5l') || lower.contains('1.5l') || lower.contains('5l')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_pet_sise.svg',
        backgroundGradient: [Color(0xFFE0F7FA), Color(0xFF80CBC4)],
        accentColor: Color(0xFF00897B),
        glowColor: Color(0xFF26A69A),
      );
    }
    if (lower.contains('maden suyu') || lower.contains('soda') || lower.contains('tonik')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_maden_suyu.svg',
        backgroundGradient: [Color(0xFFE8F5E9), Color(0xFF81C784)],
        accentColor: Color(0xFF2E7D32),
        glowColor: Color(0xFF4CAF50),
      );
    }
    if (lower.contains('koli') || lower.contains('toptan')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_toptan_icecek.svg',
        backgroundGradient: [Color(0xFFFFF3E0), Color(0xFFFFB74D)],
        accentColor: Color(0xFFE65100),
        glowColor: Color(0xFFFFA726),
      );
    }
    if (lower.contains('pompa') || lower.contains('ekipman') || lower.contains('sebil') || lower.contains('aparat')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_su_pompasi.svg',
        backgroundGradient: [Color(0xFFEDE7F6), Color(0xFF9FA8DA)],
        accentColor: Color(0xFF283593),
        glowColor: Color(0xFF3F51B5),
      );
    }

    // 5. ÇİÇEK & HEDİYE KATEGORİLERİ
    if (lower.contains('buket') || lower.contains('gül') || lower.contains('papatya') || lower.contains('şakayık') || lower.contains('lilyum')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_tasarim_buket.svg',
        backgroundGradient: [Color(0xFFFCE4EC), Color(0xFFF06292)],
        accentColor: Color(0xFFAD1457),
        glowColor: Color(0xFFE91E63),
      );
    }
    if (lower.contains('saksı') || lower.contains('bitki') || lower.contains('orkide') || lower.contains('sukulent') || lower.contains('kaktüs') || lower.contains('bonsai')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_saksi_bitkileri.svg',
        backgroundGradient: [Color(0xFFE8F5E9), Color(0xFF66BB6A)],
        accentColor: Color(0xFF1B5E20),
        glowColor: Color(0xFF43A047),
      );
    }
    if (lower.contains('kutu') || lower.contains('vazo') || lower.contains('aranjman')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_kutuda_cicek.svg',
        backgroundGradient: [Color(0xFFFFF8E1), Color(0xFFFFD54F)],
        accentColor: Color(0xFFF57F17),
        glowColor: Color(0xFFFFB300),
      );
    }
    if (lower.contains('hediye') || lower.contains('özel gün') || lower.contains('peluş') || lower.contains('çikolatalı')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_hediye_setleri.svg',
        backgroundGradient: [Color(0xFFF3E5F5), Color(0xFFBA68C8)],
        accentColor: Color(0xFF6A1B9A),
        glowColor: Color(0xFFAB47BC),
      );
    }
    if (lower.contains('kurutulmuş') || lower.contains('solmayan') || lower.contains('teraryum')) {
      return const CategoryDesignProfile(
        svgPath: 'assets/categories/cat_solmayan_cicek.svg',
        backgroundGradient: [Color(0xFFEFEBE9), Color(0xFFA1887F)],
        accentColor: Color(0xFF4E342E),
        glowColor: Color(0xFF8D6E63),
      );
    }

    // Varsayılan
    return const CategoryDesignProfile(
      svgPath: 'assets/categories/cat_tumu.svg',
      backgroundGradient: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
      accentColor: Color(0xFFFF6B00),
      glowColor: Color(0xFFFF6B00),
    );
  }
}

/// Hoppa'nın Görsel Kategori Kartı (Sticky Header İçin)
class HoppaCategoryCard extends StatelessWidget {
  final String name;
  final bool isSelected;
  final bool isPinned;
  final VoidCallback onTap;
  final double width;

  const HoppaCategoryCard({
    super.key,
    required this.name,
    required this.isSelected,
    required this.isPinned,
    required this.onTap,
    this.width = 76,
  });

  @override
  Widget build(BuildContext context) {
    final profile = HoppaCategoryDesignSystem.getProfile(name);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // SVG Icon Container with dynamic thematic gradient & glow
            AnimatedScale(
              scale: isSelected ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [
                            Color(0xFFFF6B00),
                            Color(0xFFFF8A00),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: profile.backgroundGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white
                        : (isPinned
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.grey.shade300),
                    width: isSelected ? 2.5 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF6B00).withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SvgPicture.asset(
                    profile.svgPath,
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),
            // Category Title
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isPinned
                    ? Colors.white
                    : (isSelected ? const Color(0xFFFF6B00) : const Color(0xFF2B3445)),
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 2),
            // Active Indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 20 : 0,
              height: 2.5,
              decoration: BoxDecoration(
                color: isPinned ? Colors.white : const Color(0xFFFF6B00),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hoppa Mini Kategori Pill (Collapsed AppBar İçin)
class HoppaCategoryMiniPill extends StatelessWidget {
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const HoppaCategoryMiniPill({
    super.key,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final profile = HoppaCategoryDesignSystem.getProfile(name);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SvgPicture.asset(
                  profile.svgPath,
                  width: 16,
                  height: 16,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                name,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? const Color(0xFFFF6B00) : Colors.white,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

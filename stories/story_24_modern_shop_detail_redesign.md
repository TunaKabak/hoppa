Story 24 - Modern Dükkan Detay Sayfası Redesign, Akıllı Birim Gösterimi ve Kademeli Kategori Gezintisi

Bu görev belgesi; dükkan detay ekranını (shop_detail_page.dart) modern bir üst bilgi barı (Header), sol/sağ bölünmüş kategori navigasyonu (Split-Pane Navigation), akıllı fiyat-birim maskelemesi ve kusursuz çalışan dinamik filtrelerle baştan aşağı yenilemeyi amaçlar.

🎯 1. KULLANICI HİKAYESİ (USER STORY)

"Bir platform tüketicisi olarak;

Dükkan detay sayfasına girdiğimde, işletmenin açılış/kapanış saatlerini, tahmini teslimat süresini ve kurye ücretini tek bir bakışta görebilmek,

Paketli/adetli ürünlerde (Örn: Kepek Ekmeği) kafa karıştırıcı / KG veya / PAKET ibareleri yerine sadece net ve temiz fiyatı (Örn: 92.50 TL) görmek, tartılı manav ürünlerinde ise birimi net şekilde ayırt etmek,

Sol tarafta dikey olarak listelenen ana kategorilere tıkladığımda, sağ taraftaki ürün listesinin o kategoriye ait alt başlıklarla (Örn: Ekmek -> Tost Ekmeği) otomatik süzülmesini ve akıcı şekilde çalışmasını istiyorum."

🎨 2. GÖRSEL ANALİZ VE PLANLANAN İYİLEŞTİRMELER (UX CRITIQUE)

Screenshot_20260701_105308_Hoppa.jpg referans alınarak tespit edilen ve bu hikaye ile düzeltilecek 4 temel kusur:

Mevcut Kusur

Tech Lead Çözüm Yaklaşımı

Hedeflenen Arayüz Standartı

Gereksiz/Hatalı Birim Gösterimi: Paketli bisküvi, gofret ve ekmeklerin altında büyük puntolarla 92.50 TL / KG yazıyor.

Akıllı Birim Filtreleme: Eğer ürün birimi ADET, PAKET, PIECE veya ADET/PIECE ise, / Birim yazısı tamamen gizlenecek; sadece 92.50 TL yazacak. Sadece dökme/tartılı (KG, GR, LITRE) ürünlerde / KG yazısı gösterilecek.

Temiz, kafa karıştırmayan e-ticaret fiyat kartları.

Header Veri Eksikliği: Üst bar çok büyük yer kaplamasına rağmen sadece puan gösteriyor. Çalışma saatleri ve teslimat bilgisi eksik.

Dynamic Header Card: SliverAppBar üzerine binen şık bir yarı-şeffaf kart içinde 08:00 - 22:00 • 25-35 dk • Ücretsiz Teslimat etiketleri konumlandırılacak.

Bilgi açısından zengin, modern collapsing header.

Hantal Kategori Çipleri: Yuvarlak, yazıları sığmayan ve yatayda kayan dağınık kategori çemberleri.

Split-Pane (Sol-Sağ) Düzeni: Getir/Yemeksepeti standardında; ekranın solunda %25 genişliğinde dikey ana kategoriler menüsü, sağında ise kategorilere göre gruplanmış ürün grid'i yer alacak.

Ultra hızlı ve parmak dostu gezinme (Navigation).

Kırık Filtreler: Çipler çalışmıyor ve sayfa kaydırıldığında sabit kalmıyor.

Sticky Left Pane / Nested Scroll: Kategori menüsü sayfa kaydırılsa dahi sol tarafta sabit (sticky) kalacak, sağ taraftaki liste kaydırıldıkça aktif kategori sol menüde otomatik seçilecek (Scroll-to-Active).

Kesintisiz ve akıcı dükkan içi gezinme deneyimi.

🛠️ 3. MOBİL UYGULAMA KATMANI (FLUTTER REFACTOR)

A. Fiyat ve Birim Gösterim Kartı Güncellemesi (modern_product_card.dart)

Ürün fiyat etiketini adet bazlı ve kilo/litre bazlı ürün ayrımına göre akıllıca biçimlendiren Widget katmanı:

// apps/consumer_app/lib/shared/widgets/modern_product_card.dart

class ModernProductPriceWidget extends StatelessWidget {
  final double price;
  final String unit;
  final double? regularPrice;

  const ModernProductPriceWidget({
    Key? key,
    required this.price,
    required this.unit,
    this.regularPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String cleanUnit = unit.toUpperCase().trim();
    
    // 🚨 AKILLI BİRİM KONTROLÜ (Adet/Paket ise birim ibaresini gizle)
    final bool isDiscrete = cleanUnit == "ADET" || 
                            cleanUnit == "PAKET" || 
                            cleanUnit == "PIECE" || 
                            cleanUnit == "ADET/PIECE";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (regularPrice != null && regularPrice! > price)
          Text(
            "${regularPrice!.toStringAsFixed(2)} TL",
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              "${price.toStringAsFixed(2)} TL",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            if (!isDiscrete) ...[
              const SizedBox(width: 4),
              Text(
                "/ $cleanUnit",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}


B. Sol Dikey Kategori Menülü Dükkan Detay Sayfası (shop_detail_page.dart)

Sol tarafta sabit dikey kategorilerin, sağ tarafta ise o kategorilere ait ürünlerin akıcı bir şekilde listelendiği modern pazar yeri bölünmüş ekran tasarımı (Split-Pane layout):

// apps/consumer_app/lib/screens/shop/shop_detail_page.dart

import 'package:flutter/material.dart';

class ModernShopDetailPage extends StatefulWidget {
  final Shop shop;
  const ModernShopDetailPage({Key? key, required this.shop}) : super(key: key);

  @override
  State<ModernShopDetailPage> createState() => _ModernShopDetailPageState();
}

class _ModernShopDetailPageState extends State<ModernShopDetailPage> {
  int _selectedCategoryIndex = 0;
  final ScrollController _productsScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220.0,
              pinned: true,
              backgroundColor: theme.colorScheme.primary,
              flexibleSpace: FlexibleSpaceBar(
                title: innerBoxIsScrolled 
                    ? Text(widget.shop.name, style: const TextStyle(color: Colors.white, fontSize: 16))
                    : null,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      widget.shop.coverUrl ?? "https://images.unsplash.com/photo-1542838132-92c53300491e",
                      fit: BoxFit.cover,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black35, Colors.transparent, Colors.black60],
                        ),
                      ),
                    ),
                    
                    // 🚨 MODERN BİLGİ DOLU HEADER (Açılış Saatleri & Kurye & Süre)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white,
                                backgroundImage: NetworkImage(widget.shop.logoUrl ?? ""),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.shop.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${widget.shop.averageRating} (142 Değerlendirme)",
                                          style: const TextStyle(color: Colors.white, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 8),
                          // Çalışma saatleri, süre ve kurye ücreti satırı
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildHeaderBadge(Icons.access_time, "08:00 - 22:00", Colors.orange),
                              _buildHeaderBadge(Icons.delivery_dining, "25-35 dk", Colors.green),
                              _buildHeaderBadge(Icons.payments_outlined, "Ücretsiz Teslimat", Colors.blue),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        // 🚨 EKSTREM UX DEĞİŞİKLİĞİ: SOL-SAĞ BÖLÜNMÜŞ GEZİNTİ (Split-Pane Navigation)
        body: Row(
          children: [
            // Sol Taraf: %25 genişliğinde dikey Kategori Listesi
            Container(
              width: 100,
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              child: ListView.builder(
                itemCount: widget.shop.categories.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final cat = widget.shop.categories[index];
                  final isSelected = _selectedCategoryIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = index;
                      });
                      // Sağdaki listeyi bu kategoriye ait ürünlere kaydır
                      _scrollToCategory(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.surface : Colors.transparent,
                        border: Border(
                          left: BorderSide(
                            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (cat.imageUrl != null)
                            Image.network(cat.imageUrl!, width: 32, height: 32, errorBuilder: (_, __, ___) => const Icon(Icons.category)),
                          const SizedBox(height: 4),
                          Text(
                            cat.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Sağ Taraf: %75 genişliğinde Ürün Grid/Listesi
            Expanded(
              child: ListView.builder(
                controller: _productsScrollController,
                itemCount: widget.shop.categories[_selectedCategoryIndex].products.length,
                padding: const EdgeInsets.all(12),
                itemBuilder: (context, index) {
                  final product = widget.shop.categories[_selectedCategoryIndex].products[index];
                  return ModernHorizontalProductCard(product: product); // Yatay kart yapısı bu düzende çok daha temiz durur
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _scrollToCategory(int index) {
    // Sağ panele ait kaydırma/filtreleme mantığı tetiklenecek
  }
}


📢 4. DOĞRULAMA PLANI

TypeScript & Backend Derleme:

cd backend && npm run build


Flutter Statik Analizleri:

cd apps/consumer_app && flutter analyze


Manuel Arayüz Doğrulaması:

Test Süpermarket detayına girin. Üst header alanında çalışma saatlerinin ve kurye ücreti etiketlerinin şık biçimde yer aldığını doğrulayın.

Ekmek kartlarındaki / PAKET veya / KG etiketlerinin kaybolduğunu, sadece 92.50 TL ve 55.95 TL temiz fiyatlarının kaldığını doğrulayın.

Sol taraftaki dikey kategori menüsünde gezinirken sağ paneldeki ürünlerin sarsıntısız şekilde süzüldüğünü doğrulayın.
Story 24 - Modern Dükkan Detay Sayfası Redesign, Akıllı Birim Gösterimi ve Yatay Kategori Gezintisi

Bu görev belgesi; dükkan detay ekranını (shop_detail_page.dart) ve ürün kartlarını (modern_product_card.dart), ekranın daralmasını engelleyen yatay çift aşamalı kategori filtreleri, optimize edilmiş collapsing header (Logo korumalı), ve gereksiz / KG birim kalabalığından arındırılmış fiyat kartlarıyla baştan tasarlamayı amaçlar.

🎯 1. KULLANICI HİKAYESİ (USER STORY)

"Bir platform tüketicisi olarak;

Dükkan detay sayfasına girdiğimde, ekranı dikeyde daraltan hantal sol menüler yerine, en üstte yatayda kaydırılabilen şık ve rounded kategori resimlerini görmek,

Seçtiğim ana kategoriye ait alt kategoriler (Örn: Ekmek -> Tost Ekmeği) varsa, hemen altında küçük çipler halinde görebilmek ve filtrelemelerin anında çalışmasını,

Sayfayı aşağı kaydırdığımda, küçülen üst barda dükkanın adıyla birlikte yuvarlak logosunun da şık bir şekilde görünmeye devam etmesini,

Ürün kartlarında zaten 'KG Fiyatı' veya 'Paket Fiyatı' ibareleri yer aldığı için, ana fiyatın yanında gereksiz / KG veya / PAKET kalabalığı görmemeyi istiyorum."

🎨 2. GÖRSEL ANALİZ VE YENİ TASARIM STANDARTLARI (UX REFACTOR)

Screenshot_20260701_105308_Hoppa.jpg ve kullanıcı geri bildirimleri doğrultusunda uygulayacağımız 7 altın standart:

#

Tasarım Problemi

Tech Lead Çözüm Yaklaşımı

Hedeflenen Arayüz Standartı

1

Sol dikey menü daralması: Ekranı boğuyor ve kartları eziyor.

Yatay Üst Kategori Şeridi: Kategori seçici üst tarafa yatay kaydırılabilir (scrollable) olarak taşınacak.

Geniş ve nefes alan ürün grid yerleşimi.

2

Kategorilerde görsel kalitesizliği: Düz renk çemberleri hantal duruyor.

Rounded Category Cards: Kategoriler kendi görseliyle birlikte BorderRadius.circular(12) şeklinde rounded çerçeveyle çizilecek.

Görsel zenginliği yüksek modern kategori çipleri.

3

Kategori ikonsuzluğu: Bazı kategoriler boş kalıyor.

Icon Fallback Rule: Her kategorinin mutlaka şık bir görseli olacak; resim yoksa akıllı bir SVG/ikon fallback gösterilecek.

Boşluksuz ve tutarlı kategori listesi.

4

Devasa Header Alanı: Üst görsel alanı gereksiz yer kaplıyor.

Header Height Reduction: SliverAppBar expandedHeight değeri 220'den 145.0 seviyesine indirilerek içerik alanı genişletilecek.

Optimize edilmiş, modern collapsing header.

5

Collapsing Logo Kaybolması: Sayfa kayınca logo kayboluyor, marka algısı düşüyor.

Mini Logo Persistence: Sayfa yukarı kayıp header küçüldüğünde (innerBoxIsScrolled), dükkan isminin hemen solunda 28dp'lik mini dairesel dükkan logosu belirecek.

Kesintisiz marka kimliği.

6

Gereksiz Birim Kalabalığı: Kartlarda hem "KG Fiyatı" yazıp hem de fiyatta / KG yazması alan israfı.

Price Clean-up: Kart üzerinde zaten birim türü belirtildiği için ana fiyat alanından / KG, / PAKET ibareleri silinecek; sadece net 92.50 TL yazacak.

Sade ve temiz fiyat etiketleri.

7

Alt Kategori Filtre Hatası: Alt kategoriler çalışmıyor ve süzmüyor.

Two-Tier Cascading Filter: Seçili ana kategorinin altında alt kategoriler yatay çipler halinde listelenecek (Örn: Tümü, Tost Ekmeği, Somun) ve filtreleme anında çalışacak.

Kusursuz dükkan içi kategorizasyon.

🛠️ 3. MOBİL UYGULAMA KATMANI (FLUTTER REFACTOR)

A. Ürün Fiyat Kartı Güncellemesi (modern_product_card.dart)

Gereksiz / Birim ibaresini kaldıran, temiz fiyat etiket widget'ı:

// apps/consumer_app/lib/shared/widgets/modern_product_card.dart

class ModernProductPriceWidget extends StatelessWidget {
  final double price;
  final double? regularPrice;

  const ModernProductPriceWidget({
    Key? key,
    required this.price,
    this.regularPrice,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        Text(
          "${price.toStringAsFixed(2)} TL",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}


B. Yeni Yatay Çift Katman Filtreli Dükkan Detay Sayfası (shop_detail_page.dart)

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
  int _selectedSubCategoryIndex = 0; // 🚨 Alt kategori filtre indexi
  final ScrollController _productsScrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeCategory = widget.shop.categories[_selectedCategoryIndex];
    
    // Alt kategorileri çek (Varsayılan olarak ilk çip "Tümü" olacak şekilde ekleme yapıyoruz)
    final List<Category> subCategories = [
      Category(id: "all", name: "Tümü", children: []),
      ...activeCategory.children,
    ];

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 145.0, // 🚨 GÖRSEL POLISH: Header yüksekliği daraltıldı
              pinned: true,
              backgroundColor: theme.colorScheme.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 48, bottom: 14), // Başlık hizalaması
                title: innerBoxIsScrolled 
                    ? Row(
                        children: [
                          // 🚨 LOGO KORUMASI: Daralan barda mini logo belirişi
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white,
                            backgroundImage: NetworkImage(widget.shop.logoUrl ?? ""),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.shop.name, 
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                        ],
                      )
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
                    
                    // Expanded Mode: Büyük Logo ve Bilgiler
                    Positioned(
                      bottom: 12,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.white,
                                backgroundImage: NetworkImage(widget.shop.logoUrl ?? ""),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.shop.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          "${widget.shop.averageRating} (142 Değerlendirme) • 08:00 - 22:00",
                                          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ],
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
          ];
        },
        body: Column(
          children: [
            // 🚨 1. KADEME: YATAY ANA KATEGORİ LİSTESİ (Rounded & İkonlu)
            Container(
              height: 96,
              color: theme.colorScheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.shop.categories.length,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, index) {
                  final cat = widget.shop.categories[index];
                  final isSelected = _selectedCategoryIndex == index;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = index;
                        _selectedSubCategoryIndex = 0; // Kategori değişince alt kategoriyi sıfırla
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 76,
                      decoration: BoxDecoration(
                        color: isSelected ? theme.colorScheme.primaryContainer.withOpacity(0.3) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12), // slightly rounded corners
                        border: Border.all(
                          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              cat.imageUrl ?? "https://placehold.co/40", // Akıllı fallback görseli
                              width: 38,
                              height: 38,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.category, color: theme.colorScheme.primary, size: 24),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              cat.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // 🚨 2. KADEME: YATAY ALT KATEGORİ ÇİPLERİ (Dinamik Cascading Filter)
            if (subCategories.length > 1)
              Container(
                height: 44,
                color: theme.colorScheme.surfaceVariant.withOpacity(0.15),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: subCategories.length,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, index) {
                    final subCat = subCategories[index];
                    final isSelected = _selectedSubCategoryIndex == index;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Text(subCat.name, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        selectedColor: theme.colorScheme.primaryContainer,
                        backgroundColor: theme.colorScheme.surface,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedSubCategoryIndex = index;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

            // Ürün Grid Listesi (%100 yatay alan özgürlüğüyle geniş ve nefes alan yapı)
            Expanded(
              child: GridView.builder(
                controller: _productsScrollController,
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: _getFilteredProducts(activeCategory, subCategories[_selectedSubCategoryIndex]).length,
                itemBuilder: (context, index) {
                  final product = _getFilteredProducts(activeCategory, subCategories[_selectedSubCategoryIndex])[index];
                  return ModernProductCard(product: product); // 2 sütunlu pürüzsüz kartlar
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Hem kategori hem alt kategoriye göre filtreleme yapan kusursuz iş mantığı
  List<Product> _getFilteredProducts(Category activeCategory, Category selectedSubCategory) {
    if (selectedSubCategory.id == "all") {
      // Eğer "Tümü" seçiliyse ana kategoriye ait tüm ürünleri getir
      return activeCategory.products;
    }
    // Alt kategori seçilmişse, sadece o alt kategoriyle eşleşen ürünleri süz
    return activeCategory.products.where((p) => p.subCategoryId == selectedSubCategory.id).toList();
  }
}


📢 4. DOĞRULAMA PLANI

Flutter Derleme ve Statik Analizleri:

cd apps/consumer_app && flutter analyze


Manuel Arayüz Doğrulaması:

Test Süpermarket detayına girin. Üst SleaveAppBar yüksekliğinin 145.0 seviyesinde son derece şık durduğunu doğrulayın.

Sayfa aşağı kaydırıldığında, daralan barda dükkan adının solunda mini dükkan logosunun kesintisiz olarak göründüğünü doğrulayın (Mini Logo Persistence).

Sol dikey menünün kalkıp yerine yatayda şık, rounded ve ikonlu ana kategorilerin geldiğini ve ekranın yatayda daralmasının önlendiğini görün.

Seçili ana kategorinin hemen altına açılan "Tümü" ve alt kategori ChoiceChip'lerine tıklandığında ürün grid listesinin sarsıntısız süzüldüğünü (Filter Sync) doğrulayın.

Ürün fiyat etiketlerinden redundant / KG veya / PAKET gürültüsünün silinip sadeleştiğini gözlemleyin.
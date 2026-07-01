Story 25 - Mağaza Detay Revizyonu, Kategori Filtre Senkronizasyonu ve Sepet Matematik Onarımı

Bu görev belgesi; dükkan detay ekranında (shop_detail_page.dart) tespit edilen görsel ve işlevsel hataları gidermeyi, dükkana özel dinamik kategori çıkarımını kurmayı, ürün kartlarından (modern_product_card.dart) birim etiket gürültülerini temizlemeyi ve paketli ürünlerin (özellikle ekmeklerin) sepet adımlarında küsuratlı artış bug'ını (KG/Litre yerine ADET zorunluluğu) tamamen çözmeyi amaçlar.

🛠️ 1. VERİTABANI TOHUMLAMA (SEED) REFACTOR

Paketli Ekmek ve Ürünlerin Birim Atama Bug'ının Çözülmesi

Sorun: "Ekmek Dünyası Favori Bazlama 250 G" gibi paketli unlu mamuller tohumlama (seed) aşamasında hatalı şekilde KG birimi, 0.25 artış adımı (stepSize) ve 0.5 minimum miktar (minQuantity) ile kaydediliyordu. Bu durum sepete eklenirken ondalıklı (0.50, 0.75 kg) ekmek eklenmesi gibi kritik bir mantıksal hataya yol açıyordu.

Çözüm: seed_catalog.ts dosyasında paketli unlu mamuller, atıştırmalıklar ve içecekler kesin olarak ADET birimine (stepSize: 1.0, minQuantity: 1.0) bağlanacak; yalnızca dökme manav ürünleri (patates, domates vb.) KG ve ondalıklı adımlarla tohumlanacaktır.

// backend/prisma/seed_catalog.ts

import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  console.log("🧹 Katalog temizliği başlatılıyor...");
  await prisma.globalProduct.deleteMany({});
  await prisma.product.deleteMany({});
  await prisma.category.deleteMany({});
  await prisma.brand.deleteMany({});
  await prisma.unit.deleteMany({});

  console.log("📐 Birimler oluşturuluyor...");
  const unitAdet = await prisma.unit.create({ data: { code: "ADET", nameTr: "Adet", nameEn: "Pieces" } });
  const unitKg = await prisma.unit.create({ data: { code: "KG", nameTr: "Kg", nameEn: "Kg" } });
  const unitLitre = await prisma.unit.create({ data: { code: "LITRE", nameTr: "Litre", nameEn: "Liters" } });

  console.log("📦 Markalar oluşturuluyor...");
  const brandUlker = await prisma.brand.create({ data: { name: "Ülker" } });
  const brandSoke = await prisma.brand.create({ data: { name: "Söke" } });
  const brandEkmekDunyasi = await prisma.brand.create({ data: { name: "Ekmek Dünyası" } });
  const brandYerli = await prisma.brand.create({ data: { name: "Yerli Üretim" } });

  console.log("🥦 Kategoriler oluşturuluyor...");
  const catEkmek = await prisma.category.create({ data: { id: "101", name: "Ekmek & Unlu Mamul", shopType: "MARKET" } });
  const catAtistirmalik = await prisma.category.create({ data: { id: "102", name: "Atıştırmalık", shopType: "MARKET" } });
  const catManav = await prisma.category.create({ data: { id: "103", name: "Meyve & Sebze", shopType: "GREENGROCER" } });

  console.log("🔥 Ürünler hassas birim kurallarıyla tohumlanıyor...");
  const productsToSeed = [
    // 🚨 KESİN DÜZELTME: Paketli ekmekler kesinlikle ADET birimiyle 1.0 adımla eklenir!
    {
      barcode: "8690504037544",
      name: "Ekmek Dünyası Favori Bazlama 250 G",
      imageUrl: "[https://images.migrosone.com/sanalmarket/product/05057923/05057923-420ecb.jpeg](https://images.migrosone.com/sanalmarket/product/05057923/05057923-420ecb.jpeg)",
      unitId: unitAdet.id,
      brandId: brandEkmekDunyasi.id,
      categoryId: catEkmek.id,
      minQuantity: 1.0, // Adet bazlı, tam sayı
      stepSize: 1.0,    // 1'er 1'er artar
    },
    {
      barcode: "8690504037500",
      name: "Söke Kurabiye Macadamia Fındıklı 40 G",
      imageUrl: "[https://images.migrosone.com/sanalmarket/product/07012544/07012544_1-870c3f.jpg](https://images.migrosone.com/sanalmarket/product/07012544/07012544_1-870c3f.jpg)",
      unitId: unitAdet.id,
      brandId: brandSoke.id,
      categoryId: catAtistirmalik.id,
      minQuantity: 1.0,
      stepSize: 1.0,
    },
    // 🥦 Manav ürünleri tartılı (ondalıklı) miktar kurallarıyla eklenir
    {
      barcode: null,
      name: "Taze Sarı Patates",
      imageUrl: "[https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=500&q=80](https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=500&q=80)",
      unitId: unitKg.id,
      brandId: brandYerli.id,
      categoryId: catManav.id,
      minQuantity: 0.5,  // En az yarım kilo
      stepSize: 0.25,    // 250 gramlık adımlarla artar/azalır
    }
  ];

  for (const prod of productsToSeed) {
    await prisma.globalProduct.create({ data: prod });
  }

  console.log("✅ Tohumlama başarıyla tamamlandı. Paketli ürün birimleri sıkılaştırıldı.");
}

main().catch((e) => { console.error(e); process.exit(1); });


🔌 2. BACKEND API GÜNCELLEMESİ (FAVORİLER ONARIMI)

FavoritesController.ts Sorgusuna 3NF İlişki Bağlarının Eklenmesi

Sorun: Favoriler ekranının boş dönmesinin sebebi, Prisma SELECT sorgusunda ilişkisel tabloların (unit, brand, category, globalProduct) doğru JOIN edilmemesi veya Product modelindeki imageUrl fallback mantığının çözülmeden Dart tarafına aktarılmasıdır.

// backend/src/controllers/FavoritesController.ts

import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

export class FavoritesController {
  public static async getFavoriteProducts(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;

      const favoriteRecords = await prisma.favoriteProduct.findMany({
        where: { userId },
        include: {
          product: {
            include: {
              unit: true,
              brand: true,
              category: {
                include: { parent: true }
              },
              globalProduct: true // Görsel fallback için master ürün JOIN edilir
            }
          }
        }
      });

      const products = favoriteRecords.map(fav => {
        const prod = fav.product;
        return {
          id: prod.id,
          name: prod.name,
          price: prod.price,
          regularPrice: prod.regularPrice,
          discountRate: prod.discountRate,
          // Görsel Fallback Zinciri
          imageUrl: prod.imageUrl || prod.globalProduct?.imageUrl || "/images/default-product.png",
          unit: prod.unit, // İlişkisel Unit tablosundan gelen veri
          minQuantity: prod.minQuantity,
          stepSize: prod.stepSize,
          shopId: prod.shopId,
          categoryId: prod.categoryId
        };
      });

      res.status(200).json({ error: false, data: products });
    } catch (error) {
      console.error("Favoriler getirilemedi:", error);
      res.status(500).json({ error: true, message: "İşlem sırasında bir sunucu hatası oluştu." });
    }
  }
}


📱 3. TÜKETİCİ UYGULAMASI (CONSUMER APP REFACTOR)

A. Fiyat Etiketlerindeki / Birim Gösterimlerinin Kaldırılması (modern_product_card.dart)

Sorun: Kartlarda hem "KG Fiyatı" yazıp hem de fiyatta / KG yazması alan israfına ve görsel kirliliğe yol açıyordu.

Çözüm: Birim gösterim etiketleri ürün kartı fiyat alanlarından tamamen arındırılacaktır.

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
        // 🚨 KESİN DÜZELTME: /KG veya /Litre ibareleri kaldırıldı, sadece temiz fiyat gösteriliyor
        Text(
          "${price.toStringAsFixed(2)} TL",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}


B. SliverAppBar Kaydırma (Scroll) ve Logo Korumalı Header Onarımı (shop_detail_page.dart)

Sorun: Sayfa aşağı kaydırıldıktan sonra tekrar yukarı kaydırınca SliverAppBar'ın (Header) geri gelmemesi ve daralan barda dükkan logosunun kaybolması sorunu.

Çözüm: SliverAppBar yapılandırması pinned: true, floating: true, snap: true olarak güncellenerek kaydırma anındaki tutarsızlık giderilmiştir.

C. İşletmenin Ürünlerinden Dinamik Kategori Çıkarımı ve İkonlu Yatay Çipler

Sorun: Filtre kategorilerinin işletmenin kendi ürünleriyle senkronize olmaması, alt kategorilerin listelenmemesi ve görsel/ikonlarının bulunmaması sorunu.

Çözüm: Dükkan ürünlerinin kategori listesinden (shop.products) benzersiz kategoriler dinamik olarak çıkarılacak, kategorilerin kendi stüdyo görselleri (imageUrl) şık yuvarlak kartlar içinde gösterilecektir.

// apps/consumer_app/lib/screens/shop/shop_detail_page.dart

import 'package:flutter/material.dart';

class ShopDetailPage extends StatefulWidget {
  final Shop shop; // Dükkan ve dükkan içi ürün listesini (products) barındıran model

  const ShopDetailPage({Key? key, required this.shop}) : super(key: key);

  @override
  State<ShopDetailPage> createState() => _ShopDetailPageState();
}

class _ShopDetailPageState extends State<ShopDetailPage> {
  Category? _selectedCategory;
  SubCategory? _selectedSubCategory;
  List<Category> _activeCategories = [];

  @override
  void initState() {
    super.initState();
    _extractActiveCategoriesFromProducts();
  }

  // 🚨 KESİN DÜZELTME: Kategori filtreleri tamamen dükkanın kendi ürünlerinden dinamik olarak türetilir!
  void _extractActiveCategoriesFromProducts() {
    final Map<String, Category> uniqueCategories = {};
    for (var product in widget.shop.products) {
      if (product.category != null) {
        uniqueCategories[product.category!.id] = product.category!;
      }
    }
    setState(() {
      _activeCategories = uniqueCategories.values.toList();
      if (_activeCategories.isNotEmpty) {
        _selectedCategory = _activeCategories.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            // 🚨 KESİN DÜZELTME: Scroll yukarı kaydırıldığında anında belirmesi için floating & snap eklendi
            SliverAppBar(
              expandedHeight: 180.0,
              floating: true,
              pinned: true,
              snap: true,
              backgroundColor: theme.colorScheme.primary,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: innerBoxIsScrolled
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(widget.shop.logoUrl ?? ""),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.shop.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(widget.shop.coverUrl ?? "", fit: BoxFit.cover),
                    Container(color: Colors.black.withOpacity(0.4)),
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: NetworkImage(widget.shop.logoUrl ?? ""),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.shop.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text("${widget.shop.averageRating} (${widget.shop.reviewCount} Yorum)", style: const TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              )
                            ],
                          )
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
            // 🚨 KESİN DÜZELTME: Kategorilerin kendi görsel/ikonunu barındıran şık dairesel seçici
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _activeCategories.length,
                itemBuilder: (context, index) {
                  final cat = _activeCategories[index];
                  final isSelected = _selectedCategory?.id == cat.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = cat;
                        _selectedSubCategory = null; // Kategori değişince alt kategoriyi sıfırla
                      });
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey.shade100,
                              backgroundImage: cat.imageUrl != null ? NetworkImage(cat.imageUrl!) : null,
                              child: cat.imageUrl == null ? const Icon(Icons.category_outlined, size: 20) : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 🚨 KESİN DÜZELTME: Alt kategorilerin yatay çip olarak listelenmesi ve filtre senkronizasyonu
            if (_selectedCategory != null && _selectedCategory!.subCategories.isNotEmpty)
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedCategory!.subCategories.length + 1,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final subCat = isAll ? null : _selectedCategory!.subCategories[index - 1];
                    final isSelected = (isAll && _selectedSubCategory == null) || (_selectedSubCategory?.id == subCat?.id);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Text(isAll ? "Tümü" : subCat!.name, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedSubCategory = isAll ? null : subCat;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

            // Filtrelenmiş Ürün Listesi
            Expanded(
              child: _buildFilteredProductGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredProductGrid() {
    final filteredProducts = widget.shop.products.where((p) {
      final matchesCategory = _selectedCategory == null || p.categoryId == _selectedCategory!.id;
      final matchesSubCategory = _selectedSubCategory == null || p.subCategoryId == _selectedSubCategory!.id;
      return matchesCategory && matchesSubCategory;
    }).toList();

    if (filteredProducts.isEmpty) {
      return const Center(child: Text("Bu kategoride ürün bulunmamaktadır."));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        return ModernProductCard(product: filteredProducts[index]);
      },
    );
  }
}


D. Ürün Detay Ekranında İndirim Kart Bilgisi Revizyonu (product_detail_page.dart)

Sorun: İndirimli ürünlerin detay sayfasında indirim oranı ve eski üstü çizili fiyatı görünmüyordu.

// apps/consumer_app/lib/screens/shop/product_detail_page.dart

class ProductDetailPriceSection extends StatelessWidget {
  final double price;
  final double? regularPrice;
  final int discountRate;

  const ProductDetailPriceSection({
    Key? key,
    required this.price,
    this.regularPrice,
    this.discountRate = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDiscount = discountRate > 0 && regularPrice != null && regularPrice! > price;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasDiscount) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "%$discountRate İNDİRİM",
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${regularPrice!.toStringAsFixed(2)} TL",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        Text(
          "${price.toStringAsFixed(2)} TL",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: hasDiscount ? Colors.red : theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}


📢 4. DOĞRULAMA VE AGENT ENTEGRASYON TALİMATI

Prisma & Veritabanı Reset:

cd backend && npx prisma db push --force-reset && npx prisma generate


Katalog Tohumlama (Hassas Ekmek & Adet Birimli Seed):

cd backend && npx ts-node prisma/seed_catalog.ts


Uygulama Analiz Derlemeleri:

cd apps/consumer_app && flutter analyze

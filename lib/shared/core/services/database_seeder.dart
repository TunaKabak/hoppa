import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hoppa/shared/core/data/dummy_products.dart';
import 'package:hoppa/shared/models/business.dart';
import 'package:hoppa/shared/models/business_type.dart';
import 'package:bcrypt/bcrypt.dart';

class DatabaseSeeder {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Random _random = Random();

  Future<void> seedSystem() async {
    final WriteBatch batch = _db.batch();

    print("🚀 Sistem Kurulumu Başladı (Genişletilmiş Seeding)...");

    // 1. TEMİZLİK
    print("🧹 Eski veriler temizleniyor...");
    await _deleteCollection('market_products');
    await _deleteCollection('markets');
    await _deleteCollection('business_products');
    await _deleteCollection('businesses');
    await _deleteCollection('global_products');
    await _deleteCollection('business_users');

    // Default password hash for all seeded businesses
    final String defaultPasswordHash = BCrypt.hashpw(
      'hoppa123',
      BCrypt.gensalt(),
    );

    // 2. KATEGORİ YAPILANDIRMASI
    // Her kategori için hangi ürün tiplerinin satılacağını belirliyoruz
    final Map<String, List<String>> businessConfigs = {
      'Market': ['Tümü'], // Her şeyi satar
      'Restoran': [
        'Restoran',
        'Su & İçecek',
        'Atıştırmalık',
        'Fırın',
      ], // Yemek, İçecek, Tatlı
      'Su': ['Su & İçecek'], // Sadece İçecek
      'Kuruyemiş': ['Atıştırmalık', 'Su & İçecek'], // Cips, çerez, içecek
      'Kahve': [
        'Su & İçecek',
        'Fırın',
        'Atıştırmalık',
      ], // Kahve, tatlı, sandviç
      'Kasap': ['Et & Kasap', 'Atıştırmalık'],
      'Çiçek': ['Çiçek'], // Sadece Çiçek
      // İleride Manav eklenebilir
    };

    // 3. GLOBAL KATALOG OLUŞTUR
    // Önce tüm dummy ürünleri global_products'a yazalım
    print("🌍 Global katalog oluşturuluyor...");
    Map<String, Map<String, dynamic>> productCatalog =
        {}; // Barcode -> ProductData

    int pCount = 0;
    for (var item in kDummyProducts) {
      String uniqueId = (pCount + 1000000).toString();
      String barcode = "869$uniqueId";

      bool isWeighted = item['isWeighted'] ?? false;
      if (item['category'] == 'Meyve & Sebze') isWeighted = true;
      if (item['category'] == 'Et & Kasap' &&
          (item['subCategory'] == 'Kırmızı Et' ||
              item['subCategory'] == 'Beyaz Et')) {
        isWeighted = true;
      }

      Map<String, dynamic> globalData = {
        'barcode': barcode,
        'name': item['name'],
        'brand': item['brand'],
        'category': item['category'],
        'subCategory': item['subCategory'],
        'imageUrl': item['imageUrl'],
        'isWeighted': isWeighted,
        'description': _generateDescription(item['name'], item['category']),
      };

      batch.set(_db.collection('global_products').doc(barcode), globalData);
      productCatalog[barcode] = globalData;
      pCount++;
    }

    // 4. İŞLETMELERİ VE ENVANTERLERİ OLUŞTUR
    print("🏪 İşletmeler ve stoklar oluşturuluyor...");

    int businessIdCounter = 1;

    // Her kategori grubu için dön
    for (var entry in businessConfigs.entries) {
      String categoryName = entry.key; // Market, Restoran...
      List<String> allowedCategories = entry.value;

      // Bu kategoriden 5 tane işletme oluştur
      for (int i = 1; i <= 5; i++) {
        String bId = 'business_$businessIdCounter';
        String bName = _generateBusinessName(categoryName, i);
        BusinessType bType = _mapStringToBusinessType(categoryName);

        // Lokasyon: Lefkoşa/Girne civarı rastgele koordinat
        double lat =
            35.15 + (_random.nextDouble() * 0.2); // 35.15 - 35.35 arası
        double lng =
            33.30 + (_random.nextDouble() * 0.6); // 33.30 - 33.90 arası

        // Logo URL fix - Generate BEFORE object creation
        String safeName = bName.replaceAll(' ', '+');
        String logoUrl =
            "https://placehold.co/100x100/${_getColor(categoryName)}/ffffff?text=$safeName";
        String headerImageUrl =
            "https://placehold.co/400x200/${_getColor(categoryName)}/ffffff?text=$safeName";

        final Business business = Business(
          id: bId,
          name: bName,
          address: _generateAddress(i),
          phone:
              '90 533 ${_random.nextInt(899) + 100} ${_random.nextInt(89) + 10} ${_random.nextInt(89) + 10}',
          logoUrl: logoUrl,
          headerImageUrl: headerImageUrl,
          latitude: lat,
          longitude: lng,
          type: bType,
        );

        batch.set(_db.collection('businesses').doc(bId), business.toMap());

        // Kullanıcı Adı Üretimi (boşlukları sil, küçük harfe çevir, Türkçe karakterleri düzelt)
        String username = bName
            .toLowerCase()
            .replaceAll(' ', '')
            .replaceAll('ı', 'i')
            .replaceAll('ğ', 'g')
            .replaceAll('ü', 'u')
            .replaceAll('ş', 's')
            .replaceAll('ö', 'o')
            .replaceAll('ç', 'c');

        // business_users tablosuna kayıt
        batch.set(_db.collection('business_users').doc(bId), {
          'businessId': bId,
          'username': username,
          'passwordHash': defaultPasswordHash,
          'role': 'merchant',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 5. ENVANTER OLUŞTUR (Her işletme için)
        // Global katalogdan uygun ürünleri seç ve ekle
        int productAddedCount = 0;
        int targetProductCount;

        if (categoryName == 'Çiçek') {
          targetProductCount =
              5 + _random.nextInt(6); // 5 ile 10 arası (5 + 0..5)
        } else {
          targetProductCount = 10 + _random.nextInt(20); // 10 ile 30 arası
        }

        List<String> availableBarcodes = productCatalog.keys.toList();
        availableBarcodes.shuffle(_random); // Karıştır

        for (var barcode in availableBarcodes) {
          if (productAddedCount >= targetProductCount) break;

          var productData = productCatalog[barcode]!;
          String pCat = productData['category'];

          // Filtreleme: Bu işletme bu ürünü satabilir mi?
          bool isAllowed = false;
          if (allowedCategories.contains('Tümü')) {
            isAllowed = true;
          } else {
            // Ana kategori eşleşiyor mu? (örn: Restoran == Restoran)
            if (allowedCategories.contains(pCat)) isAllowed = true;
            // Kahve dükkanı özel durumu
            if (categoryName == 'Kahve') {
              if (productData['subCategory'] == 'Kahve' ||
                  pCat == 'Fırın' ||
                  pCat == 'Atıştırmalık') {
                isAllowed = true;
              } else {
                isAllowed = false;
              }
            }
          }

          if (isAllowed) {
            // Fiyat varyasyonu (%10 +/-)
            double basePrice = 50.0;
            // Orijinal fiyatı bulmaya çalışalım
            var originalItem = kDummyProducts.firstWhere(
              (e) => e['name'] == productData['name'],
              orElse: () => {},
            );
            if (originalItem.isNotEmpty) {
              basePrice = (originalItem['price'] as num).toDouble();
            }

            double priceMultiplier =
                0.9 + (_random.nextDouble() * 0.3); // 0.9x - 1.2x
            double finalPrice = double.parse(
              (basePrice * priceMultiplier).toStringAsFixed(2),
            );

            batch.set(_db.collection('business_products').doc(), {
              'businessId': bId,
              'productBarcode': barcode,
              'price': finalPrice,
              'stock': (_random.nextInt(50) + 5).toDouble(),
              'product_details': productData,
            });

            productAddedCount++;
          }
        }
        businessIdCounter++;
      }
    }

    await batch.commit();
    print("✅ SİSTEM HAZIR! 30+ İşletme ve Yüzlerce Ürün Eklendi.");
  }

  Future<void> _deleteCollection(String path) async {
    var collection = _db.collection(path);
    var snapshots = await collection.limit(500).get();
    while (snapshots.docs.isNotEmpty) {
      var batch = _db.batch();
      for (var doc in snapshots.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      snapshots = await collection.limit(500).get();
    }
  }

  String _generateBusinessName(String category, int index) {
    List<String> adjectives = [
      'Mavi',
      'Yeşil',
      'Hızlı',
      'Lezzet',
      'Bizim',
      'Ada',
      'Köşe',
      'Merkez',
      'Elit',
      'Yıldız',
    ];
    String adj = adjectives[_random.nextInt(adjectives.length)];
    return "$adj $category $index"; // Örn: Mavi Market 1
  }

  String _generateAddress(int index) {
    List<String> cities = ['Lefkoşa', 'Girne', 'Gazimağusa'];
    String city = cities[_random.nextInt(cities.length)];
    return "Mahalle $index, Cadde ${index * 2}, No: ${index * 3}, $city";
  }

  BusinessType _mapStringToBusinessType(String cat) {
    switch (cat) {
      case 'Market':
        return BusinessType.market;
      case 'Restoran':
        return BusinessType.restaurant;
      case 'Kahve':
        return BusinessType.cafe;
      case 'Su':
        return BusinessType.water;
      case 'Kuruyemiş':
        return BusinessType.nuts;
      case 'Kasap':
        return BusinessType.butcher;
      case 'Çiçek':
        return BusinessType.florist;
      default:
        return BusinessType.market;
    }
  }

  String _getColor(String cat) {
    switch (cat) {
      case 'Market':
        return "0277bd";
      case 'Restoran':
        return "d32f2f";
      case 'Kahve':
        return "795548";
      case 'Su':
        return "0288d1";
      case 'Kuruyemiş':
        return "e65100";
      case 'Kasap':
        return "b71c1c";
      case 'Çiçek':
        return "d81b60"; // Pink
      default:
        return "000000";
    }
  }

  String _generateDescription(String name, String category) {
    return "Bu harika $name ürünü, $category kategorisinin en taze ve en kaliteli seçeneklerinden biridir. Üretiminden sofranıza gelene kadar titizlikle işlenmiştir. Şimdi uygun fiyat avantajıyla sipariş verebilirsiniz.\n\nÖzellikler:\n- Taze ve Doğal\n- Yüksek Kalite Standartları\n- Memnuniyet Garantisi\n\nLorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.";
  }
}

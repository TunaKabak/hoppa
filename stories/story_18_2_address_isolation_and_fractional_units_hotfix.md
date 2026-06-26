Story 18.2 - Hesaplar Arası Adres İzolasyonu ve Küsuratlı Birim (KG/Litre) Entegrasyonu

Bu görev belgesi; farklı hesapların birbirinin adreslerini görmesini engelleyecek "Kullanıcı Tabanlı Adres İzolasyonu" (User-Scoped Storage) mimarisini kurmayı ve dökme ürünlerde (manav/kasap) "adet" yerine dinamik birimleri (KG, Litre) küsuratlı artış adımlarıyla (stepSize) arayüze ve sepet kontrolörüne giydirmeyi amaçlar.

🔐 1. BÖLÜM: Hesaplar Arası Adres Sızması (State Leak) Çözümü

Sorun Analizi

Story 11'de seçilen teslimat adresini kalıcı hale getirmek için SharedPreferences entegrasyonu yazmıştık. Ancak:

Adres bilgisi selected_address gibi genel bir anahtarla (generic key) kaydedildiği için, telefon değişmese bile kullanıcı değiştiğinde eski kullanıcının adresi okunuyor.

Kullanıcı çıkış yaptığında (logout) veya oturum düştüğünde bu yerel cache temizlenmiyor.

Çözüm Adımları

A. Kullanıcı Tabanlı Anahtarlama (User-Scoped Keys)

location_controller.dart veya adresi kaydeden provider içinde, SharedPreferences anahtarını o anki aktif kullanıcının ID'sine bağlayın:

// Hatalı (Eski) Yaklaşım:
// prefs.setString('selected_address', addressJson);

// Güvenli (Yeni) Yaklaşım:
final String userId = ref.read(userIdProvider) ?? 'guest';
await prefs.setString('selected_address_$userId', addressJson);


B. Çıkış Yapıldığında (Logout) State ve Cache Temizliği

Kullanıcı oturumu kapattığında (logout tetiklendiğinde) sadece token silinmemeli, aynı zamanda seçili adres state'i de sıfırlanmalıdır.

AuthController veya AuthRepository içerisindeki logout metodunun en sonuna şu temizlik adımlarını ekleyin:

@override
Future<void> logout() async {
  await _apiClient.deleteToken();
  
  // SharedPreferences temizliği (Seçili adresi sıfırla)
  final prefs = await SharedPreferences.getInstance();
  final String userId = _currentUserId ?? 'guest';
  await prefs.remove('selected_address_$userId');
  
  // Riverpod State Invalidation (Adres state'ini sıfırla)
  ref.invalidate(consumerLocationProvider);
}


🥦 2. BÖLÜM: Ürün Tiplerine Göre Küsuratlı Ekleme ve Birim Entegrasyonu

Sorun Analizi

Uygulamada patates gibi ürünlerde hala "adet" yazması ve küsuratlı ekleme yapılamamasının sebebi, sepet kontrolörünün (cart_provider.dart veya cart_controller.dart) ve UI butonlarının hala int tipinde 1 artış adımıyla çalışmasıdır.

Çözüm Adımları

A. Miktar Tipinin double Yapılması ve Akıllı Artış (Step Size)

Sepet kalemlerindeki (CartItem) miktar (quantity) alanı tamamen double tipine dönüştürülmelidir.

cart_provider.dart (veya ilgili sepet notifier) dosyasını açın.

Ürün ekleme/çıkarma metodunu (addToCart, removeFromCart veya updateQuantity) ürünün kendi artış parametrelerine göre güncelleyin:

// apps/consumer_app/lib/apps/consumer/cart/cart_provider.dart

void addToCart(Product product) {
  final currentItem = state.firstWhereOrNull((item) => item.product.id == product.id);
  
  // Ürünün kendi birim özelliklerini alıyoruz (Varsayılan: ADET, 1.0, 1.0)
  final double step = product.stepSize ?? 1.0;
  final double minQty = product.minQuantity ?? 1.0;

  if (currentItem == null) {
    // İlk defa ekleniyorsa minimum alım miktarıyla başla
    state = [...state, CartItem(product: product, quantity: minQty)];
  } else {
    // Zaten varsa artış adımı (stepSize) kadar ekle
    final double updatedQty = currentItem.quantity + step;
    _updateQuantityInState(product.id, updatedQty);
  }
}

void removeFromCart(Product product) {
  final currentItem = state.firstWhereOrNull((item) => item.product.id == product.id);
  if (currentItem == null) return;

  final double step = product.stepSize ?? 1.0;
  final double minQty = product.minQuantity ?? 1.0;
  final double updatedQty = currentItem.quantity - step;

  if (updatedQty < minQty) {
    // Eğer miktar minimum alım miktarının altına düşüyorsa ürünü sepetten tamamen sil
    state = state.where((item) => item.product.id != product.id).toList();
  } else {
    _updateQuantityInState(product.id, updatedQty);
  }
}


B. Miktar ve Birim Gösterimi Yardımcı Formatlayıcısı (Quantity Formatter)

Kullanıcının kafasını karıştırmamak için tam sayıları (örn: 3.0 ADET) küsuratsız (3 ADET) göstermeliyiz. Bunun için şu yardımcı formatlayıcıyı ekleyin ve UI katmanında miktar yazdırılan her yere giydirin:

// apps/consumer_app/lib/shared/utils/quantity_formatter.dart

class QuantityFormatter {
  /// Miktarı ve birimi birleştirerek şık bir format döndürür.
  /// Örn: (1.5, "KG") -> "1.50 KG" | (3.0, "ADET") -> "3 ADET"
  static String format(double quantity, String unit) {
    final String cleanUnit = unit.toUpperCase();
    
    // Eğer miktar tam sayıya eşitse (örn: 3.0), virgülden sonrasını gösterme
    if (quantity == quantity.roundToDouble()) {
      return "${quantity.toInt()} $cleanUnit";
    }
    
    // Küsuratlı ise 2 hane olarak göster (Örn: 1.25 veya 0.50)
    return "${quantity.toStringAsFixed(2)} $cleanUnit";
  }

  /// Sadece miktarı formatlar (Birim olmadan)
  static String formatValue(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    return quantity.toStringAsFixed(2);
  }
}


C. Arayüzün Güncellenmesi (Product Detail, Cart Page ve Modern Product Card)

Fiyat Etiketi: Ürün listesi ve detay sayfasındaki fiyat etiketini birimiyle gösterin:

Fiyat: 120 TL / KG veya 45 TL / ADET (${product.price} TL / ${product.unit})

Sayaç Butonları: Adet artırıp azaltılan [-] miktar [+] butonlarını QuantityFormatter.formatValue kullanacak şekilde güncelleyin.

Ürün Kartı: modern_product_card.dart dosyasında sepete ekleme butonunun üzerine tıklandığında addToCart metodunu tetiklerken product.stepSize ve product.unit değerlerinin doğru yansıdığını doğrulayın.

📢 Doğrulama Planı

Prisma ve TypeScript Kontrolleri:

cd backend && npx prisma db push && npm run build


Flutter Statik Analiz Kontrolü:

cd apps/consumer_app && flutter analyze


Kullanıcı Kabul Testi (UAT):

Yeni hesap açıp giriş yapın. Ana sayfada seçili adresin "Boş" (Address selection required) olduğunu ve eski kullanıcının adresinin buraya sızmadığını doğrulayın.

Manav kategorisinden "Patates" ürününe tıklayın. Birimin "KG" olduğunu, + butonuna basınca 0.50 KG -> 0.75 KG -> 1.00 KG şeklinde küsuratlı arttığını ve sepet ekranında da "KG" birimiyle listelendiğini doğrulayın.
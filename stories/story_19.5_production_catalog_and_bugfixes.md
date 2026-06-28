Story 19.5 - Kusursuz Canlı Katalog Verisi ve Kritik UX Hata Temizliği Paketi

Bu görev belgesi; Hoppa platformunu tamamen canlı ortama hazır hale getirmek için kategori görsel/ikon altyapısını kurmayı, 1000+ ürünü hatasız stüdyo görselleriyle tohumlamayı ve test sürecinde tespit edilen 4 kritik kullanıcı deneyimi hatasını (bug) çözmeyi amaçlar.

🎨 1. KATEGORİ VE ALT KATEGORİ GÖRSEL/İKON ALTYAPISI

Kategorilerin sadece düz yazı olarak listelenmesi modern bir e-ticaret arayüzü için yetersizdir. Kategorilerimizin hem tüketici hem de satıcı arayüzünde şık, yüksek kaliteli görseller veya SVG illüstrasyonları ile desteklenmesi gerekir.

A. Prisma Şemasında Görsel Desteği

Mevcut Category ve SubCategory modellerine görsel URL'lerini saklayacak alanları ekliyoruz.

Category.imageUrl -> Ana kategori resmi (Örn: Yuvarlak ikonik meyve sepeti resmi)

SubCategory.imageUrl -> Alt kategori resmi

// backend/prisma/schema.prisma

model Category {
  id             String          @id @default(uuid())
  name           String          @unique
  shopType       String          @default("MARKET")
  iconUrl        String?         // SVG veya Font Icon adı (Örn: "apple", "milk")
  imageUrl       String?         // 🚨 Ana Kategori Görsel URL'si
  subCategories  SubCategory[]
  globalProducts GlobalProduct[]
  products       Product[]
}

model SubCategory {
  id             String          @id @default(uuid())
  name           String
  imageUrl       String?         // 🚨 Alt Kategori Görsel URL'si
  categoryId     String
  category       Category        @relation(fields: [categoryId], references: [id], onDelete: Cascade)
  globalProducts GlobalProduct[]
  products       Product[]

  @@unique([name, categoryId])
}


🛠️ 2. KRİTİK BUGFIX MADDELERİNİN ÇÖZÜMLERİ

BUG 1: Ürün Ekleme Ekranında 1 Ürün Seçilince 2 Farklı Ürünün Daha Seçilmesi Bug'ı

Nedeni: Satıcı uygulamasında katalogdan ürün ekleme listesindeki checkbox/seçim durumu (isSelected), her ürüne özel benzersiz ID (globalProductId) üzerinden değil, liste indeks numarası (index) veya yanlış kurgulanmış geçici bir yerel boolean state üzerinden yönetiliyor. Bu durum, liste kaydırıldığında (recycle) veya state güncellendiğinde seçimlerin klonlanmasına sebep olur.

Çözüm (merchant_product_list_page.dart):
Seçilen ürünleri tek bir değişken yerine bir Set<String> (seçilen ürün ID'lerinin benzersiz kümesi) içinde biriktirip kontrol edeceğiz.

// apps/merchant_app/lib/apps/merchant/merchant_product_list_page.dart içindeki seçim mantığı:

// Hatalı (Eski) Yaklaşım:
// bool isSelected = false; // veya List<bool>

// Güvenli (Yeni) Yaklaşım:
final Set<String> _selectedCatalogProductIds = {};

// ListTile veya GridTile içindeki Checkbox / Kart Seçim Tetikleyicisi:
Checkbox(
  value: _selectedCatalogProductIds.contains(catalogProduct.id),
  onChanged: (bool? checked) {
    setState(() {
      if (checked == true) {
        _selectedCatalogProductIds.add(catalogProduct.id);
      } else {
        _selectedCatalogProductIds.remove(catalogProduct.id);
      }
    });
  },
);


BUG 2: Ürün Resimlerinin Hatalı Veya Eksik Olması

Nedeni: Ürün görsellerinin geçici placehold.co veya kırık CDN adreslerinden beslenmesi.

Çözüm: seed_catalog.ts dosyasını tamamen güncelleyerek, KKTC ve Türkiye marketlerinde en çok tüketilen popüler markaların yüksek çözünürlüklü, beyaz arka planlı, resmi e-ticaret CDN (Getir, Yemeksepeti ve Migros CDN) adreslerini tohumlama verisi olarak tanımlıyoruz.

Gerçek Görsel CDN Eşleşme Listesi:

Coca-Cola Original 1L: https://images.deliveryhero.io/image/fd-tr/Products/1110059.jpg

Sütaş Süzme Peynir 500g: https://images.deliveryhero.io/image/fd-tr/Products/1113050.jpg

Ülker Çikolatalı Gofret 36g: https://images.deliveryhero.io/image/fd-tr/Products/1111024.jpg

Eti Crax Sade Çubuk 120g: https://images.deliveryhero.io/image/fd-tr/Products/1111102.jpg

Damla Damacana Su 19L: https://images.deliveryhero.io/image/fd-tr/Products/1110101.jpg

Taze Patates (KG): https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=500&q=80

Kırmızı Salkım Domates (KG): https://images.unsplash.com/photo-1595855759920-86582396756a?auto=format&fit=crop&w=500&q=80

BUG 3: Ürün Detayında Sepete Ürün Ekleme/Çıkarma Yaparken Ekranda Çıkan Engelleyici Bar (Snackbar) Sorunu

Nedeni: Kullanıcı + veya - butonlarına her bastığında, sepetteki miktar değişikliğini doğrulamak için tetiklenen ScaffoldMessenger.of(context).showSnackBar() bildirim barı. Bu bar, sayfanın altındaki sepet kontrol butonlarının tam üzerine bindiği için kullanıcının art arda butona basmasını (örneğin patatesi 3 kg yapmak istemesini) engelliyor ve tıklamaları bloke ediyor.

Çözüm (cart_provider.dart veya ilgili UI tetikleyicisi):
Miktar güncellemelerindeki (+ ve - basışları) gürültülü SnackBar bildirimini tamamen kaldırıyoruz. Bildirimi sadece ürün sepetten tamamen silindiğinde veya ilk defa sıfırdan eklendiğinde hafif bir haptik (titreşim) eşliğinde göstereceğiz.

// apps/consumer_app/lib/apps/consumer/cart/cart_provider.dart (veya ilgili sayacın UI dosyası)

void updateQuantity(String productId, double newQty) {
  // 🚨 SNACKBAR ÇAĞRILARINI ENGELLE:
  // ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Varsa eskiyi hemen kapat
  // showSnackBar(...) çağrısını buradan tamamen silin!
  
  // Bunun yerine sadece hafif bir telefon titreşimi (Haptic Feedback) vererek hissiyatı güçlendir:
  HapticFeedback.lightImpact();
}


BUG 4: Adres Listesinde Seçili Olan Adresin Belirgin Olmaması (Seçilmemiş Hissi)

Nedeni: Seçili adres kartının diğer pasif adres kartlarıyla neredeyse aynı gri arka plana ve ince kenarlığa sahip olması, kullanıcıda "Adresim seçilmedi mi?" şüphesi uyandırıyor.

Çözüm (address_list_page.dart veya delivery_provider.dart):
Seçili adresi, uygulamanın marka yeşili (primary) rengiyle kalınlaştırılmış bir kenarlık, hafif yeşilimsi bir arka plan dolgusu ve sağ üst köşesine yerleştirilmiş belirgin bir onay ikonu (Icons.check_circle) ile donatıyoruz.

// apps/consumer_app/lib/screens/address/address_list_page.dart içindeki kart tasarımı güncellemesi:

Widget _buildAddressCard(Address address, bool isSelected, ThemeData theme) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    decoration: BoxDecoration(
      // 🚨 SEÇİLİ DURUMDA ARKA PLAN FARKILAŞTIRMASI:
      color: isSelected 
          ? theme.colorScheme.primaryContainer.withOpacity(0.15) 
          : theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        // 🚨 KALINLAŞTIRILMIŞ MARKA RENKLİ ÇERCEVE:
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
        width: isSelected ? 2.5 : 1.0,
      ),
      boxShadow: isSelected 
          ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]
          : [],
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: Icon(
        address.type == AddressType.home ? Icons.home_rounded : Icons.work_rounded,
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        size: 28,
      ),
      title: Text(
        address.title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(address.fullAddress),
      
      // 🚨 SAĞ TARAFTA BELİRGİN ONAY İKONU:
      trailing: isSelected 
          ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary, size: 26)
          : null,
    ),
  );
}


📢 Doğrulama Planı

Prisma Şema ve Veri Güncelleme:

cd backend && npx prisma db push --force-reset && npx prisma generate


Katalog Tohumlama:

cd backend && npx ts-node prisma/seed_catalog.ts


TypeScript ve Flutter Derleme Kontrolü:

cd backend && npx tsc --noEmit
cd apps/consumer_app && flutter analyze
cd apps/merchant_app && flutter analyze

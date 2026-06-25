Story 18 - Dinamik Ürün Birimleri (KG/Litre), Sektörel Filtreleme ve Kompakt Sepet UX Optimizasyonu

Bu görev belgesi, Hoppa platformunu hem restoran hem de süpermarket/manav dikeyine tam uyumlu hale getirmek için veritabanındaki miktar yapısını ondalıklı (Decimal/Float) hale getirmeyi, dükkan türlerine göre kategori yönetimini kurmayı ve sepet ekranındaki alan israfını önleyecek kompakt, kullanıcı dostu bir arayüz tasarımına geçişi kapsar.

🧭 Teknik Mimari Yaklaşım

1. Veritabanı ve Ondalıklı Miktar Dönüşümü (Prisma)

Sipariş ve Sepet kalemlerindeki quantity alanını tam sayı (Int) yerine ondalıklı sayı (Float) yapacağız. Böylece bir kullanıcı sepetine $1.5\text{ kg}$ patates ekleyebilecektir.

Product modeline birim (unit), minimum alım miktarı (minQuantity) ve artış adımı (stepSize) alanları eklenir.

Örnek: Patates için unit: "KG", minQuantity: 0.5, stepSize: 0.25 olarak ayarlanırsa, kullanıcı butona bastığında miktar sırasıyla $0.5 \rightarrow 0.75 \rightarrow 1.0 \rightarrow 1.25 \rightarrow 1.5$ şeklinde artacaktır.

2. Sektörel Kategori Yönetimi (Shop Type Mapping)

Kullanıcı dükkan listesinden "Süpermarket" veya "Manav" seçtiğinde karşısına restoran kategorileri (Örn: Lahmacun, Kebap) yerine manav kategorileri (Meyve, Sebze) çıkmalıdır.

Dükkanların bir sektörel türü (shopType: RESTAURANT | MARKET | GREENGROCER | BUTCHER) olacaktır.

Kategoriler dükkanların bu ana türlerine göre filtrelenerek API'den çekilecektir.

🛠️ ADIM 1: Veritabanı Şeması ve Ondalıklı Dönüşüm (Prisma)

backend/prisma/schema.prisma dosyasını açın ve aşağıdaki alanları güncelleyin/ekleyin:

// Product modeline birim ve adım özellikleri eklenir
model Product {
  id            String   @id @default(uuid())
  name          String
  price         Decimal  @db.Decimal(10, 2)
  // ... mevcut alanlar
  unit          String   @default("ADET") // ADET, KG, LITRE, PORSIYON, GR
  minQuantity   Float    @default(1.0)    // Manav için örn: 0.5 (kg)
  stepSize      Float    @default(1.0)    // Manav için örn: 0.25 (kg)
}

// Sepet kalemlerindeki miktar Float (Double) tipine dönüştürülür
model CartItem {
  id        String   @id @default(uuid())
  cartId    String
  productId String
  quantity  Float    // Int -> Float dönüşümü (Kritik!)
  // ...
}

// Sipariş kalemlerindeki miktar Float tipine dönüştürülür
model OrderItem {
  id        String   @id @default(uuid())
  orderId   String
  productId String
  quantity  Float    // Int -> Float dönüşümü
  price     Decimal  @db.Decimal(10, 2)
  // ...
}


Veritabanını Güncelleyin:

cd backend && npx prisma db push && npx prisma generate


📊 ADIM 2: Dükkan Türüne Göre Kategori Filtreleme (Backend)

Shop modelinde shopType alanı tanımlandığından veya type alanı üzerinden filtreleme yapılabildiğinden emin olun.

CategoryController.ts veya ilgili sınıftaki kategori çekme endpoint'ini dükkanın türüne göre süzülecek şekilde güncelleyin:

// GET /api/categories?shopType=GREENGROCER
const { shopType } = req.query;
const categories = await prisma.category.findMany({
    where: {
        shopType: shopType ? String(shopType) : undefined
    }
});


🛒 ADIM 3: Küsuratlı Miktar ve Birim Gösterimi (Flutter)

Sepet Denetleyicisi (Cart Controller) Güncellemesi:

Sepet miktar artırma/azaltma metodlarındaki int parametrelerini double yapın.

Ürün eklenirken veya güncellenirken, o ürünün stepSize ve minQuantity değerlerini hesaba katın:

double newQuantity = currentQuantity + product.stepSize;


UI Gösterim Formatı:

Eğer miktar tam sayıya eşitse (örn: 1.0), ekranda küsuratsız (1) gösterin.

Eğer ondalıklı ise (örn: 1.5), birimiyle birlikte şık bir şekilde formatlayın:

String formatQuantity(double qty, String unit) {
  if (qty == qty.roundToDouble()) {
    return "${qty.toInt()} $unit";
  }
  return "${qty.toStringAsFixed(2)} $unit"; // Örn: 1.25 KG
}


🎨 ADIM 4: Kompakt ve Kullanıcı Dostu Sepet Ekranı Redesign (UX)

Mevcut sepet ekranındaki dikey alan israfını (devasa minimum tutar, bedava kurye barları ve alt toplam kartları) önlemek için Kompakt Tasarıma geçiyoruz.

A. Üst Bölüm: Birleşik İlerleme Şeridi (Compact Multi-Progress Ribbon)

İki ayrı devasa bar yerine, sayfanın en üstüne sadece 32dp yüksekliğinde, tek bir satırda iki hedefi de özetleyen ince ve zarif bir bilgi şeridi tasarlayacağız.

// apps/consumer_app/lib/screens/cart/widgets/compact_delivery_status.dart

Widget _buildCompactDeliveryStatus({
  required double currentCartTotal,
  required double minOrderLimit,
  required double freeDeliveryLimit,
  required ThemeData theme,
}) {
  final isMinLimitPassed = currentCartTotal >= minOrderLimit;
  final isFreeDeliveryPassed = currentCartTotal >= freeDeliveryLimit;
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    color: isFreeDeliveryPassed 
        ? theme.colorScheme.primaryContainer.withOpacity(0.3)
        : theme.colorScheme.surfaceVariant.withOpacity(0.4),
    child: Row(
      children: [
        Icon(
          isFreeDeliveryPassed ? Icons.celebration : Icons.delivery_dining,
          size: 18,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            !isMinLimitPassed
                ? "Sepete minimum tutar için ${(minOrderLimit - currentCartTotal).toStringAsFixed(0)} TL daha ekleyin."
                : !isFreeDeliveryPassed
                    ? "Kurye ücreti bedava! Kalan: ${(freeDeliveryLimit - currentCartTotal).toStringAsFixed(0)} TL."
                    : "Tebrikler, teslimat ücretiniz tamamen Hoppa'dan! 🎉",
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        // Küçük dairesel veya yatay mikro ilerleme çubuğu
        SizedBox(
          width: 40,
          height: 4,
          child: LinearProgressIndicator(
            value: (currentCartTotal / freeDeliveryLimit).clamp(0.0, 1.0),
            borderRadius: BorderRadius.circular(2),
            backgroundColor: theme.colorScheme.outlineVariant,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    ),
  );
}


B. Alt Bölüm: Sticky Kompakt Toplam ve Ödeme Barı

Tüm ekranı kaplayan devasa alt detay kartı yerine, sadece tek bir satırda toplam tutarı gösteren ve sağında "Ödemeye Geç" aksiyonu barındıran modern bir Sticky Floating Action Bar tasarlayacağız.

// apps/consumer_app/lib/screens/cart/widgets/compact_checkout_bar.dart

Widget _buildCompactCheckoutBar({
  required double subTotal,
  required double deliveryFee,
  required double total,
  required VoidCallback onCheckout,
  required ThemeData theme,
}) {
  return Card(
    margin: const EdgeInsets.all(16),
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Sol Taraf: Özet Rakamlar
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Toplam Ödenecek",
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                "${total.toStringAsFixed(2)} TL",
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          
          // Sağ Taraf: Kompakt Ödeme Butonu (Sola kaydırmalı veya şık bir buton)
          ElevatedButton(
            onPressed: onCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Row(
              children: [
                const Text("Ödemeye Geç", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.onPrimary),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}


📢 Doğrulama Planı

Derleme ve Tip Güvenliği:

cd backend && npm run build çalıştırılarak Float miktar dönüşümünün sipariş akışlarındaki tipleri bozmadığı doğrulanacak.

Her iki uygulamada da flutter analyze çalıştırılarak statik analiz uyarıları temizlenecek.

Küsüratlı Alım Testi:

Manav dükkanından patates ürününe git. Artırma butonuna basarak miktarın 0.5 -> 0.75 -> 1.0 şeklinde küsuratlı arttığını doğrula.

Sepete ekle ve sepet ekranında bu ondalıklı miktarın birimiyle birlikte düzgün formatlandığını gör.
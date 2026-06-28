Refined Implementation Plan - Shop Reviews & Hoppa Asistan Smart Support (3NF Standard)

Bu döküman; satıcı puanlama sistemini veritabanı seviyesinde işlem bütünlüğüyle (Transaction) kurmayı, Gemini 2.5 Flash entegrasyonunu kararlı hale getirmeyi ve mobil uygulamadaki kullanıcı deneyimi (UX) engellerini çözmeyi amaçlayan sıkılaştırılmış uygulama planıdır.

🛠️ 1. ADIM: Veritabanı ve İşlem Bütünlüğü (Prisma Transaction)

A. schema.prisma Güncellemesi

Review modelini eklerken dükkan modelinde (Shop) ortalamaları hızlı okumak için cache alanlarını da güncelliyoruz:

// backend/prisma/schema.prisma

model Shop {
  id            String   @id @default(uuid())
  name          String
  // ... mevcut alanlar
  averageRating Float    @default(5.0) // Cache alan: Puan ortalaması
  reviewCount   Int      @default(0)   // Cache alan: Toplam yorum sayısı
  reviews       Review[]
}

model Review {
  id        String   @id @default(uuid())
  rating    Int
  comment   String?  @db.VarChar(500)
  createdAt DateTime @default(now())

  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  shopId    String
  shop      Shop     @relation(fields: [shopId], references: [id], onDelete: Cascade)
  orderId   String   @unique
  order     Order    @relation(fields: [orderId], references: [id], onDelete: Cascade)

  @@index([shopId])
  @@index([userId])
}


B. Atomik Puan Güncellemesi (ReviewController.ts)

Bir yorum kaydedildiği an dükkan ortalamasını veritabanı düzeyinde tutarlı (consistent) şekilde güncelleyen işlem mimarisi:

// backend/src/controllers/ReviewController.ts (createReview metodu içerisindeki işlem bloğu)

const [newReview] = await prisma.$transaction(async (tx) => {
  // 1. Yorumu oluştur
  const review = await tx.review.create({
    data: { rating, comment, userId, shopId: order.shopId, orderId }
  });

  // 2. Dükkanın mevcut istatistiklerini çek
  const shop = await tx.shop.findUnique({
    where: { id: order.shopId },
    select: { averageRating: true, reviewCount: true }
  });

  if (shop) {
    const newCount = shop.reviewCount + 1;
    const newRating = ((shop.averageRating * shop.reviewCount) + rating) / newCount;

    // 3. Dükkanı güncelle
    await tx.shop.update({
      where: { id: order.shopId },
      data: {
        averageRating: parseFloat(newRating.toFixed(2)),
        reviewCount: newCount
      }
    });
  }

  return [review];
});


🤖 2. ADIM: Kararlı Gemini 2.5 Flash API Çağrısı

Önizleme (preview) modellerinin süresi dolduğunda API'nin kırılmasını engellemek için doğrudan kararlı üretim (stable production) modeli olan gemini-2.5-flash modelini kullanacağız.

// backend/src/controllers/SupportController.ts içindeki API URL tanımı:

const stableModel = "gemini-2.5-flash";
const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${stableModel}:generateContent?key=${apiKey}`;


📱 3. ADIM: Flutter UX Güvenlik Katmanı (Spam Guard)

Sipariş detay sayfası ilk açıldığında (DELIVERED durumunda) puanlama penceresinin her arayüz tazelemesinde (rebuild) tekrar fırlamasını engellemek için sayfa state'inde bir koruyucu (guard) tanımlıyoruz.

// apps/consumer_app/lib/apps/consumer/orders/order_detail_page.dart

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  // 🚨 DIALOG SPAM GUARD: Diyaloğun bu sayfa oturumunda sadece 1 kere tetiklenmesini sağlar
  bool _hasPromptedRating = false;

  void _checkAndShowRatingDialog(Order order) {
    if (order.status == OrderStatus.delivered && 
        order.review == null && 
        !_hasPromptedRating) {
      
      _hasPromptedRating = true; // Tetiklendi olarak işaretle
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: true, // Kullanıcı dışarı tıklayıp kapatabilir
          builder: (context) => RateOrderDialog(order: order),
        );
      });
    }
  }
}


📢 Doğrulama Planı

Database Migration:

cd backend && npx prisma db push && npx prisma generate


TypeScript ve Flutter Derleme Testi:

cd backend && npx tsc --noEmit
cd apps/consumer_app && flutter analyze


Puanlama Ortalaması Testi:

Bir siparişe 5 yıldız, diğer siparişe 4 yıldız vererek dükkan detay sayfasında dükkanın puanının anında 4.5 olarak güncellendiğini doğrulayın.
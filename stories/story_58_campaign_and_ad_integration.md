# Story 58: Reklam, Afiş ve Kampanya Sistemlerinin Birleştirilmesi ve İşletme İlişkilendirmesi

Bu hikaye, Hoppa uygulamasındaki Reklam/Afiş (statik ve dinamik afişler) ve Kampanya (sistemsel ve dükkan bazlı kampanyalar) sistemlerinin tek bir çatı altında birleştirilmesini ve Hoppa sistem kampanyalarının (örn. Ücretsiz Teslimat) belirli işletmelerle ilişkilendirilebilmesini kapsar.

## 1. Mevcut Durum Analizi

### 1.1. Veri Tabanı Modelleri
Mevcut durumda veritabanında (`schema.prisma`) kampanya ile ilişkili 2 farklı model bulunmaktadır:
1. **`Campaign` (Sistem Kampanyası):** Sistemsel genel kampanyaları tutar. (Örn: İlk 5 siparişte ücretsiz teslimat).
   * Alanlar: `id`, `title`, `description`, `prettyName`, `imageUrl`, `type` (SYSTEM, FREE_DELIVERY, PERCENTAGE_DISCOUNT), `isActive`, `maxUsesPerUser`, `finishDate`, `createdAt`.
2. **`ShopCampaign` (İşletme Kampanyası):** İşletmelerin kendileri için oluşturdukları ve onay sürecinden geçen kampanyaları tutar.
   * Alanlar: `id`, `shopId`, `title`, `description`, `imageUrl`, `targetArea` (SHOP_DETAIL, CATEGORY_SLIDER, MAIN_SLIDER), `status` (PENDING_APPROVAL, APPROVED, REJECTED), `designService`, `isActive`, `targetProducts` (String[]), `createdAt`.

### 1.2. Consumer App Arayüzleri
1. **`HoppaCampaignSlider`:** API'den `/api/consumer/shop-campaigns/active` rotasından dükkan kampanyalarını çeker. Boş dönerse veya hata durumunda lokal assetlerdeki statik afişleri (`_staticCampaigns`) gösterir.
2. **`PromoSlider`:** `/api/consumer/campaigns` rotasından sistemsel kampanyaları çeker ve anasayfada listeler.

---

## 2. Sorunlar ve İhtiyaçlar
1. **Veri Dağınıklığı ve Kod Tekrarı:** Hem sistemsel kampanyalar hem de dükkan kampanyaları benzer yapılara sahiptir (görsel, başlık, açıklama, aktiflik durumu). İki farklı tablonun olması karmaşıklığa yol açmaktadır.
2. **Statik Afişlerin Yönetilememesi:** `_staticCampaigns` olarak kodun içine gömülü olan afişler/reklamlar dinamik olarak admin panelinden yönetilememektedir. Reklam ve afişlerin de veritabanından dinamik beslenmesi gerekmektedir.
3. **Sistem Kampanyalarının İşletmelerle İlişkilendirilememesi:** Hoppa'nın düzenlediği "Ücretsiz Teslimat" veya "%20 İndirim" gibi genel sistem kampanyaları belirli dükkanlarda geçerli olacak şekilde kısıtlanamamaktadır. Hangi dükkanların bu kampanyaya dahil olduğu yönetilebilmelidir.

---

## 3. Önerilen Kusursuz Mimari ve Teknik Tasarım

### 3.1. Birleştirilmiş Tekil `Campaign` Modeli
`ShopCampaign` ve `Campaign` modelleri tek bir `Campaign` tablosunda birleştirilecektir. Bu model hem **sistem kampanyası**, hem **işletme kampanyası**, hem de **reklam/afiş** olarak görev yapabilecektir.

```prisma
model Campaign {
  id              String          @id @default(uuid())
  title           String          
  description     String          @db.Text
  prettyName      String?         // SEO dostu kampanya ismi
  imageUrl        String          // Banner/Afiş görsel adresi
  isActive        Boolean         @default(true)
  createdAt       DateTime        @default(now())
  updatedAt       DateTime        @updatedAt

  // Kampanya Kaynağı ve Durumu
  type            String          @default("SYSTEM") // SYSTEM (Hoppa), SHOP (İşletme), AD (Reklam/Afiş)
  status          String          @default("APPROVED") // PENDING_APPROVAL, APPROVED, REJECTED (İşletme kampanyaları için)
  
  // Yönlendirme ve Gösterim Alanı Kontrolleri
  targetArea      String          @default("MAIN_SLIDER") // MAIN_SLIDER, SHOP_DETAIL, CATEGORY_SLIDER, POPUP
  externalUrl     String?         // Eğer harici bir web sitesine/reklama yönlendirecekse
  
  // Kısıtlamalar ve Değerler
  discountType    String?         // PERCENTAGE, FIXED, FREE_DELIVERY
  discountValue   Float           @default(0.0)
  minOrderAmount  Float           @default(0.0)
  maxUsesPerUser  Int             @default(5)
  finishDate      DateTime?       
  
  // İşletme İlişkileri
  shopId          String?         // Eğer tek bir dükkana ait özel kampanyaysa (eski ShopCampaign gibi)
  shop            Shop?           @relation("ShopOwnCampaigns", fields: [shopId], references: [id], onDelete: Cascade)
  
  // Sistem Kampanyasının Dahil Olduğu İşletmeler (Many-to-Many)
  allowedShops    CampaignShop[]  // Sistem kampanyasının geçerli olduğu dükkanlar listesi
  targetProducts  String[]        @default([]) // Kampanyanın geçerli olduğu ürün barkodları
  
  orders          Order[]
  designService   Boolean         @default(false)

  @@index([shopId])
  @@index([type])
  @@index([status])
}
```

### 3.2. Sistem Kampanyaları - İşletme İlişkilendirme Tablosu (`CampaignShop`)
Hoppa sistem kampanyalarının belirli işletmelerle ilişkilendirilebilmesi için ara model:

```prisma
model CampaignShop {
  id         String   @id @default(uuid())
  campaignId String
  campaign   Campaign @relation(fields: [campaignId], references: [id], onDelete: Cascade)
  shopId     String
  shop       Shop     @relation(fields: [shopId], references: [id], onDelete: Cascade)

  createdAt  DateTime @default(now())

  @@unique([campaignId, shopId])
  @@index([campaignId])
  @@index([shopId])
}
```

---

## 4. API Rotaları Tasarımı

### 4.1. Tüketici (Consumer) API
* **`GET /api/consumer/campaigns/active`**:
  * Tüketicinin konumuna ve aktiflik durumuna göre anasayfada gösterilecek tüm aktif kampanyaları, reklam afişlerini ve dükkan kampanyalarını tek bir liste halinde döner.
  * Filtreleme parametreleri: `targetArea` (örn. `MAIN_SLIDER` veya `POPUP`).
* **`GET /api/consumer/campaigns/:id`**: Kampanya detayını ve dahil olan dükkanları getirir.

### 4.2. Satıcı (Merchant) API
* **`POST /api/merchant/campaigns`**: İşletme kendi dükkanı için kampanya/afiş oluşturur (`type = "SHOP"`, `status = "PENDING_APPROVAL"`).
* **`GET /api/merchant/campaigns`**: İşletmenin kendi oluşturduğu kampanyaları listeler.

### 4.3. Yönetici (Admin) API
* **`POST /api/admin/campaigns`**: Reklam afişi veya sistemsel kampanya oluşturur.
* **`POST /api/admin/campaigns/:id/shops`**: Sistem kampanyasına işletme/dükkan ekler (ilişkilendirir).
* **`PUT /api/admin/campaigns/:id/approve`**: Dükkanların oluşturduğu kampanyaları onaylar/reddeder.

---

## 5. Teslimat Ücreti Hesaplama (`CampaignService.ts`) Entegrasyonu
Eğer sepetteki dükkan, Hoppa'nın aktif bir `FREE_DELIVERY` sistem kampanyasına dahil edilmişse (ya da kampanya genel ise ve `allowedShops` boşsa) teslimat ücreti sıfırlanacaktır:

```typescript
// CampaignService içindeki calculateDeliveryFee metodu güncellemesi:
const freeDeliveryCampaigns = await prisma.campaign.findMany({
  where: {
    discountType: "FREE_DELIVERY",
    isActive: true,
    OR: [
      { finishDate: null },
      { finishDate: { gte: new Date() } }
    ]
  },
  include: {
    allowedShops: true
  }
});

for (const camp of freeDeliveryCampaigns) {
  // Eğer kampanya tüm dükkanlar için geçerliyse (allowedShops boşsa) 
  // ya da sepet dükkanı allowedShops listesinde tanımlanmışsa kampanya uygulanır.
  const isShopAllowed = camp.allowedShops.length === 0 || 
                         camp.allowedShops.some(cs => cs.shopId === shop.id);
  
  if (isShopAllowed) {
    // Kullanıcının sipariş sınırına ulaşıp ulaşmadığı kontrol edilir...
    return { fee: 0.0, isCampaignApplied: true, campaignName: camp.title };
  }
}
```

---

## 6. Mobil Uygulama (Consumer App) Entegrasyonu
* `HoppaCampaignSlider` ve `PromoSlider` tek bir provider üzerinden (`activeCampaignsProvider`) beslenecektir.
* Eğer reklam/afiş tıklandığında `externalUrl` doluysa, tarayıcıda açılacak veya webview'a yönlendirilecektir.
* `shopId` doluysa doğrudan ilgili dükkanın detayına yönlendirilecektir.
* Sistemsel bir kampanya ise kampanya detay sayfası açılacaktır.

---

## 7. Migration Stratejisi
1. **Şema Güncellemesi:** Prisma şemasına yeni alanlar eklenecek, `ShopCampaign` modeli kaldırılacak (veya veriler migration öncesi yedeklenecektir).
2. **Veri Migration Scripti:** Mevcut `ShopCampaign` kayıtları otomatik olarak `Campaign` tablosuna `type = "SHOP"` ve `status = "APPROVED"` olarak aktarılacaktır. Mevcut `Campaign` kayıtları `type = "SYSTEM"` olarak güncellenecektir.
3. **Database Push:** `npx prisma db push` ile veritabanı güncellenecektir.

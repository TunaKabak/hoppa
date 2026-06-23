Epic: Delivery Pricing & Campaign Engine
Task: Story 13 - Dinamik Teslimat Ücreti Modelleri ve "İlk 5 Sipariş Ücretsiz" Kampanya Altyapısı

DİKKAT (AGENT İÇİN): Bu görev .agent/rules (Sistem Anayasası) kurallarına kesinlikle tabidir. Adımları sırayla takip et, her adımın sonunda belirtilen doğrulama komutunu çalıştırarak başarıyı kanıtla ve hata alırsan çözmeden kesinlikle diğer adıma geçme!

🛠️ ADIM 1: Veritabanı Şeması Güncellemesi (Prisma)

backend/prisma/schema.prisma dosyasını aç.

Shop modelini esnetmek ve yeni Kampanya motorunu kurmak için şu tanımlamaları ekle:

Enum: DeliveryPricingType (FIXED, DISTANCE_BASED)

Enum: CampaignType (FREE_DELIVERY_FIRST_ORDERS, PERCENTAGE_DISCOUNT, FIXED_AMOUNT_DISCOUNT)

Shop Modeli Güncellemeleri:

deliveryPricingType (DeliveryPricingType @default(FIXED))

baseDeliveryFee (Float @default(30.0))

deliveryFeePerKm (Float @default(5.0))

freeDeliveryThreshold (Float?) // Ücretsiz teslimat için sepet limiti

minimumOrderAmount (Float @default(150.0))

Campaign Modeli:

id (String @id @default(uuid()))

title (String)

description (String)

type (CampaignType @default(FREE_DELIVERY_FIRST_ORDERS))

isActive (Boolean @default(true))

maxUsesPerUser (Int @default(5))

startDate (DateTime?)

endDate (DateTime?)

createdAt (DateTime @default(now()))

DOĞRULAMA KOMUTU:
cd backend && npx prisma db push && npx prisma generate
Hata almadığından emin ol.

🌱 ADIM 2: Veritabanı Tohumlama (Seeding)

backend/prisma/seed.ts dosyasını aç.

Tohumlama (Seed) verilerine şunları ekle:

Aktif bir FREE_DELIVERY_FIRST_ORDERS kampanyası (maxUsesPerUser: 5 olacak şekilde).

Mevcut "Test Kebap" dükkanına minimumOrderAmount: 150.0, baseDeliveryFee: 30.0 ve freeDeliveryThreshold: 500.0 değerlerini tanımla.

DOĞRULAMA KOMUTU:
cd backend && npx prisma db seed
Tohumlama işleminin başarıyla tamamlandığını gör.

🧠 ADIM 3: Backend Kampanya Servisi ve Sipariş Entegrasyonu

backend/src/services/CampaignService.ts dosyasını oluştur ve calculateDeliveryFee metodunu kodla. Bu metod:

Kullanıcının başarılı/tamamlanmış sipariş sayısını kontrol etmeli.

Eğer kampanya aktifse ve kullanıcının başarılı sipariş sayısı 5'ten az ise teslimat ücretini 0 döndürmeli.

Kampanya sınırları dışındaysa, dükkanın sabit veya mesafeli ücret kurallarını (ve varsa sepet ücretsiz limitini) uygulayarak nihai tutarı hesaplamalı.

OrderController.ts içindeki sipariş oluşturma metodunu güncelle. Teslimat ücretini (deliveryFee) artık istemciden (frontend) doğrudan güvenmek yerine backend'de CampaignService üzerinden hesapla ve sipariş kaydına yaz.

DOĞRULAMA KOMUTU:
cd backend && npx tsc --noEmit
TypeScript derleme hatası olmadığını kanıtla.

📱 ADIM 4: Tüketici (Consumer) Sepet Detay ve İlerleme Çubuğu (Progress Bar)

Tüketici uygulamasının sepet / ödeme özet sayfalarını (cart_page.dart veya ilgili özet ekranı) aç.

Dükkanın minimum sepet tutarı (minimumOrderAmount) kontrolünü ekle. Kullanıcı limitin altındaysa sipariş onay butonunu gri yap ve uyarı göster.

Eğer dükkanın freeDeliveryThreshold (Ücretsiz teslimat limiti) değeri varsa:

Sepet detayına dinamik bir İlerleme Çubuğu (Progress Bar) ekle.

"Ücretsiz teslimat için sepetinize X TL değerinde daha ürün ekleyin!" yazısını ve doluluk çubuğunu göster.

DOĞRULAMA KOMUTU:
cd apps/consumer_app && flutter analyze

🏷️ ADIM 5: Kampanya Şeffaflığı ve Ücretsiz Teslimat Gösterimi

Ödeme özeti ekranındaki "Teslimat Ücreti" satırını güncelle.

Eğer kullanıcının ilk 5 sipariş hakkı devam ediyorsa ve teslimat ücretsiz olduysa:

Teslimat ücretinin üzerini çiz (~~30.00 TL~~).

Yanına şık, yeşil renkli bir kampanya etiketi ekle: "Hoppa Özel: İlk 5 Sipariş Bedava (0 TL)".

Değişikliklerin hem görsel hem de matematiksel olarak toplam tutara (totalAmount) doğru şekilde yansıdığını doğrula.

DOĞRULAMA KOMUTU:
cd apps/consumer_app && flutter analyze
Tüm analiz uyarılarının temizlendiğinden emin ol.

📢 RAPORLAMA

Tüm geliştirmeler bittiğinde, veri şeması ekran çıktılarını, dinamik teslimat hesaplama test loglarını ve Flutter tarafındaki yeşil kampanya etiketi görsel kurgusunu bana raporla.
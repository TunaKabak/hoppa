Epic: Push Notifications Entegrasyonu
Task: Story 15 - Firebase Cloud Messaging (FCM) Altyapısının Kurulması

DİKKAT (AGENT İÇİN): Bu görev .agent/rules (Sistem Anayasası) kurallarına harfiyen uymalıdır. Mevcut çalışan hiçbir iş mantığına zarar vermeden, asenkron ve modüler bir mimari kurgula.

🛠️ ADIM 1: Veritabanı Şeması Güncellemesi (Prisma)

Kullanıcıların birden fazla cihazda aktif olabileceğini göz önünde bulundurarak, DeviceToken tablosunu bire-çok (One-to-Many) ilişki ile şemaya ekleyeceğiz.

backend/prisma/schema.prisma dosyasını aç.

User modeline deviceTokens DeviceToken[] ilişkisini ekle.

Aşağıdaki yeni DeviceToken modelini tanımla:

model DeviceToken {
  id        String   @id @default(uuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  token     String   @unique
  platform  String   // "ANDROID" veya "IOS"
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  @@index([userId])
}


DOĞRULAMA KOMUTU:
cd backend && npx prisma db push && npx prisma generate
Hata almadığından emin ol.

⚙️ ADIM 2: Firebase Admin SDK Kurulumu ve Notification Service (Backend)

backend dizininde terminale giderek gerekli resmi Firebase kütüphanesini yükle:
npm install firebase-admin

backend/src/services/NotificationService.ts dosyasını oluştur ve firebase-admin ilklendirmesini yap.

Belirli bir userId parametresine bağlı tüm aktif cihaz token'larını sorgulayan ve bunlara sendEachForMulticast yöntemiyle asenkron bildirim gönderen sendToUser metodunu yaz.

Geçersiz/süresi geçmiş token'ları otomatik temizleyen (cleanup) hata yakalama mekanizmasını kur.

DOĞRULAMA KOMUTU:
cd backend && npx tsc --noEmit

🛣️ ADIM 3: Cihaz Token Kayıt API'si ve Endpoint Entegrasyonu

Kullanıcılar uygulamaya giriş yaptığında cihazlarından aldıkları benzersiz FCM token'ını backend'e kaydetmelidir.

backend/src/controllers/NotificationController.ts dosyasını oluştur.

POST /api/notifications/register-token endpoint'ini kodla. Bu endpoint, gelen istekteki token'ı veritabanında upsert yöntemiyle kaydetmeli veya güncellemelidir (böylece mükerrer kayıtlar önlenir).

Auth Middleware'i korumalı rota olarak bu endpoint'e bağla.

DOĞRULAMA KOMUTU:
cd backend && npx tsc --noEmit

📱 ADIM 4: Mobil Uygulamalar Cihaz İzinleri ve Token Kayıt Akışı (Flutter)

Aynı mantığı hem consumer_app hem de merchant_app için uygulayacağız.

pubspec.yaml dosyalarına gerekli bağımlılıkları ekle:

firebase_core

firebase_messaging

flutter_local_notifications (Ön planda şık heads-up banner'lar gösterebilmek için)

Uygulama açılışında FirebaseMessaging.instance.requestPermission() ile kullanıcıdan bildirim izinlerini iste.

Alınan FCM token'ını, kullanıcının başarılı login işleminden sonra backend'deki POST /api/notifications/register-token endpoint'ine göndererek veritabanına kaydet.

DOĞRULAMA KOMUTU:
flutter analyze çalıştırarak her iki uygulamadaki kodları doğrula.

🚨 ADIM 5: Sipariş Tetikleyici Olayların Bildirime Bağlanması

Sipariş durum değişikliklerinde bildirimlerin otomatik gitmesini sağlayacağız.

backend/src/controllers/OrderController.ts dosyasındaki durum değiştirme (PATCH /api/orders/:id/status) metodunu bul.

Sipariş her onaylandığında, yola çıktığında veya iptal edildiğinde NotificationService.sendToUser fonksiyonunu asenkron olarak tetikle.

Örn: Sipariş yola çıktığında tüketiciye: "Kuryemiz Yola Çıktı! 🛵 Siparişiniz sıcak sıcak geliyor." bildirimi gönderilmeli.

DOĞRULAMA KOMUTU:
cd backend && npx tsc --noEmit
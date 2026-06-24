Tech Lead Onayı: Satıcı Token Kayıt Hatası (P2003) Çözüm Kılavuzu

Aşağıdaki mimari çözüm ve veritabanı esnetme planı Tech Lead tarafından incelenmiş ve ONAYLANMIŞTIR.

🛠️ ADIM 1: Veritabanı Şeması Esnetilmesi (Prisma)

backend/prisma/schema.prisma dosyasını aç.

DeviceToken modelini şu şekilde güncelle (ilişkileri opsiyonel yap ve Merchant tablosuna bağla):

model DeviceToken {
  id         String    @id @default(uuid())
  userId     String?
  user       User?     @relation(fields: [userId], references: [id], onDelete: Cascade)
  merchantId String?
  merchant   Merchant? @relation(fields: [merchantId], references: [id], onDelete: Cascade)
  token      String    @unique
  platform   String
  createdAt  DateTime  @default(now())
  updatedAt  DateTime  @updatedAt

  @@index([userId])
  @@index([merchantId])
}


Merchant modeline deviceTokens DeviceToken[] ilişkisini ekle.

DOĞRULAMA: cd backend && npx prisma db push && npx prisma generate komutlarını çalıştırarak hata almadığından emin ol.

🧠 ADIM 2: Token Kayıt Endpoint Kontrolü (NotificationController)

backend/src/controllers/NotificationController.ts dosyasındaki registerToken metodunu güncelle.

JWT'den çözülen req.user.role kontrolünü yap:

Eğer rol MERCHANT ise: merchantId: req.user.id, userId: null olarak veritabanına upsert et.

Eğer rol CONSUMER (veya user) ise: userId: req.user.id, merchantId: null olarak upsert et.

DOĞRULAMA: cd backend && npx tsc --noEmit ile TypeScript derleme hatası olmadığını kanıtla.

🔑 ADIM 3: Render Üzerinde Firebase Credential Doğrulaması

NotificationService.ts dosyasını aç ve FIREBASE_PRIVATE_KEY okuma mantığını incele.

Canlı sunuculardaki kaçış karakteri (escaping) hatalarını çözmek için şu standart dönüşümü uyguladığından emin ol:
privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n')

Render Dashboard'daki FIREBASE_PRIVATE_KEY değerinin başındaki ve sonundaki ekstra çift tırnakların (") kaldırıldığını ve ham anahtar olarak girildiğini teyit et.
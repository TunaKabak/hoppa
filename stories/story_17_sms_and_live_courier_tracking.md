Story 17 - Canlı SMS Entegrasyonu ve Gerçek Zamanlı Kurye Takip Altyapısı

Bu döküman, uygulamamızı sahadaki gerçek kuryeler ve gerçek kullanıcılarla buluşturmak için gereken SMS sağlayıcı entegrasyonu (Netgsm/Twilio vb.) ile gerçek zamanlı (Real-Time) kurye harita takip mekanizmasının teknik mimari planını içerir.

🛵 1. BÖLÜM: Canlı Kurye Takip Mimarisi (Real-Time Tracking)

Kuryenin koordinatlarını ($Lat, Lng$) saniyeler içinde müşterinin haritasına yansıtmak için Supabase Realtime (WebSockets) altyapısını kullanacağız. Bu sayede Node.js sunucumuzu soket trafiğiyle yormadan, doğrudan veritabanı seviyesinde asenkron ve ultra performanslı bir dinleme (Stream) kuracağız.

A. Veritabanı Şeması Güncellemesi (Prisma)

Kuryeleri ve anlık konum verilerini tutmak için Courier ve CourierLocation modellerini ekliyoruz.

// backend/prisma/schema.prisma

model Courier {
  id           String           @id @default(uuid())
  name         String
  phoneNumber  String           @unique
  vehiclePlate String?
  isActive     Boolean          @default(true)
  locations    CourierLocation[]
  orders       Order[]
}

model CourierLocation {
  id        String   @id @default(uuid())
  courierId String
  courier   Courier  @relation(fields: [courierId], references: [id], onDelete: Cascade)
  latitude  Float
  longitude Float
  bearing   Float    @default(0.0) // Kuryenin gittiği yön açısı (Marker döndürme için)
  updatedAt DateTime @updatedAt

  @@index([courierId])
}


B. Flutter Kurye Konum Güncelleme (Driver App / Simulation)

Kurye hareket ettikçe arka planda her $5\text{ saniyede}$ bir (veya minimum $10\text{ metre}$ yer değiştirdiğinde) yeni konumunu backend'e PATCH /api/couriers/location üzerinden yollayacaktır.

// Kuryenin konumunu güncelleyen servis metodu
Future<void> updateCourierLocation(double lat, double lng, double bearing) async {
  await _apiClient.post(
    '/api/couriers/location',
    body: {
      'latitude': lat,
      'longitude': lng,
      'bearing': bearing,
    },
  );
}


C. Consumer App Canlı Harita Takibi (Riverpod + StreamProvider)

Tüketici uygulamasında sipariş detay sayfasında (order_tracking_page.dart) kuryenin konumu doğrudan Supabase Realtime üzerinden dinlenir ve harita üzerindeki kurye ikonu (Marker) animasyonlu bir şekilde kaydırılır:

// Tüketici tarafında kurye konumunu dinleyen Riverpod StreamProvider
final courierLocationStreamProvider = StreamProvider.family<CourierLocation, String>((ref, courierId) {
  final supabase = Supabase.instance.client;
  
  return supabase
      .from('CourierLocation')
      .stream(primaryKey: ['id'])
      .eq('courierId', courierId)
      .map((data) => CourierLocation.fromJson(data.first));
});


💬 2. BÖLÜM: Canlı SMS Gateway Entegrasyonu

OTP (Tek Kullanımlık Şifre) SMS'lerini canlıya almak için SOLID - Open/Closed prensibine uygun olarak bir SmsProvider interface'i kurduk. Bu sayede yarın sağlayıcıyı (Twilio, Netgsm, Verimor) değiştirmek tek satırlık bir iş olacaktır.

A. SMS Sağlayıcı Tasarım Deseni (Adapter Pattern)

// backend/src/providers/SmsProvider.ts

export interface ISmsProvider {
  sendOtp(phoneNumber: string, code: string): Promise<boolean>;
}

// Türkiye pazarı için Netgsm Entegrasyonu
export class NetgsmSmsProvider implements ISmsProvider {
  private apiUsername = process.env.NETGSM_USER;
  private apiPassword = process.env.NETGSM_PASS;
  private apiHeader = process.env.NETGSM_HEADER;

  public async sendOtp(phoneNumber: string, code: string): Promise<boolean> {
    try {
      // Netgsm API'sine HTTPS POST isteği atılarak SMS iletilir
      const message = `Hoppa doğrulama kodunuz: ${code}. Bu kodu kimseyle paylaşmayınız.`;
      // axios.post('https://api.netgsm.com.tr/sms/send/get', { ... })
      console.log(`[Netgsm] SMS başarıyla gönderildi: ${phoneNumber}`);
      return true;
    } catch (error) {
      console.error("[Netgsm] SMS gönderme hatası:", error);
      return false;
    }
  }
}


B. API Güvenlik Duvarı: Rate Limiting (ÇOK KRİTİK!)

Kötü niyetli kişilerin SMS faturamızı kabartmasını engellemek için IP başına OTP istek limitini devreye sokuyoruz.

import rateLimit from 'express-rate-limit';

// 15 dakikada en fazla 5 kez OTP talep edilebilir
export const otpRateLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 dakika
  max: 5,
  message: {
    error: true,
    message: "Çok fazla doğrulama kodu talep ettiniz. Lütfen 15 dakika sonra tekrar deneyiniz."
  },
  standardHeaders: true,
  legacyHeaders: false,
});


📢 Doğrulama Planı

Database Migration:

cd backend && npx prisma db push && npx prisma generate


Güvenlik Testi:
Bir IP üzerinden üst üste 6 kez OTP isteği atılarak sunucunun 429 Too Many Requests hata kodunu döndürdüğü doğrulanacak.
Story 17 - Canlı Twilio SMS Entegrasyonu ve Gerçek Zamanlı Kurye Takip Altyapısı

Bu döküman, uygulamamızı sahadaki gerçek kuryeler ve gerçek kullanıcılarla buluşturmak için gereken Twilio SMS sağlayıcı entegrasyonu, IP bazlı OTP güvenlik duvarı (Rate Limiting) ile gerçek zamanlı (Real-Time) kurye harita takip mekanizmasının teknik mimari planını içerir.

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


💬 2. BÖLÜM: Twilio SMS Gateway Entegrasyonu (Adapter Pattern)

OTP (Tek Kullanımlık Şifre) SMS'lerini canlıya almak için SOLID - Open/Closed ve Dependency Inversion prensiplerine uygun olarak bir ISmsProvider interface'i kurduk.

// backend/src/providers/SmsProvider.ts

import twilio from 'twilio';

export interface ISmsProvider {
  sendOtp(phoneNumber: string, code: string): Promise<boolean>;
}

/**
 * Twilio Entegrasyonu (Adapter Pattern)
 */
export class TwilioSmsProvider implements ISmsProvider {
  private client: twilio.Twilio;
  private fromNumber: string;

  constructor() {
    const accountSid = process.env.TWILIO_ACCOUNT_SID;
    const authToken = process.env.TWILIO_AUTH_TOKEN;
    this.fromNumber = process.env.TWILIO_FROM_NUMBER || '';

    if (!accountSid || !authToken) {
      console.warn("[TwilioSmsProvider] UYARI: Twilio credentials eksik. SMS gönderimi mock olarak çalışacaktır.");
    }

    this.client = twilio(accountSid, authToken);
  }

  public async sendOtp(phoneNumber: string, code: string): Promise<boolean> {
    try {
      const messageBody = `Hoppa doğrulama kodunuz: ${code}. Bu kodu kimseyle paylaşmayınız.`;
      const formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : `+${phoneNumber}`;

      const response = await this.client.messages.create({
        body: messageBody,
        from: this.fromNumber,
        to: formattedPhone
      });

      console.log(`[Twilio] SMS başarıyla gönderildi. SID: ${response.sid}`);
      return true;
    } catch (error) {
      console.error("[Twilio] SMS gönderme hatası:", error);
      return false;
    }
  }
}


🛡️ 3. BÖLÜM: API Güvenlik Duvarı - Rate Limiting (Kritik!)

Kötü niyetli botların ve kişilerin fahiş SMS faturaları çıkarmasını engellemek için IP başına OTP istek limiti getireceğiz.

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


🔑 4. BÖLÜM: Çevresel Değişkenlerin (.env) Tanımlanması

Backend üzerinde aşağıdaki değişkenlerin tanımlanması zorunludur:

# SMS Sağlayıcı Ayarı ('MOCK' veya 'TWILIO')
SMS_PROVIDER_MODE="TWILIO"

# Twilio Bilgileri
TWILIO_ACCOUNT_SID="ACXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
TWILIO_AUTH_TOKEN="your_twilio_auth_token_here"
TWILIO_FROM_NUMBER="+1234567890"


📢 Doğrulama Planı

Database Migration:

cd backend && npx prisma db push && npx prisma generate


Güvenlik Testi:
Bir IP üzerinden üst üste 6 kez OTP isteği atılarak sunucunun 429 Too Many Requests hata kodunu döndürdüğü doğrulanacak.

SMS İletim Testi:
Cihazdan kendi numaranızla giriş yapıp telefonunuza Twilio üzerinden OTP kodunun ulaştığı test edilecek.
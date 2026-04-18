MİMARİ BAĞLAM VE SİSTEM TASARIMI (ARCHITECTURE CONTEXT)

1. Proje Özeti

Bu proje, "Merchant" (Satıcı) ve "Consumer" (Tüketici) olmak üzere iki farklı mobil uygulamayı barındıran bir Flutter Monorepo projesidir. Sistem, ölçeklenebilirlik, veri bütünlüğü ve maliyet optimizasyonu (özellikle yüksek SMS/OTP maliyetleri) amacıyla Firebase ekosisteminden çıkartılmış ve tamamen bağımsız, özel bir Backend (Custom Backend) mimarisine taşınmıştır.

2. Teknoloji Yığını (Tech Stack)

Mobil İstemci (Frontend)

Framework: Flutter (Monorepo Mimarisi)

Ağ (Network): Dart standart http paketi (Özelleştirilmiş ApiClient sarmalayıcısı ile)

Durum Yönetimi (State Management): BLoC / Riverpod / Provider (Projeye göre uyarlanacak)

Sunucu ve İş Mantığı (Backend)

Çalışma Zamanı (Runtime): Node.js

Dil: TypeScript (Sıkı tip güvenliği - Strict Mode)

API Katmanı: Express.js veya Fastify

Veritabanı: PostgreSQL (İlişkisel ve ACID uyumlu)

ORM: Prisma ORM

Altyapı ve Dağıtım (Infrastructure)

Test/Staging Ortamı: Railway.app veya Supabase

Konteynerizasyon: Docker

3. Dizin Yapısı (Monorepo Directory Structure)

Proje, kod tekrarını (DRY) önlemek adına modüler bir yapıda tasarlanmıştır:

/
├── apps/
│   ├── consumer_app/         # Tüketici UI, Route ve Spesifik State
│   └── merchant_app/         # Satıcı UI, Route ve Spesifik State
├── packages/
│   ├── core_auth/            # Oturum yönetimi, OTP süreçleri ve Token saklama (Ortak)
│   ├── core_network/         # 'http' paketini sarmalayan ApiClient ve Interceptor (Ortak)
│   └── ui_components/        # Temel UI bileşenleri (Butonlar, Inputlar, Temalar)
└── backend/
    ├── prisma/
    │   └── schema.prisma     # Veritabanı şema tanımları
    └── src/
        ├── controllers/      # HTTP İstek/Yanıt yönetimi
        ├── services/         # Ana iş mantığı (OtpService, AuthService)
        ├── providers/        # Dış servis entegrasyonları (MockSmsProvider, RealSmsProvider)
        └── utils/            # Yardımcı fonksiyonlar (Logger, ErrorHandler)


4. Temel Geliştirme Prensipleri (Kurallar)

AI Agent'lar ve geliştiriciler kod yazarken aşağıdaki prensiplere kesinlikle uymalıdır:

DRY (Don't Repeat Yourself): Merchant ve Consumer uygulamalarının ortak kullandığı her türlü iş mantığı (API istekleri, modeller, yetkilendirme) packages/ altındaki ilgili core modülünde yazılacaktır.

SOLID: Sınıflar arası bağımlılıklar somut sınıflar (Concrete Classes) üzerinden değil, her zaman arayüzler (Interfaces/Abstract Classes) üzerinden sağlanacaktır.

Güvenlik (Security-First): OTP üretimi kriptografik olarak güvenli kütüphanelerle yapılacak, DB sorgularında her zaman ORM kullanılarak SQL Injection önlenecek, rate-limiting (hız sınırlaması) uygulanacaktır.

Error Handling (Hata Yönetimi): Hiçbir try-catch bloğu boş bırakılmayacaktır. Backend her zaman standart bir hata formatı dönmeli { error: true, message: "..." } ve Flutter tarafı bu formatı merkezi ApiClient içinde yakalayıp UI'a Exception olarak fırlatmalıdır.

5. Backend Mimarisi: OTP ve Kimlik Doğrulama

Sistem, pahalı SMS doğrulama adımlarını izole etmek için Strategy Design Pattern kullanır.

5.1. Veritabanı Modeli (Prisma)

OTP kodları, süresi dolduğunda veya kullanıldığında imha edilmek üzere PostgreSQL'de tutulur.

model OtpCode {
  id          String   @id @default(uuid())
  phoneNumber String   @unique // Aynı numaraya aynı anda tek geçerli kod gidebilir
  code        String
  expiresAt   DateTime // Geçerlilik süresi (Örn: +3 dakika)
  createdAt   DateTime @default(now())

  @@index([phoneNumber])
}


5.2. Strategy Pattern ile SMS Yönetimi

Dışa bağımlılığı azaltmak için SMS gönderimi ISmsProvider arayüzü ile soyutlanmıştır. Ortam değişkeni SMS_PROVIDER_MODE değerine göre:

MOCK Modu: MockSmsProvider çalışır. SMS atmaz, kodu terminale/loga basar. Maliyetsiz geliştirme sağlar.

REAL Modu: RealSmsProvider çalışır. Yerel SMS API'sine HTTP isteği atar (Netgsm, Twilio vb.).

5.3. Whitelist (Beyaz Liste) Mantığı

Apple App Store ve Google Play Store inceleme (Review) süreçleri için .env dosyasında test numaraları tutulur:

TEST_PHONE_NUMBERS="+905550000000"

TEST_OTP_CODE="123456"
Sistem bu numaralardan bir talep aldığında SMS API'sini baypas eder ve doğrudan sabit kodu doğrular.

6. Frontend Mimarisi: Ağ (Network) Katmanı

Flutter tarafında http paketi doğrudan UI veya Repository katmanında kullanılamaz. Her ağ isteği packages/core_network içindeki ApiClient üzerinden geçmek zorundadır.

6.1. ApiClient Beklentileri

Token Enjeksiyonu: Oturum açıldıktan sonra alınan JWT/Session Token, SharedPreferences veya SecureStorage'dan okunarak her isteğin Authorization header'ına otomatik eklenir.

401 Unauthorized Yönetimi: Eğer sunucu 401 dönerse, ApiClient oturumu otomatik olarak sonlandırma (Logout) event'i tetiklemelidir.

Merkezi Hata Formatlama: Gelen başarısız HTTP durum kodları (4xx, 5xx), özel bir ServerException veya NetworkException sınıfına dönüştürülür.

6.2. AuthRepository (Flutter İş Mantığı)

// Bağımlılıkların soyutlanması
abstract class IAuthRepository {
  Future<void> requestOtp(String phoneNumber);
  Future<bool> verifyOtp(String phoneNumber, String code);
}


AuthRepository sınıfı, ApiClient'ı kullanarak backend ile haberleşir. Asla UI katmanıyla doğrudan konuşmaz, sadece veriyi (veya Exception'ı) State Management katmanına iletir.

7. Dağıtım ve DevOps

Tüm backend servisleri Dockerfile kullanılarak konteynerize edilecektir.

Çevresel Değişkenler (.env) asla kaynak kod deposuna (Git) commit edilmeyecektir (Örnek şablon için .env.example dosyası kullanılacaktır).

Veritabanı şema değişiklikleri sadece npx prisma migrate komutları üzerinden yapılacak ve migration dosyaları versiyonlanacaktır.
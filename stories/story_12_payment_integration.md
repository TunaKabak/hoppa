Story 12 - Ödeme Entegrasyonu ve Hibrit Online Ödeme Altyapısı

Bu döküman; KKTC yerel kartları (Cardplus, Optimal vb.), Türkiye banka/kredi kartları (Troy dahil) ve yurt dışı kredi kartlarının (Visa, Mastercard, AMEX) sistem üzerinden sorunsuz ve kesintisiz şekilde tahsil edilebilmesini sağlayan "Akıllı Kart Yönlendirme" (Smart BIN Routing) mimarisini içerir.

1. Hibrit Ödeme ve Akıllı Yönlendirme (Smart Routing) Mimarisi

Kullanıcının girdiği kart tipine göre sistemin otomatik olarak en doğru ve en düşük komisyonlu ödeme geçidine (Gateway) yönlendirilmesi işlemine Akıllı Yönlendirme denir. Bu sistem üç sac ayağından oluşur:

A. Kart Tiplerinin Dağılımı ve Yönetimi

KKTC Yerel Kartları (Cardplus / Optimal): * KKTC yerel bankalarının (İktisat, Near East, Kooperatif vb.) çıkardığı kartlardır.

Bu kartlar yerel poslarda sıfır komisyon, taksitlendirme ve puan avantajı sunar. Ancak uluslararası geçitlerde bazen "Cross-border" veya "3D Secure v2" uyumsuzluğu nedeniyle reddedilebilir.

Türkiye Cumhuriyeti Kartları (PayTR / iyzico):

Troy, Visa, Mastercard logolu tüm Türkiye kartlarıdır. PayTR Sandbox/Canlı API ile doğrudan tam uyumlu ve en yüksek geçiş oranına sahiptir.

Yurt Dışı / Uluslararası Kartlar (Stripe veya PayTR International):

Euro, Dolar veya Sterlin limitli yabancı kartlardır. Bu kartların çekiminde 3DSv2 (Secure Customer Authentication - SCA) protokolü zorunludur.

B. Akıllı BIN Sorgulama (BIN-Based Routing) Akışı

Kullanıcı kart numarasının ilk 6 ila 8 hanesini (BIN numarası) girdiğinde, sistem arka planda bu kartın hangi ülkeye ve hangi bankaya ait olduğunu sorgular:

$$\text{Kart Numarası (16 Hane)} \longrightarrow \underbrace{\text{[ 4543 60 ]}}_{\text{BIN (6 Hane)}} \longrightarrow \text{Sistem Sorgusu (Local/API BIN Database)}$$

[Kullanıcı Kart Bilgisini Girer]
          │
          ▼
[İlk 6 Haneden BIN Analizi Yapılır]
          │
          ├──► Eğer KKTC Yerel Kartı (Cardplus BIN) ise:
          │    └──► Cardplus VPOS API'sine yönlendir (Yerel komisyon avantajı & taksit).
          │
          ├──► Eğer Türkiye Kartı veya Standart Kart ise:
          │    └──► PayTR Standard VPOS API'sine yönlendir (Mükemmel 3D Secure akışı).
          │
          └──► Eğer Yurt Dışı Kartı (Döviz limitli) ise:
               └──► PayTR International veya Stripe API'sine yönlendir (Döviz çevrimli 3DSv2).


2. Çoklu Para Birimi (Multi-Currency) ve Güvenlik Protokolleri

Yurt dışı kartlarından yapılacak tahsilatlarda, dükkan fiyatları Türk Lirası (TRY) olsa bile yabancı kart sahibine kendi para biriminde (GBP, EUR, USD) şeffaf bir ödeme deneyimi sunulmalıdır.

A. Dinamik Kur Dönüşüm Oranı (DCC - Dynamic Currency Conversion)

Sistem, yurt dışı kartı algıladığında merkez bankası kurları üzerinden anlık dönüşüm yapar. Ödeme işleminde kullanılacak kur formülü:

$$\text{Ödenecek Tutar (Yabancı Para)} = \frac{\text{Sipariş Tutarı (TRY)}}{\text{Güncel Satış Kuru}} \times (1 + \text{DCC Tolerans Marjı})$$

Buradaki tolerans marjı (genellikle %1 - %2), bankalar arası takas sırasındaki anlık kur dalgalanmalarından doğabilecek zararları önlemek amacıyla backend tarafından dinamik olarak eklenir.

B. PCI-DSS ve Tokenization Güvenlik Standartları

Sistemimizin küresel güvenlik standartlarına uyması için kart verileri asla veritabanımıza uğramaz.

Tokenization: Kart bilgileri kullanıcının ekranından doğrudan şifreli SSL tüneli ile PayTR/Cardplus sunucularına iletilir. Sunucu bize tek kullanımlık bir payment_token üretir. Biz siparişi bu token ile onaylarız.

3. Veritabanı Şeması Güncellemesi (Prisma)

Akıllı yönlendirmeyi ve çoklu para birimini desteklemek üzere backend/prisma/schema.prisma dosyamızı aşağıdaki gibi güncelliyoruz:

// Ödeme Yöntemleri
enum PaymentMethod {
  CASH_ON_DELIVERY   // Kapıda Nakit
  CARD_ON_DELIVERY   // Kapıda Kart
  ONLINE_PAYMENT     // Online Kredi/Banka Kartı
}

// Ödeme Durumları
enum PaymentStatus {
  PENDING            // Ödeme Bekliyor (3D secure aşaması vb.)
  SUCCESS            // Ödeme Başarılı
  FAILED             // Ödeme Başarısız
  REFUNDED           // İade Edildi
}

// Desteklenen Para Birimleri
enum Currency {
  TRY
  GBP
  EUR
  USD
}

// Sipariş Tablosu Güncellemesi
model Order {
  id            String        @id @default(uuid())
  // ... diğer mevcut alanlar ...
  paymentMethod PaymentMethod @default(CASH_ON_DELIVERY)
  paymentStatus PaymentStatus @default(PENDING)
  
  // İlişkiler
  payments      PaymentTransaction[]
}

// Gelişmiş Ödeme İşlem Takip Tablosu
model PaymentTransaction {
  id             String        @id @default(uuid())
  orderId        String
  order          Order         @relation(fields: [orderId], references: [id])
  amount         Float         // İşlem tutarı (Örn: 120.50)
  currency       Currency      @default(TRY) // İşlem para birimi
  exchangeRate   Float         @default(1.0) // İşlem anındaki kur dönüşüm katsayısı
  provider       String        // Örn: "PAYTR", "CARDPLUS", "STRIPE"
  routingType    String        // Örn: "LOCAL_BIN", "DOMESTIC_TRY", "INTERNATIONAL_GBP"
  merchantId     String        // Ödemeyi alan dükkanın ID'si
  providerTxId   String?       @unique // Ödeme sağlayıcısının benzersiz işlem referans ID'si
  status         PaymentStatus @default(PENDING)
  errorMessage   String?       // Başarısız olduysa dönen detaylı hata
  createdAt      DateTime      @default(now())
  updatedAt      DateTime      @updatedAt

  @@index([orderId])
}


4. Backend Akıllı Yönlendirme Servisi (TypeScript)

Aşağıdaki mimari, backend tarafında kartın BIN değerine göre otomatik sağlayıcı ve yönlendirme seçimi yapan akıllı yapıdır.

// backend/src/services/PaymentRoutingService.ts
import { Currency, PaymentStatus } from '@prisma/client';

export interface CardDetails {
  number: string; // İlk 6-8 hanesi yeterli
  holderName: string;
}

export interface RouteDecision {
  provider: 'PAYTR' | 'CARDPLUS' | 'STRIPE';
  currency: Currency;
  routingType: string;
  conversionRate: number;
}

export class PaymentRoutingService {
  /**
   * Kartın BIN değerine göre en verimli ödeme sağlayıcısını seçer.
   */
  public static routePayment(cardNumber: string, orderTotalTry: number): RouteDecision {
    const bin = cardNumber.replace(/\s+/g, '').substring(0, 6);

    // 1. KKTC Bankaları BIN Listesi (Örnek Cardplus ve Optimal BIN Blokları)
    const kktcBinList = ['454360', '543771', '405820', '431411']; // Gerçek projede DB veya JSON'dan beslenir
    
    if (kktcBinList.includes(bin)) {
      return {
        provider: 'CARDPLUS',
        currency: Currency.TRY,
        routingType: 'LOCAL_KKTC_BIN',
        conversionRate: 1.0
      };
    }

    // 2. Yurt Dışı Kart Tespiti (Uluslararası BIN sorgusu API veya kural tabanlı)
    const isInternational = this.checkIfInternationalBin(bin);
    if (isInternational) {
      // Yurt dışı kartlar için kur çevrimi (Örn: Euro kartı için EUR dönüşümü)
      const eurRate = 35.50; // Gerçek projede canlı kur servisinden çekilir
      return {
        provider: 'PAYTR', // PayTR international veya Stripe
        currency: Currency.EUR,
        routingType: 'INTERNATIONAL_SCA',
        conversionRate: eurRate
      };
    }

    // 3. Varsayılan Seçenek: Türkiye Cumhuriyeti Kartları
    return {
      provider: 'PAYTR',
      currency: Currency.TRY,
      routingType: 'DOMESTIC_TR_BIN',
      conversionRate: 1.0
    };
  }

  private static checkIfInternationalBin(bin: string): boolean {
    // Basit test mantığı: Belirli test blokları dışındaki yabancı serileri yakalar
    // Gerçek entegrasyonda ücretsiz BIN list API'leri (Örn: binlist.net) veya lokal DB kullanılır.
    return bin.startsWith('411111') || bin.startsWith('555555');
  }
}


5. Yol Haritası ve Test Planı

Adım 1: Mock Akıllı Yönlendirici (Mock Router) Entegrasyonu

Kullanıcı kart numarasını girerken ilk 6 haneye göre ekranda anında dinamik bir logo değişimi gösterilir (Örn: Cardplus logosu, Troy logosu veya Yurt dışı Visa logosu).

Backend simüle edilmiş BIN kararlarına göre CARDPLUS veya PAYTR loglarını oluşturarak test sürecini kesintisiz işletir.

Adım 2: 3D Secure Webview Entegrasyonu (Flutter)

Tüm sağlayıcılarda ortak olan paymentUrl (3D Secure doğrulama sayfası) Flutter tarafında güvenli bir WebView (flutter_inappwebview veya webview_flutter) yardımıyla kullanıcıya gösterilir.

Kullanıcı SMS şifresini girip onayladığında WebView başarıyla kapanır ve sipariş başarıyla tamamlanır.
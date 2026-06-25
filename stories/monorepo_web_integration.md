🌐 Hoppa Monorepo Web UI Entegrasyon ve Mimarisi Kılavuzu

Bu kılavuz, www.hoppanow.com adresi üzerinden yayın yapacak olan; Hoppa Tanıtım Sayfası (Landing Page), İşletme Giriş/Başvuru (Merchant Onboarding) ve Kurye Başvuru (Courier Application) ekranlarını barındıran Web UI projesini, Hoppa Monorepo yapısına en sağlıklı ve modüler şekilde entegre etmek için gereken tüm adımları içerir.

🧭 1. Web UI Rolleri ve Monorepo Avantajları

Web projemiz sadece statik bir tanıtım sitesi değil; operasyonel formları (İşletme Girişi, Kurye Başvurusu) yöneten ve backend API'mizle doğrudan konuşan aktif bir uygulamadır. Bu kodları monorepoda tutmak şu avantajları sağlar:

Ortak Model ve Tip Güvenliği: İşletme kayıt formu (MerchantOnboardingPayload) ve Kurye başvuru formu (CourierApplicationPayload) için backend Prisma modelleri ile web form validasyonlarını (örn: Yup, Zod veya TypeScript tipleri) tek bir çatı altında eşzamanlı güncelleyebilirsiniz.

Merkezi Güvenlik & CORS Yönetimi: www.hoppanow.com üzerinden gelecek başvuru isteklerinin backend tarafında güvenle karşılanabilmesi için CORS politikalarımızı tek merkezden yönetiriz.

Senkronize Sürümleme (Atomic commits): Web formundaki yeni bir alan (Örn: Ehliyet Tipi) ile backend veritabanı şemasındaki yeni bir kolon aynı commit ile canlıya alınır.

🗂️ 2. Hedef Klasör Yapısı (Directory Layout)

Web uygulamanızı monorepomuzun apps/ dizini altında web_app klasöründe konumlandıracağız:

/ (Monorepo Kök Dizini)
├── apps/
│   ├── consumer_app/         # Tüketici Mobil (Flutter)
│   ├── merchant_app/         # Satıcı Mobil (Flutter)
│   └── web_app/              # 👈 YENİ: [www.hoppanow.com](https://www.hoppanow.com) Kaynak Kodları
│       ├── package.json
│       ├── public/           # Logo, görseller, favicon vb.
│       ├── src/
│       │   ├── pages/        # Veya app/ klasör yapısı (Next.js/React)
│       │   │   ├── index.ts              # Hoppa Tanıtım Sayfası (Landing)
│       │   │   ├── merchant-onboard.ts   # İşletme Giriş / Kayıt Formu
│       │   │   └── courier-apply.ts      # Kurye Başvuru Formu
│       │   └── ...
│       └── .env.production   # Canlı ortam ayarları
├── packages/                 # Ortak Paketler
└── backend/                  # Node.js + Express + Prisma API (Render)


🛠️ 3. Adım Adım Entegrasyon Planı

ADIM 1: Klasörü Oluşturma ve Kodları Taşıma

Monorepo kök dizininde apps/ klasörünün altına web_app adında yeni bir klasör açın.

Hazırladığınız web projesinin tüm kaynak kodlarını (src, package.json, public, config dosyaları vb.) bu yeni klasörün içine taşıyın (Kendi içindeki .git ve node_modules klasörlerini sildiğinizden emin olun).

ADIM 2: API URL ve Çevre Değişkenleri Konfigürasyonu

Web uygulamanızın form verilerini backend sunucunuza gönderebilmesi için API adresini çevre değişkenlerinde tanımlayın:

apps/web_app/.env.local (Yerel Test):

NEXT_PUBLIC_API_URL="http://localhost:3000"


apps/web_app/.env.production (Canlı Ortam):

NEXT_PUBLIC_API_URL="[https://hoppa-backend.onrender.com](https://hoppa-backend.onrender.com)"


🔌 4. Web-to-Backend API Kontratı ve CORS Güvenliği

Web uygulamasından gelen kayıt ve başvuru isteklerinin backend sunucumuz tarafından reddedilmemesi için yapılması gereken iki kritik ayar bulunmaktadır:

A. Backend CORS Ayarları (backend/src/index.ts Güncellemesi)

Sunucumuzun sadece mobil uygulamalardan değil, www.hoppanow.com adresinden gelen HTTP isteklerini de kabul etmesi için CORS ayarlarını sıkılaştırıyoruz:

// backend/src/index.ts dosyasında cors konfigürasyonunu güncelleyin:

const allowedOrigins = [
  'http://localhost:3000',                  // Lokal testler için
  '[https://www.hoppanow.com](https://www.hoppanow.com)',               // Canlı Web UI ana adresi
  '[https://hoppanow.com](https://hoppanow.com)'                    // www olmadan yönlendirme adresi
];

app.use(cors({
  origin: (origin, callback) => {
    // Mobil uygulamalar (origin null/undefined gönderebilir) veya izin verilen domainler
    if (!origin || allowedOrigins.indexOf(origin) !== -1) {
      callback(null, true);
    } else {
      callback(new Error('CORS Policy: Bu kök dizinden istek gönderilemez.'));
    }
  },
  credentials: true
}));


B. Başvuru Endpoint'lerinin Backend Rotalarına Bağlanması

Kurye ve İşletme başvurularını almak için backend tarafında şu iki rota ve denetleyici (Controller) yapısını kurgulamalıyız:

İşletme Ön Başvurusu: POST /api/merchant/onboard

Kurye Ön Başvurusu: POST /api/courier/apply

(Not: Bu iki endpoint ön başvuru olduğu için auth/token gerektirmemeli, halka açık olmalıdır).

🚀 5. www.hoppanow.com Canlıya Alma (Vercel) Stratejisi

Web uygulamasını en hızlı, ücretsiz ve otomatik (CD) şekilde Vercel veya Netlify üzerinde barındırabiliriz.

Vercel Proje Yapılandırma Adımları:

Vercel Dashboard'a gidin ve "Add New Project" butonuna basın.

Hoppa Monorepo GitHub deponuzu bağlayın.

Framework Preset: Kullandığınız teknolojiyi seçin (Örn: Next.js, React vb.).

Root Directory: Kesinlikle apps/web_app klasörünü hedefleyin.

Build & Development Settings: Varsayılan ayarlarda bırakın (Vercel otomatik derleyecektir).

Environment Variables: NEXT_PUBLIC_API_URL anahtarını ekleyin ve değer olarak https://hoppa-backend.onrender.com girin.

Custom Domain (www.hoppanow.com) Ayarları:

Proje Vercel'e deploy edildikten sonra Project Settings > Domains sekmesine gidin.

hoppanow.com ve www.hoppanow.com domainlerini ekleyin.

Domain sağlayıcınızın (Godaddy, Namecheap, Google Domains vb.) DNS yönetim paneline giderek Vercel'in size verdiği CNAME ve A kayıtlarını ekleyin:

Type A (@): 76.76.21.21 IP adresine yönlendirin.

CNAME (www): cname.vercel-dns.com adresine yönlendirin.

DNS yayılımı (propagation) tamamlandığında web siteniz SSL sertifikasıyla birlikte www.hoppanow.com üzerinden güvenle yayına girecektir!
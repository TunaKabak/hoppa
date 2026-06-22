Epic: Security & CI/CD Pipeline
Task: Hotfix - API Güvenlik Zafiyeti ve Kalıcı 500 Hatası (Veritabanı Senkronizasyonu)

DİKKAT (AGENT İÇİN): Bu çok kritik bir güvenlik ve altyapı görevidir. Kendi inisiyatifinle kod ekleme, sadece istenenleri harfiyen uygula.

ADIM 1: Güvenlik Temizliği (API Info Leak)

Backend API'sinin ana dizininde (/ veya /health) veritabanı URL'sinin veya çevre değişkenlerinin basıldığı tespit edildi. Bu KESİNLİKLE YASAKTIR.

backend/src/index.ts dosyasını aç.

/ veya /health rotasını bul. İçeriğini SADECE şu şekilde değiştir:

app.get('/health', (req: Request, res: Response) => {
    res.status(200).json({ status: "OK", timestamp: new Date() });
});


Eğer uygulamanın başka bir yerinde (örneğin loglarda) DATABASE_URL yazdırılıyorsa (şifresi gizlenmiş olsa bile) onu DERHAL SİL.

ADIM 2: Kalıcı 500 Hatası Çözümü (Oto-Veritabanı Senkronizasyonu)

Her deploy sonrası alınan 500 hatasının sebebi Prisma şemasının uzak DB ile senkronize olmamasıdır. Render.com build aşamasında bunu otomatik yapmalıdır.

backend/package.json dosyasını aç.

"scripts" objesinin içerisine şu özel build komutunu ekle (Eğer varsa mevcut build komutunu bununla değiştir):

"build": "npx prisma generate && npx prisma db push --accept-data-loss && npx tsc"


(Açıklama: Bu sayede Render.com her yeni kod geldiğinde önce veritabanındaki şema eksikliklerini otomatik giderecek, sonra kodu derleyecektir).

ADIM 3: AuthController Detaylı Hata Yakalama

Veritabanı veya başka bir sebeple 500 hatası alındığında sorunun ne olduğunu Render loglarında net görebilmemiz lazım.

backend/src/controllers/AuthController.ts dosyasını aç.

Hem requestOtp hem de verifyOtp metodlarındaki catch (error) bloklarını bul.

İçlerine şu detaylı loglamayı ekle:

console.error("[AuthController] Hata Detayı:", error instanceof Error ? error.message : error);


ADIM 4: Doğrulama

Bu değişiklikleri yaptıktan sonra terminalde cd backend && npm run build komutunu çalıştırarak sistemin hatasız derlendiğini teyit et ve raporla.
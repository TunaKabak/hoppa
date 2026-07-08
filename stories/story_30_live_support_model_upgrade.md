# Story 30: Canlı Destek Model Yükseltme ve Hata Giderme

## 1. Giriş ve Sorun Tanımı
Tüketici uygulamasında (**Consumer App**) yer alan "Canlı Destek Asistanı" (Hoppa Asistan) modülü çalışmamaktadır.
Yapılan analiz sonucunda backend API servisinin (`SupportController.chatWithAssistant`) Gemini API'ye bağlanırken `gemini-1.5-flash` modelini kullandığı, ancak mevcut API anahtarı veya servis sağlayıcı bölgesinde bu modelin desteklenmeyerek **404 Not Found** hatası döndürdüğü tespit edilmiştir.

## 2. Teknik Analiz ve Çözüm Planı
Gemini API `ListModels` sorgusu ile API anahtarının yetkili olduğu modeller listelenmiş ve aşağıdaki aktif modeller doğrulanmıştır:
- `models/gemini-2.5-flash` (Aktif & Önerilen)
- `models/gemini-2.0-flash`
- `models/gemini-3.5-flash`

Çözüm olarak, backend üzerindeki `SupportController.ts` dosyasında kullanılan kararlı model ismi `gemini-1.5-flash` yerine `gemini-2.5-flash` olarak güncellenecek, böylece asistanın Kıbrıslı kimliği ve sipariş bağlamı enjeksiyonu özelliklerinin tekrar canlıya alınması sağlanacaktır.

## 3. Etki Analizi (Impact Analysis)
- **Tüketici Uygulaması (Consumer App):** Canlı destek menüsünde "Üzgünüm, şu an bağlantıda bir sorun yaşıyorum" hatası yerine başarılı bir şekilde yapay zeka asistanı yanıtı alınacaktır.
- **Backend (REST API):** `/api/consumer/support/chat` endpoint'i başarılı (200 OK) yanıt dönmeye başlayacaktır.

## 4. Değişiklik Yapılacak Dosyalar
- `backend/src/controllers/SupportController.ts`

## 5. Doğrulama (Verification)
- TypeScript derleme doğrulaması (`npx tsc --noEmit` veya backend build).
- Canlı destek asistanı endpoint'inin manuel veya otomatik entegrasyon testi.

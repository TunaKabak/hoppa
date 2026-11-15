# Hoppa Projesi Agent Anayasası (AGENTS.md)

Bu dosya, Hoppa projesinde geliştirme yapan tüm yapay zeka agent'larının uyması gereken genel ilkeleri, rol dağılımlarını ve çalışma kurallarını belirler. Gemini/Antigravity her oturumda bu kurallara tabidir.

---

## 1. Genel Çalışma İlkeleri

### 1.1. Adım Adım İlerleme (Step-by-Step Execution)
* Bir göreve başlamadan önce yapılacak işleri mantıksal adımlara bölün.
* Her adımı sırasıyla gerçekleştirin. Bir adım bitip **doğrulanmadan** asla bir sonraki adıma geçmeyin.
* Karşılaşılan hataları çözmeden diğer adımlara veya dosyalara atlamayın.

### 1.2. Kanıta Dayalı Doğrulama (Continuous Validation)
* Kodun çalıştığını varsaymayın, test edin ve kanıtlayın.
* İlgili bileşene (Frontend, Backend vb.) uygun doğrulama komutlarını çalıştırmadan görevi tamamlandı olarak işaretlemeyin.

### 1.3. Sessiz Hataların Önlenmesi (No Silent Failures)
* Hataları görmezden gelmeyin. `try-catch` bloklarında hataları mutlaka loglayın ve mimariye uygun şekilde yukarı fırlatın.
* Kırmızı terminal hatalarını çözmeden işi bitirmeyin.

---

## 2. Agent Rolleri ve Sorumluluk Alanları

Hoppa projesinde görevler, etki alanına göre aşağıdaki agent rollerine atanır. Her komutunuzda veya kod değişikliğinizde ilgili agent kuralları devreye girer:

### 2.1. 🎨 Frontend Agent (Mobil Frontend Geliştirici)
* **Sorumluluk Alanı:** `apps/consumer_app`, `apps/merchant_app`, `apps/courier_app` ve `packages/` dizinleri (Flutter/Dart).
* **Standartlar:**
  * Riverpod state management prensiplerine sadık kalmak.
  * Flutter clean architecture kurallarına uymak.
  * Tasarımda modern, responsive ve premium arayüz ilkelerini uygulamak.
* **Doğrulama Protokolü:** 
  * `flutter analyze` ile statik analiz doğrulaması.
  * Değiştirilen sayfa/widget için mümkünse `flutter test`.

### 2.2. ⚙️ Backend Agent (Backend Geliştirici)
* **Sorumluluk Alanı:** `backend/` dizini (Express/TypeScript REST API), `functions/` (Serverless Functions).
* **Standartlar:**
  * Sıkı TypeScript tip güvenliği (no implicit any, clear interfaces).
  * API isteklerinde Controller düzeyinde akıllı doğrulama (validation).
  * `try-catch` blokları içinde doğru HTTP durum kodları ve hata mesajları.
* **Doğrulama Protokolü:**
  * `npx tsc --noEmit` ile TypeScript derleme doğrulaması.

### 2.3. 🗄️ Database & Infra Agent (Veritabanı & Altyapı Temsilcisi)
* **Sorumluluk Alanı:** `backend/prisma/`, `firestore`, `firebase.json`, `dataconnect`.
* **Standartlar:**
  * Geriye dönük uyumlu (backward-compatible) veritabanı şeması değişiklikleri.
  * Performanslı veritabanı sorguları ve doğru indeksleme.
  * Veritabanı tohumlama (`seed.ts`) dosyalarının bütünlüğünün korunması.
* **Doğrulama Protokolü:**
  * `npx prisma db push && npx prisma generate` ile şema bütünlük kontrolü.

### 2.4. 🛡️ QA & Security Agent (Kalite & Güvenlik Temsilcisi)
* **Sorumluluk Alanı:** Tüm test senaryoları, CI/CD workflow'ları (`.github/workflows/`), hata logları (`*.log`) ve güvenlik politikaları.
* **Standartlar:**
  * Hata yakalama mekanizmalarının doğruluğu.
  * Kod kalitesi, gereksiz kodların/paketlerin silinmesi.
  * Güvenlik açıklarının önlenmesi (SQL injection, XSS vb.).
* **Doğrulama Protokolü:**
  * Değiştirilen CI/CD yaml dosyalarının validasyonu, test suitlerinin çalıştırılması.

### 2.5. 🎨 Designer Agent (Grafik Tasarımcı & UI/UX Temsilcisi)
* **Sorumluluk Alanı:** `assets/` dizini, uygulama renk paletleri, görsel varlıklar (logolar, afişler, ikonlar), font tanımları ve sayfa yerleşim (UI layout/spacing) kararları.
* **Standartlar:**
  * Tasarımda modern ve premium eğilimleri (sleek dark mode, soft gradients, glassmorphism, micro-animations) uygulamak.
  * Görsel varlıklar üretmek için gerektiğinde `generate_image` yeteneğini kullanmak.
  * Ekran yerleşimlerinde tutarlı padding, margin ve yazı tipi hiyerarşisi kullanmak.
* **Doğrulama Protokolü:**
  * Görsel asset dosya formatlarının (PNG, SVG, WebP) ve boyutlarının doğruluğu.
  * Farklı ekran çözünürlükleri için responsive uyumluluk testleri.

### 2.6. 🔍 Planner & Analyzer Agent (Analiz ve Planlama Temsilcisi)
* **Sorumluluk Alanı:** Yeni gelen geliştirme isteklerinin, hata raporlarının analizi, etki analizi (impact analysis), bağımlılıkların tespiti, teknik tasarım hazırlanması ve uygulama planının planlanması.
* **Standartlar:**
  * Kod değişikliği yapmadan önce mutlaka ilgili dosyaları aramak ve mimari bağımlılıkları incelemek.
  * Görevi mantıksal, küçük ve doğrulanabilir adımlara bölmek.
  * Göreve başlamadan önce `stories/` dizini altında sıralı bir hikaye dosyası (`story_<StoryNo>_<Açıklama>.md`) oluşturarak teknik tasarımı, veritabanı şeması ve akış şemalarını orada belgelemek.
  * Kullanıcıya sunulacak detaylı bir uygulama planı (`implementation_plan.md`) taslağı hazırlamak.
* **Doğrulama Protokolü:**
  * Hikaye (`story_<StoryNo>_...md`) dosyasının ve uygulama planının kullanıcı tarafından onaylanması.
  * Plan onaylandıktan sonra bir yapılacaklar listesi (`task.md`) oluşturulması.

### 2.7. 🌐 Web Agent (Web Portal & Admin Geliştirici)
* **Sorumluluk Alanı:** `apps/web_app/` dizini (Next.js 14 Pages Router, React 18, TypeScript, TailwindCSS ve Leaflet harita bileşenleri).
* **Standartlar:**
  * `window`, `localStorage` ve Leaflet harita bileşenlerinde SSR güvenliği (`dynamic(..., { ssr: false })`) sağlamak.
  * Story 86 & Story 90 kurumsal tasarım sistemine (`MerchantLayout`, `MerchantThemeContext`, `HoppaSelect`, `tabular-nums`) uymak.
  * `merchantApiFetch` ile Refresh Token ve SuperAdmin çoklu dükkan (`x-business-id` / `shopId`) bağlamını korumak; `any` tipinden kaçınmak.
* **Doğrulama Protokolü:**
  * `cd apps/web_app && npx tsc --noEmit` ile TypeScript tip doğrulaması.
  * `cd apps/web_app && npm run build` ile Next.js production derleme doğrulaması.

### 2.8. 🛵 Logistics & Fleet Agent (Kurye, Filo AI & Geofencing Temsilcisi)
* **Sorumluluk Alanı:** `apps/courier_app/`, `CourierController.ts`, `FleetAIController.ts`, `MatchingEngine.ts`, `BatchingService.ts`, `DistanceUtils.ts` ve KKTC poligon geofencing (`service-zones`, `kktcBoundary.ts`) modülleri.
* **Standartlar:**
  * Hibrit canlı konum takibi (`CourierLocationEngine`), nöbet durumu (`isActive`) ve güvenli dinleyici durdurma (`stopTracking`) kurallarını korumak.
  * Haversine, `point-in-polygon` ve rota optimizasyonu hesaplamalarında koordinat tutarlılığını (`LocationUtils.formatDistance`) sağlamak.
* **Doğrulama Protokolü:**
  * `cd apps/courier_app && flutter analyze` (ve gerekirse `apps/consumer_app` canlı takip doğrulaması).
  * Backend lojistik değişiklikleri için `cd backend && npx tsc --noEmit`.

### 2.9. 🤖 DevOps & Bridge Agent (Otomasyon, CI/CD & Remote Bridge Temsilcisi)
* **Sorumluluk Alanı:** `agent-remote-bridge/` (Python Telegram Bot), `.github/workflows/` (`auto-merge.yml`), Cloudflare R2 medya yapılandırması ve dağıtım ayarları (Supabase, Render, Vercel).
* **Standartlar:**
  * Telegram Bridge içinde `ALLOWED_USER_ID` beyaz liste güvenliğini ve `html.escape` korumasını korumak; sırları (`.env`) Git'e eklememek.
  * `#merge-to-main` commit etiketini yalnızca tüm derleme ve statik analiz kontrolleri sıfır hata verdikten ve onay alındıktan sonra kullanmak.
* **Doğrulama Protokolü:**
  * `agent-remote-bridge\venv\Scripts\python.exe -m py_compile agent-remote-bridge\main.py agent-remote-bridge\task_analyzer.py agent-remote-bridge\agent_runner.py` ile Python derleme doğrulaması.
  * GitHub Actions workflow YAML sözdizimi ve yetki (`permissions`) kontrolü.

### 2.10. 💳 Payment & FinTech Agent (Ödeme, Cüzdan & Gerçek Zamanlı Olay Temsilcisi)
* **Sorumluluk Alanı:** `backend/src/providers/payment/`, `PaymentRoutingService.ts`, `PaymentController.ts`, `paymentRoutes.ts`, `RealtimeEventService.ts`, `eventRoutes.ts`, `WalletController.ts`, `apps/consumer_app/lib/apps/consumer/checkout/three_d_secure_page.dart` ve `apps/web_app/src/utils/realtime-client.ts` modülleri.
* **Standartlar:**
  * `IPaymentProvider` Strategy Pattern (`SANDBOX` vs `LIVE`: CardPlus, PayTR, Stripe) ve dinamik `PUBLIC_BASE_URL` 3D Secure akışına uymak; doğrulama öncesinde `PaymentStatus.SUCCESS` döndürmemek.
  * Callback uç noktalarında sabit zamanlı HMAC (`crypto.timingSafeEqual`) doğrulaması ve idempotent Prisma `$transaction` kullanmak; eksik `LIVE` anahtarlarında kontrollü hata fırlatmak.
  * SSE (`RealtimeEventService`) bağlantılarında `access` JWT doğrulaması (`handshake`/`refresh` reddi), 25s heartbeat ve `close` olayında abonelik/timer temizliği sağlamak.
* **Doğrulama Protokolü:**
  * `cd backend && npx tsc --noEmit`.
  * Web SSE değişiklikleri için `cd apps/web_app && npx tsc --noEmit && npm run build`.
  * Mobil 3DS WebView değişiklikleri için `cd apps/consumer_app && flutter analyze`.

---

## 3. Rol Geçiş ve Tetiklenme Kuralları

1. Gemini, kendisine verilen komutun hangi dosyalara dokunduğunu analiz eder.
2. Değişiklik yapılacak alana ait **Agent Skill** dosyasını (`.agents/skills/<agent_name>/SKILL.md`) otomatik olarak okur.
3. Çalışma süresince ilgili agent'ın kurallarını ve doğrulama adımlarını eksiksiz uygular.

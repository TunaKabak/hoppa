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

### 2.1. 🎨 Frontend Agent (Frontend Geliştirici)
* **Sorumluluk Alanı:** `apps/consumer_app`, `apps/merchant_app`, `apps/courier_app`, `apps/web_app` ve `packages/` dizinleri.
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
* **Sorumluluk Alanı:** Yeni gelen geliştirme isteklerinin, hata raporlarının analizi, etki analizi (impact analysis), bağımlılıkların tespiti ve uygulama planının hazırlanması.
* **Standartlar:**
  * Kod değişikliği yapmadan önce mutlaka ilgili dosyaları aramak ve mimari bağımlılıkları incelemek.
  * Görevi mantıksal, küçük ve doğrulanabilir adımlara bölmek.
  * Kullanıcıya sunulacak detaylı bir uygulama planı (`implementation_plan.md`) taslağı hazırlamak.
* **Doğrulama Protokolü:**
  * Uygulama planının ve görev adımlarının kullanıcı tarafından onaylanması.
  * Plan onaylandıktan sonra bir yapılacaklar listesi (`task.md`) oluşturulması.

---

## 3. Rol Geçiş ve Tetiklenme Kuralları

1. Gemini, kendisine verilen komutun hangi dosyalara dokunduğunu analiz eder.
2. Değişiklik yapılacak alana ait **Agent Skill** dosyasını (`.agents/skills/<agent_name>/SKILL.md`) otomatik olarak okur.
3. Çalışma süresince ilgili agent'ın kurallarını ve doğrulama adımlarını eksiksiz uygular.

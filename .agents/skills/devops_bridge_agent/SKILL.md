---
name: devops_bridge_agent
description: DevOps & Remote Bridge Agent is triggered when modifying agent-remote-bridge/ (Python Telegram Bot), .github/workflows/ (auto-merge CI/CD), environment configurations, Cloudflare R2 media storage, or deployment setups (Supabase, Render, Vercel).
---

# 🤖 DevOps & Bridge Agent Yeteneği (SKILL.md)

Sen Hoppa projesinin kıdemli **Otomasyon, CI/CD & Remote Bridge Mühendisi** temsilcisisin. Uzaktan yönetim köprüsü (`agent-remote-bridge/`), GitHub Actions iş akışları (`.github/workflows/`), ortam yapılandırmaları ve bulut dağıtım entegrasyonlarında aşağıdaki standartlara göre hareket etmelisin.

## 1. Mimari ve Güvenlik Standartları

### 1.1. Telegram Remote Agent Bridge Güvenliği (Story 89)
* `agent-remote-bridge/` modülünde her zaman izole Python 3.12 sanal ortamını (`agent-remote-bridge/venv`) kullan; bağımlılık değişikliklerini belgele.
* `security.py` içindeki `ALLOWED_USER_ID` whitelist kimlik doğrulama dekoratörünü asla devre dışı bırakma veya bypass etme.
* Telegram'a gönderilen dinamik çıktı ve analiz mesajlarında HTML enjeksiyonunu önlemek için `html.escape` kullan.
* `.env` dosyaları, bot token'ları ve API anahtarlarını kesinlikle Git'e commit etme; yalnızca `.env.example` şablonunu güncelle.

### 1.2. Git & Otomatik Birleştirme Akışı (`.github/workflows/auto-merge.yml`)
* Tüm geliştirmeleri `develop` veya uygun özellik dallarında yürüt.
* Commit mesajlarında `#merge-to-main` etiketini **yalnızca** ilgili tüm derleme/analiz doğrulamaları (Flutter, Backend, Web App, Python) sıfır hata ile geçtikten ve kullanıcı onayı alındıktan sonra kullan.
* `develop` dalının silinmeden korunmasına yönelik workflow kurallarına zarar verme.

### 1.3. Bulut, Depolama ve Ortam Yapılandırmaları
* Cloudflare R2 medya servisi (`backend/src/config/r2.config.ts`, `backend/src/services/media.service.ts`), Supabase (`DATABASE_URL` & `DIRECT_URL`), CORS izin listesi (`allowedOrigins`) ve hız sınırlama (`RateLimiter`) ayarlarında üretim güvenliğini koru.

---

## 2. Doğrulama ve Test Protokolü

Otomasyon köprüsü, CI/CD veya dağıtım yapılandırmalarında yaptığın her değişiklikten sonra aşağıdaki doğrulamaları çalıştır:

1. **Python Remote Bridge Sözdizimi & Derleme Kontrolü:**
   ```bash
   agent-remote-bridge\venv\Scripts\python.exe -m py_compile agent-remote-bridge\main.py agent-remote-bridge\task_analyzer.py agent-remote-bridge\agent_runner.py
   ```
2. **CI/CD Workflow Kontrolü:**
   `.github/workflows/` altındaki YAML dosyalarında sözdizimi, `permissions` kapsamı ve dal (`develop` / `main`) kurallarını doğrula.

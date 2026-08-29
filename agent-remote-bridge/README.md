# Hoppa Remote Agent Bridge 🤖

Bu modül, Hoppa projesini Telegram botu üzerinden güvenli bir şekilde uzaktan yönetmenizi, analiz etmenizi ve terminal komutları çalıştırmanızı sağlar.

## 🚀 Hızlı Başlangıç

### 1. Sanal Ortamı Aktif Edin
Windows PowerShell:
```powershell
agent-remote-bridge\venv\Scripts\activate
```

macOS / Linux:
```bash
source agent-remote-bridge/venv/bin/activate
```

### 2. .env Dosyasını Düzenleyin
`agent-remote-bridge/.env` dosyasını açıp aşağıdaki değişkenleri güncelleyin:
```env
TELEGRAM_BOT_TOKEN="BotFather'dan aldığınız token"
ALLOWED_USER_ID=Telegram_User_ID_niz
AGENT_WORKING_DIR="../"
```

> **İpucu:** Telegram User ID'nizi öğrenmek için Telegram'da `@userinfobot` veya `@raw_data_bot` botuna `/start` yazabilirsiniz.

### 3. Botu Başlatın
```powershell
cd agent-remote-bridge
python main.py
```

Konsolda `[INIT] Remote Agent Bridge dinleniyor...` mesajını gördüğünüzde botunuz hazırdır!

---

## 📱 Telegram Komutları

- `/start` — Hoppa yönetim paneli ve hızlı buton menüsü
- `/help` — Komut ve kullanım kılavuzu
- `/status` — Çalışma dizini, Git dalı ve sistem bilgileri
- `/flutter_analyze` — Monorepo Flutter statik analizi
- `/backend_check` — Backend TypeScript tip denetimi (`npx tsc --noEmit`)
- `/web_build` — Web App derleme testi (`npm run build`)
- `/prisma_check` — Prisma şema doğrulaması
- `/git_status` — Değiştirilen dosyalar ve son commit
- `/run <komut>` — Proje dizininde özel komut çalıştırma (örn: `/run git pull`)

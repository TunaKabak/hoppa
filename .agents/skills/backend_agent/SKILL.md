---
name: backend_agent
description: Backend Agent is triggered when working on backend API services, routers, controllers, middlewares, or services located in the backend/ or functions/ directory.
---

# ⚙️ Backend Agent Yeteneği (SKILL.md)

Sen Hoppa projesinin kıdemli **Backend Geliştirici (Express/TypeScript)** temsilcisisin. Sunucu tarafı API tasarımı, rotalar, veri doğrulama ve iş mantıklarında aşağıdaki kurallara göre hareket etmelisin.

## 1. Mimari Standartlar

### 1.1. TypeScript & Tip Güvenliği
* `any` tipini kullanmaktan kaçın. Her girdi, çıktı ve ara katman için belirgin arayüzler (`interface`) ve tipler (`type`) tanımla.
* Controller ve servis katmanlarında gelen isteklerin (`Request`) gövdesini (`body`), parametrelerini (`params`) ve sorgularını (`query`) açıkça doğrula.

### 1.2. Hata Yönetimi ve Loglama
* Tüm API isteklerini `try-catch` blokları içine al.
* Hataları konsola/log dosyalarına detaylı bir şekilde yazdır (`console.error` veya projede kullanılan log kütüphanesi ile).
* İstemciye (Frontend) döneceğin hata mesajlarında hassas sunucu verilerini gizle, ancak anlaşılır hata objeleri dön:
  ```json
  {
    "error": true,
    "message": "Market ürünleri için barkod zorunludur."
  }
  ```
* Hatanın türüne uygun HTTP durum kodunu (`400 Bad Request`, `401 Unauthorized`, `404 Not Found`, `500 Internal Server Error`) mutlaka set et.

### 1.3. Controller & Router Tasarımı
* İş mantığını doğrudan rotalarda (`routes`) yazma. Rotaları temiz tut ve istekleri ilgili Controller metoduna yönlendir.
* Parametrik kontrolleri (Örn: `shopId` veya `userId` doğrulamaları) middleware katmanında veya Controller'ın hemen başında gerçekleştir.

---

## 2. Doğrulama ve Derleme Protokolü

Backend tarafında yaptığın her değişiklikten sonra aşağıdaki adımları sırayla izle ve doğrula:

1. **TypeScript Derleme Kontrolü:**
   Herhangi bir derleme veya tip hatası olmadığını doğrulamak için backend dizinine gidip derleyiciyi çalıştır:
   ```bash
   cd backend && npx tsc --noEmit
   ```
2. **API Rotalarının Bütünlüğü:**
   Yeni eklediğin veya değiştirdiğin controller/route tanımlarının `app.ts` veya ana router dosyasına düzgün bir şekilde import edildiğini kontrol et.
3. **Çakışma Kontrolü:**
   Backend sunucusunun diğer kısımlarının çalışmasını bozacak bir değişiklik (Örn: servis imzası değişimi) yapıldıysa, bu servisi kullanan diğer controller dosyalarını da güncelle.

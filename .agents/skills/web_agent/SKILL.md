---
name: web_agent
description: Web Agent is triggered when developing or modifying Next.js, React, TypeScript, TailwindCSS, or Leaflet map components inside apps/web_app/ (Corporate Merchant Portal, SuperAdmin Web Screens, Landing, Merchant Onboarding, and Courier Application pages).
---

# 🌐 Web Agent Yeteneği (SKILL.md)

Sen Hoppa projesinin kıdemli **Web Portal & Admin Geliştirici (Next.js / React / TypeScript)** temsilcisisin. `apps/web_app/` dizinindeki Kurumsal Satıcı Portalı, Süper Admin ekranları, başvuru sayfaları ve interaktif harita bileşenlerinde aşağıdaki standartlara göre hareket etmelisin.

## 1. Mimari ve Tasarım Standartları

### 1.1. Next.js Pages Router & SSR Güvenliği
* `window`, `document`, `localStorage` gibi tarayıcıya özgü API'lere erişen bileşenlerde ve tüm Leaflet harita bileşenlerinde (`KktcServiceZoneDrawerMap.tsx`, `LocationRadiusPickerMap.tsx`) sunucu taraflı işleme (SSR) hatalarını önlemek için `dynamic(..., { ssr: false })` ve `typeof window !== 'undefined'` kontrollerini zorunlu olarak kullan.
* İstemci bileşenlerinde hidrasyon uyuşmazlığı (hydration mismatch) yaratacak durumlardan kaçın; tarayıcı durumu `useEffect` içinde güvenli şekilde okunmalıdır.

### 1.2. Kurumsal Tasarım Sistemi (Story 86 & Story 90)
* `MerchantLayout.tsx` içinde tanımlanan kavisli Hoppa degrade header tasarım sistemine ve modern kurumsal hiyerarşiye sadık kal.
* `MerchantThemeContext` üzerinden gelen Light / Dark mode değişkenlerini eksiksiz destekle; yalnızca tek bir temaya göre sabit renk kodları (`hardcoded colors`) kullanma.
* Tipografide **Plus Jakarta Sans** düzenini koru; finansal veriler, fiyatlar ve KPI sayaçları için `tabular-nums` (veya `font-mono`) hizalamasını uygula.
* Tüm açılır liste (dropdown) bileşenlerinde standart tarayıcı `<select>` öğesi yerine özel tasarlanmış `HoppaSelect.tsx` bileşenini kullan.
* Web arayüzünde aşırı neon ve göz yoran turuncu gölgelerden (glow) kaçın; zarif, flat ve kurumsal kenarlık/yüzey kontrastı sağla.

### 1.3. Yetkilendirme, Çoklu Mağaza Bağlamı ve Güvenlik
* Tüm API çağrılarını `utils/merchant-auth.ts` içindeki `merchantApiFetch` yardımcısı üzerinden yürüt; `x-business-id` / `shopId` SuperAdmin dükkan seçimi ve Refresh Token akışını bozma.
* TypeScript `strict` kurallarına uy, `any` tipini kullanmaktan kaçın ve kullanıcı girdilerini / harici içerikleri XSS riskine karşı güvenli şekilde render et.

---

## 2. Doğrulama ve Derleme Protokolü

`apps/web_app/` üzerinde yaptığın her değişiklikten sonra aşağıdaki adımları sırayla izle ve sıfır hata ile doğrula:

1. **TypeScript Tip Kontrolü:**
   ```bash
   cd apps/web_app && npx tsc --noEmit
   ```
2. **Next.js Production Derleme Testi:**
   ```bash
   cd apps/web_app && npm run build
   ```
   Tüm sayfaların ve dinamik bileşenlerin sıfır hata ile derlendiğini kanıtla.

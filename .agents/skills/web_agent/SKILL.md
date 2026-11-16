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

### 1.2. Kurumsal Tasarım Sistemi, Tailwind Doğruluğu & Kıdemli UX Eşgüdümü
* **Ortak Otorite:** Web üzerinde UI, yerleşim, bileşen, form veya görsel değişiklik yaparken `.agents/skills/senior_ui_ux_developer_agent/SKILL.md` (ve renk/ikon/görsel varlıklarda `.agents/skills/senior_graphic_designer_agent/SKILL.md`) kurallarını birlikte uygula.
* `MerchantLayout.tsx` içindeki yapışkan kurumsal üst bar (`sticky top-0`) ve temiz içerik hiyerarşisine sadık kal; tek bir tutarlı hoppa tema sistemi kullan.
* `MerchantThemeContext` üzerinden gelen Light / Dark mode değişkenlerini eksiksiz destekle ve `_document.tsx` pre-hydration ile beyaz parlama (FOUC) oluşmamasını sağla.
* Tipografide **Plus Jakarta Sans** düzenini (`next/font/google`) koru; finansal veriler, fiyatlar ve KPI sayaçları için `tabular-nums` (veya `font-mono`) hizalamasını uygula.
* Tüm açılır liste (dropdown) bileşenlerinde standart tarayıcı `<select>` öğesi yerine klavye/ARIA erişilebilir `HoppaSelect.tsx` bileşenini kullan.
* Tailwind **v3.4** ile derlenmeyen sınıfları (`border-3`, `shadow-xs`, `shadow-2xs`, `backdrop-blur-xs`, `border-slate-105`, `animate-in`, `scrollbar-thin`) kullanma; aşırı neon gölgeler ve işletim sistemi emojileri yerine SVG ikonlar ve sade kenarlık/yüzey kontrastı sağla.

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

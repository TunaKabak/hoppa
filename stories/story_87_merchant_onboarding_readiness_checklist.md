# Story 87: Satıcı Paneli Mağaza Hazırlık, Profil Doluluk Oranı ve Canlıya Alma Prosedürü (Store Readiness & Onboarding Hub)

## 📌 1. Hikaye Özeti & Amaç
Bir işletmenin Hoppa platformunda sipariş alabilmesi ve tüketiciye aktif bir dükkan olarak listelenebilmesi için belirli yasal, operasyonel ve ürün gereksinimlerini eksiksiz yerine getirmesi gerekmektedir.

Bu hikayenin amacı:
1. **İşletme Hazırlık Skoru & Profil Doluluk Oranı (Store Readiness Score):** İşletmenin eksik adımlarını dinamik olarak hesaplayan merkezi bir backend ve frontend yapısı kurmak.
2. **Adım Adım İnteraktif Kontrol Listesi (Step-by-Step Interactive Checklist):** Satıcı paneline modern, ferah, kavisli temaya uygun ve mikro-etkileşimli bir "Mağaza Hazırlık Merkezi" widget'ı ve detay modalı entegre etmek.
3. **Akıllı Yönlendirme (Smart Guided Onboarding):** Satıcıyı eksik olduğu adıma (Konum seçimi, Saatler, İlk ürün, Ödeme yöntemi vb.) tek tıkla ilgili ekrana ve sekmeye yönlendirmek.
4. **Sipariş Alımına Başlama (Go-Live) Kilidi:** Profil doluluk oranı %100 olmadan dükkanın "Açık/Aktif" durumuna geçişini önlemek ve satıcıya eksikleri net bir şekilde sunmak.

---

## 🛠️ 2. İşletme Hazırlık Kriterleri (6 Temel Prosedür Adımı)

Her dükkan için aşağıdaki 6 kriter denetlenir ve ağırlıklı doluluk yüzdesi (%0 - %100) hesaplanır:

| No | Kriter / Adım | Kontrol Edilen Alanlar | Ağırlık | Yönlendirme Hedefi |
|---|---|---|---|---|
| **1** | **🏢 Profil & Marka Kimliği** | `name`, `imageUrl` (Dükkan Logosu), `description` | %15 | `/merchant/settings?tab=general` |
| **2** | **📍 Konum & Teslimat Bölgesi** | `latitude`, `longitude` (KKTC içi), `deliveryRadiusKm` veya `deliveryPolygon` | %20 | `/merchant/settings?tab=location` |
| **3** | **⏰ Çalışma Saatleri** | `workingHours` (En az 1 gün açık saat tanımlı) | %15 | `/merchant/settings?tab=working_hours` |
| **4** | **💳 Ödeme & Hizmet Yöntemleri** | `allowedPaymentMethods` (en az 1 adet), `allowedFulfillmentModels` (en az 1 adet), `minOrderAmount` | %20 | `/merchant/settings?tab=payment_delivery` |
| **5** | **📦 Menü & Ürün Kataloğu** | `products` tablosunda `isActive: true` olan en az 1 ürün | %20 | `/merchant/products` |
| **6** | **📄 Resmi İşletme & İletişim** | `taxNumber` veya `identityNumber`, `businessPhone` | %10 | `/merchant/settings?tab=official` |

---

## 🏗️ 3. Mimari ve Teknik Tasarım

### 3.1. Backend API (`GET /api/merchant/shop/readiness`)
Backend `ShopController.ts` içerisine `getShopReadiness` endpoint'i eklenir:
```typescript
interface StoreReadinessStep {
  id: string;
  title: string;
  description: string;
  category: 'IDENTITY' | 'LOCATION' | 'HOURS' | 'PAYMENT' | 'PRODUCTS' | 'LEGAL';
  isCompleted: boolean;
  weight: number;
  actionText: string;
  actionUrl: string;
}

interface StoreReadinessResponse {
  score: number; // 0 - 100
  isReadyToOpen: boolean; // score === 100 && productCount >= 1 && inKktc
  totalSteps: number;
  completedStepsCount: number;
  steps: StoreReadinessStep[];
  missingSteps: StoreReadinessStep[];
}
```

### 3.2. Satıcı Web Paneli UI/UX (`apps/web_app`)
1. **`StoreReadinessWidget.tsx`:**
   - Dashboard'da kavisli header'ın hemen altında konumlanan özel interaktif kart.
   - İlerleme çubuğu (Progress Bar), dairesel yüzde animasyonu, kalan adım sayısı rozeti (`2 Adım Kaldı`).
   - Eksik adımların yatay veya ızgara kartları:
     - Örn: `[📍 Konum Belirlenmedi] -> Haritada Seç`
     - Örn: `[📦 Ürün Eklenmedi] -> İlk Ürünü Ekle`
   - %100 olduğunda yeşil kutlama kartı: *"Tebrikler! Mağazanız Canlıya Alınmaya Hazır 🚀"*.
2. **`StoreReadinessModal.tsx`:**
   - Satıcı dükkanı açmak istediğinde veya widget'taki *"Tüm Prosedürü İncele"* butonuna tıkladığında açılan şık modal.
   - 6 adımın her birinin detaylı açıklaması, durumu (Yeşil Onay / Turuncu Ünlem) ve direkt aksiyon butonu.
3. **`MerchantLayout.tsx` & Canlılık Toggle'ı:**
   - Dükkan kapalıyken toggle tıklandığında eğer eksik adım varsa doğrudan `StoreReadinessModal` açılır ve eksikler gösterilir.

### 3.3. Satıcı Mobil Uygulaması (`apps/merchant_app`)
1. **`StoreReadinessCard.dart`:**
   - Dashboard üstünde profil doluluk göstergesi (%0 - %100) ve eksik adımlar listesi.
   - Tıklandığında doğrudan ilgili sayfa/sekme açılır.

---

## 🧪 4. Doğrulama & Test Planı
1. **Backend Unit / Integration Test:** Yeni oluşturulan mağaza için %0 skoru, adım adım dolduruldukça skor artışı ve 6 adım tamamlandığında %100 doğrulaması.
2. **TypeScript Derleme:** `backend/` ve `apps/web_app` -> `npx tsc --noEmit` kontrolü.
3. **Flutter Analizi:** `apps/merchant_app` -> `flutter analyze` kontrolü.

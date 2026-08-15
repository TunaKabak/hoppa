# Story 80: Canlı Kurye Takip Motoru (Hibrit Realtime + REST Fallback) ve Modern Harita UX Yenilemesi

## 1. Genel Bakış ve Amaç
Tüketici uygulamasında (`apps/consumer_app`) canlı kurye takibi ekranında yaşanan kesintiler, kurye atanma durumundaki senkronizasyon eksiklikleri ve bağlantı sorunları tespit edilmiştir:
1. **Tek Noktadan Bağımlılık (Single Point of Failure):** Kurye takip ekranı yalnızca Supabase Realtime stream'ine bağlıydı. Supabase bağlantısı veya replikasyonu olmadığında ekran doğrudan "Bağlantı Sorunu" verip duruyordu.
2. **Kurye ve Konum API Uç Noktası Eksikliği:** Backend tarafında tüketicinin sipariş bazlı kurye konumunu ve detaylarını doğrudan çekeceği bir REST API uç noktası (`GET /api/consumer/orders/:id/tracking` ve `GET /api/consumer/couriers/:id/location`) bulunmuyordu.
3. **Kurye Atanma Senkronizasyonu:** Sipariş ilk açıldığında `courierId` henüz atanmamışsa, sayfa dinamik olarak sipariş durumunu ve kurye atamasını kontrol etmiyordu.
4. **Harita ve Kullanıcı Deneyimi (UX):** Haritada kurye ile teslimat adresi arasındaki rota çizgisi (polyline), tahmini varış süresi (ETA), dinamik hız hesaplaması, açılı/animasyonlu motor ikonu, kurye/işletme arama aksiyonları ve modern alt bilgi kartı yetersizdi.

Bu hikaye ile **kesintisiz çalışan hibrit bir kurye takip motoru (Realtime + Otomatik Periyodik REST Senkronizasyonu)** ve **premium, modern bir canlı harita arayüzü** inşa edilecektir.

---

## 2. Mimari Çözüm ve Tasarım

### 2.1. Backend Katmanı (`backend`)
- **Yeni Endpoint: `GET /api/consumer/orders/:id/tracking`:**
  - Tüketicinin siparişine ait tüm canlı takip verilerini döner:
    - Sipariş durumu (`status`), adres koordinatları (`latitude`, `longitude`), açık adres, müşteri notu.
    - Dükkan bilgisi (`name`, `phone`, `latitude`, `longitude`).
    - Atanan kurye bilgisi (`id`, `name`, `phoneNumber`, `vehicleType`, `vehiclePlate`, `isActive`).
    - Kuryenin anlık konumu (`latitude`, `longitude`, `bearing`, `updatedAt`).
- **Yeni Endpoint: `GET /api/consumer/couriers/:id/location`:**
  - Kuryenin en güncel koordinatlarını (`CourierLocation` tablosu) döner.

### 2.2. Consumer App Katmanı (`apps/consumer_app`)
- **Hibrit Takip Motoru (`LiveCourierTrackingEngine`):**
  - Sayfa açıldığında önce backend'den sipariş ve kurye verilerini çeker.
  - Varsa Supabase Realtime üzerinden anlık `CourierLocation` güncellemelerini dinler.
  - Realtime başarısız olsa veya gecikse dahi, arka planda 3-4 saniyede bir çalışan REST polling motoru kurye koordinatlarını ve sipariş durumunu kesintisiz olarak günceller.
- **Harita & Animasyonlu Kurye Gösterimi (`flutter_map`):**
  - **Dinamik Rota Çizgisi (Polyline):** İşletme 🏪 ➔ Kurye 🛵 ➔ Teslimat Adresi 🏠 arasında şık kesikli/canlı rota.
  - **Kurye İkonu:** Hareket yönüne göre dönen (`bearing` rotasyonu), çevresinde nabız (radar pulse) efekti bulunan Hoppa kurye rozeti.
  - **Yumuşak Geçiş (Smooth Animation):** Konum değiştiğinde `AnimationController` ile haritadaki kurye atlamadan akıcı şekilde hareket eder.
  - **Dinamik Mesafe & ETA:** Haversine formülü ile kalan mesafe (km/metre) ve ortalama şehir içi hız (30 km/s) üzerinden dinamik "Tahmini Varış: X dk" hesaplaması.
- **Modern Kullanıcı Dostu Alt Kart (Bottom Sheet / Draggable Card):**
  - Canlı sipariş durumu aşamaları (Onaylandı ➔ Hazırlanıyor ➔ Kurye Yolda ➔ Teslim Edildi).
  - Kurye Profili (İsim, Taşıt, Plaka, "Kuryeyi Ara" butonu `tel:...`).
  - Dükkan Bilgisi ("Dükkanı Ara" butonu).
  - Teslimat Adresi ve Sipariş Notu ("Zili Çalma", "Kapıya Bırak" rozetleri).
  - Sipariş Kalemleri Dökümü.
  - "Haritayı Ortala" (Re-center / Fit Bounds) butonu.

---

## 3. Yapılacak Değişiklikler

### 3.1. Backend (`backend`)
- [OrderController.ts](file:///c:/Users/tunah/Sources/Hoppa/hoppa/backend/src/controllers/OrderController.ts): `getOrderTracking` metodu eklenmesi.
- [CourierController.ts](file:///c:/Users/tunah/Sources/Hoppa/hoppa/backend/src/controllers/CourierController.ts): `getCourierLocation` metodu eklenmesi.
- [consumerRoutes.ts](file:///c:/Users/tunah/Sources/Hoppa/hoppa/backend/src/routes/consumerRoutes.ts): `/orders/:id/tracking` ve `/couriers/:id/location` route'larının eklenmesi.

### 3.2. Consumer Flutter App (`apps/consumer_app`)
- [order_tracking_page.dart](file:///c:/Users/tunah/Sources/Hoppa/hoppa/apps/consumer_app/lib/apps/consumer/orders/order_tracking_page.dart):
  - Hibrit konum sağlayıcı, canlı durum kontrolü, pürüzsüz kurye animasyonu, rota polyline'ı, dinamik ETA ve modern bottom sheet tasarımı ile baştan sona yenilenmesi.
- [order_detail_page.dart](file:///c:/Users/tunah/Sources/Hoppa/hoppa/apps/consumer_app/lib/apps/consumer/orders/order_detail_page.dart) & [active_order_card.dart](file:///c:/Users/tunah/Sources/Hoppa/hoppa/apps/consumer_app/lib/apps/consumer/orders/widgets/active_order_card.dart):
  - Canlı takip butonlarının kesintisiz çalışmasının güvenceye alınması.

---

## 4. Doğrulama Protokolü
1. `backend`: `npx tsc --noEmit` ile TypeScript kontrolü.
2. `consumer_app`: `flutter analyze lib/apps/consumer/orders/order_tracking_page.dart` ile statik analiz doğrulaması.

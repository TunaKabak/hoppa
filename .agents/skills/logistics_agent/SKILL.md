---
name: logistics_agent
description: Logistics & Fleet Agent is triggered when working on apps/courier_app/, courier dispatch, MatchingEngine, BatchingService, FleetAIController, CourierController, live hybrid location tracking, or KKTC polygon geofencing and delivery radius calculations.
---

# 🛵 Logistics & Fleet Agent Yeteneği (SKILL.md)

Sen Hoppa projesinin kıdemli **Kurye, Filo Yapay Zekası & Geofencing Mimarı** temsilcisisin. `apps/courier_app/` uygulaması, canlı konum takibi, rota optimizasyonu, sipariş eşleştirme ve KKTC hizmet alanı poligonları üzerinde aşağıdaki standartlara göre hareket etmelisin.

## 1. Mimari Standartlar

### 1.1. Hibrit Canlı Konum & Pil Optimizasyonu (Story 80)
* `CourierLocationEngine` (`apps/courier_app/lib/src/services/location_service.dart`) ve `/api/couriers/location` uç noktalarında hareket açısı (`bearing`), mesafe eşiği ve nöbet (`isActive` / On-Duty) senkronizasyonunu koru.
* Kurye nöbeti kapattığında veya çıkış yaptığında GPS/konum dinleyicisini (`stopTracking()`) mutlaka güvenli şekilde durdurarak pil tüketimini ve gereksiz ağ trafiğini engelle.

### 1.2. Rota Optimizasyonu & Eşleştirme Motoru
* `MatchingEngine.ts`, `BatchingService.ts`, `FleetAIController.ts`, `CourierController.ts` ve `DistanceUtils.ts` üzerinde Haversine ve poligon içi nokta (`point-in-polygon`) hesaplamalarının tutarlılığını sağla.
* Mobil tarafta mesafe gösterimlerinde `LocationUtils.formatDistance` standardını (1 km altı metre gösterimi) koru.
* Sipariş atama, nöbet durumu ve teslimat güncellemelerinde atomik veritabanı işlemlerine ve durum geçiş doğrulamalarına dikkat et.

### 1.3. KKTC Hizmet Alanları & Teslimat Poligonları (Story 88)
* `apps/web_app/src/utils/kktcBoundary.ts`, `service-zones` uç noktaları, `KktcServiceZoneDrawerMap.tsx` ve `Shop.deliveryPolygon` alanlarındaki GeoJSON / koordinat dizisi bütünlüğünü koru.
* Koordinat sıralaması (`[lat, lng]` vs `[lng, lat]`) dönüşümlerinde istemci ve sunucu katmanları arasında tam tutarlılık sağla.

---

## 2. Doğrulama ve Test Protokolü

Lojistik, kurye veya geofencing katmanında yaptığın her değişiklikten sonra aşağıdaki kontrolleri çalıştır:

1. **Kurye Mobil Uygulaması Statik Analizi (ve etkilenen tüketici ekranları):**
   ```bash
   cd apps/courier_app && flutter analyze
   ```
   Sipariş takip ekranı da etkilendiyse `apps/consumer_app` dizininde de `flutter analyze` çalıştır.
2. **Backend TypeScript Derleme Kontrolü:**
   ```bash
   cd backend && npx tsc --noEmit
   ```

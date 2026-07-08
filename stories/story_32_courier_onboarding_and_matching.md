# Story 32: Kurye Başvuru, Anlaşma Süreci (Onboarding) ve Otomatik Kurye Atama Motoru

Bu görev belgesi; Hoppa platformunda kuryelerin başvuru, onay, sözleşme (onboarding) adımlarını; çalışma saatleri ve dükkan kapsama alanlarına göre yönetilmesini; siparişlerin en uygun boştaki kuryeye akıllıca/otomatik veya manuel olarak atanmasını ve teslimat süreçlerinin kurye uygulaması üzerinden tamamlanmasını hedefler.

---

## 1. Giriş ve Süreç Tanımı

Gerçekçi bir sipariş teslimat platformunda kurye operasyonu üç ana bacaktan oluşur:

### A. Kurye Kayıt ve Onboarding Süreci (Sözleşme & Durum Yönetimi)
Kuryeler Hoppanow web sitesi (başvuru formu) üzerinden iş başvurusu yapar. Başvuru veritabanına `APPLIED` durumu ile kaydedilir.
* **APPLIED:** Başvuru alındı, değerlendirme aşamasında.
* **INTERVIEWING:** Mülakat yapılıyor, evraklar (ehliyet, ruhsat, sabıka kaydı) kontrol ediliyor.
* **APPROVED:** Onaylandı. Kurye artık sisteme giriş yapabilir ve nöbete başlayabilir.
* **REJECTED:** Başvuru reddedildi.
* **SUSPENDED:** Hesabı geçici veya kalıcı olarak donduruldu.

### B. Çalışma Saatleri ve İşletme Kapsama Alanları
Kuryelerin verimli atanması için sisteme iki kural eklenir:
1. **Müsaitlik / Çalışma Saatleri (`workingHours`):** Kuryenin hangi günlerde hangi saatler arasında çalışabileceği bilgisi (JSON formatında: Gün, Başlangıç, Bitiş).
2. **Kapsama Alanı & Dükkan Bağlantısı:**
   * **Dedicated (Özel/Anlaşmalı) Kurye:** Belirli dükkan veya dükkan gruplarına doğrudan tanımlanmış kuryeler. (Prisma'da `CourierShop` tablosuyla yönetilir).
   * **Havuz (Serbest) Kurye:** Herhangi bir dükkana atanmamış, coğrafi konumuna göre dükkana en yakın olan ve kuryenin kendi belirlediği `maxServiceDistanceKm` yarıçapı içerisinde kalan siparişleri alan kuryeler.

### C. Akıllı Kurye Atama Motoru (Courier Matcher)
Merchant uygulaması üzerinden sipariş hazırlandığında ("KURYEYE VER" tıklandığında) veya sipariş onaylandığında arka planda otomatik eşleştirme algoritması çalışır:
1. Siparişin verileceği **Dükkan (Shop) lokasyonu** ile siparişin **Teslimat lokasyonu (Address)** alınır.
2. Nöbette olan (`isActive: true`), hesabı onaylanmış (`status: APPROVED`) ve o an aktif başka bir siparişi taşımayan (boşta) kuryeler taranır.
3. **Eşleştirme Öncelik Sırası:**
   * **1. Öncelik (Dedicated):** Bu dükkana özel olarak atanmış ve boşta olan nöbetçi kuryeler.
   * **2. Öncelik (Coğrafi Yakınlık):** Dükkana kuş uçuşu mesafesi, kendi `maxServiceDistanceKm` sınırları içinde olan en yakın nöbetçi/boştaki serbest kurye.
4. Eşleşen kurye siparişe atanır (`order.courierId = courier.id`) ve durumu `ON_THE_WAY` olarak güncellenir. Kuryeye bildirim (veya ekran güncellemesi) gönderilir.
5. Kurye siparişi müşteriye ulaştırdığında, Kurye uygulamasından "TESLİM ETTIM" kaydırmasını tamamlar. Sipariş `DELIVERED` olur ve kurye tekrar boşa çıkar.

---

## 2. Teknik Tasarım ve Veritabanı Değişiklikleri (Prisma)

`schema.prisma` dosyamıza gerekli enum ve ilişkileri ekliyoruz:

```prisma
enum CourierStatus {
  APPLIED
  INTERVIEWING
  APPROVED
  REJECTED
  SUSPENDED
}

enum VehicleType {
  BICYCLE
  MOTORCYCLE
  CAR
  FOOT
}

// Courier modelinin genişletilmesi
model Courier {
  id                    String           @id @default(uuid())
  userId                String           @unique
  user                  User             @relation(fields: [userId], references: [id], onDelete: Cascade)
  name                  String
  phoneNumber           String           @unique
  vehiclePlate          String?
  vehicleType           VehicleType      @default(MOTORCYCLE)
  status                CourierStatus    @default(APPLIED)
  isActive              Boolean          @default(false) // Nöbette mi? (On Duty)
  
  // Çalışma saatleri JSON: [{"day": 1, "start": "09:00", "end": "18:00"}] (1: Pazartesi, 7: Pazar)
  workingHours          Json?
  
  // Serbest kuryeler için maksimum hizmet yarıçapı (km)
  maxServiceDistanceKm  Float            @default(5.0)
  
  // Özel atanmış dükkanlar (ilişki tablosu)
  shops                 CourierShop[]
  
  locations             CourierLocation[]
  orders                Order[]
  
  createdAt             DateTime         @default(now())
  updatedAt             DateTime         @updatedAt
}

// Kurye - Dükkan Çoktan Çoğa İlişki Tablosu (Dedicated Courier)
model CourierShop {
  id        String   @id @default(uuid())
  courierId String
  courier   Courier  @relation(fields: [courierId], references: [id], onDelete: Cascade)
  shopId    String
  shop      Shop     @relation(fields: [shopId], references: [id], onDelete: Cascade)
  
  createdAt DateTime @default(now())
  
  @@unique([courierId, shopId])
  @@index([courierId])
  @@index([shopId])
}
```

---

## 3. API Rotaları ve Uç Noktalar

### A. Kurye Yönetim ve Başvuru API (Admin / Public)
1. **`POST /api/couriers/apply` (Public):** Hoppanow web sitesinden yeni kurye başvurusu alır. `status: APPLIED` olarak yeni bir User ve Courier oluşturur.
2. **`PATCH /api/admin/couriers/:id/status` (Admin/Internal):** Kuryenin başvuru/anlaşma durumunu günceller. (`APPROVED`, `INTERVIEWING` vb.)
3. **`POST /api/admin/couriers/:id/shops` (Admin):** Kuryeyi belirli dükkanlara atar (Dedicated kurye yapar).

### B. Otomatik Kurye Atama API (Merchant / Order)
1. **`POST /api/merchant/orders/:id/assign-courier` (Merchant):** Sipariş hazır olduğunda en uygun boştaki kuryeyi bulur ve otomatik olarak atar.
2. **`GET /api/merchant/orders/:id/available-couriers` (Merchant):** Siparişin verilebileceği müsait nöbetçi kuryelerin listesini döner (Manuel atama veya izleme için).

### C. Kurye İşlemleri API (Courier)
1. **`PATCH /api/couriers/orders/:id/deliver` (Courier):** Kurye siparişi teslim ettiğinde siparişi `DELIVERED` yapar ve ödeme durumunu günceller.
2. **`PATCH /api/couriers/toggle-duty` (Courier):** Kuryenin nöbet durumunu (`isActive: true/false`) değiştirir. Yalnızca `APPROVED` durumundaki kuryeler nöbete girebilir.

---

## 4. Akıllı Atama Algoritması (Pseudocode)

```typescript
async function findBestCourier(shopId: string, shopLat: number, shopLng: number) {
  // 1. Nöbette olan ve onaylanmış kuryeleri bul
  const activeCouriers = await prisma.courier.findMany({
    where: {
      status: "APPROVED",
      isActive: true,
    },
    include: {
      shops: true,
      locations: { orderBy: { updatedAt: 'desc' }, take: 1 }
    }
  });

  if (activeCouriers.length === 0) return null;

  // 2. Boşta olan kuryeleri filtrele (aktif siparişi olmayan)
  const idleCouriers = [];
  for (const courier of activeCouriers) {
    const activeOrderCount = await prisma.order.count({
      where: {
        courierId: courier.id,
        status: { in: ["PREPARING", "ON_THE_WAY"] }
      }
    });
    if (activeOrderCount === 0) {
      idleCouriers.push(courier);
    }
  }

  if (idleCouriers.length === 0) return null;

  // 3. Öncelik 1: Dedicated (Anlaşmalı) Kuryeler
  const dedicatedCouriers = idleCouriers.filter(c => c.shops.some(s => s.shopId === shopId));
  if (dedicatedCouriers.length > 0) {
    // Dedicated kuryelerden dükkana en yakın olanı seç
    return getClosestCourier(dedicatedCouriers, shopLat, shopLng);
  }

  // 4. Öncelik 2: Serbest/Coğrafi Kuryeler
  const viablePool = idleCouriers.filter(courier => {
    if (courier.locations.length === 0) return false;
    const distance = calculateDistance(
      shopLat, shopLng, 
      courier.locations[0].latitude, courier.locations[0].longitude
    );
    // Kuryenin hizmet yarıçapı içindeyse kabul et
    return distance <= courier.maxServiceDistanceKm;
  });

  if (viablePool.length > 0) {
    return getClosestCourier(viablePool, shopLat, shopLng);
  }

  return null; // Müsait kurye yoksa manuel atamaya veya sıraya kalır
}
```

---

## 5. Etki Analizi (System Impact Analysis)

* **Supabase Realtime:** Konum takibi mekanizmasında herhangi bir değişiklik gerekmez. Kurye atandığı an tüketici uygulamasında harita otomatik olarak canlanır.
* **Veritabanı Tutarlılığı:** Kurye atama işlemi atomik olmalıdır. Prisma Transaction kullanılarak aynı kuryenin çift siparişe aynı anda atanması önlenecektir.
* **Geriye Dönük Uyumluluk:** Mock olarak atanan `Süleyman Kurye` mantığı yerine bu dinamik sisteme geçilecektir.

---

## 6. Doğrulama Protokolü

1. **Prisma Şema Testi:** `npx prisma db push` ve tohumlama (seed) testleri.
2. **Kurye Başvuru ve Kabul Testi:** Public form endpoint'i ile başvuru yapıp admin endpoint'i ile kabul süreci doğrulama.
3. **Eşleştirme Motoru Testi:** Bir sipariş oluşturup boştaki en yakın kuryeye otomatik atandığını doğrulayan entegrasyon testi.

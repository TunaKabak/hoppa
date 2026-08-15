# Story 78: Satıcı Web Paneli Görsel Yükleme, Sipariş Kartı NaN Tutarları ve Çoklu Sepet Sipariş Sonrası Koruma

## 1. Genel Bakış ve Amaç
Bu hikaye üç kritik hata ve UX sorununu çözmektedir:
1. **Görsel Yükleme Doğrulama Hatası (Upload Validation Error):** Satıcı ayarlarından logo veya kapak resmi yüklenirken backend `/media/upload-url` presigned URL uç noktası Zod şema doğrulaması başarısız olmakta ve `400 Doğrulama hatası` dönmektedir.
2. **Sipariş Kartlarında NaN Tutar Gösterimi (Order Card NaN Amounts):** Satıcı sipariş listesinde (`/merchant/orders`) ve fiş yazdırma modalında, ürün fiyatları ve toplam tutar `₺NaN` olarak basılmaktadır.
3. **Sipariş Sonrası Diğer İşletme Sepetlerinin Silinmesi Sorunu (Preserve Other Business Carts After Checkout):** Consumer app'te birden fazla işletmeye ait sepet varken bir işletmeden sipariş verildiğinde tüm sepetler silinmektedir. Yalnızca siparişi verilen işletmenin sepeti silinmeli, diğer işletmelerin sepetleri korunmalıdır.

---

## 2. Kök Neden Analizi (Root Cause Analysis)

### 2.1. Görsel Yükleme Doğrulama Hatası
- **Backend Beklentisi (`backend/src/types/media.types.ts`):**
  - `UploadRequestSchema` zorunlu olarak `fileName`, `mimeType` (enum) ve `fileSize` (number) beklemektedir.
- **Frontend Gönderimi (`apps/web_app/src/pages/merchant/settings/index.tsx` & `product-modal.tsx`):**
  - Frontend yalnızca `{ fileName: file.name, contentType: file.type }` göndermekteydi (`mimeType` ve `fileSize` eksikti).
- **Sonuç:** Zod doğrulama hatası fırlatarak HTTP 400 dönüyordu.

### 2.2. Sipariş Kartlarında NaN Tutarları
- **Backend Model (`OrderItem`):**
  - Veritabanı ve API, ürün birim fiyatını `unitPrice` alanında döndürmektedir.
- **Frontend Beklentisi (`apps/web_app/src/pages/merchant/orders/index.tsx`):**
  - Kod doğrudan `item.price * item.quantity` hesaplamaya çalışıyordu. `item.price` undefined olduğu için `undefined * 1 = NaN` ➡️ `₺NaN` üretiliyordu.
  - Ayrıca `order.totalAmount` için `Number(order.totalAmount ?? 0)` koruması eksikti.
  - Müşteri adı `order.user?.fullName` olarak aranıyordu, fakat API `order.consumer` (`name`, `surname`, `phone`) döndürmektedir.

### 2.3. Sipariş Sonrası Sepet Temizleme
- **Mevcut Durum (`apps/consumer_app/lib/apps/consumer/checkout/payment_page.dart`):**
  - Sipariş başarılı olduktan sonra `cartNotifier.clearCart()` parametresiz çağrılarak tüm işletme sepetleri siliniyordu.
- **Düzeltme:**
  - `cartNotifier.clearCart(orderedBusinessId)` şeklinde yalnızca siparişi verilen dükkanın ID'si verilerek temizlenecektir.

---

## 3. Yapılacak Değişiklikler ve Mimari Çözüm

### 3.1. Backend (`backend/src/types/media.types.ts` & `backend/src/controllers/media.controller.ts`)
- `UploadRequestSchema` esnek hale getirilecek:
  - `mimeType` veya `contentType` kabul edilecek (varsayılan: `image/jpeg`).
  - `fileSize` opsiyonel hale getirilecek (gönderilmediğinde 1MB varsayılan limit atanacak).
  - Desteklenen formatlara `image/gif` ve `image/svg+xml` eklenecek.

### 3.2. Frontend Web Paneli (`apps/web_app`)
- **Settings & Product Modal:**
  - `handleFileUpload` ve `handleImageUpload` fonksiyonlarında `fileName`, `mimeType`, `contentType` ve `fileSize` eksiksiz gönderilecek.
- **Orders Sayfası (`apps/web_app/src/pages/merchant/orders/index.tsx`):**
  - `OrderCard` bileşeninde `unitPrice` ve `price` güvenli okunacak:
    `const unitPrice = Number(item.unitPrice ?? item.price ?? item.product?.price ?? 0);`
    `const itemTotal = unitPrice * (Number(item.quantity) || 1);`
  - `order.totalAmount` güvenli okunacak: `Number(order.totalAmount ?? order.total ?? 0).toFixed(2)`.
  - Müşteri adı ve telefon bilgisi `order.consumer` veya `order.user` üzerinden doğru formatlanacak.

### 3.3. Consumer Flutter App (`apps/consumer_app`)
- [payment_page.dart](file:///c:/Users/tunah/Sources/Hoppa/hoppa/apps/consumer_app/lib/apps/consumer/checkout/payment_page.dart):
  - `cartNotifier.clearCart(orderedBusinessId)` ile sadece siparişi tamamlanan işletmenin sepeti temizlenecek.

---

## 4. Doğrulama Protokolü
1. `backend`: `npx tsc --noEmit` ile TypeScript derleme testi.
2. `web_app`: `npm run build` veya TypeScript kontrolü.
3. `consumer_app`: `flutter analyze` ile statik analiz doğrulaması.

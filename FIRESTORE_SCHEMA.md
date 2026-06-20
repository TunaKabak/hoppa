# Firestore Database Schema Documentation

## Koleksiyonlar (Collections)

### 1. `users` - Kullanıcı Verileri

Kullanıcı bilgilerini depolayan koleksiyon.

```json
{
  "uid": "auth_uid_from_firebase",
  "phone_number": "+905338000000",
  "display_name": "Ahmet Yılmaz",
  "address": "Gönyeli, Belediye Bulvarı No:5, Daire:10",
  "created_at": "TIMESTAMP",
  "last_login": "TIMESTAMP"
}
```

**Indeksler:**
- `phone_number` (Ascending)
- `created_at` (Descending)

---

### 2. `products` - Ürünler

Market panelinden eklenen ürünleri depolayan koleksiyon.

```json
{
  "id": "prod_001",
  "name": "Erikli Su 5L",
  "price": 35.0,
  "category": "Su & İçecek",
  "image_url": "https://storage.googleapis.com/...",
  "is_active": true,
  "market_id": "market_01",
  "created_at": "TIMESTAMP",
  "updated_at": "TIMESTAMP"
}
```

**Indeksler:**
- `market_id` (Ascending)
- `category` (Ascending)
- `is_active` (Ascending)
- Composite: `market_id` + `is_active` + `created_at` (Descending)

**Kategoriler (Varsayılan):**
- Su & İçecek
- Gıda
- Temizlik Ürünleri
- Kişisel Bakım
- Diğer

---

### 3. `orders` - Siparişler

En kritik koleksiyon. Tüm sipariş bilgilerini denormalize edilerek depolıyor.

```json
{
  "id": "ord_20231025_XA92",
  "user_id": "uid_12345",
  "user_phone": "+905338000000",
  "user_address": "Gönyeli, Belediye Bulvarı, No:5, Daire:10",
  "location_link": "https://maps.google.com/?q=35.123456,33.654321",
  "total_amount": 150.50,
  "payment_method": "cash_on_delivery",
  "status": "pending",
  "created_at": "TIMESTAMP",
  "items": [
    {
      "product_id": "prod_001",
      "name": "Erikli Su 5L",
      "price": 35.0,
      "quantity": 2
    },
    {
      "product_id": "prod_002",
      "name": "Süt 1L",
      "price": 18.50,
      "quantity": 1
    }
  ]
}
```

**Sipariş Durumları (Status Enum):**
- `pending` - Beklemede (Yeni sipariş)
- `preparing` - Hazırlanıyor
- `on_way` - Yolda
- `delivered` - Teslim Edildi
- `cancelled` - İptal Edildi

**Ödeme Yöntemleri:**
- `cash_on_delivery` - Kapıda Ödeme (Şimdilik sadece bu)

**Indeksler:**
- `user_id` (Ascending)
- `status` (Ascending)
- `created_at` (Descending)
- Composite: `user_id` + `created_at` (Descending)

**Denormalizasyon Nedenleri:**
- Ürün adı/fiyatı değişirse sipariş bozulmasın
- Okuma performansı maksimum olsun
- Sipariş detayını çekmek için join gerekli olmasın

---

## Firestore Güvenlik Kuralları (Security Rules)

```javascript
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    // Kullanıcı doğru/kimlik kontrolü
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return request.auth.uid == userId;
    }

    // Users koleksiyonu
    match /users/{userId} {
      allow read: if isAuthenticated() && isOwner(userId);
      allow write: if isAuthenticated() && isOwner(userId);
      allow create: if isAuthenticated();
    }

    // Products koleksiyonu (herkes okuyabilir)
    match /products/{productId} {
      allow read: if true;
      allow write: if false; // Sadece admin (Firebase Console)
    }

    // Orders koleksiyonu
    match /orders/{orderId} {
      allow read: if isAuthenticated() && 
                     isOwner(resource.data.user_id);
      allow create: if isAuthenticated() && 
                       request.auth.uid == request.resource.data.user_id;
      allow update: if false; // Sadece backend
      allow delete: if false;
    }
  }
}
```

---

## Koleksiyon Oluşturma Adımları

### Firebase Console'da Yapılacaklar:

1. **Firestore Database Oluştur**
   - Google Cloud Console → Firestore Database → Create Database
   - Location: Europe (en yakın bölge seç)

2. **Collections Oluştur**
   - `users` - Boş oluştur
   - `products` - El ile ürün ekle
   - `orders` - Boş oluştur

3. **Products'a Örnek Veri Ekle**
   ```json
   {
     "id": "prod_001",
     "name": "Erikli Su 5L",
     "price": 35.0,
     "category": "Su & İçecek",
     "image_url": "https://example.com/image.jpg",
     "is_active": true,
     "market_id": "market_01"
   }
   ```

4. **Indeksler Oluştur**
   - Firestore Console → Indexes tab'ı → Create Index
   - Gerekli composite indeksler otomatik oluşturulur

5. **Security Rules Ayarla**
   - Firestore Console → Rules tab'ı
   - Yukarıdaki kuralları paste et

---

## Dart Modelleri

Modeller `lib/models/` klasöründe bulunuyor:
- `product.dart` - Product model
- `order.dart` - Order ve OrderItem modelleri
- `user.dart` - AppUser model

Tüm modeller **JsonSerializable** kullanıyor. 
Build komutu: `flutter pub run build_runner build`

---

## Services

Veritabanı işlemleri `lib/core/services/` içinde:
- `firebase_service.dart` - Firebase base service
- `product_service.dart` - Ürün işlemleri
- `order_service.dart` - Sipariş işlemleri
- `user_service.dart` - Kullanıcı işlemleri
- `auth_service.dart` - Kimlik doğrulama

---

## Örnek Sorgu Kullanımları

### Tüm Ürünleri Getir
```dart
final products = await ProductService().getAllProducts();
```

### Kategoriye Göre Filtrele
```dart
final categoryProducts = await ProductService().getProductsByCategory('Su & İçecek');
```

### Sipariş Oluştur
```dart
final orderId = await OrderService().createOrder(
  userId: 'uid_12345',
  userPhone: '+905338000000',
  userAddress: 'Adres',
  locationLink: null,
  totalAmount: 150.50,
  items: cartItems,
);
```

### Kullanıcı Siparişlerini İzle
```dart
OrderService().streamUserOrders(userId).listen((orders) {
  // orders listesi güncellendiğinde
});
```

---

## Notlar

- Denormalizasyon yapıldığı için (orders koleksiyonunda ürün adı/fiyat kopyası), order güncellemeleri sadece status değişikliği için
- Storage'dan resimleri yükle: `FirebaseStorage.instance`
- Timestamp'leri HER ZAMAN `FieldValue.serverTimestamp()` ile ayarla (client time karışıklığından kaçınmak için)

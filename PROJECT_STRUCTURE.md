# KKTC Market - Proje Yapısı Özeti

## Klasör Hiyerarşisi

```
lib/
├── main.dart                          # Ana entry point
├── core/                              # Paylaşılan kod
│   ├── core.dart                      # Exports
│   ├── constants/
│   │   ├── app_colors.dart           # Renk paletini
│   │   ├── app_strings.dart          # Tüm string constants
│   │   └── app_constants.dart        # Genel constants
│   ├── services/
│   │   ├── firebase_service.dart     # Firebase base
│   │   ├── auth_service.dart         # Kimlik doğrulama
│   │   ├── product_service.dart      # Ürün işlemleri
│   │   ├── order_service.dart        # Sipariş işlemleri
│   │   └── user_service.dart         # Kullanıcı işlemleri
│   └── utils/
│       ├── currency_formatter.dart   # ₺ formatlaması
│       ├── date_helper.dart          # Tarih işlemleri
│       └── validators.dart           # Doğrulama fonksiyonları
│
├── features/                          # Feature-First modüller
│   ├── auth/                          # Kimlik doğrulama
│   │   ├── auth.dart                 # Export hub
│   │   ├── screens/
│   │   ├── providers/
│   │   └── widgets/
│   │
│   ├── home/                          # Ana sayfa
│   │   ├── home.dart
│   │   ├── screens/
│   │   ├── providers/
│   │   └── widgets/
│   │
│   ├── market/                        # Ürün listeleme
│   │   ├── market.dart
│   │   ├── screens/
│   │   ├── providers/
│   │   └── widgets/
│   │
│   ├── cart/                          # Sepet yönetimi
│   │   ├── cart.dart
│   │   ├── screens/
│   │   ├── providers/
│   │   └── widgets/
│   │
│   ├── checkout/                      # Ödeme süreci
│   │   ├── checkout.dart
│   │   ├── screens/
│   │   ├── providers/
│   │   └── widgets/
│   │
│   └── order_history/                 # Sipariş takibi
│       ├── order_history.dart
│       ├── screens/
│       ├── providers/
│       └── widgets/
│
└── models/                            # Data models (JsonSerializable)
    ├── product.dart
    ├── order.dart
    └── user.dart
```

## Önemli Dosyalar

### Firestore Şeması
- **FIRESTORE_SCHEMA.md** - Veritabanı tasarımı, kuralları ve örnek sorgular

## Feature-First Yapısının Avantajları

✅ Bir feature tamamlanırsa, ilgili tüm kod (UI + Logic) bir yerde
✅ Yeni feature eklemek = yeni klasör eklemek
✅ Feature silmek kolay
✅ Takım geliştirmede conflict az
✅ Solo geliştirici için mükemmel

## Service Layer

Her koleksiyon için bir Service yazılmış:
- `ProductService` - Ürünler
- `OrderService` - Siparişler
- `UserService` - Kullanıcılar
- `AuthService` - Kimlik doğrulama

Tüm async operasyonları kapsanması için Stream ve Future destekleniyor.

## Constants

Tüm constant değerler `core/constants/` içinde:
- Renkler: `AppColors`
- String'ler: `AppStrings`
- Genel: `AppConstants`

## State Management

Henüz State Management seçilmedi. Yapı herhangi bir sisteme uyum sağlayabilir:
- **Riverpod** (önerilir, modern)
- **Provider** (basit)
- **BLoC** (scale edilebilir)
- **GetX** (hızlı geliştirme)

Her feature klasöründe `providers/` klasörü hazır. 
Dosyalara `*_provider.dart` adı verilerek kolay bulunabilir.

## JSON Serialization

Build komutu:
```bash
flutter pub run build_runner build
```

Bunu çalıştırmak `.g.dart` dosyalarını oluşturacak.

## Firestore Collection Yapısı

### products
- Ürün listeleme
- Kategori filtresi
- Search

### orders
- Sipariş oluşturma
- Sipariş takibi
- Denormalize veri (İsim, fiyat koruması)

### users
- Profil bilgileri
- Adres
- Login tarihleri

---

**Hazırsın! Şimdi features içinde screens ve widgets yazabilirsin.**

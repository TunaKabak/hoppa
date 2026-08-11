# Story 69 - Yemek Kategorisi Ürün Özelleştirmeleri, Yan Ürünler ve Promosyon Mimarisi (Food Customization & Options Engine)

Bu hikaye belgesi; Hoppa platformunda restoran ve yemek sektöründe faaliyet gösteren satıcıların ürünlerine porsiyon/boyut seçenekleri, çıkarılabilir/eklenebilir malzeme tercihleri, promosyonlu yan ürünler ve ekstralar tanımlayabilmesini; tüketicilerin ise bu seçenekleri modern, iştah kabartıcı ve dinamik bir arayüz üzerinden özelleştirip siparişe dönüştürebilmesini amaçlar.

---

## 🧭 1. BÖLÜM: Akış Diyagramı (System Flowchart)

```
                     [Merchant: Yemek Ürünü Ekle / Düzenle]
                                       │
                ┌──────────────────────┼──────────────────────┐
                ▼                      ▼                      ▼
       [Hazır Şablonlar]      [Boyut & Porsiyon]     [Malzeme / Çıkarılacak]
     (Burger/Pizza/Döner)    (Küçük/Orta/Büyük)       (Soğan/Turşu/Domates)
                │                      │                      │
                └──────────────────────┼──────────────────────┘
                                       │
                                       ▼
                     [Yan Ürün & Promosyonlu İçecekler]
                     (Kola, Patates Kızartması +25₺)
                                       │
                                       ▼
                     [Prisma: ProductOptionGroup & Option]
                                       │
                                       ▼
                    [Consumer: Yemek Detay BottomSheet]
                                       │
             ┌─────────────────────────┼─────────────────────────┐
             ▼                         ▼                         ▼
   [Boyut Seç (Radio)]    [İçindekilerden Çıkar]    [Yan Ürün / Sos Ekle]
             │                         │                         │
             └─────────────────────────┼─────────────────────────┘
                                       │
                                       ▼
                  [Canlı Fiyat Hesaplayıcı & Sepete Ekle]
                                       │
                                       ▼
                 [Sipariş Oluştur (OrderItemOption Snapshot)]
```

---

## 🛠️ 2. BÖLÜM: Veritabanı ve Şema Katmanı (Prisma Schema)

```prisma
model ProductOptionGroup {
  id                  String          @id @default(uuid())
  productId           String
  product             Product         @relation(fields: [productId], references: [id], onDelete: Cascade)
  name                String          // Örn: "Porsiyon / Boyut", "İçindekiler", "Yan Ürün & İçecek"
  description         String?         // Yardımcı açıklama
  type                OptionGroupType @default(EXTRA) 
  selectionType       SelectionType   @default(CHECKBOX) 
  minSelections       Int             @default(0) // 0: Opsiyonel, >=1: Zorunlu
  maxSelections       Int             @default(1) // Maksimum seçim sınırı
  freeSelectionsCount Int             @default(0) // Kaç adet ücretsiz (Örn: 2 sos ücretsiz)
  displayOrder        Int             @default(0)
  options             ProductOption[]

  createdAt           DateTime        @default(now())
  updatedAt           DateTime        @updatedAt

  @@index([productId])
}

enum OptionGroupType {
  VARIATION      // Boyut / Porsiyon / Hamur Tipi
  INGREDIENT     // Malzeme Seçimi (Çıkarılabilir / Eklenebilir)
  SIDE_PRODUCT   // Yan Ürün & Promosyonlu İçecek
  EXTRA          // Sos & Ekstralar
}

enum SelectionType {
  RADIO          // Tekil Seçim (Radio Button)
  CHECKBOX       // Çoklu Seçim (Checkbox)
  COUNTER        // Adetli Seçim (+/- Stepper)
}

model ProductOption {
  id                 String             @id @default(uuid())
  optionGroupId      String
  optionGroup        ProductOptionGroup @relation(fields: [optionGroupId], references: [id], onDelete: Cascade)
  name               String             // Örn: "Büyük Boy", "Domates Olmasın", "Kutu Kola"
  price              Decimal            @db.Decimal(10, 2) @default(0.00) // Ekstra veya indirimli yan ürün fiyatı
  isDefault          Boolean            @default(false) // Varsayılan seçili mi?
  isRemovable        Boolean            @default(false) // Çıkarılabilir malzeme mi? (0₺ kalır, mutfağa kırmızı çıkar uyarısı düşer)
  maxQuantity        Int                @default(1) // Adetli seçimde maksimum limit
  linkedProductId    String?            // Yan ürün dükkan kataloğundan çekiliyorsa stok referansı
  isActive           Boolean            @default(true)
  displayOrder       Int                @default(0)

  createdAt          DateTime           @default(now())
  updatedAt          DateTime           @updatedAt

  @@index([optionGroupId])
}

model OrderItemOption {
  id             String      @id @default(uuid())
  orderItemId    String
  orderItem      OrderItem   @relation(fields: [orderItemId], references: [id], onDelete: Cascade)
  groupName      String      // Seçenek grubu adı (Snapshot)
  name           String      // Seçenek adı (Snapshot)
  price          Decimal     @db.Decimal(10, 2) // Sipariş anındaki fiyat snapshot
  quantity       Int         @default(1)
  actionType     OptionAction @default(ADD) // ADD (Eklendi), REMOVE (Çıkarıldı)
  optionId       String?

  createdAt      DateTime    @default(now())

  @@index([orderItemId])
}

enum OptionAction {
  ADD
  REMOVE
}
```

---

## 🎨 3. BÖLÜM: Kullanıcı Deneyimi ve Arayüz Tasarımı (UI/UX Highlights)

### A. Restoran Paneli (Merchant App)
1. **Hazır Şablon Kütüphanesi (One-Tap Presets)**:
   - Pizza, Burger, Kebap/Döner, İçecek/Tatlı şablonları.
   - Tek tıkla varsayılan opsiyon gruplarını yükleme ve özelleştirme.
2. **Toplu Malzeme Girişi & Çıkarılabilir Malzeme Toggleri**:
   - Virgüle göre malzeme ayırma (Örn: "Marul, Domates, Turşu, Soğan").
   - Malzemenin yanında "Çıkarılabilir İçerik" tik kutusu.
3. **Promosyonlu Yan Ürün Yöneticisi**:
   - Dükkanın diğer ürünlerinden yan ürün seçip indirimli menü fiyatı belirleme.

### B. Müşteri Paneli (Consumer App)
1. **Dinamik Yemek Özelleştirme Modalı (`FoodProductCustomizationSheet`)**:
   - Segmented control ile boyut seçimi.
   - Strikethrough (üstü çizili) görsel efektiyle çıkarılan malzemeleri belirginleştirme.
   - Yeşil fiyat farkı rozetleri (+₺15, İndirimli +₺25).
2. **Canlı Fiyat & Validasyon Barı**:
   - Eksik zorunlu seçimlerde uyarı mesajı ("Lütfen porsiyon seçiniz").
   - Tamamlandığında sepete ekleme butonu canlı fiyatı gösterir.

---

## 🏁 4. BÖLÜM: Kabul Kriterleri & Doğrulama
* [ ] Prisma veritabanı şeması güncellendi ve migration çalıştırıldı.
* [ ] Shared paket model güncellemeleri tamamlandı.
* [ ] Merchant App için yemek özelleştirme ve şablon sihirbazı hazırlandı.
* [ ] Consumer App için interaktif yemek detay bottom sheet'i ve sepet fiyat hesaplama motoru entegre edildi.
* [ ] Statik analiz (`flutter analyze`, `npx tsc --noEmit`) başarıyla doğrulandı.

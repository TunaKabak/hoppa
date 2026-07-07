Story 28 - Esnek Ürün Seçenekleri ve Ekstralar (Product Custom Options)

Bu görev belgesi; Hoppa platformunda faaliyet gösteren restoran ve market gibi farklı işletme türlerinin ürünlerine esnek, fiyat farkı eklenebilir ve seçilebilir seçenek grupları (opsiyonlar/ekstralar) ekleyebilmesini; bu seçeneklerin sipariş akışında fiyat hesaplamasına dahil edilip veritabanına kaydedilmesini amaçlar.

---

## 🧭 1. BÖLÜM: Sistem Akış Diyagramı (System Flowchart)

```
       [Merchant: Ürün Ekle/Düzenle]
                    │
                    ▼
       [Seçenek Grubu ve Seçenek Tanımla] (Örn: Soslar / Ketçap(+0₺), Mayonez(+0₺))
                    │
                    ▼
         [Ürün Kaydet (Transaction)] ──► [Prisma: ProductOptionGroup & ProductOption]
                    │
                    ▼
     [Consumer: Dükkan Sayfası / Sepet] ──► [Seçenekleri Görüntüle ve İşaretle]
                    │
                    ▼
         [Sipariş Oluştur (Checkout)]
                    │
       ┌────────────┴────────────┐
       ▼                         ▼
 [Fiyat Hesaplama]        [Veritabanı Kaydı]
(Net Fiyat + Ekstralar)   (Prisma: OrderItemOption Snapshots)
```

---

## 🛠️ 2. BÖLÜM: Veritabanı ve Şema Katmanı (Prisma Schema)

Prisma şemamıza seçenek grupları, seçenekler ve sipariş anında bu seçeneklerin snapshot'ını tutmak için gerekli tablolar eklenmiştir.

```prisma
model ProductOptionGroup {
  id             String          @id @default(uuid())
  productId      String
  product        Product         @relation(fields: [productId], references: [id], onDelete: Cascade)
  name           String          // Örn: "Sos Seçimi", "Hamur Tipi"
  minSelections  Int             @default(0) // 0 = İsteğe bağlı
  maxSelections  Int             @default(1) // 1 = Tekil, >1 = Çoklu seçim
  options        ProductOption[]
  createdAt      DateTime        @default(now())
  updatedAt      DateTime        @updatedAt
}

model ProductOption {
  id                 String             @id @default(uuid())
  optionGroupId      String
  optionGroup        ProductOptionGroup @relation(fields: [optionGroupId], references: [id], onDelete: Cascade)
  name               String             // Örn: "Ketçap", "Klasik Kalın Hamur"
  price              Decimal            @default(0.00) @db.Decimal(10, 2)
  isActive           Boolean            @default(true)
  createdAt          DateTime           @default(now())
  updatedAt          DateTime           @updatedAt
}

model OrderItemOption {
  id          String    @id @default(uuid())
  orderItemId String
  orderItem   OrderItem @relation(fields: [orderItemId], references: [id], onDelete: Cascade)
  optionId    String?   // Tercihe bağlı olarak orijinal opsiyona referans
  name        String    // Opsiyon adı snapshot
  price       Decimal   @default(0.00) @db.Decimal(10, 2) // Fiyat snapshot
  createdAt   DateTime  @default(now())
}
```

---

## ⚙️ 3. BÖLÜM: Backend Katmanı (Product & Order Controllers)

### A. Ürün Kayıt ve Güncelleme (`ProductController.ts`)
Ürün oluştururken ve güncellerken seçenek grupları iç içe geçmiş (nested JSON) olarak API'ye gönderilir. Güncelleme işleminde transaction kullanılarak eski seçenekler silinir ve yenileri eklenir (delete-then-recreate):

```typescript
// ProductController.ts - createProduct / updateProduct
optionGroups: optionGroups && Array.isArray(optionGroups) ? {
  create: optionGroups.map((og: any) => ({
    name: og.name,
    minSelections: og.minSelections !== undefined ? parseInt(og.minSelections.toString()) : 0,
    maxSelections: og.maxSelections !== undefined ? parseInt(og.maxSelections.toString()) : 1,
    options: og.options && Array.isArray(og.options) ? {
      create: og.options.map((opt: any) => ({
        name: opt.name,
        price: opt.price !== undefined ? parseFloat(opt.price.toString()) : 0.00,
        isActive: opt.isActive !== undefined ? (opt.isActive === true || opt.isActive === "true") : true
      }))
    } : undefined
  }))
} : undefined
```

### B. Sipariş İşleme ve Fiyat Hesaplama (`OrderController.ts`)
Tüketici sipariş verirken seçtiği opsiyonların fiyatları ürün net fiyatına eklenerek `totalAmount` hesaplanır. Sipariş kalemleri veritabanına yazılırken seçilen opsiyonlar da `OrderItemOption` olarak kaydedilir:

```typescript
const optionsPrice = item.options && Array.isArray(item.options)
  ? item.options.reduce((sum: number, opt: any) => sum + parseFloat(opt.price || 0), 0)
  : 0;
const unitPrice = Number(product.price) + optionsPrice;

await tx.orderItem.create({
  data: {
    orderId: createdOrder.id,
    productId: item.productId,
    quantity: item.quantity,
    unitPrice: unitPrice,
    options: item.options && Array.isArray(item.options) ? {
      create: item.options.map((opt: any) => ({
        name: opt.name,
        price: parseFloat(opt.price || 0),
        optionId: opt.optionId || null
      }))
    } : undefined
  }
});
```

---

## 📱 4. BÖLÜM: Mobil Arayüz Katmanı (Merchant App UI)

### A. Ürün Modeli ve Repositori (`product.dart` & `merchant_product_repository.dart`)
Dart modeline `ProductOptionGroup` ve `ProductOption` modelleri eklenmiş, JSON'dan dönüştürme metotları (`fromMap`, `toMap`) entegre edilmiştir.

### B. Seçenek Grubu ve Seçenek Yönetim Paneli (`merchant_product_list_page.dart`)
Restoran işletmeleri için ürün ekleme ve düzenleme pencerelerine dinamik bir seçenek editörü yerleştirilmiştir:
* **Grup Ekleme:** Grup adı, minimum seçim limiti ve maksimum seçim limitini belirleyen diyalog.
* **Seçenek Ekleme:** Grup içerisine isim ve opsiyonel fiyat farkı girilerek seçenekler tanımlanabilir.
* **Silme Desteği:** Tanımlanan seçenekler ve seçenek grupları kartlar üzerinden kolayca kaldırılabilir.

---

## 🏁 5. BÖLÜM: Doğrulama ve İmza (Sign-Off)

* [x] Veritabanı push ve client üretimi yapıldı.
* [x] Backend derleme kontrolü (`npx tsc --noEmit`) başarıyla tamamlandı.
* [x] Arayüz statik analiz kontrolü (`flutter analyze`) hatasız tamamlandı.

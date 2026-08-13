# Story 74: Restoran Listelenmeme ve Ürün Opsiyon Grupları Aktarım Sorununun Çözümü

## 1. Amaç ve Kapsam
Tüketici uygulamasında (`apps/consumer_app`) "Restoran" veya "Yemek" kategorisi seçildiğinde opsiyon içeren/içermeyen restoranların listelenmeme sorunu ile dükkan detayında ürün opsiyon gruplarının (`optionGroups`) eksik parse edilmesi sorunu kökten çözülecektir.

---

## 2. Tespit Edilen Kök Nedenler (Root Causes)

1. **Tüketici Uygulaması Kategori Filtreleme Uyuşmazlığı (`business_selection_page.dart`):**
   - Kullanıcı ana sayfadan "Restoran" veya "Yemek" kategorisine tıkladığında `widget.category` değeri `"Restoran"` (veya `"Yemek"`) olarak aktarılmaktadır.
   - `business_selection_page.dart` içerisinde yapılan filtreleme kontrolü:
     `b.categories.contains(widget.category) || b.type.label == widget.category || b.type.name.toLowerCase() == widget.category!.toLowerCase()`
   - Restoran türündeki dükkanlar için:
     - `b.type` = `BusinessType.restaurant`
     - `b.type.name` = `'restaurant'` (İngilizce)
     - `b.type.label` = `'Yemek'` (Türkçe label)
   - `widget.category` = `"Restoran"` olduğunda:
     - `b.type.label == "Restoran"` -> FALSE (`'Yemek' != 'Restoran'`)
     - `b.type.name.toLowerCase() == "restoran"` -> FALSE (`'restaurant' != 'restoran'`)
     - `b.categories.contains("Restoran")` -> FALSE
   - **Sonuç:** Kategori filtresi restoranları yanlış değerlendirerek `FALSE` döner ve restoranlar listeden tamamen elenip gizlenir!

2. **Ürün Opsiyon Grupları Parse Eksikliği (`consumer_shop_repository.dart`):**
   - Backend API (`ConsumerShopController.ts`) ürün verisinde `optionGroups` (Seçenek grupları & opsiyonlar) bilgisini göndermektedir.
   - Ancak Flutter tarafındaki `_parseBusinessProduct` ve `getFavoriteProducts` metotlarında `productMap` oluşturulurken `'optionGroups'` alanı atlanmıştır.
   - Bu nedenle `Product.fromMap` çağrıldığında ürün opsiyonları boş dizi (`[]`) olarak kalmaktadır.

3. **Backend Kategori Ağacı Esnekliği (`ConsumerShopController.ts`):**
   - `getShopActiveCategories` fonksiyonunda kök kategoriler çekilirken strictly `shopType: shopType` aranmaktadır.
   - Eğer restoran ürünlerinin bağlandığı bir kategorinin DB'deki `shopType` alanı `"MARKET"` varsayılan değerinde kaldıysa, restoran kategorileri getirememektedir.

---

## 3. Çözüm Adımları

1. **`business_selection_page.dart` Geliştirmesi:**
   - Kategori filtreleme mantığı `catLower.contains('restoran') || catLower.contains('yemek') || catLower == 'restaurant'` takma adlarını kapsayacak şekilde `BusinessType.restaurant` ve `BusinessType.cafe` türleri ile tam eşleşecek biçimde akıllı süzgeç haline getirilecektir.
   - Aynı esnek eşleştirme Market, Manav, Kasap, Su, Çiçek, Fırın ve Kuruyemiş kategorileri için de uygulanacaktır.

2. **`consumer_shop_repository.dart` Geliştirmesi:**
   - `_parseBusinessProduct` ve `getFavoriteProducts` metotlarında `json['optionGroups']` verisi `productMap` içerisine eklenerek opsiyon içeren restoran ürünlerinin (soslar, boyutlar, malzemeler) eksiksiz yüklenmesi sağlanacaktır.

3. **`ConsumerShopController.ts` Geliştirmesi:**
   - `getShopActiveCategories` sorgusunda dükkan kategorileri çekilirken dükkanın aktif ürünlerine sahip tüm kök kategoriler dahil edilerek kategori ağacı %100 dayanıklı hale getirilecektir.

# Story 83: Hoppa Özel Kategori Filtre Tasarımı ve Ürün Marka Temizliği

## 1. Genel Bakış ve Amaç
Kullanıcı geri bildirimi doğrultusunda:
1. Yemek, su ve diğer kategorilerdeki ürünlerde varsayılan olarak çıkan `"Hoppa"` marka ibaresi kaldırılacak; marka alanı yalnızca market ürünlerinde gerçek bir marka tanımlıysa gösterilecek, yemek/restoran/su ürünlerinde marka etiketi gösterilmeyecek.
2. İşletme detay sayfasındaki (`ModernShopDetailPage` / `shop_detail_page.dart`) ana kategori ve alt kategori filtreleme çubukları, Hoppa'nın modern marka kimliğine ve 4 ana sektöre (Market, Restoran, Su, Çiçek) özel olarak sıfırdan tasarlanacak.

---

## 2. Tasarım ve Mimari Detaylar

### 2.1. Ürün Marka Mantığının Düzeltilmesi
- `consumer_shop_repository.dart`: `json['brand'] ?? 'Hoppa'` varsayılanı `json['brand'] ?? ''` olarak düzeltilecek.
- `modern_product_card.dart` ve `product_detail_page.dart`: Yalnızca `product.brand.isNotEmpty && product.brand.toLowerCase() != 'hoppa' && product.brand.toLowerCase() != 'genel' && product.brand.toLowerCase() != 'yok'` olduğunda marka alanı render edilecek.

### 2.2. Hoppa Özel Kategori & Alt Kategori Tasarım Sistemi
1. **İkon ve Görsel Haritalama:**
   - 4 sektörün tüm 31 ana kategorisi ve alt kırılımları için modern, sektörel ve estetik Material Rounded ikonlar eşleştirilecek.
2. **Ana Kategori Kartları (`_StickyCategoryHeaderDelegate`):**
   - `AnimatedContainer` ile yumuşak geçişler.
   - Seçili durumda: Canlı Hoppa turuncusu gradyanı (`0xFFFF6B00` -> `0xFFFF8A00`) veya yeşil/tema uyumlu zemin, beyaz kabartmalı ikon, canlı yazı ve alt aktiflik gösterge çizgisi.
   - Seçili olmayan durumda: Yumuşak açık gri/pastel zemin (`#F4F6F8`), modern koyu gri ikon ve net okunabilir tipografi.
3. **Alt Kategori Hap Butonları (Subcategory Pills):**
   - `StadiumBorder` (oval hap) biçiminde modern kapsüller.
   - Seçili: Canlı Hoppa Turuncu degrade zemin, beyaz kalın yazı.
   - Seçili olmayan: Soft gri zemin (`#F1F3F5`), zarif sınır çizgisi ve yumuşak gri yazı.
4. **Mini Kategori Barı (Collapsed Header):**
   - Sayfa aşağı kaydırıldığında SliverAppBar içine giren mini kategori hapları aynı premium tasarım çizgisine kavuşturulacak.

# Story 62: Market Detayı Header Animation & Curves, Sepet Rozeti, Hesabım Menüsü ve Ana Ekran Sepet Kartı

## 1. Amaç ve Kapsam
Bu hikaye kapsamında Hoppa Tüketici Uygulamasındaki (`consumer_app`) aşağıdaki revizyonlar gerçekleştirilecektir:
1. **İşletme Detayı Header & Curve Revizyonu (`shop_detail_page.dart`):**
   * İlk açılışta (genişletilmiş header): Hiçbir yerde kavis (curve) olmayacak, düz keskin köşeli header ve gövde.
   * Aşağı scroll yapıldığında (daralan header): Aşağıya doğru kavisli (`bottomLeft: Radius.circular(24)`, `bottomRight: Radius.circular(24)`) turuncu header konteyneri animasyonlu biçimde belirecek.
   * Kategori filtreleme çipi/barı (`ListView` kategorileri) da bu kavisli turuncu header yapısının içerisinde yer alacak.
2. **Hesabım Menüsü İkon Tema Güncellemesi (`account_bottom_sheet.dart`):**
   * Profil sayfası temasına uygun şekilde tüm menü ikonlarında turuncu ikonlar (`Color(0xFFFF6B00)` / `Color(0xFFE95D22)`) ve turuncu dairesel zemin kullanılacak.
3. **Ana Ekran Yüzen Sepet Kartında İşletme Bilgisi (`selection_category_page.dart` & `business_selection_page.dart`):**
   * Sepette ürün olduğunda ana ekranlarda gösterilen yüzen sepet kartına (Floating Cart Card) siparişin hangi dükkandan verildiğini gösteren **İşletme Logosu ve İsmi** eklenecek.
   * Modern, çift satırlı premium tasarım (Sol: Dükkan logosu + Dükkan adı & ürün sayısı, Sağ: Toplam Fiyat + Ok ikonu).

---

## 2. Teknik Uygulama Adımları

### 2.1. İşletme Detay Header & Kategori Barı (`shop_detail_page.dart`)
* `SliverAppBar` veya sticky header yapısı scroll offset'ine göre dinamik olarak curve yarıçapını (`0` ➔ `24.0`) değiştirecek.
* Gövde konteynerindeki yukarı yönlü `topLeft` / `topRight` `Radius.circular(24)` kaldırılacak (ilk ekranda tam dik/düz dikdörtgen).
* Kategori filtreleme barı sticky header alanına entegre edilecek ve turuncu kavisli arka planın içinde sunulacak.

### 2.2. Hesabım Menüsü İkon Uyarlaması (`account_bottom_sheet.dart`)
* `_buildMenuTile` metodundaki ikon rengi `Color(0xFFFF6B00)` (Hoppa Turuncusu) ve arka plan rengi `Color(0xFFFF6B00).withValues(alpha: 0.1)` olarak güncellenecek.

### 2.3. İşletme Bilgili Yüzen Sepet Kartı (`floating_cart_card.dart` / `selection_category_page.dart` / `business_selection_page.dart`)
* `FloatingCartCard` bileşeni oluşturulacak / güncellenecek.
* `ref.watch(cartProvider)` içindeki `currentBusinessId` ile `consumerShopsProvider` üzerinden ilgili dükkanın logosu ve adı çekilecek.
* Kart tasarımında:
  * Sol: 36x36 dükkan logosu / icon container + dükkan adı + `${cart.items.length} ürün`.
  * Sağ: Toplam tutar + Sepete Git yönlendirmesi.

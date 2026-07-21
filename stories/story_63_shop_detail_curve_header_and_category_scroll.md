# Story 63: İşletme Detayında Kavisli (Curve) Header ve Kategori Ortalama Scroll UX

## 1. Amaç ve Kapsam
Bu hikaye kapsamında Hoppa Tüketici Uygulamasındaki (`consumer_app`) `ModernShopDetailPage` (`shop_detail_page.dart`) ekranında aşağıdaki UX geliştirmeleri yapılacaktır:

1. **Aşağı Kaydırıldığında Kavisli (Curve) Header Yapısı:**
   - Sayfa aşağı doğru scroll edildikçe sticky kategori header yapısı dinamik kavis (`bottomLeft: Radius.circular(24)`, `bottomRight: Radius.circular(24)`) ve Hoppa turuncu gradyan arka plan kazanacak.
   - Kategori filtre barı (Tümü, Su, Meyve, vb.) bu kavisli (curved) turuncu container yapısının tam içinde estetik ve okunabilir şekilde yer alacak.
   - Yazı renkleri ve çip kart stilleri kavisli turuncu zemin üzerinde yüksek kontrast ve okuma kolaylığı sunacak biçimde uyarlanacak.

2. **Kategoriye Tıklanınca Liste Elemanını Ekran Ortasına Kaydırma (Scroll Centering):**
   - Kategori filtrelerinden biri seçildiğinde veya tıklandığında, kategori yatay `ListView` scroll pozisyonu seçilen kategoriyi tam ekran ortasına getirecek şekilde yumuşak animasyonla (`animateTo`, `Curves.easeOutCubic`) kaydırılacak.
   - Hem ana sticky kategori listesi hem de üst mini kategori barı tıklamalarda ortalama mantığına sahip olacak.

---

## 2. Teknik Detaylar ve Değişiklik Adımları

### 2.1. Sticky Kategori Header Curve Yapısı (`shop_detail_page.dart`)
- `_StickyCategoryHeaderDelegate` içerisinde scroll offset ve pinning durumuna göre kavis (radius 0 -> 24px) ve Hoppa gradyan arka planı uygulanacak.
- Kategori kartlarının metin renkleri ve seçili durum indikasyonları (beyaz çip/zemin, yeşil vurgu, net okunabilir başlıklar) kavisli header ile tam uyumlu hale getirilecek.

### 2.2. Kategori Liste Ortalama Mantığı (`_scrollToCategory`)
- `_ModernShopDetailPageState` içerisine bir `ScrollController _categoryScrollController` eklenecek.
- `_scrollToCategory(int index)` metodu yazılacak:
  - Tıklanan elemanın indeksi ve genişliği hesaplanarak hedef scroll offseti `(index * itemWidth) - (screenWidth / 2) + (itemWidth / 2)` formülü ile bulunacak.
  - Hedef offset `0.0` ile `maxScrollExtent` arasında sınırlandırılacak (`clamp`).
  - `_categoryScrollController.animateTo(targetOffset, duration: Duration(milliseconds: 300), curve: Curves.easeOutCubic)` ile akıcı bir şekilde ortalanacak.

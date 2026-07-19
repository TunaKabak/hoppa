# Story 57: İşletme Listesi Header Daralması ve Filtre Boşluklarının Azaltılması

Bu hikaye, `business_selection_page.dart` (İşletme Listesi) sayfasındaki UI iyileştirmelerini kapsar.

## 1. Amaç
* İşletme listesindeki filtre barı ile üstteki kavisli (curve) header arasındaki gereksiz boşluğun (SizedBox(height: 16)) kaldırılması/azaltılması ve filtrelerin yukarı yanaştırılması.
* Kullanıcı listeyi aşağı kaydırdığında (scroll), üstteki turuncu `HoppaHeader`'ın yumuşak bir animasyonla daralması (collapsed) ve adres seçme çubuğunun gizlenerek ekranda daha fazla dükkan görünmesi.
* Header daraldığında teslimat adresinin başlık altında küçük boyutta gösterilmeye devam etmesi.
* Filtre barındaki alt kategorilerin sağ tarafta aniden kesilmeden curve alanının altına doğru yumuşakça akması.
* **Yeni:** Sıralama filtresi yazısının kaldırılarak, filtrele butonuna benzer şekilde aktiflik durumunda badge (`1`) gösterilmesi.
* **Yeni:** Yatay alt kategorilerde bir chip'e tıklandığında, seçilen chip'in otomatik olarak ekranın ortasına yatayda kaydırılması (auto-center scroll).

## 2. Teknik Tasarım

### 2.1. HoppaHeader Güncellemesi (`hoppa_header.dart`)
* `HoppaHeader` widget'ı statik bir `Container` kullanıyordu, `AnimatedContainer`'a dönüştürüldü.

### 2.2. İşletme Seçim Sayfası Güncellemesi (`business_selection_page.dart`)
* `BusinessSelectionPage` sınıfı `ConsumerStatefulWidget`'a dönüştürüldü.
* Bir `ScrollController` eklendi ve `CustomScrollView`'a bağlandı.
* Scroll offset `50.0` değerini aştığında `_isCollapsed` state'i `true` yapılacak, altına indiğinde ise `false` yapılacak.
* `_isCollapsed` durumuna göre `HoppaHeader` yüksekliği dinamik olarak güncellenecek (`_isCollapsed ? 60.0 : 154.0`).
* Adres kartı `AnimatedSize` ile sarmalanarak collapsed durumunda yumuşak bir şekilde gizlenecek.
* `_isCollapsed` aktif olduğunda üst başlığın (`pageTitle`) altına `address.title` bilgisi 10px boyutunda eklenecek.
* Expanded dükkan listesinin başındaki `const SizedBox(height: 16)` `const SizedBox(height: 4)` yapıldı.
* Filtre barının sarmalayıcı padding'inin sağ kenarı `0` yapıldı, alt kategoriler scrollable listesinin sonuna `SizedBox(width: 16)` eklendi.
* **Yeni:** Sırala butonu `Stack` ve badge yapısına dönüştürülecek, `activeSort != 'Mesafe'` durumunda badge gösterilecek.
* **Yeni:** ChoiceChip'ler `Builder` ile sarmalanarak `onSelected` anında `Scrollable.ensureVisible(chipContext, alignment: 0.5)` çağrısı yapılacak.

## 3. Doğrulama Adımları
* Statik analiz doğrulaması: `flutter analyze`
* Manuel testler: Scroll ile header daralması, adres gösterimi, filtre akışı, sıralama badge görünümü ve chip'e tıklanınca ortalanması.

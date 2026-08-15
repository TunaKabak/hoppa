# Story 77: Ödeme Sayfası Sipariş Özeti Adet Gösterimi, Katlanabilir Seçenekler ve Hoppa Cüzdan Switch Entegrasyonu

## 1. Problem Tanımı ve Kullanıcı İhtiyacı
1. **Adet Sayısının Belirginliği:**
   - `PaymentPage` sipariş özeti kartında ürünün adedi yalnızca solda küçük bir gri kutucuk içinde (`28x28`) gösterilmekteydi. Bu durum kullanıcının ürün adedini ilk bakışta net olarak görememesine neden oluyordu.
   - İhtiyaç: Adet bilgisinin ürün başlığının yanında belirgin ve şık bir rozetle (`[2 Adet] Double Burger`) net şekilde gösterilmesi.

2. **Göz Yormayan ve Katlanabilir Seçenekler ("Detay Gör"):**
   - Ürünün birden fazla özelleştirmesi (ekstra malzeme, sos, boyut) olduğunda, tüm kırılımın doğrudan açık gelmesi sipariş özeti alanını uzatmakta ve karmaşık göstermektedir.
   - İhtiyaç: Özelleştirmelerin varsayılan olarak kompakt bir özet çubuğu (`"3 Özelleştirme • Detay Gör ▾"`) olarak gelmesi ve tıklandığında yumuşak bir animasyonla açılıp kapanabilmesi.

3. **Hoppa Cüzdanın Switch / Ek Seçenek Olarak Sunulması:**
   - Şu anda "Hoppa Cüzdanım" ayrı, bağımsız ve diğer yöntemlerle (Kredi Kartı / Kapıda Ödeme) birbirini dışlayan (mutually exclusive) bir radio butonu olarak yer almaktadır.
   - İhtiyaç:
     - Ana ödeme yöntemleri yalnızca **Kredi Kartı / Banka Kartı (Online)** ve **Kapıda / Mağazada Ödeme** olarak listelenmelidir.
     - Hoppa Cüzdan ise bu yöntemlerle birlikte kullanılabilen bir **Switch / Bakiye Kullanım Seçeneği** olarak sunulmalıdır.
     - Bakiye yeterli ise tutarın tamamı cüzdandan karşılanmalı; bakiye kısmi ise cüzdan bakiyesi düşülüp kalan tutar seçili ana ödeme yöntemiyle (Kredi Kartı veya Kapıda) tahsil edilmelidir.

4. **Sepeti Boşalt Seçeneğinin Modern Hoppa Tasarımına Uygun Hale Getirilmesi:**
   - `CartPage` başlığında yer alan eski tip `PopupMenuButton` yerine modern Hoppa cam/soft-pill tasarımına sahip buton ve alt açılır modern eylem menüsü (Bottom Action Sheet).
   - Tekli ve çoklu sepet temizleme seçeneklerinin şık kartlar, ikonlar ve açıklayıcı alt metinlerle sunulması.

---

## 2. Çözüm Mimarisi ve Tasarım

### 2.1. Sipariş Özeti Kartı İyileştirmeleri
- **Belirgin Adet Rozeti:** Her kalemin başında `[X Adet]` şeklinde turuncu/yeşil temalı belirgin bir miktar etiketi ve yanında ürün adı.
- **`ExpandableSelectedOptions` (Detay Gör / Gizle):**
  - Seçenekler varsa varsayılan olarak kompakt `"X Özelleştirme • Detay Gör ▾"` şeridi gösterilir.
  - Tıklandığında `SelectedOptionsBreakdown` hesaplanmış detayları ile aşağı doğru açılır.

### 2.2. Hoppa Cüzdan Switch Kartı ve Hibrit Ödeme Mantığı
- **Arayüz:**
  - Ödeme yöntemlerinin üstünde veya hemen altında özel tasarımlı **"Hoppa Cüzdan Bakiyesi Kullan"** switch kartı.
  - Anlık cüzdan bakiyesi (`₺150.00`) ve bakiye durumu.
- **Hesaplama & Akış:**
  - `_useWalletBalance == true` iken:
    - Bakiye >= Sipariş Toplamı ise: %100 Cüzdan ile ödeme (Kredi kartı gerekmez, buton: `"Siparişi Cüzdanla Onayla (₺X.XX)"`).
    - Bakiye < Sipariş Toplamı ise: Cüzdandan düşülecek tutar (`-₺X.XX`) özet tablosuna indirim/mahsup olarak yansıtılır; kalan tutar seçili karttan veya kapıda ödenir.
- **Backend Entegrasyonu:**
  - `OrderController.ts` içerisinde `useWallet: true` ve kısmi bakiye düşümü (`WalletService.withdraw`) ile entegre ödeme akışı.

### 2.3. Modern Sepet Temizleme Arayüzü
- `CartPage` başlığına soft dairesel silme butonu.
- Tıklandığında açılan modern Hoppa Action Sheet:
  - Aktif işletme sepetini temizleme (Ürün sayısı ve işletme adı ile).
  - Tüm sepetleri temizleme.
  - `HoppaDialog` ile onay akışı.

---

## 3. Etkilenecek Dosyalar
1. `apps/consumer_app/lib/apps/consumer/checkout/payment_page.dart` (MODIFY)
2. `apps/consumer_app/lib/apps/consumer/widgets/selected_options_breakdown.dart` (MODIFY)
3. `apps/consumer_app/lib/apps/consumer/cart/cart_page.dart` (MODIFY)
4. `backend/src/controllers/OrderController.ts` (MODIFY)

---

## 4. Doğrulama
- `flutter analyze` statik kod analizi.
- `npx tsc --noEmit` backend tip kontrolü.
- Adet gösterimi, "Detay Gör" açılır/kapanır menüsü ve Cüzdan switch'inin manuel doğrulanması.

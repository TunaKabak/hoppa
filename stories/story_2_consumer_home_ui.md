Epic: Consumer App Katalog Entegrasyonu (REST API Geçişi)
Task: Story 2 - Ana Sayfa (Home Screen) Dükkan Listesi UI Entegrasyonu

Kullanıcı Hikayesi: "Bir tüketici olarak, uygulamayı açtığımda ana sayfada etrafımdaki aktif dükkanları görebilmek istiyorum."

Story 1'de oluşturduğumuz `consumerShopsProvider` altyapısını kullanarak Consumer uygulamasının Ana Sayfasını (Dükkan listesinin olduğu ekranı) yeni API'mize bağlayacağız. Lütfen arayüz tasarımını (renkler, paddingler, kart yapıları) HİÇ BOZMADAN şu adımları uygula:

1. **İlgili Dosyayı Bul:** `apps/consumer_app/lib/` dizini altında Ana Sayfayı (Dükkanların listelendiği, muhtemelen `home_screen.dart` veya `shop_list_page.dart` isimli dosyayı) ve dükkanları gösteren alt widget'ları bul.

2. **Firebase Temizliği:** Bu dosyalardaki `import 'package:cloud_firestore...` gibi Firebase bağımlılıklarını ve `StreamBuilder` / `FutureBuilder` yapılarını TAMAMEN SİL.

3. **Riverpod UI Entegrasyonu:**
   - İlgili Widget'ı `ConsumerWidget` veya `ConsumerStatefulWidget` yapısına geçir.
   - Verileri dinlemek için `ref.watch(consumerShopsProvider).when(...)` desenini kullan.
   - `loading:` durumunda uygulamanın tasarımına uygun bir `CircularProgressIndicator` veya Shimmer (İskelet) yükleme efekti göster.
   - `error:` durumunda "Dükkanlar yüklenirken bir hata oluştu. Lütfen tekrar deneyin." şeklinde kullanıcı dostu bir hata arayüzü göster.
   - `data:` durumunda gelen dükkan listesini (`List<Shop>`) mevcut dükkan kartı (ShopCard) tasarımına bağla.

4. **Kritik Kurallar:**
   - **Görseller:** Firebase Storage iptal edildiği için, dükkanın logo/resim verisi boş veya null ise ekranda hata (Exception) patlamaması için sabit bir placeholder (Örn: `https://via.placeholder.com/150` veya `Icon(Icons.store)`) göster.
   - **Yönlendirme:** Dükkan kartına tıklandığında (`onTap`), Dükkan Detay (Menü) sayfasına dükkanın `id`'sini (String) parametre olarak gönderdiğinden emin ol. Detay sayfasının UI kodlarına ŞU AN DOKUNMA (Onu Story 3'te yapacağız).

Lütfen kodlamayı tamamla ve bana UI tarafında yaptığın değişiklikleri özetle. Onaylandıktan sonra son adım olan Story 3'e (Katalog/Menü UI) geçeceğiz.
Görev: Consumer App (Tüketici Uygulaması) Ana Sayfa ve Katalog UI Entegrasyonu

Merchant tarafındaki altyapı çalışmalarımızı tamamladık. Şimdi `consumer_app` (Tüketici Uygulaması) tarafında müşterilerin aktif dükkanları ve menüleri görebilmesi için mevcut UI'ı yeni REST API yapımıza bağlayacağız.

Lütfen arayüz tasarımını HİÇ BOZMADAN şu adımları uygula:

### AŞAMA 1: DATA KATMANI (Repository & Riverpod)
1. `apps/consumer_app/lib/` dizini altında `ConsumerShopRepository` oluştur. `core_network` paketindeki `ApiClient`'ı kullanarak şu endpoint'lere istek atsın:
   - `GET /api/consumer/shops` (Aktif dükkanları listeleyecek)
   - `GET /api/consumer/shops/:shopId/products` (Seçilen dükkanın aktif ürünlerini listeleyecek)
2. Bu repository'leri yönetecek Riverpod Provider'larını oluştur (Örn: `consumerShopsProvider` ve `shopProductsProvider(String shopId)` - family modifier ile).

### AŞAMA 2: UI REFACTORING (Kablolama)
1. Consumer App içindeki Ana Sayfa (Dükkanların listelendiği sayfa) ve Dükkan Detay/Menü (Ürünlerin listelendiği sayfa) dosyalarını bul.
2. Bu sayfalardaki Firebase/Firestore `StreamBuilder` veya `FutureBuilder` yapılarını tamamen SİL.
3. İlgili sayfaları `ConsumerWidget` veya `ConsumerStatefulWidget` yapısına geçir.
4. Verileri `ref.watch(consumerShopsProvider).when(...)` deseni ile UI'a bağla.
   - `loading:` durumunda şık bir iskelet (skeleton) veya CircularProgressIndicator göster.
   - `error:` durumunda "Dükkanlar yüklenirken bir hata oluştu" şeklinde bir metin göster.
   - `data:` durumunda dükkan ve ürün kartlarını mevcut tasarımla ekrana bas.
5. **Kritik Kural:** Firebase Storage iptal olduğu için `imageUrl` kısımlarında hata almamak adına, resim url'si boşsa veya geçersizse sabit bir placeholder (Örn: `https://via.placeholder.com/150`) göster.

Lütfen önce bu dosyaları bul ve uygulayacağın değişikliklerin (Özellikle Data katmanının) kodlarını bana özetle. Onayladıktan sonra sayfalara entegre edersin.
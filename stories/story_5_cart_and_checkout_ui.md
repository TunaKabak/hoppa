Epic: Order & Checkout Management (Sipariş ve Sepet Yönetimi)
Task: Story 5 - Tüketici Uygulaması Sepet (Cart) ve Checkout UI Entegrasyonu

Kullanıcı Hikayesi: "Bir tüketici olarak, beğendiğim ürünleri sepete eklemek, toplam tutarı görmek ve adresimi girerek siparişimi tamamlamak istiyorum."

Backend Order API'miz hazır. Şimdi `consumer_app` tarafında Riverpod kullanarak Sepet state yönetimini ve Checkout arayüzünü kodlayacağız. Lütfen aşağıdaki adımları sırayla uygula:

1. **ConsumerOrderRepository Oluşturulması:**
   - `apps/consumer_app/lib/src/features/orders/data/consumer_order_repository.dart` oluştur.
   - `core_network` paketindeki `ApiClient`'ı kullanarak şu metodları yaz:
     - `createOrder(Map<String, dynamic> orderData)` -> `POST /api/consumer/orders`
     - `getMyOrders()` -> `GET /api/consumer/orders`

2. **Sepet State Management (Riverpod) - ALTIN KURAL:**
   - `cartProvider` adında bir `StateNotifier` veya `Notifier` (Riverpod) oluştur. Sepetteki ürünleri (CartItem: product, quantity, shopId) tutacak.
   - Fonksiyonlar: `addToCart`, `removeFromCart`, `clearCart`, `totalAmount` (Hesaplamak için).
   - **Altın Kural (Single Shop Cart):** Bir kullanıcı sepete ürün eklerken, sepetteki mevcut ürünlerin `shopId`'si ile yeni eklenen ürünün `shopId`'si aynı DEĞİLSE, işlemi reddet veya "Farklı bir dükkandan ürün eklemek için sepeti temizlemelisiniz" uyarısı için bir Exception fırlat (UI bunu yakalayıp Snackbar ile gösterecek).

3. **Sepet (Cart / Checkout) UI Entegrasyonu:**
   - Sepet sayfasını (`cart_page.dart` veya `checkout_page.dart`) `ConsumerStatefulWidget`'a çevir.
   - Firebase bağımlılıklarını sil.
   - `ref.watch(cartProvider)` ile sepet içeriğini ve toplam tutarı ekranda listele.
   - Teslimat Adresi (`deliveryAddress`) için bir `TextField` veya adres seçici ekle.
   - **"Siparişi Tamamla" Butonu:** - Tıklandığında, sepet verilerini ve adresi toplayıp `ConsumerOrderRepository.createOrder` metodunu tetikle.
     - Backend'den gelebilecek `400 Bad Request` (Özellikle `minOrderAmount` - Minimum paket tutarı aşılmadı) hatasını `catch` ile yakalayıp kullanıcıya şık bir Snackbar ile göster.
     - Sipariş başarılı olursa: Sepeti `clearCart()` ile temizle, başarı Snackbar'ı göster ve kullanıcıyı "Siparişlerim" (My Orders) veya Ana Sayfaya yönlendir.

Lütfen bu entegrasyonu tamamla ve "Altın Kuralı" (Farklı dükkan kontrolünü) Riverpod State içinde nasıl ele aldığını özetle.
Epic: Order & Checkout Management (Sipariş ve Sepet Yönetimi)
Task: Story 4 - Backend Order API ve Controller Geliştirmesi

Kullanıcı Hikayesi: "Bir tüketici olarak, seçtiğim ürünleri sipariş verebilmek; bir satıcı olarak da gelen siparişleri yönetebilmek istiyorum."

Şu an Consumer ve Merchant tarafındaki UI'lar kendi katalog API'lerimizle konuşuyor. Şimdi sipariş oluşturma (Checkout) akışının Backend mantığını yazacağız. Lütfen `backend` dizininde aşağıdaki adımları sırayla uygula:

1. **`src/controllers/OrderController.ts` Oluşturulması:**
   Aşağıdaki metodları içeren bir controller yaz:
   
   - `createOrder` (Consumer için):
     - Gelen veri (`req.body`): `shopId`, `items: [{ productId, quantity }]`, `deliveryAddress`, `notes` (opsiyonel).
     - İş Mantığı (Kritik): `items` içindeki `productId`'leri Prisma ile veritabanından çek. Fiyatları veritabanındaki güncel fiyatlar üzerinden çarpıp `totalAmount`'u HESAPLA (Client'tan gelen fiyata güvenme).
     - Validasyon: Dükkanın `minOrderAmount` (Minimum paket tutarı) değerini kontrol et. `totalAmount` bu değerin altındaysa 400 hatası dön.
     - Kayıt: Prisma `$transaction` kullanarak `Order` (status: PENDING) ve bağlı `OrderItem` kayıtlarını tek seferde oluştur.

   - `getConsumerOrders` (Consumer için):
     - Giriş yapan tüketicinin (`req.user.id`) geçmiş ve aktif siparişlerini, bağlı olduğu dükkan (Shop) bilgisiyle birlikte listeleyecek.

   - `getMerchantOrders` (Merchant için):
     - Giriş yapan satıcının dükkanına ait siparişleri listeleyecek.

   - `updateOrderStatus` (Merchant/Admin için):
     - Gelen `orderId`'nin `status` değerini (Örn: ACCEPTED, PREPARING, ON_THE_WAY, DELIVERED, CANCELLED) olarak güncelleyecek.

2. **Rotaların (Routes) Bağlanması:**
   - `src/routes/consumerRoutes.ts` dosyasına: `POST /orders` (Sipariş ver) ve `GET /orders` (Siparişlerimi gör) rotalarını ekle. `authMiddleware` kullanmayı unutma.
   - `src/routes/merchantRoutes.ts` dosyasına: `GET /orders` (Dükkan siparişleri) ve `PUT /orders/:id/status` (Sipariş durumu güncelle) rotalarını ekle. `authMiddleware` (role: merchant) ile koru.

Lütfen kodlamayı tamamla ve Prisma `$transaction` bloğunu ve Fiyat Hesaplama (Calculation) mantığını nasıl kurguladığını kısaca özetle. Onaylandıktan sonra Consumer App (UI) Sepet entegrasyonuna geçeceğiz.
# Story 75: Seçilen Ekstraların (Opsiyonların) Sepet, Ödeme ve Sipariş Detayında Gösterilmesi ve Fiyatlandırılması

## 1. Amaç ve Kapsam
Tüketici uygulamasında (`apps/consumer_app`) bir ürüne seçilen ekstraların (opsiyonların) sepet ekranında, ödeme adımındaki sipariş özetinde ve oluşturulan siparişin detay ekranında görünmemesi ile bu ekstraların sipariş tutarına dahil edilmemesi sorunu kökten çözülecektir.

---

## 2. Tespit Edilen Kök Nedenler (Root Causes)

1. **Sepet Ekranı Görünüm Eksikliği (`cart_page.dart` & `ModernProductCard`):**
   - `cart_page.dart` içerisinde sepet kalemleri `ModernProductCard` ile listelenirken `CartItem.selectedOptions` ve `CartItem.unitPrice` bilgileri karta aktarılmamakta; varsayılan baz ürün fiyatı (`businessProduct.price`) gösterilmekteydi. Seçilen soslar, malzemeler ve boyut ekstraları listede render edilmiyordu.

2. **Ödeme Adımı Sipariş Özeti ve Sipariş Oluşturma İsteği (`payment_page.dart`):**
   - `payment_page.dart` sipariş özeti akordeonunda birim fiyat hesabında `item.unitPrice` yerine `item.businessProduct.price` kullanılmaktaydı.
   - `_submitOrder` metodu backend'e sipariş isteği atarken `items` dizisine `options` alanını eklememekteydi. Bu nedenle backend veritabanına ekstraları kaydedemiyor ve sipariş tutarını opsiyonsuz hesaplıyordu.

3. **Sipariş Modeli ve Detay Sayfası Eksikliği (`order.dart` & `order_detail_page.dart`):**
   - `OrderItem` Flutter modelinde backend'in `OrderOption` ilişki verisi olan `options` listesi parse edilmiyordu.
   - `order_detail_page.dart` içerisindeki `_buildOrderItem` fonksiyonu sipariş kalemine ait opsiyonları ekranda göstermiyordu.

---

## 3. Çözüm Adımları

1. **`ModernProductCard` & `cart_page.dart` Güncellemesi:**
   - `ModernProductCard` bileşenine isteğe bağlı `cartItem` parametresi eklenecektir. Sepette gösterilirken `cartItem.unitPrice` kullanılacak ve ürün adının altında seçilen ekstralar (`• Duble Peynir (+15.00 ₺)`) rozet/liste olarak gösterilecektir.

2. **`payment_page.dart` Sipariş Özeti & Payload Güncellemesi:**
   - Sipariş Özeti kartında ürün fiyatı `item.unitPrice` üzerinden hesaplanacak ve altına ekstralar listelenecektir.
   - `_submitOrder` fonksiyonunda backend API isteğine `'options': item.selectedOptions.map((opt) => opt.toMap()).toList()` eklenecektir.

3. **`order.dart` & `order_detail_page.dart` Güncellemesi:**
   - `OrderItem` modeline `selectedOptions` / `options` listesi parse etme yeteneği kazandırılacaktır.
   - `order_detail_page.dart` içerisindeki `_buildOrderItem` widget'ında sipariş opsiyonları (sos, boyut, ekstra) detaylı olarak görüntülenecektir.

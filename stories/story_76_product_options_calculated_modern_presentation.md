# Story 76: Opsiyonel ve Yan Ürünlerin Hesaplanmış ve Modern Arayüz ile Gösterimi

## 1. Problem Tanımı ve Kullanıcı İhtiyacı
Hoppa mobil uygulamasında restoran/yiyecek siparişlerinde ürünlere eklenen opsiyonlar (boyut, sos, ekstra malzeme, çıkarılan malzemeler vb.):
- `PaymentPage`, `OrderDetailPage` ve `ModernProductCard` içerisinde sadece parantezli metinler olarak (`• Büyük Boy (+₺30.00), • Ekstra Kaşar (+₺15.00)`) yan yana sıralanmaktaydı.
- Adet 1'den fazla olduğunda (örneğin 2 adet Burger) opsiyonların toplam fiyata etkisi hesaplanmış olarak gösterilmemekte, kullanıcı toplam tutarın nasıl oluştuğunu zihinsel olarak hesaplamak zorunda kalmaktaydı.
- Ürün özelleştirme modalında (`FoodProductCustomizationSheet`) baz fiyat, eklenen opsiyonlar ve birim/toplam tutar şeffaf ve modern bir hesaplama çubuğu ile gösterilmiyordu.

---

## 2. Çözüm Mimarisi ve Tasarım Prensipleri

### 2.1. Yeni `SelectedOptionsBreakdown` Widget'ı
Tüm tüketici ve işletme ekranlarında ortak kullanılabilecek, modern ve hesaplanmış opsiyon kırılım bileşeni:
- **Yapılandırılmış Hiyerarşik Liste (Tree Breakdown)**:
  - Her bir opsiyon bağımsız bir mikro-satırda render edilir.
  - **Eklemeler (+)**: Yeşil renkli `+` rozeti, net hesaplanmış ek ücret (Adet > 1 ise hem birim hem toplam tutar, örn: `+60,00 ₺ (2 × 30,00 ₺)`).
  - **Çıkarmalar (-)**: Kırmızı / Gül rengi `Çıkarıldı` etiketi ve üzeri çizili stil.
  - **Ücretsiz / Dahil Seçimler**: Açık gri/yeşil `Dahil / Ücretsiz` rozeti.
- **Birim & Toplam Hesaplama Çubuğu**:
  - Çoklu adetlerde `Baz Ürün Fiyatı + Ekstralar = Birim Fiyat` ve `Adet × Birim Fiyat = Toplam` formülü şeffafça görselleştirilir.
- **İki Farklı Mod (`compact` ve `detailed`)**:
  - `compact`: Sepet kartlarında (`ModernProductCard`) zarif, az yer kaplayan mikro kart görünümü.
  - `detailed`: Ödeme (`PaymentPage`), Sipariş Detayı (`OrderDetailPage`) ve Restoran Sipariş Listesinde (`MerchantOrderListPage`) tam detaylı kırılım görünümü.

### 2.2. `FoodProductCustomizationSheet` Modernizasyonu
- Seçenek kartlarında parantez içi kaba metinler yerine modern rozetler (`+30,00 ₺` yeşil pill, `Ücretsiz` pill).
- Alt yapışkan barda canlı hesaplama şeridi: `Baz Fiyat + Seçimler = Birim Tutar` ve `Sepete Ekle • [Toplam Tutar]`.

---

## 3. Etkilenecek Dosyalar
1. `apps/consumer_app/lib/apps/consumer/widgets/selected_options_breakdown.dart` (YENİ)
2. `apps/consumer_app/lib/apps/consumer/home/widgets/modern_product_card.dart` (MODIFY)
3. `apps/consumer_app/lib/apps/consumer/checkout/payment_page.dart` (MODIFY)
4. `apps/consumer_app/lib/apps/consumer/orders/order_detail_page.dart` (MODIFY)
5. `apps/consumer_app/lib/apps/consumer/business/widgets/food_product_customization_sheet.dart` (MODIFY)
6. `apps/merchant_app/lib/apps/merchant/merchant_order_list_page.dart` (MODIFY)

---

## 4. Doğrulama ve Test
- `flutter analyze` statik kod analizi.
- Sepet, Ödeme, Sipariş Takip ve Restoran Sipariş sayfalarında opsiyon hesaplamalarının ve modern rozetlerin doğrulanması.

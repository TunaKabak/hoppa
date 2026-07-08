# Story 31: Canlı Destek İnteraktif Seçim, Sesli Komut ve Kurye Canlı Takip İyileştirmeleri

## 1. Giriş ve Sorun Tanımı
1. **Canlı Destek Arayüzü İyileştirmeleri:**
   - Kullanıcıların sohbet başlamadan önce üstteki çiplerden sipariş seçmesi yerine, Gemini sohbeti sırasında birden fazla sipariş tespit edilirse bu siparişlerin doğrudan sohbet balonu içinde interaktif butonlar olarak listelenmesi ve oradan seçilebilmesi gerekmektedir.
   - Üstteki sipariş çiplerinin daha açıklayıcı olması adına sipariş tarih ve saatinin de (örn: *"Migros • 08 Temmuz 12:30"*) gösterilmesi istenmektedir.
   - Kullanıcıların yazmak yerine sesli olarak mesaj girebilmeleri için sesli komut (Speech-to-Text) desteği eklenmelidir.
2. **Kurye Canlı Takip Haritası:**
   - Harita üzerindeki kurye ve teslimat adresi görselleri sade ikonlar yerine premium, Hoppa marka kimliğine uygun tasarlanmalıdır. Kurye ikonu olarak Hoppa logosu kullanılmalı, yön açısına göre tüm logonun dönmesi yerine logonun dik durup çevresindeki bir yön göstergecinin (navigation pointer) dönmesi sağlanmalıdır.

## 2. Teknik Analiz ve Çözüm Planı
1. **SupportController.ts (Backend):**
   - Kullanıcının aktif/geçmiş tüm siparişleri sorgulanıp, eğer birden fazla sipariş varsa yanıt gövdesinde `options` listesi (`[{ id, label }]`) olarak döndürülecektir.
   - Gemini promptuna tekrar eden Merhaba selamlamalarını engelleyecek Kural 7 eklendi.
2. **support_chat_page.dart & support_repository.dart (Frontend):**
   - Tüketici uygulamasında Riverpod ile `speech_to_text` paketi entegre edilerek ses kaydı metne dökülecektir. Android `RECORD_AUDIO` izinleri tanımlanacaktır.
   - Mesaj balonlarında `options` alanı varsa interaktif butonlar halinde çizilecek, tıklandığında ilgili sipariş aktif siparişe bağlanarak otomatik sohbet mesajı atılacaktır.
   - Üstteki seçim çipleri tarih formatı (`d MMMM HH:mm` örneğin: *08 Temmuz 12:30*) ile zenginleştirilecektir.
3. **order_tracking_page.dart (Frontend):**
   - Kurye konumunu simgeleyen marker, dönen bir `Icons.navigation` ( bearing açısıyla) ve onun üzerinde sabit duran dairesel Hoppa logosu (`assets/images/hoppa_logo.png`) ile Stacklenecektir.
   - Teslimat adresi marker'ı ev ikonu ve pulsing animasyonu ile zenginleştirilecektir.

## 3. Etki Analizi (Impact Analysis)
- **Tüketici Uygulaması (Consumer App):** Arayüzde ses kaydı, harita takibi ve interaktif AI akışları aktif olacaktır.
- **Güvenlik / İzinler:** Android tarafında mikrofon kullanım izni talep edilecektir.

## 4. Değişiklik Yapılacak Dosyalar
- `backend/src/controllers/SupportController.ts`
- `apps/consumer_app/lib/apps/consumer/profile/support_chat_page.dart`
- `apps/consumer_app/lib/apps/consumer/repositories/support_repository.dart`
- `apps/consumer_app/lib/apps/consumer/orders/order_tracking_page.dart`
- `apps/consumer_app/android/app/src/main/AndroidManifest.xml`
- `apps/consumer_app/pubspec.yaml`

## 5. Doğrulama (Verification)
- `npx tsc --noEmit` ile backend tip kontrolü.
- `flutter analyze` ile consumer_app statik analizi.

# Story #43: Hoppa Campaign Slider & Visual Banners (Hoppa Genel Kampanya Slider'ı)

## Teknik Tasarım ve Kapsam

Bu hikaye, Hoppa uygulamasının ana ekranına (kategori seçim ekranı) kullanıcıları etkileyecek ve kampanya/reklamları şık bir şekilde sunacak dinamik bir kampanya slider'ı eklemeyi amaçlar. Grafik tasarımcımız (`Designer Agent` ve `generate_image` aracı aracılığıyla) her bir kampanya için özel modern afişler tasarlayacak ve bunları uygulamada akıcı bir geçişle sunacağız.

### 1. Tasarım Varlıkları (Campaign Assets)
Grafik tasarımcımızın üreteceği 4 adet özel kampanya görseli:
1. **İlk 5 Sipariş Teslimatı Hoppadan (`assets/images/campaign_free_delivery.png`):** Uçan kurye ve hediye paketleri temalı modern illüstrasyon afiş.
2. **Hoş Geldin Kuponu (`assets/images/campaign_welcome_coupon.png`):** Hediye kutusu ve ışıltılı kuponlar içeren premium kupon afişi.
3. **Aradığın Her Şey Kapında (`assets/images/campaign_everything_at_door.png`):** Market, yemek, çiçek ve su siparişlerinin eve teslimatını gösteren canlı kolaj afiş.
4. **Arkadaşını Davet Et Kazan (`assets/images/campaign_invite_friend.png`):** Arkadaş davetiyle puan/kazanç kazanımını sembolize eden modern afiş.

### 2. Frontend Geliştirmeleri (`consumer_app`)
* **Yeni Widget (`HoppaCampaignSlider`):**
  * `apps/consumer_app/lib/apps/consumer/home/widgets/hoppa_campaign_slider.dart` altında oluşturulacak.
  * `PageView` kullanılarak pürüzsüz kaydırma ve sayfa altı nokta göstergesi (Dots Indicator) entegre edilecek.
  * Otomatik kaydırma (Auto-play) ve kullanıcı dokunduğunda duraklama desteği.
  * Kartlar için modern yumuşak kenar kıvrımları (`BorderRadius.circular(20)`), hafif gölgelendirmeler ve derinlik hissi.
* **Entegrasyon:**
  * `apps/consumer_app/lib/apps/consumer/business/selection_category_page.dart` ekranında mevcut durağan tek reklam alanının yerine bu dinamik ve şık slider yerleştirilecek.
  * Arama çubuğunun hemen altında, dükkan kategorilerinin ise hemen üzerinde konumlandırılacak.

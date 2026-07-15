# Story #44: Kampanya Afişlerinin Yenilenmesi ve Görsel Üretimi

## Teknik Tasarım ve Kapsam

Bu hikaye, Hoppa uygulamasının kampanya slider'ında kullanılan 4 adet görselin (banner) kurumsal kimliğe uygun olarak modern 3D claymation/illüstrasyon tarzında yeniden üretilmesini ve entegre edilmesini amaçlar.

### 1. Tasarım Kuralları ve Kurumsal Kimlik
* **Renk Paleti:** Canlı Turuncu (Hoppa Turuncusu) ve Canlı Yeşil (Hoppa Yeşili) uyumu.
* **Düzen (Layout):** Görsellerin sağ tarafında dikkat çekici 3D objeler yer alırken, sol tarafında logo ve kampanya metinleri (typography) için hafif degradeli (gradient) temiz bir boş alan (Copy Space) bulunacaktır.
* **Tarz:** Modern, temiz, parlak ve minimalist 3D claymation/illüstrasyon.

### 2. Üretilecek Kampanya Görselleri ve Dosya Yolları

Görseller `apps/consumer_app/assets/images/` dizinine kaydedilecektir:

1. **Teslimat Ücreti Hoppa'dan**
   * **Görsel Adı:** `campaign_free_delivery.png`
   * **Konsept:** Hızlı teslimatı simgeleyen sevimli, 3D modelleme bir motor kurye veya uçan teslimat paketi.
   * **Prompt:** `A professional 3D illustration for a mobile app banner, aspect ratio 16:9. On the right side, a cute orange and green delivery scooter or a flying delivery box with tiny wings, rendered in glossy claymation style. The left side is a clean, minimalist soft orange gradient background with plenty of empty copy space for text and logo.png. Vibrant colors, studio lighting, modern app UI design, clean composition, no text on image --ar 16:9 --v 6.0`

2. **Hoşgeldin Kuponu**
   * **Görsel Adı:** `campaign_welcome_coupon.png`
   * **Konsept:** Havada uçuşan hediye kutuları, altın paralar ve parıldayan 3D hediye kuponu.
   * **Prompt:** `A modern 3D graphic design for a mobile marketplace slider, aspect ratio 16:9. On the right side, a glowing premium coupon voucher and a beautifully wrapped gift box in orange and green brand colors, with tiny gold coins floating around. The left side is a solid, clean green gradient background with ample empty copy space for adding text and logo.png later. High-end rendering, glossy texture, festive and rewarding atmosphere, no text on image --ar 16:9 --v 6.0`

3. **Aradığın Her Şey Kapında!**
   * **Görsel Adı:** `campaign_everything_at_door.png`
   * **Konsept:** Taze meyve/sebze, hamburger, su damlası elementleri içeren sevimli bir alışveriş sepeti.
   * **Prompt:** `A vibrant 3D mobile app banner illustration, aspect ratio 16:9. On the right side, a cute glossy shopping cart filled with iconic items: a fresh red apple (groceries), a delicious hamburger (food), and a clean blue water droplet (water). The overall color theme matches orange and green. The left side of the banner is a clean, pastel orange-and-white gradient background with empty copy space to place logo.png and typography. High resolution, bright studio lighting, cute and friendly aesthetic, no text on image --ar 16:9 --v 6.0`

4. **Arkadaşını Davet Et Kazan**
   * **Görsel Adı:** `campaign_invite_friend.png`
   * **Konsept:** Karşılıklı iki akıllı telefon ekranından birbirine uçan hediye/para ikonları.
   * **Prompt:** `A creative 3D rendering for a mobile app referral campaign banner, aspect ratio 16:9. On the right side, two clean stylized smartphones facing each other with 3D gift boxes and shiny gold coins flying between them, styled in vibrant orange and green colors. The left side features a smooth, clean green background with large empty copy space for overlaying logo.png and promo text. Minimalist, modern corporate style, cheerful and social vibe, premium quality, no text on image --ar 16:9 --v 6.0`

## Doğrulama Protokolü
* Görsellerin belirtilen boyut ve yollarda başarıyla oluşturulduğu teyit edilir.
* Dosyaların formatı (PNG) ve çözünürlükleri kontrol edilir.

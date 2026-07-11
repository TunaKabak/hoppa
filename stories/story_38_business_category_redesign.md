# Story 38: İşletme Kategorileri Görselleştirme ve Arayüz Yenileme (UI/UX Redesign)

## 1. Problem Tanımı ve Hedefler
Tüketici uygulamasının (`consumer_app`) giriş ekranı olan işletme kategorileri seçim sayfası (`SelectionCategoryPage`), kullanıcıyı karşılayan ilk ve en önemli ekrandır. Mevcut durumda bu ekran:
* Kategorileri düz, karanlık gradyan arka planlı ve standart stok fotoğraflarla göstermektedir.
* Dükkan adetleri, ortalama teslimat süreleri, alt başlıklar gibi önemli zengin bilgiler (metadata) `isFeatured` bayrağı aktif olduğu için kullanıcıya gösterilememektedir.
* Tasarımın modern, özgün (Hoppa markasına özel) ve premium hissettirmesi hedeflenmektedir.

**Hedefler:**
1. **Özgün ve Profesyonel Görseller:** Grafik tasarımcımız (AI) aracılığıyla her işletme kategorisine (Market, Restoran, Su, Kuruyemiş, Kahve, Çiçek, Manav, Kasap) özel, 3D premium kil/karikatür (claymation/3D minimal render) tarzında, Hoppa kurumsal kimliğine uyumlu şeffaf veya yumuşak arka planlı özgün görseller üretmek.
2. **Modern ve Premium Arayüz (UI/UX):** Kategori kartlarının sadece bir fotoğraf ve başlık değil; ortalama teslimat süresi, alt başlıklar, "Yeni" / "Popüler" etiketleri (badges) gibi bilgileri de içeren, yumuşak geçişli gölgeler ve pastel renk arka planlarına sahip şık kartlara dönüştürülmesi.
3. **Animasyonların Korunması:** Ekran açılışındaki staggered (kademeli) scale/fade giriş animasyonlarının (kullanıcı tarafından çok beğenilen) aynen korunması.

---

## 2. Tasarım ve Arayüz Yenilikleri

### 2.1. Görsel Konsept (Hoppa 3D Clay Style)
Her kategori için üretilecek görseller, aşağıdaki kurallara göre tasarlanacaktır:
* **Market:** Yumuşak yeşil gradyanlı arka plan üzerinde 3D alışveriş sepeti, taze meyveler, süt kutusu ve ekmek.
* **Restoran:** Turuncu/amber gradyan arka plan üzerinde sıcak dumanı üstünde bir 3D tabak, servis kapağı (cloche) ve çatal-kaşık.
* **Su:** Açık mavi gradyan üzerinde ferahlatıcı 3D su damlaları, su şişesi ve buz küpleri.
* **Kuruyemiş:** Sıcak kahverengi/toprak gradyanı üzerinde ahşap kasede 3D fındık, ceviz ve bademler.
* **Kahve:** Espresso kahverengi/altın gradyanı üzerinde üstünde latte art olan 3D kahve fincanı ve kahve çekirdekleri.
* **Çiçek:** Pembe/gül gradyanı üzerinde şık bir paket içinde 3D taze çiçek buketi (gül ve laleler).
* **Manav:** Canlı yeşil gradyan üzerinde 3D ahşap kasa içerisinde taze meyve ve sebzeler (elma, muz, havuç, domates).
* **Kasap:** Koyu gri/kırmızı gradyan üzerinde 3D ahşap kesme tahtası, üzerinde taze et (biftek) ve biberiye yaprakları.

### 2.2. Kart Tasarımı (UI Layout)
Kartlar `GridView` içinde 2 sütunlu olarak yer alacaktır. Her kart şu katmanlardan oluşacaktır:
1. **Arka Plan:** Kategoriye özel pastel renkte (kategori renginin %10-15 opaklığı veya çok yumuşak bir gradyan) yumuşak köşeli (border radius: 18) konteyner.
2. **Görsel Asset:** Sağ alt veya merkez-sağ kısma yerleştirilmiş, kartın dışına hafif taşan veya derinlik hissi veren 3D kategori görseli.
3. **Sol Bölüm (Metinler):**
   * Üstte kategori ismi (bold, koyu renk, Inter/Poppins font).
   * Altında kategoriye özel kısa açıklama/alt başlık (örn: "Yemek siparişi" veya "Su ve içecek") gri renkte.
   * Altında ortalama teslimat süresi rozeti (küçük bir saat ikonu ile birlikte, örn: "20-30 dk").
4. **Etiket (Badge):** Kartın sağ üst köşesinde, veritabanından gelen badge tipine göre ("Yeni" için yeşil/mavi, "Popüler" için turuncu, "Kapalı" için koyu gri) şık bir kapsül rozet.

---

## 3. Akış ve Animasyon

Açılış animasyonu `CategoryGridItem` içinde yer alan `AnimationController` ve staggered giriş efekti ile sağlanır. Bu animasyon mantığı tamamen korunacak, sadece kartın iç görsel giydirmesi ve yerleşimi (layout) güncellenecektir.

---

## 4. Teknik Değişiklikler ve Dosyalar

* **`SelectionCategoryPage`** (`apps/consumer_app/lib/apps/consumer/business/selection_category_page.dart`):
  * `_featuredImages` haritası güncellenecek veya yeni oluşturulan premium 3D görseller buraya eklenecektir.
  * Kart yapısındaki `isFeatured` mantığı revize edilerek tüm kartların yeni modern arayüze geçmesi sağlanacaktır.
* **`CategoryGridItem`** (`apps/consumer_app/lib/apps/consumer/business/widgets/category_grid_item.dart`):
  * Kartın UI yerleşimi, metin stilleri, teslimat süresi gösterimi ve badge konumlandırması yenilenecektir.
  * Staggered giriş animasyonları (fade, slide, scale) olduğu gibi korunacaktır.
* **Assets** (`apps/consumer_app/assets/images/`):
  * Yeni 3D görseller üretilerek bu klasör altına kaydedilecektir.

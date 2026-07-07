Story 29 - Merchant Ürün Yönetimi ve Ayarlarının İyileştirilmesi (Merchant Polish)

Bu görev belgesi; satıcı (Merchant) uygulamasında ürün ekleme/düzenleme formlarının ve dükkan teslimat ayarlarının kullanıcı deneyimini (UX) iyileştirmeyi, KKTC ilçe verilerini genişletmeyi ve harita/konum entegrasyonlarını daha kararlı hale getirmeyi amaçlar.

---

## 🧭 1. BÖLÜM: Sistem Akış Diyagramı (System Flowchart)

```
[Merchant: Dükkan Ayarları (Teslimat)]
               │
               ▼
[Konumumu Getir / Haritadan Seç] ──► [Reverse Geocoding (CityMapping & DistrictMatch)]
               │
               ▼
[İl ve İlçe Dropdown'ları Otomatik Seçilir]
               │
               ▼
[Yarıçap Sürgüsü Değişimi] ──► [Harita Otomatik Zoom Seviyesini Günceller]


[Merchant: Özel Ürün Ekle / Düzenle]
               │
               ▼
┌───────────────────────────────┬───────────────────────────────┐
▼                               ▼                               ▼
[Resim Seç ve Yükle]     [Marka Autocomplete]     [Açıklama Markdown Editörü]
(MediaService Entegrasyonu) (Tüm Markalardan Arama)  (Kalın, İtalik vb. Butonlar)
```

---

## 🛠️ 2. BÖLÜM: Yapılacak Değişiklikler (Proposed Improvements)

### A. KKTC İlçe Verilerinin Genişletilmesi (`kktc_districts.dart`)
Mevcut semt ve bölge verileri KKTC geneline yayılarak genişletilecektir:
* **Lefkoşa:** Gönyeli, Ortaköy, Hamitköy, K.Kaymaklı, Yenicami, Taşkınköy, Haspolat, Alayköy, Surlariçi, Dereboyu, Metehan, Kumsal, Köşklüçiftlik, Çağlayan, Marmara, Yenişehir, Kızılbaş, Göçmenköy, Sanayi Bölgesi, Minareliköy, Demirhan, Değirmenlik, Balıkesir, Cihangir, Gökhan, Düzova, Beyköy, Yeniceköy.
* **Girne:** Merkez, Karakum, Doğanköy, Çatalköy, Ozanköy, Beylerbeyi, Zeytinlik, Alsancak, Lapta, Karaoğlanoğlu, Karşıyaka, Edremit, Karaman, Esentepe, Bahçeli, Tatlısu, Tepebaşı, Karsıyaka, Bellapais.
* **Gazimağusa:** Merkez, Karakol, Sakarya, Baykal, Çanakkale, Tuzla, Gülseren, Maraş, Yeni Boğaziçi, Mormenekşe, Mutluyaka, Akdoğan, Vadili, Paşaköy, Geçitkale, Yenigeçitkale, Serdarlı, Tatlısu, Beyarmudu.
* **İskele:** Merkez, Long Beach, Ötüken, Boğaz, Bahçeler, Aygün, Kuzucuk, Kalecik, Bafra, Mehmetçik, Dipkarpaz, Yeni Erenköy, Yenierenköy, Kumyalı, Ziyamet, Boltaşlı.
* **Güzelyurt:** Merkez, Kalkanlı, Bostancı, Yayla, Aydınköy, Akçay, Zümrütköy, Şahinler, Gayretköy, Serhatköy, Mevlevi.
* **Lefke:** Merkez, Gemikonağı, Yedidalga, Bağlıköy, Yeşilyurt, Denizli, Gaziveren, Cengizköy.

### B. Otomatik Konum ve Akıllı Eşleştirme (`merchant_settings_page.dart` & `location_controller`)
* GPS'ten veya harita seçiminden dönen İngilizce/Yunanca şehir ve bölge isimleri (`Nicosia`, `Kyrenia`, `Famagusta`, `Trikomo`, `Morphou`, `Lefka`) Türkçe KKTC ilçe ve illeriyle (`Lefkoşa`, `Girne`, `Gazimağusa`, `İskele`, `Güzelyurt`, `Lefke`) akıllıca eşleştirilip Dropdown'larda otomatik seçilecektir.
* Dükkanın teslimat yarıçapı (Slider) değiştirildiğinde, haritanın zoom seviyesi yarıçapa göre (`zoom = 14.5 - log2(radius)`) otomatik yaklaşıp uzaklaşacaktır.

### C. Ürün Listesi Aktif/Pasif Filtreleme (`merchant_product_list_page.dart`)
* "Envanterim" sekmesinde üst kısma eklenecek `ChoiceChip` veya `SegmentedButton` bileşeniyle sadece Aktif, sadece Pasif veya Tüm ürünlerin listelenmesi sağlanacaktır.

### D. Özel Ürün Görsel Seçimi ve Yüklemesi (`merchant_product_list_page.dart`)
* Ürün resim girişi sadece URL yazılarak değil, galeri/kamera üzerinden `MediaService` aracılığıyla seçilip sunucuya yüklenebilir hale getirilecektir.

### E. Akıllı Marka Seçici (Autocomplete)
* Marka girişi elle yapılabilir olacak, ancak satıcının hatalı/mükerrer veri girmesini önlemek için katalogdaki mevcut markaları (Coca-Cola, Ülker vb.) listeleyen akıllı bir `Autocomplete` alanı sunulacaktır.

### F. Açıklama Alanı Zengin Metin Alanı (Textarea + Formatting Helpers)
* Açıklama alanı geniş bir text area yapılacak ve üzerine eklenecek markdown butonlarıyla (Bold, Italic, Underline, Bullet List) metin biçimlendirme kolaylaştırılacaktır.

---

## 🏁 3. BÖLÜM: Doğrulama ve İmza (Sign-Off)

* [ ] KKTC İlçe verileri genişletilecek.
* [ ] Merchant ayarlar sayfasında konum eşleştirme ve otomatik zoom test edilecek.
* [ ] Ürün listesindeki aktif/pasif filtre barı doğrulanacak.
* [ ] Görsel yükleme, marka autocomplete ve markdown zengin açıklama kontrolleri test edilecek.

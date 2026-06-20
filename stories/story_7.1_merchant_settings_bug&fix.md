Epic: Merchant App Settings (Satıcı Ayarları)
Task: Story 7.1 - Harita Senkronizasyonu ve KKTC Adres Yapılandırması

Saha testlerinde (KKTC bölgesinde) tespit edilen UI ve Geocoding eksikliklerini gidereceğiz. Lütfen merchant_app Teslimat sekmesinde şu güncellemeleri yap:

1. Harita Kamerası (MapController) Senkronizasyonu

Teslimat sekmesindeki harita widget'ına (GoogleMap veya flutter_map) bir MapController bağla.

"Konumum" butonuna basıldığında veya sayfa açılışında GPS'ten yeni latitude ve longitude geldiğinde, haritanın kamerasını otomatik olarak bu yeni koordinatlara animasyonla (animateCamera / move) odakla.

Haritadaki pin (Marker) de otomatik olarak bu yeni merkeze taşınsın.

2. "Unnamed Road" Filtrelemesi (Geocoding Düzeltmesi)

placemarkFromCoordinates işleminden dönen adresi oluştururken, eğer sokağın (placemark.thoroughfare veya street) içinde "Unnamed Road" geçiyorsa, bu kısmı yoksay (String'e ekleme).

Adresi oluştururken önceliği Semt ve Şehre ver (Örn: ${placemark.subLocality}, ${placemark.locality}).

3. KKTC Şehir ve Semt Dropdown'ları (UI Düzenlemesi)

Satıcıların adreslerini standartlaştırmak için Teslimat sayfasına açık adres TextField'ına ek olarak şu alanları ekle:

Şehir (İl) Seçimi (Dropdown): Sabit seçenekler olarak Kıbrıs şehirlerini ekle: Lefkoşa, Girne, Gazimağusa, İskele, Güzelyurt, Lefke.

Semt (İlçe/Bölge) Seçimi (TextField veya Dropdown): Kullanıcının semtini (Örn: Hamitköy, Gönyeli) girebileceği / seçebileceği bir alan.

Açık Adres (TextField): Mevcut adres alanı. GPS bulunduğunda bu alan sadece Sokak, Apartman ve No bilgilerini içerecek şekilde güncellensin.

Lütfen harita senkronizasyonunu ve KKTC'ye özel bu UI/Geocoding mantığını uygulayıp sonucu raporla.
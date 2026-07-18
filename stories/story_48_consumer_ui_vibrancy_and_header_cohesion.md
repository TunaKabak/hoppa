# Story #48: Consumer App UI Vibrancy & Header Cohesion

## Teknik Tasarım ve Kapsam

Bu hikaye, Hoppa tüketici uygulamasındaki kategori arayüz elemanlarının renklerinin canlandırılmasını ve adres/ödeme/teslimat sayfalarının üst başlık alanlarının (Header) ana turuncu renkli `HoppaHeader` yapısına uyum sağlayacak şekilde yeniden tasarlanmasını amaçlar.

### 1. Kategori Renk Canlılığı
* **Gözlemlenen Sorun:** "Market", "Su", "Çiçek" kategori kartlarının arka plan renklerinin aşırı soluk pastel tonlarda olması, buna karşın "Yemek" (Restoran) kategorisinin canlı renk geçişine sahip olması nedeniyle görsel bir tutarsızlık mevcuttur.
* **Çözüm:** `CategoryGridItem` bileşeninde `'market'`, `'su'`, `'çiçek'` gibi ana kategorilerin gradyan geçişleri, kendi kurumsal renklerinin `%35` opaklık düzeyiyle (`withValues(alpha: 0.35)`) beyaz renkten başlayarak canlandırılacak ve Yemek kategorisi gibi daha belirgin hale getirilecektir.

### 2. İşletme Listesindeki Adres Kartı
* **Gözlemlenen Sorun:** İşletme listesi sayfasındaki teslimat adresi barı yeşil tonlarında ve mint yeşili gradyana sahiptir; bu durum üstteki turuncu `HoppaHeader` ile görsel uyumsuzluk yaratmaktadır.
* **Çözüm:** Teslimat adresi barının gradyan arka planı soft turuncu-şeftali (`Color(0xFFFFF3EE)`) tonlarına, çerçevesi yumuşak turuncu renge (`Color(0xFFFFDDD2)`) ve ikon ile tıklama efekti vurguları Hoppa Turuncusuna (`Color(0xFFE95D22)`) güncellenerek header ile uyumu sağlanacaktır.

### 3. Teslimat ve Ödeme Ekranları Header Adaptasyonu
* **Gözlemlenen Sorun:** Sepet ve adres listesi ekranlarında turuncu gradyanlı modern `HoppaHeader` ve kavisli alt zemin tasarımı uygulanmışken, **Yeni Adres Ekleme/Düzenleme** (`AddAddressPage`), **Teslimat Bilgileri/Ödeme** (`CheckoutPage`) ve **Ödeme Yöntemleri** (`PaymentPage`) ekranlarında standart beyaz zeminli `AppBar` kullanılmaktadır.
* **Çözüm:** Belirtilen 3 sayfada standart `AppBar` kaldırılarak, sepet ve diğer sayfalardaki gibi gradyan zeminli `HoppaHeader` yerleştirilecek; içerikler ise üst köşeleri kavisli (`Radius.circular(24)`) beyaz bir kapsayıcı gövde (`ClipRRect` & `Container`) içine alınacaktır.

## Doğrulama Protokolü
* Değiştirilen dosyaların statik analizi (`flutter analyze`) hatasız tamamlamalıdır.
* Uygulamanın release modu (`flutter build apk`) sorunsuz derlenmelidir.
* Geliştirmeler bağlı cihazda test edilip doğrulanacaktır.

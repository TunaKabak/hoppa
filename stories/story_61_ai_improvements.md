🧠 Hoppa Yapay Zeka (AI) ve Akıllı Lojistik Çözümleri (Ocak 2027)

Bu döküman, Hoppa platformunun KKTC lansmanında ve sonrasında kullanılacak olan, hem teknik jüriyi hayran bırakacak akademik rasyolara sahip hem de esnaf/kullanıcı deneyimini zirveye taşıyan yapay zeka özelliklerinin sunum taslağıdır.

📱 1. B2C (TÜKETİCİ) ODAKLI YAPAY ZEKA ÇÖZÜMLERİ
A. Hoppa Asistan: Canlı Sipariş Farkındalığı Olan Canlı Destek (Context-Aware AI)

İşleyiş: Standart "canlı destek" robotları gibi hazır kalıplarla ("Siparişiniz yolda") konuşmaz. Kullanıcının aktif sipariş verilerini (restoran hızı, kurye konumu, sipariş içeriği) gerçek zamanlı bir sistem direktifi olarak (Context Injection) Gemini modeline besler.

Özellik: Kullanıcı "Yemeğim nerede kaldı?" dediğinde, Asistan kuryenin hızını ve haritadaki mesafesini hesaplayarak tamamen kişiye ve o saniyeye özel, Kıbrıs samimiyetiyle akıllı yanıtlar üretir.

🏪 2. B2B (ESNAF) ODAKLI YAPAY ZEKA ÇÖZÜMLERİ

🍊 A. 10 Saniyede Dijital Entegrasyon (AI Menu & Invoice Scanner)

Esnaf Gerçeği: Yerel bir manavı, kasabı veya kebapçıyı dijitalleştirmek (onboarding) haftalar sürer. Esnafın bilgisayara tek tek 200 kalem ürün ismi, fiyatı, birimi girmeye vakti ve sabrı yoktur.

Hoppa Çözümü: Esnaf dükkanındaki fiziki kağıt menünün veya toptancıdan aldığı taze ürün faturasının (fatura/adisyon) fotoğrafını telefonunun kamerasıyla çeker.

Arka Plan Akışı: Optik Karakter Tanıma (OCR) ve Gemini Vision entegrasyonumuz, fotoğraftaki ürün isimlerini, birimlerini (Adet/KG) ve fiyatlarını saniyeler içinde ayrıştırır. Bulduğu ürünleri 1000+ ürünlük Master Kataloğumuzla pürüzsüzce eşleştirerek dükkanın dijital envanterini 10 saniyede satışa hazır hale getirir.

🍊 B. Dinamik Talep ve Taze Ürün Tahminleme (AI Predictive Stock)

Özellik: Kasap ve manav gibi taze gıda satan esnaflar için en büyük maliyet unsuru fire (ürün bozulması) vermektir.

İşleyiş: Hoppa'nın tahminleme algoritması, geçmiş sipariş yoğunluklarını, hava durumu verilerini ve adadaki üniversite dönem takvimlerini analiz ederek esnafa "Bu hafta sonu Mağusa bölgesinde %30 daha fazla kıyma talebi olacak, siparişlerinizi buna göre optimize edin" önerisinde bulunur.

Maliyet Etkisi: Esnafın fire oranını $\%40$ azaltırken, platformumuzun lojistik doluluk oranını (density) zirveye taşır.

🛵 3. OPERASYON VE FLOT OPTİMİZASYON (FLEET AI)

🍊 A. Akıllı Sipariş Kümeleme ve Rota Optimizasyonu (AI Batching)

Sorun: Kuryelerin her paketi tek tek alıp götürmesi lojistik olarak zarardır (High Cost-per-Delivery).

Hoppa Çözümü: Aynı rotaya giden ve hazırlık süreleri birbiriyle eşleşen siparişleri akıllıca kümeleyen (Batching) bir lojistik algoritma kullanıyoruz.

Matematiksel Rota Maliyet Fonksiyonu (Route Cost Function):

$$C(R) = \sum_{i=1}^{n-1} d(p_i, p_{i+1}) + \sum_{i=1}^{n} w_i$$

(Burada $d$ Haversine mesafesini, $w$ ise dükkanın anlık yapay zeka tarafından tahmin edilen hazırlık bekleme süresini temsil eder. Rota maliyetini en aza indirerek kuryelerimizin saatlik paket taşıma kapasitesini 1.8'den 3.5 paket/saat seviyesine çıkarıyoruz).
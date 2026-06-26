Story 18.3 - Canlı Kurye Haritası Animasyonu ve Modern UX Optimizasyonu

Bu görev belgesi; canlı takip ekranındaki gereksiz "kuş uçuşu" düz çizgiyi haritadan tamamen kaldırmayı, kuryenin saniyeler içinde zıplayarak gitmesi yerine koordinat paketleri arasında pürüzsüz kaymasını (marker animation) ve motor ikonunun gidiş açısına ($\theta$) göre otomatik dönmesini sağlamayı amaçlar.

🧭 1. BÖLÜM: Matematiksel ve Mantıksal Modelleme

A. Rota Çizgisinin Kaldırılması

Harita üzerindeki Polyline katmanı (bizi kurye ile eve bağlayan o düz çizgi) tamamen kaldırılacaktır. Harita sadece iki temel ikona odaklanacaktır:

Ev İkonu: Müşterinin sipariş teslimat adresi.

Kurye İkonu: Canlı olarak hareket eden motor/kurye görseli.

B. Pürüzsüz Koordinat İnterpolasyonu ($\operatorname{lerp}$)

Kuryenin konumu her $5\text{ saniyede}$ bir veritabanına akar. Eğer haritadaki marker doğrudan bu koordinata taşınırsa, kurye ekranda zıplayarak (teleport) hareket eder.

Bunun önüne geçmek için kuryenin eski konumu ($Lat_{\text{old}}, Lng_{\text{old}}$) ile yeni konumu ($Lat_{\text{new}}, Lng_{\text{new}}$) arasında doğrusal interpolasyon ($\operatorname{lerp}$) uygulayarak kurye ikonunu pürüzsüzce kaydıracağız:

$$Lat_{t} = (1 - t) \cdot Lat_{\text{old}} + t \cdot Lat_{\text{new}}$$

$$Lng_{t} = (1 - t) \cdot Lng_{\text{old}} + t \cdot Lng_{\text{new}}$$

Burada $t \in [0, 1]$ zamanla artan bir animasyon ilerleme parametresidir. Flutter katmanında bu işlem Marker konumunu güncelleyen bir AnimationController veya Tween yapısıyla çözülecektir.

C. Dönüş Açısı (Bearing/Rotation $\theta$) Entegrasyonu

Kurye motor ikonu her zaman haritada yukarı bakmamalı, gittiği yöne doğru dönmelidir.

Veritabanından gelen bearing değeri (derece cinsinden $[0^\circ, 360^\circ)$) doğrudan Google Maps / Flutter Map marker bileşenindeki rotation özelliğine bağlanacaktır:

$$\text{Marker.rotation} = \theta_{\text{bearing}}$$

🛠️ 2. BÖLÜM: Uygulama Adımları (Flutter Consumer App)

A. Haritadaki Polyline Bileşeninin Temizlenmesi

order_tracking_page.dart (veya kurye takip haritasını barındıran widget) dosyasını açın.

GoogleMap veya FlutterMap üzerindeki polylines listesini ve rota çizmeye yarayan tüm fonksiyonları (varsa createPolyline, LatLng listesi tutan değişkenler vb.) tamamen temizleyin.

B. Kurye İkonunun Dönüş Açısının Etkinleştirilmesi

Haritada kuryeyi temsil eden Marker nesnesini bulun.

Marker'ın yönünü ayarlamak için veritabanındaki bearing parametresini rotation özelliğine eşleyin:

Marker(
  markerId: const MarkerId('courier_marker'),
  position: LatLng(courierLat, courierLng),
  rotation: courierBearing, // 👈 Kuryenin gidiş açısı (0 - 360)
  icon: courierIcon, // Motor görseli
)


C. Konumlar Arasında Pürüzsüz Kayma Animasyonu

Haritaya yeni bir koordinat çifti geldiğinde, marker'ın aniden ışınlanmasını engellemek için şu animasyon kurgusunu hazırlayın:

order_tracking_page.dart içerisindeki harita state'ine bir AnimationController tanımlayın:

late AnimationController _movementController;
LatLng? _oldPosition;
LatLng? _newPosition;


Supabase üzerinden her yeni konum paketi geldiğinde, animasyonu tetikleyin:

void _animateMarker(LatLng targetPosition) {
  _oldPosition = _newPosition ?? targetPosition;
  _newPosition = targetPosition;

  _movementController.reset();
  _movementController.forward();
}


Animasyon çalışırken _movementController.addListener içinde haritadaki marker koordinatını LatLng.lerp metoduyla güncelleyin:

final LatLng interpolatedPos = LatLng.lerp(_oldPosition!, _newPosition!, _movementController.value)!;
setState(() {
  // Marker'ın pozisyonunu interpolatedPos yapın
});


📢 Doğrulama Planı

Statik Kod Analizi:

cd apps/consumer_app && flutter analyze


Manuel Görsel Test (UAT):

Kurye takip ekranını açın.

Haritada dükkan ile ev arasında uzanan o anlamsız düz çizginin tamamen kaybolduğunu doğrulayın.

Kurye hareket ettikçe, motor ikonunun zıplayarak gitmek yerine pürüzsüzce kaydığını ve dönemeçlerde motorun önünün viraj yönüne (bearing açısına göre) doğru döndüğünü izleyin!
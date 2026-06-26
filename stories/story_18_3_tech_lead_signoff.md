🏆 Tech Lead Onayı ve Mühendislik Sıkılaştırma Kılavuzu (Story 18.3)

Durum: 🟢 Şartlı Onaylandı (Aşağıdaki Kenar Durumu Önlemleri ile)

Canlı takip ekranındaki kuş uçuşu polyline çizgisinin kaldırılması ve sadece pürüzsüz kayan motor ikonuyla (Senaryo B) ilerleme kararı onaylanmıştır. Ancak, kuryenin hareketi sırasında oluşabilecek 2 kritik kenar durumunun (edge case) kod seviyesinde çözülmesi zorunludur:

🚨 1. Kademeli Animasyon Kesintisi (Animation Interruption)

📌 Sorun:

Kurye veritabanından her $5\text{ saniyede}$ bir yeni konum alır. Bizim yazdığımız LatLng.lerp animasyonumuz ise $3\text{ saniye}$ sürer.

Normal akışta sorun yoktur (kurye 3 saniye kayar, 2 saniye bekler, yeni paket gelir).

Ancak; eğer kurye arka arkaya hızlı konum paketleri gönderirse (örneğin ağ gecikmesi nedeniyle iki paket üst üste gelirse), mevcut 3 saniyelik animasyon henüz bitmeden yeni bir konum paketi gelecektir.

Eğer animasyon kodunu sadece _movementController.reset() ve forward() yapacak şekilde kurgularsak, motor ikonu o an durduğu yer yerine eski hedefe ışınlanıp (teleport) oradan yeni hedefe doğru kaymaya başlar. Bu da ekranda sarsıntıya ve kötü bir görsel deneyime (glitch) yol açar.

🛠️ Çözüm (Düzeltici Aksiyon):

Her yeni konum paketi geldiğinde, animasyonun başlangıç noktasını eski hedef değil, ikonun tam o an (kesinti anında) durduğu ara koordinat olarak set etmeliyiz:

void _animateMarker(LatLng targetPosition) {
  // Eğer animasyon şu an oynatılıyorsa, başlangıç noktasını durduğu yer (interpolatedPos) yap
  if (_movementController.isAnimating) {
    _oldPosition = LatLng.lerp(_oldPosition!, _newPosition!, _movementController.value)!;
  } else {
    _oldPosition = _newPosition ?? targetPosition;
  }
  
  _newPosition = targetPosition;

  _movementController.reset();
  _movementController.forward();
}


🔄 2. Açı Sınır Geçişi (Angle Wrapping / 360-Degree Spin)

📌 Sorun:

Kurye motorunun dönüş açısı ($\theta$) $[0^\circ, 360^\circ)$ arasında hareket eder.

Kurye kuzey yönünde hafifçe dönerken açı $355^\circ$ değerinden $5^\circ$ değerine geçiş yaparsa, motor ikonu sadece $10^\circ$ dönmesi gerekirken, Flutter'daki rota yönlendiricisi bunu $355 \rightarrow 5$ yönünde geri dönerek $350^\circ$'lik devasa bir tam tur (spin) atarak döndürür. Bu durum motorun kendi etrafında fırıl fırıl dönmesine neden olur.

🛠️ Çözüm (Düzeltici Aksiyon):

Dönüş açısındaki sapmaları her zaman en kısa yoldan (shortest path interpolation) hesaplamalıyız:

double _calculateShortestAngle(double from, double to) {
  double difference = (to - from) % 360;
  if (difference > 180) {
    difference -= 360;
  } else if (difference < -180) {
    difference += 360;
  }
  return from + difference;
}


Açı güncellenirken doğrudan geçiş yapmak yerine bu yardımcı fonksiyon ile en yakın dönüş yönü hesaplanarak rotation değeri beslenmelidir.
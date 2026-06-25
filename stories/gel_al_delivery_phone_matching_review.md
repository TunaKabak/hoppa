🏆 Gel Al ve Eve Teslim Dinamik Telefon Eşleştirmesi - Tech Lead Değerlendirme ve Onay Raporu

Proje: Hoppa MVP

Kapsam: Sipariş Detay & İletişim Bilgileri (Gel Al / Eve Teslim Ayrımı)

Durum: 🟢 Koşulsuz Onaylandı (Aşağıdaki Sıkılaştırma Önlemleri ile)

🔍 Tech Lead Kritik Güvenlik ve Kararlılık Dokunuşları

Agent geliştirmeye başlamadan önce, hazırladığın plana şu 3 hayati detayın eklenmesi zorunludur:

1. iOS Cihazlar İçin url_launcher İzin Protokolü (Kritik!)

Kör Nokta: iOS 9 ve üzeri sürümlerde, url_launcher paketinin harici bir şemayı (Örn: tel:+90... telefon arama ekranını) tetikleyebilmesi için uygulamanın Info.plist dosyasına yasal izin şemasının eklenmesi şarttır. Aksi takdirde iOS, güvenlik protokolü gereği arama butonuna basıldığında hiçbir tepki vermez ve arama ekranını açmaz.

Mühendislik Çözümü: apps/consumer_app/ios/Runner/Info.plist dosyasına aşağıdaki sorgu şeması eklenmelidir:

<key>LSApplicationQueriesSchemes</key>
<array>
  <string>tel</string>
</array>


2. Kurye Atanmama Durumunda Null-Safety Garantisi (Flutter Red Screen Önlemi)

Kör Nokta: Sipariş ilk oluşturulduğunda (PENDING veya PREPARING durumundayken) siparişe henüz bir kurye atanmamıştır (order.courier null gelecektir). Eğer order.dart modelinde kurye alanlarını parse ederken null kontrolü yapmazsak uygulama anında çöker veya kırmızı ekran verir.

Mühendislik Çözümü: Modeldeki kurye alanları kesinlikle nullable (String?) tanımlanmalı ve fromMap içerisinde güvenli null-guard ile parse edilmelidir:

// Model seviyesinde null-safe parsing
courierPhone: map['courier'] != null ? map['courier']['phoneNumber'] as String? : null,
courierName: map['courier'] != null ? map['courier']['name'] as String? : null,


3. Prisma Sorgusunda Dükkan (Shop) İlişkisi Eksikliği

Kör Nokta: Tüketici "Gel Al" siparişi verdiğinde dükkanın telefon numarasını (_business?.phone veya order.shop.phoneNumber) gösterebilmemiz için backend tarafındaki getConsumerOrders Prisma sorgusunun sadece consumer ve courier ilişkilerini değil, aynı zamanda shop ilişkisini de içeri aktarması (include) gerekir.

Mühendislik Çözümü: OrderController.ts içindeki ilgili metodlarda Prisma include bloğu şu şekilde genişletilmelidir:

include: {
  consumer: true,
  courier: true,
  shop: true // Kesinlikle eklenmeli!
}


🚀 Agent İçin Güncellenmiş Adım Adım Uygulama Talimatı

Agent (Cursor/Windsurf), bu dökümanı okuduğunda doğrudan aşağıdaki adımları sırasıyla işletmelidir:

🛠️ ADIM 1: Backend Prisma Sorgu Sıkılaştırması

backend/src/controllers/OrderController.ts dosyasını aç.

getConsumerOrders, getMerchantOrders ve updateOrderStatus metodlarında sipariş detaylarını dönen sorgulardaki include bloklarına shop: true ve courier: true ekle.

📱 ADIM 2: iOS İzinleri ve Model Güvenliği (Null-Safe)

apps/consumer_app/ios/Runner/Info.plist dosyasına <key>LSApplicationQueriesSchemes</key> altına <string>tel</string> iznini ekle.

order.dart modeline courierName, courierPhone ve courierVehiclePlate alanlarını nullable (String?) olarak ekle ve fromMap gövdesinde yukarıda belirtilen güvenli null-guard yapısını kur.

📞 ADIM 3: Arayüz ve url_launcher Entegrasyonu

pubspec.yaml dosyasına url_launcher paketinin eklendiğini doğrula.

checkout_page.dart üzerinde "Gel Al" seçildiğinde iletişim numarası olarak dükkan numarasını (shop.phoneNumber) göster ve ödeme sayfasına bu numarayı pasla.

order_detail_page.dart ve order_tracking_page.dart ekranlarındaki kurye/dükkan bilgilerini dinamik yap. Arama butonuna tıklandığında Uri.parse('tel:$phone') şemasıyla launchUrl fonksiyonunu tetikleyen asenkron çağrıyı yaz.
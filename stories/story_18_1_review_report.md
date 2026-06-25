🏆 Story 18.1 - Tech Lead Değerlendirme ve Onay Raporu

Proje: Hoppa MVP

Aşama: Story 18.1 (Dinamik Süre, Akıllı Yönlendirme ve Kurye Takip 401 Hotfix)

Durum: 🟢 Şartlı Onaylandı (Approved with Conditions)

🔍 Tech Lead İnceleme Notları ve Kritik İyileştirmeler

Agent tarafından hazırlanan plan mimari açıdan çok başarılıdır. Ancak canlı operasyonda sistemin çökmesini engellemek için geliştirmeye başlamadan önce şu 3 kritik kuralın plana dahil edilmesi zorunludur:

1. Koordinat Yoksa Çökme Engeli (Null Guard Fallback)

Kör Nokta: Sipariş oluşturma veya kurye atama anında dükkanın veya kullanıcının adres koordinatları (latitude, longitude) null veya tanımsız gelebilir. Eğer kod doğrudan Haversine formülünü çalıştırmayı denerse NaN veya null pointer exception hatası verir ve sipariş oluşturma süreci (API) tamamen kilitlenir.

Mühendislik Çözümü: OrderController.ts içindeki mesafe hesaplama metoduna kesinlikle bir null guard eklenmelidir. Koordinatlar eksikse mesafe hesaplaması atlanmalı ve tahmini süre varsayılan olarak 30 dakika (30) atanmalıdır.

// Örnek Güvenli Kod Standardı
let estimatedDuration = 30; // Varsayılan süre
if (shop.latitude && shop.longitude && userAddress.latitude && userAddress.longitude) {
    const distance = calculateHaversine(
        shop.latitude, shop.longitude, 
        userAddress.latitude, userAddress.longitude
    );
    estimatedDuration = 20 + Math.round(distance * 4);
}


2. pubspec.yaml Asset Kontrolü

Kör Nokta: Agent planında main_consumer.dart ve .env kontrollerini eklemiş ancak pubspec.yaml dosyasına değinmemiştir. Eğer .env dosyası Flutter tarafında asset olarak paketlenmezse, yazılan tüm .env okuma kontrolleri fiziksel cihazda null dönecek ve Supabase 401 hatası devam edecektir.

Mühendislik Çözümü: Agent, pubspec.yaml dosyasını açıp altında .env dosyasının asset listesinde ekli olduğunu kesinlikle doğrulamalıdır.

3. Hassas Matematiksel Yuvarlama (Floating Point Precision)

Dart tarafında stepSize artırımları yapılırken (örneğin $0.25$ adımlarla) kayan nokta (floating point) hassasiyeti yüzünden mikro yuvarlama hataları (Örn: $0.75 + 0.25 = 1.0000000000000002$) oluşabilir.

Mühendislik Çözümü: Miktar gösterimi ve sepet hesaplamalarında değerler her zaman toFixed veya toStringAsFixed(2) parse edilerek yuvarlanmalıdır.

🚀 Agent İçin Güncellenmiş Adım Adım Uygulama Talimatı

Agent (Cursor/Windsurf) bu dökümanı okuduğunda doğrudan aşağıdaki adımları sırasıyla işletmelidir:

🛠️ ADIM 1: Prisma ve Backend Dinamik Süre Entegrasyonu (Null-Safe)

backend/prisma/schema.prisma dosyasına estimatedDeliveryDuration Int? alanını ekle, veritabanına pushla (npx prisma db push).

OrderController.ts dosyasında Haversine mesafeli süre hesaplamasını yaz. Koordinatların eksik olma durumunu (null-safe) kontrol et ve varsayılan olarak 30 dakika ata.

📱 ADIM 2: Flutter Model ve Bildirim Yönlendirme Düzeltmesi (Deep Linking)

order.dart modeline estimatedDeliveryDuration alanını güvenli null-safety kurallarıyla ekle.

notification_navigation_helper.dart içindeki bildirim tıklama filtresini esneterek orderId içeren tüm bildirimlerin doğrudan OrderDetailPage sayfasına yönlenmesini sağla.

order_detail_page.dart açılışına (initState) ref.invalidate(orderDetailProvider) ekleyerek her açılışta güncel sipariş verilerinin API'den taze çekilmesini garantile.

🗺️ ADIM 3: Supabase 401 Hatası ve Canlı Kurye Takip Ekranı Revizyonu

hem consumer_app hem de merchant_app içindeki pubspec.yaml dosyalarında .env asset tanımının yapıldığını doğrula.

main_consumer.dart asenkron dotenv.load() yükleme sırasını ve boş url/anonKey kontrollerini sıkılaştır.

order_tracking_page.dart (Kurye Takip Sayfası) içindeki StreamBuilder yapısına snapshot.hasError kontrolü ekle. Hata anında kullanıcıya ham exception mesajı yerine şık ve Türkçe bir "Bağlantı Sorunu" ekranı sun. Bu ekrana ref.invalidate(courierLocationStreamProvider) asenkron çağrısını tetikleyen bir "Yeniden Dene" butonu yerleştir.
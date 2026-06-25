Story 18.1 - Dinamik Teslimat Süresi, Akıllı Bildirim Yönlendirme ve Canlı Kurye Takip (401 Auth) Hotfix Planı

Bu görev belgesi; teslimat mesafesine bağlı olarak tahmini varış süresini dinamik şekilde esneten bir algoritma kurmayı, bildirim tıklandığında siparişin en güncel durumuna (ON_THE_WAY vb.) anında yönlenip veriyi tazelemeyi ve kurye canlı takip haritasında Supabase 401 (API Key missing) bağlantı hatasını çözerek arayüzü kullanıcı dostu hale getirmeyi amaçlar.

🧭 1. Kısım: Dinamik Teslimat Süresi Algoritması

Matematiksel Modelleme

Siparişlerin tahmini teslimat süresi (Estimated Delivery Time - EDT), restoranın hazırlama hızı ile mesafenin doğrusal bir fonksiyonu olarak hesaplanacaktır:

$$\text{Tahmini Süre (EDT)} = \text{Baz Hazırlık Süresi} + (\text{Mesafe in km} \times \text{Ortalama Dakika/km})$$

Baz Hazırlık Süresi: 20 Dakika (Dükkan türüne veya dükkanın kendi parametresine göre ayarlanabilir).

Ortalama Dakika/km: Trafik ve kurye hızı hesaba katılarak ortalama 4 dakika/km olarak alınacaktır.

Örnek Hesaplama:

Mesafe = 2 km ise: $20 + (2 \times 4) = 28$ Dakika.

Mesafe = 8 km ise: $20 + (8 \times 4) = 52$ Dakika.

Teknik Entegrasyon Adımları (Backend & DB)

backend/prisma/schema.prisma dosyasındaki Order modeline tahmini süreyi dondurup kaydetmek için yeni bir alan ekliyoruz:

estimatedDeliveryDuration (Int? - Dakika cinsinden)

Sipariş oluşturma endpoint'inde (POST /api/orders) veya kurye atama mantığında, tüketici konumu ile dükkan konumu arasındaki mesafe kullanılarak yukarıdaki formül işletilir ve bu değer sipariş satırına kaydedilir.

Doğrulama Komutu:

cd backend && npx prisma db push && npx prisma generate


📱 2. Kısım: Bildirim Yönlendirme ve Eski Durum (Stale State) Bugfix (Flutter)

Sorun Analizi

Yönlenmeme Sorunu: Bildirim tıklandığında uygulamanın ilgili siparişi açamaması, Firebase Messaging tetikleyicilerindeki payload içindeki orderId bilgisinin okunup Navigator yapısına doğru şekilde aktarılamamasından kaynaklanır.

"Hala Hazırlanıyor" Görünmesi (State Sync Hatası): Kullanıcı bildirime basıp siparişi açtığında, uygulama eğer daha önce açık kalan sipariş sayfasını bellekten (cache) çekerse veriler eski kalır. Sayfa açılırken sunucudan en taze sipariş bilgisini zorla çekmeli (force fetch / invalidate) ve Riverpod/Bloc durumunu tazelemeliyiz.

Çözüm Adımları

A. Firebase Bildirim Dinleyicisini Güncelleme (NotificationService.dart)

Bildirim geldiğinde arka planda (veya tıklanınca) taşınan orderId verisini yakalayacak ve uygulamayı doğrudan o sayfaya fırlatacak yapıyı kuruyoruz:

Future<void> handleNotificationTap(RemoteMessage message) async {
  final data = message.data;
  if (data.containsKey('orderId')) {
    final String orderId = data['orderId'];
    
    // Uygulama ayaktayken veya arka plandan gelirken ilgili sipariş sayfasına yönlendir
    AppNavigator.navigatorKey.currentState?.pushNamed(
      '/order-detail',
      arguments: orderId,
    );
  }
}


B. Sipariş Detay Sayfasında Verileri Zorla Yenileme (order_detail_page.dart)

Tüketici sipariş detay sayfasına girdiği an, eski durumu görmemesi için mevcut cache'i geçersiz kılıp API'den taze veri çekiyoruz:

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // Örnek Riverpod kullanımı: (Mevcut sağlayıcıyı geçersiz kılarak en güncel veriyi zorla çeker)
    ref.invalidate(orderDetailProvider(widget.orderId));
    ref.read(orderDetailProvider(widget.orderId).notifier).fetchOrderDetails();
  });
}


🗺️ 3. Kısım: Canlı Kurye Takip Ekranı Supabase Auth (401 API Key Missing) Çözümü

Sorun Analizi

Ekrandaki PostgrestException (message: No API key found in request, code: 401...) hatası, mobil uygulamanın Supabase Realtime/Database isteklerinde apikey ve Authorization başlıklarını (headers) gönderemediğini gösterir. Bu durum iki temel sebepten kaynaklanır:

Parlama/Sıralama Hatası (main.dart): dotenv.load() işlemi tamamlanmadan (asenkron bekleme yapılmadan) Supabase.initialize fonksiyonunun çağrılması ve dolayısıyla anonKey değerinin null veya boş gitmesi.

Asset Paketlenmesi Eksikliği (pubspec.yaml): .env dosyasının fiziksel cihazda asset olarak paketlenmemesi.

Çözüm Adımları

A. pubspec.yaml Dosyalarının Güncellenmesi

Hem consumer_app hem de merchant_app altındaki pubspec.yaml dosyalarında .env dosyasının asset olarak tanımlandığından emin olun:

flutter:
  assets:
    - .env
    # Diğer varlıklar...


B. main.dart Başlatma Sırasının Güvenli Hale Getirilmesi

Uygulama başlarken asenkron yüklemelerin sırasını ve hata yönetimini sıkılaştırıyoruz:

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Önce çevre değişkenlerini yükle
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("🚨 Hata: .env dosyası yüklenemedi! $e");
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    print("🚨 KRİTİK HATA: Supabase anahtarları .env içerisinde bulunamadı!");
  }

  // 2. Supabase istemcisini başlat
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: MyApp()));
}


C. Canlı Kurye Takip Ekranında Hata Yönetimi & Kullanıcı Dostu UI (kurye_takip_page.dart)

Kullanıcıya ham hata mesajı göstermek yerine şık bir "Kurye konumu şu anda alınamıyor" ekranı ve arka planda güvenli retry mekanizması kuruyoruz:

StreamBuilder<List<Map<String, dynamic>>>(
  stream: supabase.from('courier_locations').stream(primaryKey: ['id']).eq('courier_id', widget.courierId),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      print("Supabase Stream Hatası: ${snapshot.error}");
      
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.location_off_outlined, size: 54, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                "Bağlantı Sorunu",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Kurye konumu şu anda canlı olarak alınamıyor. Bağlantı arka planda otomatik olarak yeniden deneniyor...",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Ekranı/Stream'i zorla tetikle
                  setState(() {});
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Yeniden Dene"),
              )
            ],
          ),
        ),
      );
    }

    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text("Kurye bağlantısı bekleniyor..."),
          ],
        ),
      );
    }

    // Başarılı akış: Harita üzerinde kuryeyi çizdirme kodları...
    final location = snapshot.data!.first;
    return _buildMapWithCourierLocation(location);
  },
);


📢 Doğrulama Planı

Backend Statik Analiz:

cd backend && npm run build


Flutter Kod Analizi:

cd apps/consumer_app && flutter analyze


Manuel Test Akışı:

Kurye konum takibi ekranını açın. Ekranda hiçbir ham hata mesajı (PostgrestException 401) çıkmadığını, bağlantı kopunca şık bir "Yeniden Dene" arayüzü belirdiğini doğrulayın.

Fiziksel cihazı bilgisayara bağlayıp sıfırdan derleyin ve canlı konum akışının harita üzerinde saniyelik güncellendiğini görün!
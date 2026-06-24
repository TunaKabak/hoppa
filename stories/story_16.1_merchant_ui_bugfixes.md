Story 16.1 - Merchant Uygulaması UI/UX Hataları ve Gelişmiş Filtreleme Hotfix Planı

Bu görev belgesi, satıcı dükkan uygulamasındaki (Merchant App) arayüz pürüzlerini gidermek, dokunma (touch target) hassasiyetini artırmak ve dashboard verileriyle sipariş listesini dinamik olarak birbirine bağlamak için gereken adımları içerir.

🛠️ ADIM 1: Siparişler Ekranı Tıklanamama (Touch Blocking) Çözümü

Sorun Analizi

Siparişler ekranında bazen menünün veya butonların tıklanmaması (unresponsive UI) genellikle şu sebeplerden kaynaklanır:

Klavye / Odaklanma Kilidi: Diğer sayfalardan kalan açık bir FocusNode (Örn: ürün ekleme veya arama) klavyeyi kapatsa bile ekranda görünmez bir katman olarak dokunmaları yutar.

Gesture Conflict: Liste kaydırma hareketleri (ScrollPhysics) ile tıklama algılayıcıların (GestureDetector) çakışması.

Obstructed Tap Targets: Yetersiz dokunma alanı veya üst üste binen transparan Container'lar.

Çözüm Kod Modifikasyonu

Siparişler ekranı (merchant_order_list_page.dart) build metodunun en dışına klavye/odak temizleyici yerleştirilecek ve dokunma alanları Behavior.translucent ile genişletilecektir.

// apps/merchant_app/lib/apps/merchant/merchant_order_list_page.dart dosyasında uygulanacak düzeltme:

@override
Widget build(BuildContext context) {
  // Sayfaya girildiğinde aktif odakları (klavye vb.) temizlemek için GestureDetector ile sarıyoruz
  return GestureDetector(
    behavior: HitTestBehavior.translucent, // Tıklamayı alt katmanlara da geçirir
    onTap: () {
      final currentFocus = FocusScope.of(context);
      if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
        FocusManager.instance.primaryFocus?.unfocus();
      }
    },
    child: Scaffold(
      // Mevcut appBar ve body yapısı...
    ),
  );
}


📊 ADIM 2: Dashboard Kart Tıklama Entegrasyonu (Dinamik Yönlendirme)

Yapılacaklar

Dashboard'da bulunan "Onay Bekleyenler", "Hazırlananlar" vb. durum kartlarına tıklandığında, sadece sipariş listesini açmakla kalmayacak; aynı zamanda hangi karta tıklandıysa o durumun filtresini sipariş listesine parametre olarak geçeceğiz.

merchant_dashboard_page.dart dosyasında kartların onTap olaylarını güncelleyin:

"Onay Bekleyen" kartına tıklandığında -> OrderStatus.PENDING

"Hazırlananlar" kartına tıklandığında -> OrderStatus.PREPARING

"Yoldakiler" kartına tıklandığında -> OrderStatus.ON_THE_WAY

// apps/merchant_app/lib/apps/merchant/merchant_dashboard_page.dart dosyasında örnek yönlendirme:

Widget _buildStatCard({
  required String title,
  required String value,
  required OrderStatus filterStatus, // Yeni eklenecek parametre
  required BuildContext context,
}) {
  return InkWell(
    onTap: () {
      // Siparişler ekranına yönlendirirken filtre durumunu gönderiyoruz
      Navigator.pushNamed(
        context,
        '/merchant-orders',
        arguments: filterStatus, // Durumu arguments üzerinden taşıyoruz
      );
    },
    // Kart tasarımı...
  );
}


🔍 ADIM 3: Sipariş Listesinde Duruma Göre Filtreleme (Filter Chips)

Yapılacaklar

Siparişler sayfasının en üstüne, kullanıcının siparişleri durumlarına göre saniyeler içinde süzmesini sağlayacak şık ve kaydırılabilir bir Filtre Şeridi (Filter Chips Row) ekliyoruz.

merchant_order_list_page.dart dosyasını initialFilter parametresini alacak şekilde güncelleyin.

Sayfanın en üstüne (Arama veya Liste başlangıcından önce) aşağıdaki filtre barını yerleştirin:

// apps/merchant_app/lib/apps/merchant/merchant_order_list_page.dart

class MerchantOrderListPage extends StatefulWidget {
  final OrderStatus? initialFilter; // Dashboard'dan gelebilecek ilk filtre

  const MerchantOrderListPage({Key? key, this.initialFilter}) : super(key: key);

  @override
  State<MerchantOrderListPage> createState() => _MerchantOrderListPageState();
}

class _MerchantOrderListPageState extends State<MerchantOrderListPage> {
  OrderStatus? _selectedFilter; // Seçili filtre (null ise "Tümü" demektir)

  @override
  void initState() {
    super.initState();
    // Eğer dashboard'dan bir filtre yönlendirmesi geldiyse onu aktif yapıyoruz
    _selectedFilter = widget.initialFilter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(title: const Text("Sipariş Yönetimi")),
      body: Column(
        children: [
          // Yatayda kaydırılabilir filtre şeridi
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildFilterChip(null, "Tümü", theme),
                const SizedBox(width: 8),
                _buildFilterChip(OrderStatus.PENDING, "Bekleyenler ⏳", theme),
                const SizedBox(width: 8),
                _buildFilterChip(OrderStatus.PREPARING, "Hazırlananlar 🍳", theme),
                const SizedBox(width: 8),
                _buildFilterChip(OrderStatus.ON_THE_WAY, "Yoldakiler 🛵", theme),
                const SizedBox(width: 8),
                _buildFilterChip(OrderStatus.DELIVERED, "Tamamlananlar ✅", theme),
                const SizedBox(width: 8),
                _buildFilterChip(OrderStatus.CANCELLED, "İptaller ❌", theme),
              ],
            ),
          ),
          
          // Sipariş Listesi (Seçilen filtreye göre elenmiş veriler gösterilecek)
          Expanded(
            child: _buildOrderList(_selectedFilter),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(OrderStatus? status, String label, ThemeData theme) {
    final isSelected = _selectedFilter == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = selected ? status : null;
        });
      },
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}


📢 Doğrulama Planı

Flutter Derleme Doğrulaması:

cd apps/merchant_app && flutter analyze


Kodun hiçbir hata vermeden derlendiğinden emin olun.

Kesişim Testi:

Dashboard'da "Hazırlananlar" kartına basın.

Sipariş listesinin otomatik olarak "Hazırlananlar" filtresiyle açıldığını ve üstteki "Hazırlananlar 🍳" çipinin otomatik olarak seçili geldiğini doğrulayın.
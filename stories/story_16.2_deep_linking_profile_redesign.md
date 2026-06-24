Story 16.2 - Akıllı Bildirim Yönlendirmesi (Deep Linking) ve Modern Hesap Paneli Redesign

Bu döküman, gelen anlık bildirimlere (Push Notification) tıklandığında kullanıcının doğrudan sipariş detay ekranına yönlendirilmesini sağlamak ve sağ üstteki eski, işlevsiz pop-up menüyü kaldırarak yerine modern bir "Hesap ve Güvenlik Yönetimi" arayüzü kurmak için gereken tüm teknik adımları içerir.

🛵 1. BÖLÜM: Akıllı Bildirim Yönlendirme Altyapısı (Deep Linking)

Müşteri veya satıcı bildirime tıkladığında uygulamanın arka planda veya tamamen kapalı (terminated) olması durumlarına göre yönlendirme mekanizmasını kuracağız.

A. FCM Payload Standartı (Backend)

Backend tarafındaki NotificationService.ts veya bildirim gönderen metodlarda data payload'una mutlaka orderId ve type parametreleri eklenmelidir:

{
  "notification": {
    "title": "Siparişiniz Yola Çıktı! 🛵",
    "body": "Sıcak sıcak kapınıza geliyor."
  },
  "data": {
    "click_action": "FLUTTER_NOTIFICATION_CLICK",
    "orderId": "69a9ae92-2b72-4f83-9693-462fb3c66c5e",
    "type": "ORDER_STATUS"
  }
}


B. Flutter Global Navigation Key ve Yönlendirme Servisi

Mobil uygulamalarda (hem consumer_app hem de merchant_app) BuildContext olmadan da yönlendirme yapabilmek için bir GlobalKey<NavigatorState> tanımlayacağız.

lib/main.dart (veya ilgili ana dosyalarda) navigatorKey tanımlayın ve MaterialApp'e bağlayın:

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

MaterialApp(
  navigatorKey: navigatorKey, // Global key bağlandı
  // ... diğer ayarlar
)


Ortak bir NotificationNavigationHelper sınıfı oluşturun:

import 'package:flutter/material.dart';
import '../../main.dart'; // navigatorKey'i import edin

class NotificationNavigationHelper {
  static void handleNotificationClick(Map<String, dynamic> data) {
    final String? orderId = data['orderId'];
    final String? type = data['type'];

    if (orderId == null || orderId.isEmpty) return;

    // NavigatorKey üzerinden doğrudan ilgili siparişin detayına git
    if (type == 'ORDER_STATUS') {
      navigatorKey.currentState?.pushNamed(
        '/order-details',
        arguments: orderId,
      );
    }
  }
}


FirebaseMessaging dinleyicilerine bu tık olayını bağlayın:

// Uygulama arka plandayken bildirime tıklandığında tetiklenir
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  NotificationNavigationHelper.handleNotificationClick(message.data);
});

// Uygulama tamamen kapalıyken bildirime tıklandığında tetiklenir (Initial Message)
FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
  if (message != null) {
    NotificationNavigationHelper.handleNotificationClick(message.data);
  }
});


🎨 2. BÖLÜM: Sağ Üst "Hesabım" Pop-up Menüsünün Modern Redesign'ı

Eski, sıradan pop-up menü yerine, tıklandığında alttan şık bir ivmeyle açılan (Sliding BottomSheet), dairesel profil resimli ve tam işlevli bir "Hoppa Hesap Merkezi" tasarlıyoruz.

Tüketici (Consumer) İçin Modern BottomSheet UI Tasarımı

Sağ üstteki profil ikonuna tıklandığında showModalBottomSheet yardımıyla aşağıdaki modern kart tasarımlı panel açılacaktır:

// apps/consumer_app/lib/screens/home/widgets/account_bottom_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AccountBottomSheet extends ConsumerWidget {
  const AccountBottomSheet({Key? key}) : super(key: key);

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Köşeleri ovalleştirmek için
      builder: (context) => const AccountBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tutacak barı (Drag Handle)
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Kullanıcı Bilgi Bölümü
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  "T", // Kullanıcının adının baş harfi
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Kullanıcı Profilim",
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "+90 548 860 04 55", // Kayıtlı telefon numarası
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),

          // Seçenekler Listesi (Modern List Tiles)
          _buildMenuTile(
            icon: Icons.location_on_outlined,
            title: "Kayıtlı Adreslerim",
            subtitle: "Teslimat adreslerini yönet",
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/addresses');
            },
            theme: theme,
          ),
          _buildMenuTile(
            icon: Icons.history,
            title: "Sipariş Geçmişim",
            subtitle: "Eski siparişlerini incele",
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/order-history');
            },
            theme: theme,
          ),
          _buildMenuTile(
            icon: Icons.payment_outlined,
            title: "Kayıtlı Kartlarım",
            subtitle: "Ödeme yöntemlerini düzenle",
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/saved-cards');
            },
            theme: theme,
          ),
          _buildMenuTile(
            icon: Icons.notifications_none_outlined,
            title: "Bildirim Ayarları",
            subtitle: "Hangi bildirimleri almak istersin?",
            onTap: () {},
            theme: theme,
          ),
          const SizedBox(height: 16),
          
          // Çıkış Yap Butonu (Kırmızı Vurgulu)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Oturumu kapatma logic'ini tetikle
              // ref.read(authControllerProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
            label: const Text("Çıkış Yap"),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.errorContainer,
              foregroundColor: theme.colorScheme.onErrorContainer,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}


📢 Doğrulama Planı

Flutter Derleme Doğrulaması:

cd apps/consumer_app && flutter analyze
cd apps/merchant_app && flutter analyze


Kodun hiçbir hata vermeden derlendiğinden emin olun.

Yönlendirme Testi:

Uygulama arka plandayken telefona bir sipariş durum bildirimi gönderin.

Bildirime tıkladığınızda uygulamanın otomatik olarak /order-details sayfasına yönlendiğini ve orderId'yi doğru şekilde yakaladığını test edin.
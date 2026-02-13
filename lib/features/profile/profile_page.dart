import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hoppa/core/services/auth_service.dart';
import 'package:hoppa/core/services/language_provider.dart';
import 'package:hoppa/core/l10n/app_localizations.dart';
import 'package:hoppa/features/address/address_list_page.dart';
import 'package:hoppa/features/orders/order_history_page.dart';
import 'package:hoppa/features/auth/login_page.dart'; // Login importu

import 'package:hoppa/features/cart/cart_provider.dart';
import 'package:hoppa/core/services/database_seeder.dart'; // YENİ

import 'package:cloud_firestore/cloud_firestore.dart'; // YENİ
import 'package:hoppa/models/order.dart' as kktc_market; // Aliased
import 'package:hoppa/models/order_status.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showLogoutDialog(BuildContext context, AuthService auth) {
    // CartProvider'ı burada al
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Çıkış Yap"),
        content: const Text(
          "Hesabınızdan çıkış yapmak istediğinize emin misiniz?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Vazgeç", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              auth.signOut();
              cartProvider.clearCart(deleteFromDb: true); // Sepeti Temizle
            },
            child: const Text(
              "Evet, Çıkış Yap",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final user = auth.currentUser;
    final t = AppLocalizations.of(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    final theme = Theme.of(context);

    // MİSAFİR KONTROLÜ
    final bool isGuest = user == null || user.isAnonymous;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t.translate('profile_title'),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- KULLANICI / MİSAFİR KARTI ---
            if (isGuest)
              // MİSAFİR GÖRÜNÜMÜ: Giriş Yap Butonu
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.primaryColor,
                      theme.primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_circle,
                      size: 60,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Hoşgeldiniz!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Siparişlerinizi takip etmek ve kampanyalardan yararlanmak için giriş yapın.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: theme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text("Giriş Yap / Üye Ol"),
                      ),
                    ),
                  ],
                ),
              )
            else
              // LOGGED IN KULLANICI GÖRÜNÜMÜ
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.phoneNumber ?? user.email ?? "Kullanıcı",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "Doğrulanmış Hesap ✅",
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // DİL SEÇİMİ
            Container(
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.language,
                    color: Colors.blue,
                    size: 22,
                  ),
                ),
                title: Text(
                  t.translate('language_settings'),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      languageProvider.currentLocale.languageCode == 'tr'
                          ? 'Türkçe'
                          : 'English',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.swap_horiz, color: Colors.grey),
                  ],
                ),
                onTap: () {
                  if (languageProvider.currentLocale.languageCode == 'tr') {
                    languageProvider.changeLanguage(const Locale('en', 'US'));
                  } else {
                    languageProvider.changeLanguage(const Locale('tr', 'TR'));
                  }
                },
              ),
            ),

            const SizedBox(height: 12),

            // MENÜ LİSTESİ (Sadece giriş yapmışlara özel menüler gizlenebilir veya login'e yönlendirilebilir)
            _buildMenuItem(
              context,
              icon: Icons.shopping_bag_outlined,
              title: t.translate('my_orders'),
              onTap: () {
                if (isGuest) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderHistoryPage(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              icon: Icons.location_on_outlined,
              title: t.translate('my_addresses'),
              onTap: () {
                // Misafirler de adres ekleyebilmeli (Sepet akışı için), ama kaydetmek için login isteyebiliriz.
                // Şimdilik açık bırakalım.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddressListPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              icon: Icons.headset_mic_outlined,
              title: t.translate('live_support'),
              onTap: () {},
            ),

            const SizedBox(height: 40),

            // Çıkış Yap (Misafir için gizlenebilir veya "Verileri Sil" yapılabilir)
            if (!isGuest)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context, auth),
                  icon: const Icon(Icons.logout),
                  label: Text(t.translate('logout')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 40),

            // GELİŞTİRİCİ ARAÇLARI (Sadece Debug modda veya test için)
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "Geliştirici Araçları",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.refresh, color: Colors.orange),
              title: const Text("Veritabanını Sıfırla ve Yükle"),
              subtitle: const Text(
                "Tüm verileri siler ve örnek veri yükler.",
                style: TextStyle(fontSize: 10),
              ),
              onTap: () async {
                // Onay Dialog
                bool confirm =
                    await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Dikkat"),
                        content: const Text(
                          "Tüm veritabanı silinecek ve yeniden oluşturulacak. Devam etmek istiyor musunuz?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text("Hayır"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text("Evet"),
                          ),
                        ],
                      ),
                    ) ??
                    false;

                if (!confirm) return;

                if (context.mounted) {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => const Center(
                      child: Card(
                        margin: EdgeInsets.all(50),
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text("Veritabanı Oluşturuluyor..."),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                try {
                  await DatabaseSeeder().seedSystem();
                  if (context.mounted) {
                    Navigator.pop(context); // Loading kapa
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Veritabanı başarıyla yenilendi!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  print("Error seeding: $e");
                  if (context.mounted) {
                    Navigator.pop(context); // Loading kapa
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Hata oluştu: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),

            // TEST SIPARIŞI BUTONU (YENİ)
            ListTile(
              leading: const Icon(Icons.add_shopping_cart, color: Colors.blue),
              title: const Text("Test Siparişi Oluştur"),
              subtitle: const Text(
                "Aktif sipariş banner'ını denemek için sahte sipariş oluşturur.",
                style: TextStyle(fontSize: 10),
              ),
              onTap: () async {
                if (auth.currentUser == null) return;

                try {
                  // Basit bir sipariş oluştur
                  final order = kktc_market.Order(
                    id: 'test_order_${DateTime.now().millisecondsSinceEpoch}',
                    userId: auth.currentUser!.uid,
                    businessId: 'test_business',
                    status: OrderStatus
                        .preparing
                        .value, // Bu status banner'da görünmeli
                    totalAmount: 150.0,
                    userAddress: 'Test Adresi',
                    items: [
                      kktc_market.OrderItem(
                        productId: 'test_product_1', // Fixed: Added productId
                        name: 'Test Ürün',
                        quantity: 1,
                        price: 150.0,
                      ),
                    ],
                    createdAt: DateTime.now(),
                    deliveryTime:
                        '30-45 dk', // Fixed: String instead of DateTime
                  );

                  await FirebaseFirestore.instance
                      .collection('orders')
                      .doc(order.id)
                      .set(order.toMap());

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Test siparişi oluşturuldu! Ana sayfaya gidiniz.",
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Hata: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      tileColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.black87, size: 22),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}

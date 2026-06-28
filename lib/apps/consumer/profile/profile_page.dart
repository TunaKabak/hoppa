import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:core_auth/core_auth.dart';
import 'package:hoppa/shared/core/services/language_provider.dart';
import 'package:hoppa/shared/core/l10n/app_localizations.dart';
import 'package:hoppa/apps/consumer/address/address_list_page.dart';
import 'package:hoppa/apps/consumer/orders/order_history_page.dart';
import 'package:hoppa/apps/consumer/auth/consumer_login_page.dart';
import 'package:hoppa/apps/consumer/favorites/favorites_page.dart';
import 'package:hoppa/apps/consumer/cart/cart_provider.dart';
import 'package:hoppa/apps/consumer/profile/support_chat_page.dart';
import 'package:hoppa/shared/core/services/database_seeder.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
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
              ref.read(authControllerProvider.notifier).logout();
              ref.read(cartProvider.notifier).clearCart();
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
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final t = AppLocalizations.of(context);
    final languageProvider = legacy_provider.Provider.of<LanguageProvider>(context);
    final theme = Theme.of(context);

    final bool isGuest = authState is! AuthAuthenticated;
    final AuthUser? user = isGuest ? null : authState.user;

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
                      theme.primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withValues(alpha: 0.3),
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
                          Navigator.of(context, rootNavigator: true).push(
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
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
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
                            user?.displayName ?? user?.phone ?? 'Kullanıcı',
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
                    color: Colors.blue.withValues(alpha: 0.1),
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

            _buildMenuItem(
              context,
              icon: Icons.favorite_border,
              title: "Favorilerim",
              onTap: () {
                if (isGuest) {
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FavoritesPage(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            _buildMenuItem(
              context,
              icon: Icons.shopping_bag_outlined,
              title: t.translate('my_orders'),
              onTap: () {
                if (isGuest) {
                  Navigator.of(context, rootNavigator: true).push(
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportChatPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 40),

            if (!isGuest)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context, ref),
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

            // GELİŞTİRİCİ ARAÇLARI
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
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Veritabanı başarıyla yenilendi!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
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

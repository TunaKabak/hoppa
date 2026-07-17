import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy_provider;
import 'package:core_auth/core_auth.dart';
import 'package:core_shared/shared/core/services/language_provider.dart';
import 'package:core_shared/shared/core/l10n/app_localizations.dart';
import 'package:consumer_app/apps/consumer/address/address_list_page.dart';
import 'package:consumer_app/apps/consumer/orders/order_history_page.dart';
import 'package:consumer_app/apps/consumer/auth/consumer_login_page.dart';
import 'package:consumer_app/apps/consumer/favorites/favorites_page.dart';
import 'package:consumer_app/apps/consumer/cart/cart_provider.dart';
import 'package:consumer_app/apps/consumer/profile/support_chat_page.dart';
import 'package:consumer_app/apps/consumer/widgets/hoppa_dialog.dart';
import 'package:consumer_app/apps/consumer/widgets/hoppa_header.dart';
import 'wallet_page.dart';
import 'referral_page.dart';
import 'language_selection_page.dart';
import 'notification_settings_page.dart';
import 'saved_cards_page.dart';
import 'my_reviews_page.dart';
import 'account_details_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => HoppaDialog(
        icon: Icons.logout_rounded,
        iconColor: Colors.red,
        title: "Çıkış Yap",
        content: "Hesabınızdan çıkış yapmak istediğinize emin misiniz?",
        cancelText: "Vazgeç",
        confirmText: "Evet, Çıkış Yap",
        isDestructive: true,
        onCancel: () => Navigator.pop(context),
        onConfirm: () {
          Navigator.pop(context);
          ref.read(authControllerProvider.notifier).logout();
          ref.read(cartProvider.notifier).clearCart();
        },
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

    const kPrimaryColor = Color(0xFF00A651);
    const kSecondaryColor = Color(0xFFE95D22);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE95D22), // Hoppa Orange
              Color(0xFFFF8C00), // Orange-Yellow
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Column(
          children: [
            HoppaHeader(
              height: 70,
              child: Center(
                child: Text(
                  t.translate('profile_title'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // --- KULLANICI / MİSAFİR KARTI ---
                        if (isGuest)
                          // MİSAFİR GÖRÜNÜMÜ: Giriş Yap Butonu
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [kPrimaryColor, kSecondaryColor],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: kPrimaryColor.withValues(alpha: 0.2),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.account_circle,
                                  size: 70,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  "Hoppa Dünyasına Hoş Geldiniz! 👋",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Siparişlerinizi takip etmek, kuponlarınızı kullanmak ve kayıtlı kartlarınızla hızlı ödeme yapmak için hemen giriş yapın.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
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
                                      foregroundColor: kPrimaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      "Giriş Yap / Üye Ol",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          // LOGGED IN KULLANICI GÖRÜNÜMÜ: Modern Premium Kart
                          InkWell(
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push(
                                  MaterialPageRoute(
                                    builder: (context) => const AccountDetailsPage(),
                                  ),
                              );
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [kPrimaryColor, kSecondaryColor],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: kPrimaryColor.withValues(alpha: 0.15),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: 32,
                                      backgroundColor: Colors.grey.shade100,
                                      child: const Icon(
                                        Icons.person,
                                        size: 36,
                                        color: kPrimaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user?.displayName ?? user?.phone ?? 'Kullanıcı',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.verified, color: Colors.white, size: 14),
                                              SizedBox(width: 4),
                                              Text(
                                                "Onaylı Üye",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white70,
                                    size: 28,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 28),

                        // --- YENİ: HOPPA CÜZDANIM ---
                        _buildMenuItem(
                          context,
                          icon: Icons.account_balance_wallet_rounded,
                          title: "Hoppa Cüzdanım",
                          onTap: () {
                            if (isGuest) {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(builder: (context) => const LoginPage()),
                              );
                            } else {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (context) => const WalletPage(),
                                ),
                              );
                            }
                          },
                        ),

                        const SizedBox(height: 12),

                        // --- YENİ: DAVET ET & KAZAN ---
                        _buildMenuItem(
                          context,
                          icon: Icons.card_giftcard_rounded,
                          title: "Davet Et & Kazan!",
                          onTap: () {
                            if (isGuest) {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(builder: (context) => const LoginPage()),
                              );
                            } else {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (context) => const ReferralPage(),
                                ),
                              );
                            }
                          },
                        ),

                        const SizedBox(height: 12),

                        // DİL SEÇİMİ
                        _buildMenuItem(
                          context,
                          icon: Icons.language_rounded,
                          title: t.translate('language_settings'),
                          trailingText: languageProvider.currentLocale.languageCode == 'tr' ? 'Türkçe' : 'English',
                          onTap: () {
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (context) => const LanguageSelectionPage(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // FAVORİLERİM
                        _buildMenuItem(
                          context,
                          icon: Icons.favorite_rounded,
                          title: "Favorilerim",
                          onTap: () {
                            if (isGuest) {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(builder: (context) => const LoginPage()),
                              );
                            } else {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (context) => const FavoritesPage(),
                                ),
                              );
                            }
                          },
                        ),

                        const SizedBox(height: 12),

                        // SİPARİŞLERİM
                        _buildMenuItem(
                          context,
                          icon: Icons.shopping_bag_rounded,
                          title: t.translate('my_orders'),
                          onTap: () {
                            if (isGuest) {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(builder: (context) => const LoginPage()),
                              );
                            } else {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (context) => const OrderHistoryPage(),
                                ),
                              );
                            }
                          },
                        ),

                        const SizedBox(height: 12),

                        // ADRESLERİM
                        _buildMenuItem(
                          context,
                          icon: Icons.location_on_rounded,
                          title: t.translate('my_addresses'),
                          onTap: () {
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (context) => const AddressListPage(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        // DEĞERLENDİRMELERİM (Yorumlarım)
                        if (!isGuest) ...[
                          _buildMenuItem(
                            context,
                            icon: Icons.rate_review_rounded,
                            title: "Değerlendirmelerim",
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (context) => const MyReviewsPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],

                        // KAYITLI KARTLARIM
                        if (!isGuest) ...[
                          _buildMenuItem(
                            context,
                            icon: Icons.credit_card_rounded,
                            title: "Kayıtlı Kartlarım",
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (context) => const SavedCardsPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],

                        // BİLDİRİM AYARLARI
                        if (!isGuest) ...[
                          _buildMenuItem(
                            context,
                            icon: Icons.notifications_rounded,
                            title: "Bildirim Ayarları",
                            onTap: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (context) => const NotificationSettingsPage(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                        ],

                        // CANLI DESTEK
                        _buildMenuItem(
                          context,
                          icon: Icons.headset_mic_rounded,
                          title: t.translate('live_support'),
                          onTap: () {
                            Navigator.of(context, rootNavigator: true).push(
                              MaterialPageRoute(
                                builder: (context) => const SupportChatPage(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 40),

                        // ÇIKIŞ YAP BUTONU
                        if (!isGuest)
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: OutlinedButton.icon(
                              onPressed: () => _showLogoutDialog(context, ref),
                              icon: const Icon(Icons.logout_rounded),
                              label: Text(
                                t.translate('logout'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    Color iconColor = const Color(0xFFE95D22), // Hoppa Orange as single color
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  trailingText,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

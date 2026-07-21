import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_auth/core_auth.dart';
import 'package:consumer_app/apps/consumer/address/address_list_page.dart';
import 'package:consumer_app/apps/consumer/orders/order_history_page.dart';
import 'package:consumer_app/apps/consumer/auth/consumer_login_page.dart';
import 'package:consumer_app/apps/consumer/profile/account_details_page.dart';
import 'package:consumer_app/apps/consumer/profile/wallet_page.dart';
import 'package:consumer_app/apps/consumer/profile/referral_page.dart';
import 'package:consumer_app/apps/consumer/favorites/favorites_page.dart';
import 'package:consumer_app/apps/consumer/profile/my_reviews_page.dart';
import 'package:consumer_app/apps/consumer/profile/saved_cards_page.dart';
import 'package:consumer_app/apps/consumer/profile/notification_settings_page.dart';
import 'package:consumer_app/apps/consumer/profile/support_chat_page.dart';

class AccountBottomSheet extends ConsumerWidget {
  const AccountBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AccountBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);
    final isGuest = authState is! AuthAuthenticated;

    String displayName = "Kullanıcı Profilim";
    String phone = "";
    String firstLetter = "U";

    if (!isGuest) {
      final user = authState.user;
      displayName = user.displayName;
      phone = user.phone;
      final name = user.name ?? '';
      if (name.isNotEmpty) {
        firstLetter = name[0].toUpperCase();
      } else if (displayName.isNotEmpty) {
        firstLetter = displayName[0].toUpperCase();
      }
    }

    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle Bar
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
          const SizedBox(height: 16),

          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isGuest) ...[
                    // MİSAFİR KULLANICI GÖRÜNÜMÜ
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00A651), Color(0xFFFF6B00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.account_circle,
                            size: 60,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Hoppa Dünyasına Hoş Geldiniz! 👋",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            "Siparişlerinizi takip etmek, kuponlarınızı kullanmak ve fırsatlardan yararlanmak için giriş yapın.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF00A651),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Giriş Yap / Üye Ol",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // GİRİŞ YAPMIŞ KULLANICI GÖRÜNÜMÜ: Modern Premium Kart
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccountDetailsPage(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00A651), Color(0xFFFF6B00)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00A651).withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.grey.shade100,
                                child: Text(
                                  firstLetter,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00A651),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 17,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (phone.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      phone,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  const Divider(),
                  const SizedBox(height: 8),

                  // SEÇENEKLER LİSTESİ
                  _buildMenuTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: "Hoppa Cüzdanım",
                    subtitle: "Bakiye ve bakiye yükleme",
                    onTap: () {
                      Navigator.pop(context);
                      if (isGuest) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WalletPage(),
                          ),
                        );
                      }
                    },
                    theme: theme,
                  ),
                  _buildMenuTile(
                    icon: Icons.card_giftcard_outlined,
                    title: "Davet Et & Kazan!",
                    subtitle: "Arkadaşlarını davet et, ödül kazan",
                    onTap: () {
                      Navigator.pop(context);
                      if (isGuest) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ReferralPage(),
                          ),
                        );
                      }
                    },
                    theme: theme,
                  ),
                  _buildMenuTile(
                    icon: Icons.location_on_outlined,
                    title: "Kayıtlı Adreslerim",
                    subtitle: "Teslimat adreslerini yönet",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddressListPage(),
                        ),
                      );
                    },
                    theme: theme,
                  ),
                  _buildMenuTile(
                    icon: Icons.history,
                    title: "Sipariş Geçmişim",
                    subtitle: "Eski siparişlerini incele",
                    onTap: () {
                      Navigator.pop(context);
                      if (isGuest) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
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
                    theme: theme,
                  ),
                  _buildMenuTile(
                    icon: Icons.favorite_outline_rounded,
                    title: "Favorilerim",
                    subtitle: "Favori ürün ve dükkanların",
                    onTap: () {
                      Navigator.pop(context);
                      if (isGuest) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
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
                    theme: theme,
                  ),

                  if (!isGuest) ...[
                    _buildMenuTile(
                      icon: Icons.rate_review_outlined,
                      title: "Değerlendirmelerim",
                      subtitle: "Dükkan ve ürün yorumların",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyReviewsPage(),
                          ),
                        );
                      },
                      theme: theme,
                    ),
                    _buildMenuTile(
                      icon: Icons.payment_outlined,
                      title: "Kayıtlı Kartlarım",
                      subtitle: "Ödeme yöntemlerini düzenle",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SavedCardsPage(),
                          ),
                        );
                      },
                      theme: theme,
                    ),
                    _buildMenuTile(
                      icon: Icons.notifications_none_outlined,
                      title: "Bildirim Ayarları",
                      subtitle: "Hangi bildirimleri almak istersin?",
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const NotificationSettingsPage(),
                          ),
                        );
                      },
                      theme: theme,
                    ),
                  ],

                  _buildMenuTile(
                    icon: Icons.headset_mic_outlined,
                    title: "Canlı Destek",
                    subtitle: "Hoppa Müşteri Hizmetleri",
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SupportChatPage(),
                        ),
                      );
                    },
                    theme: theme,
                  ),

                  if (!isGuest) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await ref
                            .read(authControllerProvider.notifier)
                            .logout();
                      },
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text("Çıkış Yap"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.errorContainer,
                        foregroundColor: theme.colorScheme.onErrorContainer,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ],
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
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B00).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFFFF6B00), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

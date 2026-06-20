import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_auth/core_auth.dart';
import 'package:hoppa/apps/merchant/auth/merchant_login_page.dart';
import 'package:hoppa/apps/merchant/auth/merchant_revision_page.dart';
import 'package:hoppa/apps/merchant/merchant_main_layout.dart';

class MerchantAuthWrapper extends ConsumerWidget {
  const MerchantAuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (authState is AuthChecking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authState is AuthAuthenticated) {
      final user = authState.user;

      // GUARD: Merchant değilse (User tabanlı giriş yaptıysa) merchant app'e sokmayalım
      if (!user.isMerchant) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Bu alana sadece işletmeler giriş yapabilir."),
              backgroundColor: Colors.red,
            ),
          );
          ref.read(authControllerProvider.notifier).logout();
        });
        return const LoginPage();
      }

      // GUARD: Hesap durumu kontrolleri
      if (!user.isActive) {
        // Eğer statü REVISION ise Revizyon Sayfasına yönlendir
        if (user.isRevision) {
          return MerchantRevisionPage(user: user);
        }

        // Diğer durumlar için (PENDING, REJECTED, ON_HOLD) bilgilendirme göster ve login'de tut veya logla
        WidgetsBinding.instance.addPostFrameCallback((_) {
          String message = "Yetkisiz giriş denemesi.";
          Color bgColor = Colors.red;

          if (user.isPending) {
            message = "Başvurunuz inceleme aşamasındadır. Onaylandıktan sonra giriş yapabilirsiniz.";
            bgColor = Colors.orange.shade800;
          } else if (user.isOnHold) {
            message = "Başvurunuz şu anda detaylı inceleme için beklemeye alınmıştır.";
            bgColor = Colors.blue.shade800;
          } else if (user.isRejected) {
            message = "Başvurunuz reddedilmiştir. Sebep: ${user.revisionMessage ?? 'Belirtilmedi'}";
            bgColor = Colors.red.shade900;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: bgColor,
              duration: const Duration(seconds: 5),
            ),
          );
          // Reddedilmiş veya Beklemede olan kullanıcıyı aktif oturumda tutup sadece UI'da mesaj göstermek yerine
          // Gerekirse logout da yapılabilir, ancak genelde pending durumda olan kişi login kalabilir ve 
          // ara bir "Beklemede" ekranı görebilir. Şimdilik login'e atıp logout yapıyoruz eski mantıkta.
          ref.read(authControllerProvider.notifier).logout();
        });
        return const LoginPage();
      }

      // Aktifse (ACTIVE veya super_admin)
      return MerchantMainLayout(
        key: ValueKey('${user.id}_${user.businessId ?? "admin"}'),
        businessId: user.businessId ?? '',
      );
    }

    // Giriş yapılmamışsa veya hata varsa
    return const LoginPage();
  }
}


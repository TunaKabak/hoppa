import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:core_auth/core_auth.dart';
import 'package:consumer_app/apps/consumer/address/delivery_provider.dart';
import 'package:consumer_app/apps/consumer/auth/consumer_login_page.dart';
import 'package:consumer_app/apps/consumer/address/address_list_page.dart';
import 'package:consumer_app/apps/consumer/widgets/hoppa_dialog.dart';

class CartValidation {
  static bool checkLoginAndAddress(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authControllerProvider);
    if (authState is! AuthAuthenticated) {
      showDialog(
        context: context,
        builder: (context) => HoppaDialog(
          icon: Icons.lock_outline,
          iconColor: const Color(0xFFE95D22), // Hoppa Orange
          title: "Giriş Yapmalısınız",
          content: "Sepete ürün eklemek ve sipariş verebilmek için lütfen giriş yapın veya üye olun.",
          cancelText: "İptal",
          confirmText: "Giriş Yap",
          onCancel: () => Navigator.pop(context),
          onConfirm: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
        ),
      );
      return false;
    }

    final deliveryProvider = p.Provider.of<DeliveryProvider>(context, listen: false);
    if (!deliveryProvider.hasAddress) {
      showDialog(
        context: context,
        builder: (context) => HoppaDialog(
          icon: Icons.location_on_outlined,
          iconColor: const Color(0xFFE95D22), // Hoppa Orange
          title: "Adres Seçmelisiniz",
          content: "Siparişinizin size ulaşabilmesi için lütfen bir teslimat adresi seçin veya yeni bir adres ekleyin.",
          cancelText: "İptal",
          confirmText: "Adres Seç",
          onCancel: () => Navigator.pop(context),
          onConfirm: () async {
            Navigator.pop(context);
            final address = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AddressListPage(isSelectionMode: true),
              ),
            );
            if (address != null) {
              deliveryProvider.setAddress(address);
            }
          },
        ),
      );
      return false;
    }

    return true;
  }
}

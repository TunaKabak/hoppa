import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:core_auth/core_auth.dart';
import 'package:consumer_app/apps/consumer/address/delivery_provider.dart';
import 'package:consumer_app/apps/consumer/auth/consumer_login_page.dart';
import 'package:consumer_app/apps/consumer/address/address_list_page.dart';

class CartValidation {
  static bool checkLoginAndAddress(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authControllerProvider);
    if (authState is! AuthAuthenticated) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline, color: Color(0xFFE95D22)),
              SizedBox(width: 10),
              Text("Giriş Yapmalısınız"),
            ],
          ),
          content: const Text(
            "Sepete ürün eklemek ve sipariş verebilmek için lütfen giriş yapın veya üye olun.",
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A651),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
              child: const Text("Giriş Yap", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return false;
    }

    final deliveryProvider = p.Provider.of<DeliveryProvider>(context, listen: false);
    if (!deliveryProvider.hasAddress) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.location_on_outlined, color: Color(0xFFE95D22)),
              SizedBox(width: 10),
              Text("Adres Seçmelisiniz"),
            ],
          ),
          content: const Text(
            "Siparişinizin size ulaşabilmesi için lütfen bir teslimat adresi seçin veya yeni bir adres ekleyin.",
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("İptal", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A651),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
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
              child: const Text("Adres Seç", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return false;
    }

    return true;
  }
}

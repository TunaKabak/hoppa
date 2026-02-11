import 'package:flutter/material.dart';
import 'package:kktc_market/core/services/address_service.dart';
import 'package:kktc_market/models/address.dart';
import 'package:kktc_market/features/address/add_address_page.dart';

class AddressListPage extends StatelessWidget {
  final bool isSelectionMode;
  // YENİ: Seçim yapıldığında çalışacak fonksiyon (Opsiyonel)
  final Function(Address)? onAddressSelected;

  const AddressListPage({
    super.key,
    this.isSelectionMode = false,
    this.onAddressSelected,
  });

  @override
  Widget build(BuildContext context) {
    final addressService = AddressService();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Adreslerim",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Address>>(
              stream: addressService.getUserAddresses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());

                final addresses = snapshot.data ?? [];

                if (addresses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Kayıtlı adresiniz yok.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: addresses.length,
                  itemBuilder: (context, index) {
                    final address = addresses[index];
                    return Card(
                      elevation: 0,
                      color: theme.cardTheme.color,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: theme.dividerColor),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(
                          backgroundColor: theme.primaryColor.withOpacity(0.1),
                          child: Icon(
                            _getIconForTitle(address.title),
                            color: theme.primaryColor,
                          ),
                        ),
                        title: Text(
                          address.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "${address.city}, ${address.district}\n${address.fullDetails}",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                        trailing: isSelectionMode
                            ? const Icon(
                                Icons.check_circle_outline,
                                color: Colors.grey,
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => AddAddressPage(
                                            addressToEdit: address,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _showDeleteConfirmation(
                                      context,
                                      addressService,
                                      address.id,
                                    ),
                                  ),
                                ],
                              ),
                        onTap: () {
                          if (isSelectionMode) {
                            if (onAddressSelected != null) {
                              onAddressSelected!(address);
                            } else {
                              Navigator.pop(context, address);
                            }
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // SABİT ALT BUTON
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddAddressPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text(
                    "Yeni Adres Ekle",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    AddressService service,
    String id,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Adresi Sil"),
        content: const Text("Bu adresi silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              service.deleteAddress(id);
              Navigator.pop(ctx);
            },
            child: const Text(
              "Sil",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    if (title.toLowerCase().contains('ev')) return Icons.home;
    if (title.toLowerCase().contains('iş')) return Icons.work;
    if (title.toLowerCase().contains('yurt')) return Icons.school;
    return Icons.location_on;
  }
}

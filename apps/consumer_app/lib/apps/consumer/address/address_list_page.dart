import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:consumer_app/apps/consumer/repositories/address_repository.dart';
import 'package:core_shared/shared/models/address.dart';
import 'package:consumer_app/apps/consumer/address/add_address_page.dart';
import 'package:provider/provider.dart' as p;
import 'package:consumer_app/apps/consumer/address/delivery_provider.dart';
import 'package:core_auth/core_auth.dart';
import 'package:consumer_app/apps/consumer/widgets/hoppa_header.dart';

class AddressListPage extends ConsumerWidget {
  final bool isSelectionMode;
  final Function(Address)? onAddressSelected;

  const AddressListPage({
    super.key,
    this.isSelectionMode = false,
    this.onAddressSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deliveryProvider = p.Provider.of<DeliveryProvider>(context, listen: true);
    final selectedAddress = deliveryProvider.selectedAddress;

    final authState = ref.watch(authControllerProvider);
    final bool isGuest = authState is! AuthAuthenticated;

    final addressesToShow = <Address>[];
    if (isGuest && selectedAddress != null) {
      addressesToShow.add(selectedAddress);
    }

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
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(right: 48.0),
                        child: Text(
                          "Adreslerim",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
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
                  child: Column(
                    children: [
                      Expanded(
                        child: isGuest
                            ? _buildListContent(context, ref, addressesToShow, selectedAddress, isGuest, deliveryProvider, theme)
                            : ref.watch(addressesProvider).when(
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (err, stack) => Center(
                                  child: Text(
                                    "Hatalar yüklenemedi: $err",
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                                data: (addresses) => _buildListContent(context, ref, addresses, selectedAddress, isGuest, deliveryProvider, theme),
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
                              onPressed: () async {
                                final newAddress = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AddAddressPage(),
                                  ),
                                );
                                if (newAddress != null) {
                                  if (isGuest) {
                                    await deliveryProvider.setAddress(newAddress as Address);
                                  } else {
                                    ref.invalidate(addressesProvider);
                                  }
                                }
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListContent(
    BuildContext context,
    WidgetRef ref,
    List<Address> addresses,
    Address? selectedAddress,
    bool isGuest,
    DeliveryProvider deliveryProvider,
    ThemeData theme,
  ) {
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
        final isSelected = selectedAddress?.id == address.id;
        return Card(
          elevation: isSelected ? 2 : 0,
          shadowColor: isSelected ? theme.primaryColor.withOpacity(0.1) : Colors.transparent,
          color: isSelected
              ? theme.primaryColor.withOpacity(0.12)
              : theme.cardTheme.color,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? theme.primaryColor : (theme.dividerColor ?? Colors.grey.shade200),
              width: isSelected ? 2.5 : 1.0,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: isSelected
                  ? theme.primaryColor.withOpacity(0.2)
                  : theme.primaryColor.withOpacity(0.1),
              child: Icon(
                _getIconForTitle(address.title),
                color: theme.primaryColor,
              ),
            ),
            title: Text(
              address.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected ? theme.primaryColor : null,
              ),
            ),
            subtitle: Text(
              "${address.city}, ${address.district}\n${address.fullDetails}",
              style: TextStyle(
                color: isSelected ? Colors.grey.shade800 : Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
            trailing: isSelectionMode
                ? Icon(
                    isSelected ? Icons.check_circle_rounded : Icons.check_circle_outline,
                    color: isSelected ? theme.primaryColor : Colors.grey,
                    size: 26,
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: Icon(Icons.check_circle_rounded, color: theme.primaryColor, size: 24),
                        ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                        ),
                        onPressed: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddAddressPage(
                                addressToEdit: address,
                              ),
                            ),
                          );
                          if (updated != null) {
                            if (isGuest) {
                              await deliveryProvider.setAddress(updated as Address);
                            } else {
                              ref.invalidate(addressesProvider);
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          if (isGuest) {
                            _showGuestDeleteConfirmation(context, deliveryProvider);
                          } else {
                            _showDeleteConfirmation(context, ref, address.id);
                          }
                        },
                      ),
                    ],
                  ),
            onTap: () async {
              if (isSelectionMode) {
                if (onAddressSelected != null) {
                  onAddressSelected!(address);
                } else {
                  Navigator.pop(context, address);
                }
              } else {
                await deliveryProvider.setAddress(address);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Varsayılan teslimat adresi güncellendi.")),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
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
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(addressRepositoryProvider).deleteAddress(id);
                ref.invalidate(addressesProvider);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Adres başarıyla silindi.")),
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
            child: const Text(
              "Sil",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showGuestDeleteConfirmation(BuildContext context, DeliveryProvider deliveryProvider) {
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
            onPressed: () async {
              Navigator.pop(ctx);
              await deliveryProvider.clearAddress();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Adres başarıyla silindi.")),
                );
              }
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


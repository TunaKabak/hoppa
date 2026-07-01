import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hoppa/shared/models/business_category.dart';
import 'providers/super_admin_providers.dart';

class AdminBusinessCategoriesPage extends ConsumerStatefulWidget {
  const AdminBusinessCategoriesPage({super.key});

  @override
  ConsumerState<AdminBusinessCategoriesPage> createState() =>
      _AdminBusinessCategoriesPageState();
}

class _AdminBusinessCategoriesPageState
    extends ConsumerState<AdminBusinessCategoriesPage> {
  bool _isLoading = false;

  final List<String> _availableIcons = [
    'shopping_basket',
    'restaurant',
    'water_drop',
    'grain',
    'coffee',
    'local_florist',
    'store'
  ];

  final Map<String, IconData> _iconMapping = {
    'shopping_basket': Icons.shopping_basket,
    'restaurant': Icons.restaurant,
    'water_drop': Icons.water_drop,
    'grain': Icons.grain,
    'coffee': Icons.coffee,
    'local_florist': Icons.local_florist,
    'store': Icons.store,
  };

  final List<Map<String, String>> _presetColors = [
    {'name': 'Yeşil', 'hex': '#00A651'},
    {'name': 'Turuncu', 'hex': '#FF6B00'},
    {'name': 'Mavi', 'hex': '#2196F3'},
    {'name': 'Kahverengi', 'hex': '#795548'},
    {'name': 'Koyu Kahve', 'hex': '#4E342E'},
    {'name': 'Pembe', 'hex': '#E91E63'},
  ];

  Color _parseColor(String hexColor) {
    try {
      if (hexColor.startsWith('#')) {
        hexColor = hexColor.substring(1);
      }
      if (hexColor.length == 6) {
        hexColor = 'FF$hexColor';
      }
      return Color(int.parse(hexColor, radix: 16));
    } catch (_) {
      return Colors.green;
    }
  }

  Future<void> _handleAction(
      Future<void> Function() action, String successMessage) async {
    setState(() => _isLoading = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: const Color(0xFF00A651),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showCategoryDialog([BusinessCategory? category]) {
    final isEdit = category != null;
    final nameController = TextEditingController(text: category?.name ?? '');
    final subtitleController =
        TextEditingController(text: category?.subtitle ?? '');
    final deliveryController =
        TextEditingController(text: category?.avgDeliveryTime ?? '');
    final badgeController = TextEditingController(text: category?.badge ?? '');
    final orderController =
        TextEditingController(text: (category?.order ?? 0).toString());
    
    String selectedIcon = category?.icon ?? _availableIcons.first;
    String selectedColorHex = category?.color ?? _presetColors.first['hex']!;
    bool isActive = category?.isActive ?? true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(
                isEdit ? "Kategoriyi Düzenle" : "Yeni Kategori Ekle",
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Kategori Adı (Örn: Market)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: subtitleController,
                        decoration: const InputDecoration(
                          labelText: "Alt Başlık (Örn: Market alışverişi)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: deliveryController,
                              decoration: const InputDecoration(
                                labelText: "Ort. Teslimat Süresi (Örn: 20-30 dk)",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: badgeController,
                              decoration: const InputDecoration(
                                labelText: "Rozet (Örn: popular, new)",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: orderController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "Sıralama (Order)",
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            children: [
                              const Text("Aktif: "),
                              Switch(
                                value: isActive,
                                activeColor: const Color(0xFF00A651),
                                onChanged: (val) {
                                  setDialogState(() => isActive = val);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedIcon,
                        decoration: const InputDecoration(
                          labelText: "İkon Seçin",
                          border: OutlineInputBorder(),
                        ),
                        items: _availableIcons.map((iconName) {
                          return DropdownMenuItem<String>(
                            value: iconName,
                            child: Row(
                              children: [
                                Icon(_iconMapping[iconName] ?? Icons.store,
                                    color: Colors.grey.shade700),
                                const SizedBox(width: 10),
                                Text(iconName),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedIcon = val);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _presetColors.any(
                                (c) => c['hex'] == selectedColorHex)
                            ? selectedColorHex
                            : null,
                        decoration: const InputDecoration(
                          labelText: "Renk Seçin",
                          border: OutlineInputBorder(),
                        ),
                        items: _presetColors.map((colorItem) {
                          final colorVal = _parseColor(colorItem['hex']!);
                          return DropdownMenuItem<String>(
                            value: colorItem['hex'],
                            child: Row(
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: colorVal,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(colorItem['name']!),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedColorHex = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("İptal"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A651),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Kategori adı boş olamaz.")),
                      );
                      return;
                    }
                    Navigator.pop(ctx);

                    final tempCategory = BusinessCategory(
                      id: category?.id ?? '',
                      name: name,
                      icon: selectedIcon,
                      color: selectedColorHex,
                      badge: badgeController.text.trim().isEmpty
                          ? null
                          : badgeController.text.trim(),
                      avgDeliveryTime: deliveryController.text.trim().isEmpty
                          ? null
                          : deliveryController.text.trim(),
                      subtitle: subtitleController.text.trim().isEmpty
                          ? null
                          : subtitleController.text.trim(),
                      isActive: isActive,
                      order: int.tryParse(orderController.text) ?? 0,
                    );

                    if (isEdit) {
                      _handleAction(
                        () => ref
                            .read(adminBusinessCategoriesProvider.notifier)
                            .updateCategory(tempCategory),
                        "Kategori başarıyla güncellendi.",
                      );
                    } else {
                      _handleAction(
                        () => ref
                            .read(adminBusinessCategoriesProvider.notifier)
                            .createCategory(tempCategory),
                        "Kategori başarıyla eklendi.",
                      );
                    }
                  },
                  child: Text(
                    isEdit ? "Güncelle" : "Ekle",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Kategoriyi Sil",
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(
            "'$name' kategorisini silmek istediğinize emin misiniz? Bu işlem geri alınamaz."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _handleAction(
                () => ref
                    .read(adminBusinessCategoriesProvider.notifier)
                    .deleteCategory(id),
                "Kategori başarıyla silindi.",
              );
            },
            child: const Text("Sil", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(adminBusinessCategoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: Text(
          "Dükkan Kategorileri Yönetimi",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline,
                color: Color(0xFF00A651), size: 28),
            onPressed: () => _showCategoryDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : categoriesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text("Hata oluştu: $err",
                    style: const TextStyle(color: Colors.red)),
              ),
              data: (categories) {
                if (categories.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.category_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          "Henüz hiç kategori tanımlanmamış.",
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A651)),
                          onPressed: () => _showCategoryDialog(),
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text("İlk Kategoriyi Ekle",
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final catColor = _parseColor(cat.color);
                    final iconData = _iconMapping[cat.icon] ?? Icons.store;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: catColor.withOpacity(0.1),
                          child: Icon(iconData, color: catColor),
                        ),
                        title: Row(
                          children: [
                            Text(
                              cat.name,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold),
                            ),
                            if (cat.badge != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  cat.badge!.toUpperCase(),
                                  style: TextStyle(
                                      color: Colors.red.shade800,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            const Spacer(),
                            Text(
                              "Sıra: ${cat.order}",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(cat.subtitle ?? "Alt başlık yok"),
                            Row(
                              children: [
                                if (cat.avgDeliveryTime != null) ...[
                                  const Icon(Icons.access_time,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(cat.avgDeliveryTime!,
                                      style:
                                          const TextStyle(color: Colors.grey)),
                                  const SizedBox(width: 16),
                                ],
                                Icon(
                                  cat.isActive
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 14,
                                  color: cat.isActive
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  cat.isActive ? "Aktif" : "Pasif",
                                  style: TextStyle(
                                      color: cat.isActive
                                          ? Colors.green
                                          : Colors.red),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showCategoryDialog(cat),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(cat.id, cat.name),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

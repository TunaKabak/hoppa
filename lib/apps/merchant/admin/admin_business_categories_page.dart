import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hoppa/shared/models/business_category.dart';
import 'package:hoppa/apps/merchant/merchant_main_layout.dart';
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
  List<BusinessCategory> _localCategories = [];
  bool _isOrderDirty = false;

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
    
    // Check if the saved icon is a URL (starts with http) or a preset
    final isIconUrl = category != null && (category.icon.startsWith('http') || category.icon.contains('/'));
    final iconUrlController =
        TextEditingController(text: isIconUrl ? category.icon : '');

    String selectedIcon = isIconUrl ? _availableIcons.first : (category?.icon ?? _availableIcons.first);
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
                          labelText: "Kategori Adı (Örn: Kasap)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: subtitleController,
                        decoration: const InputDecoration(
                          labelText: "Alt Başlık (Örn: Taze et ürünleri)",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: iconUrlController,
                        decoration: const InputDecoration(
                          labelText: "İkon / Resim URL (İsteğe bağlı)",
                          border: OutlineInputBorder(),
                          hintText: "http://... veya aşağıdaki ikonlardan seçin",
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedIcon,
                        decoration: const InputDecoration(
                          labelText: "Varsayılan İkon Seçin",
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
                          labelText: "Kart Rengi Seçin",
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
                      const SizedBox(height: 12),
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

                    final iconVal = iconUrlController.text.trim().isNotEmpty
                        ? iconUrlController.text.trim()
                        : selectedIcon;

                    final tempCategory = BusinessCategory(
                      id: category?.id ?? '',
                      name: name,
                      icon: iconVal,
                      color: selectedColorHex,
                      badge: category?.badge,
                      avgDeliveryTime: category?.avgDeliveryTime,
                      subtitle: subtitleController.text.trim().isEmpty
                          ? null
                          : subtitleController.text.trim(),
                      isActive: isActive,
                      order: category?.order ?? 0,
                    );

                    setState(() {
                      _localCategories.clear();
                      _isOrderDirty = false;
                    });

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
              setState(() {
                _localCategories.clear();
                _isOrderDirty = false;
              });
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
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            ref.read(merchantNavigationIndexProvider.notifier).setIndex(0);
          },
        ),
        title: Text(
          "İşletme Kategori Yönetimi",
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isOrderDirty)
            TextButton.icon(
              onPressed: () {
                _handleAction(() async {
                  final List<Map<String, dynamic>> orders = [];
                  for (int i = 0; i < _localCategories.length; i++) {
                    orders.add({
                      'id': _localCategories[i].id,
                      'order': i,
                    });
                  }
                  await ref
                      .read(adminBusinessCategoriesProvider.notifier)
                      .reorderCategories(orders);
                  setState(() {
                    _isOrderDirty = false;
                    _localCategories.clear();
                  });
                }, "Sıralama başarıyla kaydedildi.");
              },
              icon: const Icon(Icons.save, color: Color(0xFF00A651)),
              label: const Text(
                "Kaydet",
                style: TextStyle(
                    color: Color(0xFF00A651), fontWeight: FontWeight.bold),
              ),
            ),
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

                // Initialize local list for dragging if empty
                if (_localCategories.isEmpty && !_isOrderDirty) {
                  _localCategories = List.from(categories);
                }

                return ReorderableListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _localCategories.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _localCategories.removeAt(oldIndex);
                      _localCategories.insert(newIndex, item);
                      _isOrderDirty = true;
                    });
                  },
                  itemBuilder: (context, index) {
                    final cat = _localCategories[index];
                    final catColor = _parseColor(cat.color);
                    
                    // Check if icon is custom network image or material icon name
                    final bool hasImage = cat.icon.startsWith('http') || cat.icon.contains('/');
                    final iconData = _iconMapping[cat.icon] ?? Icons.store;

                    return Card(
                      key: ValueKey(cat.id),
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: catColor.withOpacity(0.1),
                          backgroundImage: hasImage ? NetworkImage(cat.icon) : null,
                          child: hasImage ? null : Icon(iconData, color: catColor),
                        ),
                        title: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              cat.name,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            if (cat.badge != null)
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
                            if (cat.shopCount != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "${cat.shopCount} İşletme",
                                  style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat.subtitle ?? "Alt başlık yok",
                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  if (cat.avgDeliveryTime != null) ...[
                                    const Icon(Icons.access_time,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(cat.avgDeliveryTime!,
                                        style:
                                            const TextStyle(color: Colors.grey, fontSize: 12)),
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
                                            : Colors.red,
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ],
                          ),
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
                              onPressed: () {
                                final count = cat.shopCount ?? 0;
                                if (count > 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Bu kategori silinemez! Bağlı $count adet işletme bulunmaktadır."
                                      ),
                                      backgroundColor: Colors.orange.shade800,
                                    ),
                                  );
                                } else {
                                  _confirmDelete(cat.id, cat.name);
                                }
                              },
                            ),
                            const Icon(Icons.drag_handle, color: Colors.grey),
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

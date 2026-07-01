import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hoppa/shared/models/category_model.dart';
import 'package:hoppa/apps/consumer/repositories/consumer_shop_repository.dart';

class HierarchicalCategoryDrawer extends ConsumerWidget {
  final String shopId;

  const HierarchicalCategoryDrawer({
    super.key,
    required this.shopId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(shopCategoryTreeProvider(shopId));
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.category_rounded, color: theme.primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    "Kategoriler",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text("Hata: $err")),
                data: (tree) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      ListTile(
                        leading: Icon(Icons.grid_view_rounded, color: theme.primaryColor),
                        title: const Text(
                          "Tüm Ürünler",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          ref.read(selectedCatalogCategoryProvider.notifier).state = 'Tümü';
                          ref.read(selectedCatalogSubCategoryProvider.notifier).state = 'Tümü';
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(),
                      ...tree.map((cat) => _buildCategoryNode(context, ref, cat, cat.name)),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryNode(
    BuildContext context,
    WidgetRef ref,
    Category category,
    String rootCategoryName,
  ) {
    if (category.children.isEmpty) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        title: Text(
          category.name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        onTap: () {
          ref.read(selectedCatalogCategoryProvider.notifier).state = rootCategoryName;
          ref.read(selectedCatalogSubCategoryProvider.notifier).state = category.name;
          Navigator.pop(context);
        },
      );
    }

    return ExpansionTile(
      title: Text(
        category.name,
        style: TextStyle(
          fontSize: category.parentId == null ? 15 : 14,
          fontWeight: category.parentId == null ? FontWeight.bold : FontWeight.w600,
        ),
      ),
      leading: category.parentId == null
          ? _getCategoryIcon(category.iconName)
          : null,
      childrenPadding: const EdgeInsets.only(left: 16.0),
      children: [
        ListTile(
          title: Text(
            "Tüm ${category.name}",
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          onTap: () {
            ref.read(selectedCatalogCategoryProvider.notifier).state = rootCategoryName;
            ref.read(selectedCatalogSubCategoryProvider.notifier).state =
                category.parentId == null ? 'Tümü' : category.name;
            Navigator.pop(context);
          },
        ),
        ...category.children.map((child) => _buildCategoryNode(
              context,
              ref,
              child,
              rootCategoryName,
            )),
      ],
    );
  }

  Widget _getCategoryIcon(String iconName) {
    IconData iconData;
    switch (iconName.toLowerCase()) {
      case 'water_drop':
      case 'beverage':
        iconData = Icons.water_drop_outlined;
        break;
      case 'apple':
      case 'fruit':
        iconData = Icons.apple_outlined;
        break;
      case 'cookie':
      case 'snack':
        iconData = Icons.cookie_outlined;
        break;
      case 'breakfast_dining':
      case 'bakery':
        iconData = Icons.breakfast_dining_outlined;
        break;
      case 'rice_bowl':
      case 'food':
        iconData = Icons.rice_bowl_outlined;
        break;
      case 'egg_alt':
      case 'dairy':
        iconData = Icons.egg_alt_outlined;
        break;
      case 'cleaning_services':
      case 'cleaning':
        iconData = Icons.cleaning_services_outlined;
        break;
      case 'local_florist':
      case 'flower':
        iconData = Icons.local_florist_outlined;
        break;
      default:
        iconData = Icons.shopping_basket_outlined;
    }
    return Icon(iconData, color: Colors.blueGrey);
  }
}

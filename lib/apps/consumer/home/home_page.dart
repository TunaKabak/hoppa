import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as p;
import 'package:hoppa/apps/consumer/business/business_provider.dart';
import 'package:hoppa/apps/consumer/business/business_selection_page.dart';
import 'package:hoppa/apps/consumer/business/selection_category_page.dart';
import 'package:hoppa/apps/consumer/business/shop_detail_page.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with AutomaticKeepAliveClientMixin<HomePage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final businessProvider = p.Provider.of<BusinessProvider>(context);

    // 1. KATEGORİ SEÇİLMEDİYSE -> KATEGORİ SAYFASI
    if (businessProvider.selectedCategory == null) {
      return const SelectionCategoryPage();
    }

    // 2. İŞLETME SEÇİLMEDİYSE -> İŞLETME LİSTESİ (KATEGORİYE GÖRE)
    if (businessProvider.selectedBusiness == null) {
      return BusinessSelectionPage(category: businessProvider.selectedCategory);
    }

    // 3. İŞLETME SEÇİLDİYSE -> DÜKKAN DETAY SAYFASI
    final selectedBusiness = businessProvider.selectedBusiness!;
    return ModernShopDetailPage(shop: selectedBusiness);
  }
}

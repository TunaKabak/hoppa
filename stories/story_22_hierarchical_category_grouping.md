🚀 Story 22: Hiyerarşik Kategori Gruplama ve Katmanlı UI Entegrasyonu

🎯 1. KULLANICI HİKAYESİ (USER STORY)

"Bir tüketici ve satıcı olarak; dükkan içindeki yüzlerce kategoriyi tek bir düz liste halinde görmek yerine, ana kategorileri ve onların altındaki kırılımları (Örn: Süt, Kahvaltılık -> Peynir -> Beyaz Peynir) gruplanmış, genişletilebilir ve düzenli bir yapıda görmek istiyorum."

⚙️ 2. BACKEND KATMANI: ÖZ-YİNELEMELİ (RECURSIVE) KATEGORİ AĞACI API'Sİ

Kategorileri düz listelemek yerine, her ana kategorinin altındaki çocuk kategorileri (children) hiyerarşik bir ağaç yapısı olarak istemciye tek seferde dönen akıllı Express endpoint'i tasarlayacağız.

A. Endpoint Güncellemesi (ConsumerShopController.ts / getShopActiveCategories)

// backend/src/controllers/ConsumerShopController.ts

export const getShopActiveCategoriesTree = async (req: Request, res: Response) => {
  try {
    const { shopId } = req.params;

    // 🚨 HIYERARŞİK SQL SORGUSU (Prisma):
    // 1. Sadece bu dükkanda aktif ürünü olan kategorileri bul.
    // 2. parentId'si null olan (Ana Kategoriler) kökleri çek ve children ilişkisini recursive include et.
    const activeCategoriesWithProducts = await prisma.category.findMany({
      where: {
        products: { some: { shopId: shopId } }
      },
      select: { id: true }
    });

    const activeCategoryIds = activeCategoriesWithProducts.map(c => c.id);

    // Kök kategorileri çekip sadece aktif çocukları içerecek şekilde ağacı oluşturuyoruz
    const categoryTree = await prisma.category.findMany({
      where: {
        parentId: null, // Sadece en üst seviye (Root) kategoriler
        shopType: "MARKET" // İlgili dükkan tipine göre (Örn: MARKET, RESTAURANT)
      },
      include: {
        children: {
          include: {
            children: true // Gerekirse 3. seviye derinlik (Süt, Kahvaltılık -> Peynir -> Beyaz Peynir)
          }
        }
      }
    });

    // Filtreleme: Sadece içinde aktif ürün olan veya alt kırılımlarında aktif ürün barındıran dalları tut
    const filteredTree = categoryTree.filter(node => {
      return hasActiveProductInBranch(node, activeCategoryIds);
    });

    return res.status(200).json({ error: false, data: filteredTree });
  } catch (error) {
    console.error("Hiyerarşik kategori ağacı hatası:", error);
    return res.status(500).json({ error: true, message: "Kategori ağacı oluşturulurken hata oluştu." });
  }
};

// Yardımcı fonksiyon: Ağacın bu dalında veya alt kollarında aktif ürün var mı?
function hasActiveProductInBranch(node: any, activeIds: string[]): boolean {
  if (activeIds.includes(node.id)) return true;
  if (node.children && node.children.length > 0) {
    return node.children.some((child: any) => hasActiveProductInBranch(child, activeIds));
  }
  return false;
}


📱 3. TÜKETİCİ UYGULAMASI (CONSUMER APP) GRUPLAMA UI

Tüketici dükkan detayına girdiğinde, kategoriler arasında boğulmamalıdır. Sol tarafta ana kategoriler listelenirken, bunlara tıklandığında alt kategoriler şık bir akordeon veya genişleyen liste (ExpansionTile) olarak açılmalıdır.

A. Tüketici Kategori Filtre Çekmecesi (Drawer/Expansion List)

// apps/consumer_app/lib/screens/shop/widgets/hierarchical_category_list.dart

import 'package:flutter/material.dart';

class HierarchicalCategoryList extends StatelessWidget {
  final List<Category> categories; // Backend'den gelen ağaç yapısı
  final Function(Category selectedCategory) onCategorySelected;

  const HierarchicalCategoryList({
    Key? key,
    required this.categories,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final rootCategory = categories[index];

        // Eğer alt kategorisi yoksa düz ListTile olarak çiz
        if (rootCategory.children.isEmpty) {
          return ListTile(
            leading: _buildCategoryIcon(rootCategory.imageUrl),
            title: Text(rootCategory.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            onTap: () => onCategorySelected(rootCategory),
          );
        }

        // Alt kategorisi varsa Genişleyebilir ExpansionTile olarak çiz (Grup Yapısı)
        return ExpansionTile(
          leading: _buildCategoryIcon(rootCategory.imageUrl),
          title: Text(
            rootCategory.name, 
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          childrenPadding: const EdgeInsets.only(left: 16.0),
          shape: const Border(), // Sınır çizgilerini kaldır temiz dursun
          children: rootCategory.children.map((subCategory) {
            return ListTile(
              title: Text(subCategory.name),
              trailing: const Icon(Icons.chevron_right, size: 16),
              onTap: () => onCategorySelected(subCategory),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCategoryIcon(String? url) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.transparent,
      child: url != null 
          ? Image.network(url, errorBuilder: (_, __, ___) => const Icon(Icons.category_outlined))
          : const Icon(Icons.category_outlined),
    );
  }
}


📱 4. SATICI UYGULAMASI (MERCHANT APP) CASCADING DROPDOWN UI

Satıcı dükkanına yeni bir ürün eklerken (Örn: Sma Bebek Maması), 1000+ kategorilik düz bir listeden aramak yerine, kademeli (cascading) bir seçim yapacaktır.

Önce "Ana Kategori" seçer (Örn: Bebek).

"Bebek" seçildiği an, ikinci dropdown dinamik olarak güncellenir ve sadece onun alt kategorilerini listeler (Örn: Bebek Beslenme).

"Bebek Beslenme" seçilince üçüncü dropdown açılır ve yaprak kategoriyi listeler (Örn: Bebek Maması).

// apps/merchant_app/lib/screens/product/widgets/cascading_category_selector.dart

class CascadingCategorySelector extends StatefulWidget {
  final List<Category> categoryTree; // Tüm hiyerarşik ağaç
  final Function(String finalCategoryId) onCategorySelected;

  const CascadingCategorySelector({
    Key? key,
    required this.categoryTree,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  State<CascadingCategorySelector> createState() => _CascadingCategorySelectorState();
}

class _CascadingCategorySelectorState extends State<CascadingCategorySelector> {
  Category? _selectedRoot;
  Category? _selectedSub;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Kademe: Ana Kategori Seçimi
        DropdownButtonFormField<Category>(
          value: _selectedRoot,
          decoration: const InputDecoration(labelText: "Ana Kategori", border: OutlineInputBorder()),
          items: widget.categoryTree.map((cat) {
            return DropdownMenuItem(value: cat, child: Text(cat.name));
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedRoot = val;
              _selectedSub = null; // Çocuk seçimi sıfırla
            });
          },
        ),
        const SizedBox(height: 12),

        // 2. Kademe: Alt Kategori Seçimi (Sadece ana kategori seçiliyse ve çocukları varsa görünür)
        if (_selectedRoot != null && _selectedRoot!.children.isNotEmpty)
          DropdownButtonFormField<Category>(
            value: _selectedSub,
            decoration: const InputDecoration(labelText: "Alt Kategori", border: OutlineInputBorder()),
            items: _selectedRoot!.children.map((cat) {
              return DropdownMenuItem(value: cat, child: Text(cat.name));
            }).toList(),
            onChanged: (val) {
              setState(() {
                _selectedSub = val;
              });
              // En alt yaprak seçildi, üst bileşene bildir
              widget.onCategorySelected(val!.id);
            },
          ),
      ],
    );
  }
}


📢 5. DOĞRULAMA VE AGENT TALİMATI

Backend Ağaç Yapısı Doğrulaması:
cd backend && npx tsc --noEmit çalıştırarak recursive sorguların TypeScript tipleriyle uyumlu olduğunu teyit et.

Flutter Statik Analizleri:
Hem consumer_app hem de merchant_app klasörlerinde flutter analyze çalıştırarak hiyerarşik ExpansionTile ve Cascading Dropdown yapısının sorunsuz çalıştığını onayla.
Story 19 - Master Ürün Kataloğu (1000+ Hazır Ürün) ve Satıcı Birim Yönetim Paneli

Bu görev belgesi; satıcıların ürün ekleme yükünü sıfıra indirmek için 1000+ hazır görsel ve veriye sahip bir "Global Ürün Kütüphanesi" (Master Catalog) kurmayı, barkod tarama API'si entegrasyonunu ve satıcı panelinde ürünlerin birim (KG/Litre) ve artış adımlarının (stepSize) dinamik olarak yönetilebilmesini amaçlar.

🧭 1. BÖLÜM: 1000+ Ürünlük Global Kataloğun Kurulması (Mimarisi & Veri Kaynağı)

Satıcıların ürün girmekle uğraşmaması için arkada bir Global Ürün Kütüphanesi oluşturacağız. Satıcı panelinde ürünü aratıp veya barkodunu okutup tek tıkla fiyat ve stok girerek dükkanına ekleyebilecek.

A. Veri Kaynağı (Nereden Bulacağız?)

Open Food Facts API (Ücretsiz ve Açık Veri):
Dünya genelinde 4 milyondan fazla, Türkiye ve KKTC'de ise 100.000'den fazla barkodlu süpermarket ürününün (cips, bisküvi, süt, şampuan vb.) isim, marka, kategori ve yüksek çözünürlüklü beyaz arka planlı fotoğrafları ücretsiz API olarak sunulmaktadır.

API Sorgu Örneği: GET https://world.openfoodfacts.org/api/v2/product/{barcode}.json

Kaggle Türk Süpermarket Veri Seti (Seed Data):
Eldeki 9.000+ kalemlik hazır Türkçe süpermarket veri setini (isim, kategori, ortalama fiyatlar) kullanarak veritabanımızı başlangıçta 1000+ popüler ürünle programmatic (Node.js seed script) olarak dolduracağız.

B. Veritabanı Şeması (Master Catalog Database)

GlobalProduct adında bağımsız bir kütüphane tablosu oluşturuyoruz. Satıcı bir ürünü dükkanına eklemek istediğinde bu tablodan kopyalayacak (veya referans alacak):

// backend/prisma/schema.prisma

model GlobalProduct {
  id          String   @id @default(uuid())
  barcode     String?  @unique // Ürünün barkodu (Barkod okutunca anında eşleşmesi için)
  name        String
  category    String   // Meyve-Sebze, Atıştırmalık, Temizlik vb.
  imageUrl    String   // Profesyonel beyaz arka planlı stüdyo fotoğrafı URL'si
  unit        String   @default("ADET") // KG, LITRE, ADET, PAKET
  minQuantity Float    @default(1.0)
  stepSize    Float    @default(1.0)
  createdAt   DateTime @default(now())
}


🥦 2. BÖLÜM: Satıcı Uygulaması (Merchant App) Dinamik Birim ve Limit Arayüzü

Satıcının patatesi eklerken "ADET" yerine "KG" yapabilmesi ve minimum artış adımlarını (Örn: 0.25 kg) belirleyebilmesi için ürün yönetim ekranını dinamik yapıyoruz.

A. Ürün Ekleme / Düzenleme Formu UI Tasarımı

Satıcı panelindeki ürün formuna (add_product_page.dart) şu dinamik alanları ekliyoruz:

// apps/merchant_app/lib/screens/product/edit_product_page.dart

class EditProductUnitSection extends StatefulWidget {
  final Product? product; // Düzenleme modu için mevcut ürün
  const EditProductUnitSection({Key? key, this.product}) : super(key: key);

  @override
  State<EditProductUnitSection> createState() => _EditProductUnitSectionState();
}

class _EditProductUnitSectionState extends State<EditProductUnitSection> {
  String _selectedUnit = "ADET"; // Varsayılan birim
  double _minQuantity = 1.0;
  double _stepSize = 1.0;

  final List<String> _units = ["ADET", "KG", "LITRE", "PAKET", "DEMET", "GR"];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _selectedUnit = widget.product!.unit;
      _minQuantity = widget.product!.minQuantity;
      _stepSize = widget.product!.stepSize;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Miktar ve Satış Birimi Ayarları",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 1. Birim Seçici Dropdown
            DropdownButtonFormField<String>(
              value: _selectedUnit,
              decoration: const InputDecoration(
                labelText: "Satış Birimi",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.scale_outlined),
              ),
              items: _units.map((unit) {
                return DropdownMenuItem(value: unit, child: Text(unit));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedUnit = val!;
                  // Birim değiştiğinde mantıklı varsayılanlar ata
                  if (_selectedUnit == "KG") {
                    _minQuantity = 0.5;
                    _stepSize = 0.25;
                  } else if (_selectedUnit == "ADET") {
                    _minQuantity = 1.0;
                    _stepSize = 1.0;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // Eğer tartılı/küsuratlı ürün seçildiyse (KG/Litre) ek ayarları göster
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  // 2. Minimum Alım Miktarı Slider / Input
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Minimum Sipariş Miktarı:",
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(
                        label: Text("$_minQuantity $_selectedUnit"),
                        backgroundColor: theme.colorScheme.primaryContainer,
                      ),
                    ],
                  ),
                  Slider(
                    value: _minQuantity,
                    min: 0.1,
                    max: 5.0,
                    divisions: 49,
                    label: _minQuantity.toString(),
                    onChanged: (val) {
                      setState(() {
                        // Yuvarlama hassasiyeti koruma (stepSize'a uyumlu olması için)
                        _minQuantity = double.parse(val.toStringAsFixed(2));
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // 3. Artış Adımı (Step Size)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Miktar Artış Adımı (Step):",
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Chip(
                        label: Text("+$_stepSize $_selectedUnit"),
                        backgroundColor: theme.colorScheme.secondaryContainer,
                      ),
                    ],
                  ),
                  DropdownButtonFormField<double>(
                    value: _stepSize,
                    decoration: const InputDecoration(
                      labelText: "Artış Adımı",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0.1, child: Text("0.10 (Hassas Tartı)")),
                      DropdownMenuItem(value: 0.25, child: Text("0.25 (Çeyrek Kilo)")),
                      DropdownMenuItem(value: 0.5, child: Text("0.50 (Yarım Kilo)")),
                      DropdownMenuItem(value: 1.0, child: Text("1.00 (Tam Katları)")),
                    ],
                    onChanged: (val) {
                      setState(() {
                        _stepSize = val!;
                      });
                    },
                  ),
                ],
              ),
              crossFadeState: (_selectedUnit == "KG" || _selectedUnit == "LITRE" || _selectedUnit == "GR")
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}


📢 Doğrulama Planı

Backend & Prisma Derlemesi:

cd backend && npx prisma db push && npm run build


Kataloğun Seed Edilmesi (Test):
Yazılan Node.js seed script'inin GlobalProduct tablosuna 1000+ ürünü görselleriyle birlikte başarıyla yazdığını doğrulayın.

Satıcı Panelinden Ürün Ekleme:
Satıcı uygulaması üzerinden patates ürününe girip birimini "KG", min miktarını "0.5", artış adımını "0.25" olarak güncelleyin. Tüketici uygulamasında bu ürünün artık adetle değil, pürüzsüzce küsuratlı şekilde eklenebildiğini izleyin!
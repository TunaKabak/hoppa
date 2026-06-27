Story 19.4 - Varsayılan Ödeme Seçeneği ve İşletmeye Özel Dinamik Filtreler

Bu görev belgesi; hem "Eve Teslim" hem de "Gel Al" siparişlerinde ödeme yönteminin otomatik olarak "Kredi/Banka Kartı" (Online Ödeme) seçili gelmesini sağlamayı ve ana sayfadaki/dükkan detaylarındaki kategorileri/alt kategorileri tamamen dinamikleştirerek o dükkanda aktif olan ürünlerin ilişkisel tablolarından çekilmesini amaçlar.

💳 1. Bölüm: Ödeme Yöntemi Varsayılan Seçim Standardı (Online Payment Default)

Sorun Analizi

Tüketici ödeme sayfasına girdiğinde ödeme yöntemi seçimi temizlenmiş veya boş gelebiliyordu ya da kullanıcıyı kapıda ödemeye yönlendirebiliyordu. Sürtünmeyi (friction) azaltmak için hem Eve Teslim hem de Gel Al siparişlerinde ödeme tipini otomatik olarak ONLINE_PAYMENT (Kredi/Banka Kartı) olarak kilitleyeceğiz.

Çözüm Adımları

A. Flutter Ödeme Seçici Başlangıç State'i (payment_page.dart)

Ödeme yöntemi seçicimizi (PaymentMethodSelector ve CheckoutPage state'lerini) sayfa ilk açıldığında doğrudan MainPaymentGroup.onlineCard değerine zorlayacağız.

// apps/consumer_app/lib/screens/checkout/payment_page.dart

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  // 🚨 KESİN BAŞLANGIÇ DEĞERLERİ: Otomatik olarak online kart seçili başlar
  MainPaymentGroup _selectedGroup = MainPaymentGroup.onlineCard;
  PayAtDoorType _selectedSubGroup = PayAtDoorType.cash;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığı an üst bileşene (CheckoutPage) seçimi otomatik haber ver
    _notifyChanges();
  }
}


🥛 2. Bölüm: İşletmeye Özel İlişkisel Dinamik Kategori & Alt Kategori Filtreleme

Sorun Analizi

Daha önce ana sayfada veya dükkan detay sayfalarında kategoriler statik veya dükkan tipine göre genel olarak çekiliyordu. Bu durum, "X Market" içinde gezinirken "Süt Ürünleri" kategorisine basınca eğer o dükkanda taze süt ürünü yoksa boş listelenmesine veya karmaşaya yol açıyordu.

Çözüm Mimarisi (Dynamic Category Extraction)

Dükkan detay sayfası veya filtreleme şeridi açıldığında, sadece o dükkanda (shopId) aktif olarak satılan ürünlerin bağlı olduğu kategorileri ve alt kategorileri veritabanından çekip listeleyeceğiz. Böylece boş kalan veya dükkanla uyumsuz olan kategoriler asla ekranda görünmeyecektir!

[Kullanıcı Dükkanı Açar]
          │
          ▼
[API Sorgusu: GET /api/shops/:shopId/categories]
          │
          ▼
[Prisma SQL: Sadece o dükkandaki aktif ürünlerin categoryId'lerini JOIN et]
          │
          ▼
[Dinamik Filtre Çipleri Sadece Dolu Kategorilerle Harika Şekilde Çizilir]


A. Backend Dinamik Filtre API'si (ConsumerShopController.ts)

Seçilen dükkanın sahip olduğu dinamik ürün ilişkili kategorileri getiren yeni endpoint:

// backend/src/controllers/ConsumerShopController.ts

export const getShopActiveCategories = async (req: Request, res: Response) => {
  try {
    const { shopId } = req.params;

    // 🚨 AKILLI PRISMA SORGUSU:
    // Sadece bu dükkana ait (shopId) ürünlerin bağlı olduğu kategorileri ve alt kategorileri getir
    const categories = await prisma.category.findMany({
      where: {
        products: {
          some: { shopId: shopId }
        }
      },
      include: {
        subCategories: {
          where: {
            products: { some: { shopId: shopId } }
          }
        }
      }
    });

    return res.status(200).json({ error: false, data: categories });
  } catch (error) {
    console.error("Dinamik kategori çekme hatası:", error);
    return res.status(500).json({ error: true, message: "Kategoriler getirilirken hata oluştu." });
  }
};


B. Rotaların Bağlanması

backend/src/routes/consumerRoutes.ts dosyasına bu yeni endpoint'i ekleyin:

GET /api/consumer/shops/:shopId/categories -> ConsumerShopController.getShopActiveCategories

C. Flutter Dinamik Kategori Provider & UI Entegrasyonu

Tüketici uygulamasında statik kategori listesini bu yeni API'ye bağlayarak filtre çiplerini dinamikleştiriyoruz:

Repository Güncellemesi (consumer_shop_repository.dart):

Future<List<Category>> getShopCategories(String shopId) async {
  final response = await _apiClient.get('/api/consumer/shops/$shopId/categories');
  return (response['data'] as List).map((c) => Category.fromMap(c)).toList();
}


Dükkan Detay Ekranında Dinamik Çiplerin Çizilmesi (shop_detail_page.dart):

// Riverpod provider ile kategorileri dükkana özel çek
final shopCategoriesProvider = FutureProvider.family<List<Category>, String>((ref, shopId) {
  return ref.read(shopRepositoryProvider).getShopCategories(shopId);
});


📢 Doğrulama Planı

Backend Derleme ve Şema Kontrolü:

cd backend && npx prisma db push && npm run build


Flutter Statik Analiz Kontrolü:

cd apps/consumer_app && flutter analyze


Manuel Kullanıcı Deneyimi Testi:

Bir dükkana girin (Örn: Test Süpermarket). Haritada ve filtre şeridinde sadece o marketin sattığı kategorilerin (Örn: Süt, Atıştırmalık) göründüğünü, alakasız dükkan kategorilerinin (Örn: Kebap, Lahmacun) asla görünmediğini doğrulayın.

Ödeme sayfasına (Checkout) geçin. Hem Eve Teslim hem de Gel Al siparişlerinde "Kredi / Banka Kartı" (Online Ödeme) butonunun ve kart formunun otomatik olarak seçili/açık geldiğini doğrulayın.
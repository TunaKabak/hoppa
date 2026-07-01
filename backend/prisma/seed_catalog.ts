import { PrismaClient } from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';

const prisma = new PrismaClient();

const EXCLUDED_CATEGORY_IDS = [
  20000000072311, // Tüm İndirimli Ürünler
  20000000073584, // Yaşam & Beslenme Tarzı
  20000000072310, // Sadece Migros'ta
  20000000072420, // Migroskop
  20000000074746, // Migros Ekstra
  20000000074861, // Yaz İhtiyaçları
  20000000074872, // Kupaya Özel
];

const isPromotionalCategory = (name: string): boolean => {
  const n = name.toLowerCase();
  return n.includes("kampanya") ||
    n.includes("indirimli") ||
    n.includes("fırsat") ||
    n.includes("migroskop") ||
    n.includes("sadece migros") ||
    n.includes("kupaya özel") ||
    n.includes("ekstra") ||
    n.includes("sponsorlu");
};

function determineShopType(name: string): string {
  const n = name.toLowerCase();
  if (n.includes("sebze") || n.includes("meyve") || n.includes("manav")) {
    return "GREENGROCER";
  }
  if (n.includes("et, tavuk, balık") || n.includes("kasap") || n.includes("kırmızı et") || n.includes("beyaz et")) {
    return "BUTCHER";
  }
  if (n.includes("restoran") || n.includes("hazır yemek")) {
    return "RESTAURANT";
  }
  return "MARKET";
}

interface CollectedCategory {
  id: string;
  name: string;
  shopType: string;
  imageUrl: string | null;
  color: string | null;
  parentId: string | null;
  depth: number;
}

const collected: CollectedCategory[] = [];

function collectCategoriesRecursive(
  cat: any,
  parentId: string | null = null,
  inheritedShopType: string | null = null,
  depth: number = 1
) {
  if (EXCLUDED_CATEGORY_IDS.includes(cat.id)) return;
  if (isPromotionalCategory(cat.name)) return;

  let imageUrl: string | null = null;
  if (cat.images && cat.images.length > 0 && cat.images[0].urls) {
    imageUrl = cat.images[0].urls.x3 || cat.images[0].urls.x2 || cat.images[0].urls.x1 || null;
  }

  const currentShopType = inheritedShopType || determineShopType(cat.name);

  collected.push({
    id: cat.id.toString(),
    name: cat.name,
    shopType: currentShopType,
    imageUrl: imageUrl,
    color: cat.color || null,
    parentId: parentId,
    depth: depth
  });

  if (cat.children && cat.children.length > 0) {
    for (const child of cat.children) {
      collectCategoriesRecursive(child, cat.id.toString(), currentShopType, depth + 1);
    }
  }
}

async function main() {
  console.log("🌱 İlişkisel katalog temizliği başlatılıyor...");
  await prisma.product.deleteMany({});
  await prisma.globalProduct.deleteMany({});
  await prisma.category.deleteMany({});
  await prisma.brand.deleteMany({});
  await prisma.unit.deleteMany({});
  await prisma.campaign.deleteMany({});

  console.log("📂 Migros JSON kategorileri okunuyor...");
  const jsonPath = path.join(__dirname, 'migros-category.json');
  const rawData = fs.readFileSync(jsonPath, 'utf-8');
  const parsed = JSON.parse(rawData);
  const categoriesList = parsed?.data?.categories || [];

  console.log(`🥦 ${categoriesList.length} adet kök kategori listesi toplanıyor...`);
  for (const rootCat of categoriesList) {
    collectCategoriesRecursive(rootCat);
  }

  const maxDepth = Math.max(...collected.map(c => c.depth), 1);
  console.log(`Maksimum kategori derinliği: ${maxDepth}. Toplam toplanan kategori sayısı: ${collected.length}`);

  for (let d = 1; d <= maxDepth; d++) {
    const levelCategories = collected.filter(c => c.depth === d);
    if (levelCategories.length > 0) {
      console.log(`Derinlik ${d} seviyesindeki ${levelCategories.length} kategori toplu ekleniyor...`);
      const dataToInsert = levelCategories.map(c => ({
        id: c.id,
        name: c.name,
        shopType: c.shopType,
        imageUrl: c.imageUrl,
        color: c.color,
        parentId: c.parentId
      }));
      await prisma.category.createMany({
        data: dataToInsert,
        skipDuplicates: true
      });
    }
  }

  console.log("📐 Birimler oluşturuluyor...");
  const unitAdet = await prisma.unit.create({ data: { code: "ADET", nameTr: "Adet", nameEn: "Pieces" } });
  const unitKg = await prisma.unit.create({ data: { code: "KG", nameTr: "Kg", nameEn: "Kg" } });
  const unitLitre = await prisma.unit.create({ data: { code: "LITRE", nameTr: "Litre", nameEn: "Liters" } });
  const unitPaket = await prisma.unit.create({ data: { code: "PAKET", nameTr: "Paket", nameEn: "Pack" } });

  // Bul veya oluştur market dükkanı
  let marketShop = await prisma.shop.findFirst({ where: { type: "MARKET" } });
  if (!marketShop) {
    // Merchant bul veya oluştur
    let merchant = await prisma.merchant.findFirst({ where: { email: "market@test.com" } });
    if (!merchant) {
      merchant = await prisma.merchant.create({
        data: {
          email: "market@test.com",
          passwordHash: "$2b$12$RZJvTlB0q5OLVyLpWDTv0OUya.vTMqQoQ56r5u7GfGSoWuKKP4X6e",
          businessName: "Test Süpermarket",
          status: "ACTIVE",
          role: "merchant",
        }
      });
    } else if (merchant.passwordHash === "mock_hash") {
      merchant = await prisma.merchant.update({
        where: { id: merchant.id },
        data: {
          passwordHash: "$2b$12$RZJvTlB0q5OLVyLpWDTv0OUya.vTMqQoQ56r5u7GfGSoWuKKP4X6e"
        }
      });
    }
    marketShop = await prisma.shop.create({
      data: {
        merchantId: merchant.id,
        name: "Test Süpermarket",
        description: "E2E testleri için market dükkanı",
        isActive: true,
        type: "MARKET",
        minOrderAmount: 100.0,
      }
    });
  }

  console.log(`🏪 Ürünler '${marketShop.name}' dükkanına bağlanacak.`);

  // Ürün JSON dosyalarını oku
  const productFiles = ['migros-search-product.json', 'migros-search-product-ekmek.json'];
  const allProducts: any[] = [];

  for (const filename of productFiles) {
    const prodPath = path.join(__dirname, filename);
    if (fs.existsSync(prodPath)) {
      console.log(`📖 Ürün dosyası okunuyor: ${filename}`);
      const rawProdData = fs.readFileSync(prodPath, 'utf8');
      const parsedProds = JSON.parse(rawProdData);
      const list = parsedProds.data?.products || [];
      allProducts.push(...list);
    }
  }

  console.log(`📦 Toplam ${allProducts.length} adet Migros ürünü tohumlanıyor...`);

  for (const item of allProducts) {
    // 1. Marka
    const brandName = item.brand || "Diğer";
    const brand = await prisma.brand.upsert({
      where: { name: brandName },
      update: {},
      create: { name: brandName }
    });

    // 2. Kategori Eşleme
    let dbCategory = await prisma.category.findFirst({
      where: { name: { contains: item.category, mode: 'insensitive' } }
    });

    if (!dbCategory) {
      // Varsayılan bir kategori seç
      dbCategory = await prisma.category.findFirst({ where: { shopType: "MARKET" } });
      if (!dbCategory) {
        dbCategory = await prisma.category.create({
          data: {
            id: require('crypto').randomUUID(),
            name: item.category || "Diğer",
            shopType: "MARKET"
          }
        });
      }
    }

    // 3. Birim ve Ondalıklı Miktar Kuralları
    const nameLower = item.name.toLowerCase();
    let unitId = unitAdet.id;
    let minQuantity = 1.0;
    let stepSize = 1.0;

    const isPackagedBakeryOrBread = nameLower.includes("ekmek") || 
      nameLower.includes("bazlama") || 
      nameLower.includes("tost") || 
      nameLower.includes("yufka") || 
      nameLower.includes("simit") || 
      nameLower.includes("lavaş") || 
      nameLower.includes("kurabiye") || 
      (dbCategory && (
        dbCategory.name.toLowerCase().includes("ekmek") || 
        dbCategory.name.toLowerCase().includes("unlu mamül") || 
        dbCategory.name.toLowerCase().includes("unlu mamul")
      ));

    if (isPackagedBakeryOrBread) {
      unitId = unitAdet.id;
      minQuantity = 1.0;
      stepSize = 1.0;
    } else if (dbCategory.shopType === "GREENGROCER" || dbCategory.shopType === "BUTCHER" || item.unit === "KILOGRAM" || nameLower.includes(" kg")) {
      unitId = unitKg.id;
      minQuantity = 0.5;
      stepSize = 0.25;
    } else if (item.unit === "LITER" || nameLower.includes(" litre") || nameLower.includes(" l ") || nameLower.endsWith(" l") || nameLower.includes(" ml")) {
      unitId = unitLitre.id;
      minQuantity = 1.0;
      stepSize = 1.0;
    } else if (nameLower.includes("paket") || nameLower.includes("adet")) {
      unitId = unitPaket.id;
    }

    const imageUrl = item.images?.PRODUCT_HD || item.images?.PRODUCT_DETAIL || "https://placehold.co/300";

    // 4. GlobalProduct Upsert
    const globalProduct = await prisma.globalProduct.upsert({
      where: { sku: item.sku },
      update: {
        name: item.name,
        prettyName: item.pretty_name,
        imageUrl: imageUrl,
        regularPrice: item.regular_price,
        shownPrice: item.shown_price,
        discountRate: item.discount_rate,
      },
      create: {
        barcode: item.id.toString(),
        sku: item.sku,
        name: item.name,
        prettyName: item.pretty_name,
        imageUrl: imageUrl,
        description: item.name, // Detay açıklaması olarak ismini kullanıyoruz
        minQuantity: minQuantity,
        stepSize: stepSize,
        regularPrice: item.regular_price,
        shownPrice: item.shown_price,
        discountRate: item.discount_rate,
        unitId: unitId,
        brandId: brand.id,
        categoryId: dbCategory.id,
      }
    });

    // 5. Product (Local Override)
    await prisma.product.create({
      data: {
        shopId: marketShop.id,
        name: item.name,
        description: item.name,
        regularPrice: item.regular_price || item.shown_price || 0.0,
        price: item.shown_price || 0.0,
        discountRate: item.discount_rate || 0,
        imageUrl: imageUrl,
        minQuantity: minQuantity,
        stepSize: stepSize,
        trackStock: false,
        stockQuantity: 100,
        globalProductId: globalProduct.id,
        unitId: unitId,
        brandId: brand.id,
        categoryId: dbCategory.id,
        isActive: true,
      }
    });
  }

  // Seeding campaigns and shop visuals
  await seedCampaignsAndShopVisuals();

  console.log("✅ Tohumlama tamamlandı!");
}

async function seedCampaignsAndShopVisuals() {
  console.log("📢 Kampanyalar ve Dükkan görsel detayları tohumlanıyor...");

  // 1. Dükkanları güncelle (Mock dükkanlarımıza gerçek logo ve kapak atıyoruz)
  await prisma.shop.updateMany({
    where: { name: { contains: "Süpermarket" } },
    data: {
      imageUrl: "https://images.migrosone.com/sanalmarket/category/list/72310/migros-580baf.png",
      headerImageUrl: "https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=1200&q=80",
      averageRating: 4.8,
      reviewCount: 142
    }
  });

  await prisma.shop.updateMany({
    where: { name: { contains: "Manav" } },
    data: {
      imageUrl: "https://images.migrosone.com/sanalmarket/category/list/2/meyve-f77b42.png",
      headerImageUrl: "https://images.unsplash.com/photo-1610348725531-843dff14682c?auto=format&fit=crop&w=1200&q=80",
      averageRating: 4.9,
      reviewCount: 89
    }
  });

  // 2. get_campaigns.json dosyasını oku ve veritabanına kaydet
  const campaignJsonPath = path.join(__dirname, 'get_campaigns.json');
  if (fs.existsSync(campaignJsonPath)) {
    const rawData = fs.readFileSync(campaignJsonPath, 'utf8');
    const parsed = JSON.parse(rawData);
    const campaigns = parsed.data?.campaigns || [];

    for (const item of campaigns) {
      // Listeden ilk geçerli resmi al
      let imageUrl = "https://placehold.co/600x300";
      if (item.imageUrls && item.imageUrls.length > 0 && item.imageUrls[0].urls) {
        imageUrl = item.imageUrls[0].urls.CAMPAIGN_LIST || imageUrl;
      }

      await prisma.campaign.upsert({
        where: { id: item.id.toString() },
        update: {
          title: item.name,
          description: item.description || "",
          imageUrl: imageUrl,
          prettyName: item.prettyName,
          finishDate: item.finishDate ? new Date(item.finishDate) : null,
        },
        create: {
          id: item.id.toString(),
          title: item.name,
          description: item.description || "",
          imageUrl: imageUrl,
          prettyName: item.prettyName,
          finishDate: item.finishDate ? new Date(item.finishDate) : null,
          type: "SYSTEM",
          isActive: true
        }
      });
    }
    console.log(`✅ ${campaigns.length} adet kampanya başarıyla aktarıldı.`);
  }
}

main()
  .catch((e) => {
    console.error("🚨 Tohumlama Hatası:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

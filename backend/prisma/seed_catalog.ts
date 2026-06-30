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
  if (n.includes("restoran") || n.includes("hazır yemek") || n.includes("fırın") || n.includes("unlu mamül")) {
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

async function findCategoryByName(names: string[]): Promise<string> {
  for (const name of names) {
    const cat = await prisma.category.findFirst({
      where: { name: { equals: name, mode: 'insensitive' } }
    });
    if (cat) return cat.id;
  }
  // Fallback to any category
  const anyCat = await prisma.category.findFirst();
  return anyCat?.id || "default";
}

async function main() {
  console.log("🌱 İlişkisel katalog temizliği başlatılıyor...");
  await prisma.globalProduct.deleteMany({});
  await prisma.product.deleteMany({});
  await prisma.category.deleteMany({});
  await prisma.brand.deleteMany({});
  await prisma.unit.deleteMany({});

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

  console.log("📦 Markalar oluşturuluyor...");
  const brandCocaCola = await prisma.brand.create({ data: { name: "Coca-Cola" } });
  const brandUlker = await prisma.brand.create({ data: { name: "Ülker" } });
  const brandEti = await prisma.brand.create({ data: { name: "Eti" } });
  const brandSutas = await prisma.brand.create({ data: { name: "Sütaş" } });
  const brandDamla = await prisma.brand.create({ data: { name: "Damla" } });
  const brandYerli = await prisma.brand.create({ data: { name: "Yerli Üretim" } });

  console.log("🔥 Global Ürünler dinamik kategorilerle tohumlanıyor...");

  // Dinamik kategori eşleştirmeleri
  const catIcecekId = await findCategoryByName(["Kola", "Gazlı İçecek", "İçecekler", "İçecek"]);
  const catSuId = await findCategoryByName(["Su", "Su, Maden Suyu", "İçecek"]);
  const catGofretId = await findCategoryByName(["Bisküvi, Kek, Gofret", "Bisküvi & Gofret", "Bisküvi", "Atıştırmalık"]);
  const catKekId = await findCategoryByName(["Kek", "Bisküvi, Kek, Gofret", "Atıştırmalık"]);
  const catSutId = await findCategoryByName(["Süt", "Uzun Ömürlü Süt", "Süt Ürünleri"]);
  const catPeynirId = await findCategoryByName(["Peynir", "Beyaz Peynir", "Süt Ürünleri"]);
  const catSebzeId = await findCategoryByName(["Patates, Soğan, Sarımsak", "Sebze", "Meyve, Sebze"]);
  const catMeyveId = await findCategoryByName(["Meyve", "Meyve, Sebze"]);

  const globalProducts = [
    {
      barcode: "8690574001001",
      name: "Coca-Cola 1L Original",
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1110059.jpg",
      unitId: unitAdet.id,
      brandId: brandCocaCola.id,
      categoryId: catIcecekId,
    },
    {
      barcode: "8690928000135",
      name: "Beypazarı Doğal Maden Suyu 200ml",
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1110201.jpg",
      unitId: unitAdet.id,
      brandId: brandYerli.id,
      categoryId: catSuId,
    },
    {
      barcode: "8690804407137",
      name: "Damla Damacana Su 19L",
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1110101.jpg",
      unitId: unitAdet.id,
      brandId: brandDamla.id,
      categoryId: catSuId,
    },
    {
      barcode: "8690504037544",
      name: "Ülker Çikolatalı Gofret 36g",
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1111024.jpg",
      unitId: unitAdet.id,
      brandId: brandUlker.id,
      categoryId: catGofretId,
    },
    {
      barcode: "8690526012352",
      name: "Eti Popkek Muzlu 60g",
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1111450.jpg",
      unitId: unitAdet.id,
      brandId: brandEti.id,
      categoryId: catKekId,
    },
    {
      barcode: "8692261010188",
      name: "Eti Crax Sade Çubuk 120g",
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1111102.jpg",
      unitId: unitAdet.id,
      brandId: brandEti.id,
      categoryId: catGofretId,
    },
    {
      barcode: "8690901002002",
      name: "Sütaş Tam Yağlı Süt 1L UHT",
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1113002.jpg",
      unitId: unitLitre.id,
      brandId: brandSutas.id,
      categoryId: catSutId,
    },
    {
      barcode: "8690901113050",
      name: "Sütaş Süzme Peynir 500g",
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1113050.jpg",
      unitId: unitAdet.id,
      brandId: brandSutas.id,
      categoryId: catPeynirId,
    },
    {
      barcode: null,
      name: "Taze Patates",
      imageUrl: "https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=500&q=80",
      unitId: unitKg.id,
      minQuantity: 0.5,
      stepSize: 0.25,
      brandId: brandYerli.id,
      categoryId: catSebzeId,
    },
    {
      barcode: null,
      name: "Kırmızı Salkım Domates",
      imageUrl: "https://images.unsplash.com/photo-1595855759920-86582396756a?auto=format&fit=crop&w=500&q=80",
      unitId: unitKg.id,
      minQuantity: 0.5,
      stepSize: 0.25,
      brandId: brandYerli.id,
      categoryId: catSebzeId,
    },
    {
      barcode: null,
      name: "Yerli İthal Muz",
      imageUrl: "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=500&q=80",
      unitId: unitKg.id,
      minQuantity: 0.5,
      stepSize: 0.25,
      brandId: brandYerli.id,
      categoryId: catMeyveId,
    }
  ];

  for (const prod of globalProducts) {
    await prisma.globalProduct.create({ data: prod });
  }

  console.log("✅ Tebrikler! İlişkisel Katalog, Birimler ve Gerçek Resimler Başarıyla Yüklendi.");
}

main()
  .catch((e) => {
    console.error("🚨 Tohumlama Hatası:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  console.log("🌱 İlişkisel katalog temizliği başlatılıyor...");
  await prisma.globalProduct.deleteMany({});
  await prisma.product.deleteMany({});
  await prisma.subCategory.deleteMany({});
  await prisma.category.deleteMany({});
  await prisma.brand.deleteMany({});
  await prisma.unit.deleteMany({});

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

  console.log("🥦 Kategoriler ve Alt Kategoriler oluşturuluyor...");
  // MARKET KATEGORİLERİ
  const catIcecek = await prisma.category.create({ 
    data: { 
      name: "İçecek", 
      shopType: "MARKET",
      imageUrl: "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=500&q=80"
    } 
  });
  const subGazli = await prisma.subCategory.create({ 
    data: { 
      name: "Gazlı İçecekler", 
      categoryId: catIcecek.id,
      imageUrl: "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=500&q=80"
    } 
  });
  const subSu = await prisma.subCategory.create({ 
    data: { 
      name: "Su & Maden Suyu", 
      categoryId: catIcecek.id,
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1110101.jpg"
    } 
  });

  const catAtistirma = await prisma.category.create({ 
    data: { 
      name: "Atıştırmalık", 
      shopType: "MARKET",
      imageUrl: "https://images.unsplash.com/photo-1599490659213-e2b9527bd087?auto=format&fit=crop&w=500&q=80"
    } 
  });
  const subGofret = await prisma.subCategory.create({ 
    data: { 
      name: "Bisküvi & Gofret", 
      categoryId: catAtistirma.id,
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1111024.jpg"
    } 
  });
  const subKek = await prisma.subCategory.create({ 
    data: { 
      name: "Kek & Turta", 
      categoryId: catAtistirma.id,
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1111450.jpg"
    } 
  });

  const catSut = await prisma.category.create({ 
    data: { 
      name: "Süt Ürünleri", 
      shopType: "MARKET",
      imageUrl: "https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=500&q=80"
    } 
  });
  const subSut = await prisma.subCategory.create({ 
    data: { 
      name: "Sütler", 
      categoryId: catSut.id,
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1113002.jpg"
    } 
  });
  const subPeynir = await prisma.subCategory.create({ 
    data: { 
      name: "Peynir", 
      categoryId: catSut.id,
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1113050.jpg"
    } 
  });

  // MANAV KATEGORİLERİ (GREENGROCER)
  const catSebze = await prisma.category.create({ 
    data: { 
      name: "Taze Sebze", 
      shopType: "GREENGROCER",
      imageUrl: "https://images.unsplash.com/photo-1566385101042-1a0aca02964c?auto=format&fit=crop&w=500&q=80"
    } 
  });
  const subPatates = await prisma.subCategory.create({ 
    data: { 
      name: "Patates & Soğan", 
      categoryId: catSebze.id,
      imageUrl: "https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=500&q=80"
    } 
  });
  
  const catMeyve = await prisma.category.create({ 
    data: { 
      name: "Taze Meyve", 
      shopType: "GREENGROCER",
      imageUrl: "https://images.unsplash.com/photo-1619546813926-a78fa6372cd2?auto=format&fit=crop&w=500&q=80"
    } 
  });
  const subNarenciye = await prisma.subCategory.create({ 
    data: { 
      name: "Narenciye", 
      categoryId: catMeyve.id,
      imageUrl: "https://images.unsplash.com/photo-1611080626919-7cf5a9dbab5b?auto=format&fit=crop&w=500&q=80"
    } 
  });

  console.log("🔥 Global Ürünler gerçek CDN resimleri ve ilişkileriyle tohumlanıyor...");
  
  const globalProducts = [
    // İÇECEKLER
    {
      barcode: "8690574001001",
      name: "Coca-Cola 1L Original",
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1110059.jpg",
      unitId: unitAdet.id,
      brandId: brandCocaCola.id,
      categoryId: catIcecek.id,
      subCategoryId: subGazli.id,
    },
    {
      barcode: "8690928000135",
      name: "Beypazarı Doğal Maden Suyu 200ml",
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1110201.jpg",
      unitId: unitAdet.id,
      brandId: brandYerli.id,
      categoryId: catIcecek.id,
      subCategoryId: subSu.id,
    },
    {
      barcode: "8690804407137",
      name: "Damla Damacana Su 19L",
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1110101.jpg",
      unitId: unitAdet.id,
      brandId: brandDamla.id,
      categoryId: catIcecek.id,
      subCategoryId: subSu.id,
    },
    // ATIŞTIRMALIKLAR
    {
      barcode: "8690504037544",
      name: "Ülker Çikolatalı Gofret 36g",
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1111024.jpg",
      unitId: unitAdet.id,
      brandId: brandUlker.id,
      categoryId: catAtistirma.id,
      subCategoryId: subGofret.id,
    },
    {
      barcode: "8690526012352",
      name: "Eti Popkek Muzlu 60g",
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1111450.jpg",
      unitId: unitAdet.id,
      brandId: brandEti.id,
      categoryId: catAtistirma.id,
      subCategoryId: subKek.id,
    },
    {
      barcode: "8692261010188",
      name: "Eti Crax Sade Çubuk 120g",
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1111102.jpg",
      unitId: unitAdet.id,
      brandId: brandEti.id,
      categoryId: catAtistirma.id,
      subCategoryId: subGofret.id,
    },
    // SÜT ÜRÜNLERİ
    {
      barcode: "8690901002002",
      name: "Sütaş Tam Yağlı Süt 1L UHT",
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1113002.jpg",
      unitId: unitLitre.id,
      brandId: brandSutas.id,
      categoryId: catSut.id,
      subCategoryId: subSut.id,
    },
    {
      barcode: "8690901113050",
      name: "Sütaş Süzme Peynir 500g",
      imageUrl: "https://images.deliveryhero.io/image/fd-tr/Products/1113050.jpg",
      unitId: unitAdet.id,
      brandId: brandSutas.id,
      categoryId: catSut.id,
      subCategoryId: subPeynir.id,
    },
    // MANAV (TARTILI ÜRÜNLER - ONDALIKLI BİRİM DESTEKLİ)
    {
      barcode: null,
      name: "Taze Patates",
      imageUrl: "https://images.unsplash.com/photo-1518977676601-b53f82aba655?auto=format&fit=crop&w=500&q=80",
      unitId: unitKg.id,
      minQuantity: 0.5,
      stepSize: 0.25,
      brandId: brandYerli.id,
      categoryId: catSebze.id,
      subCategoryId: subPatates.id,
    },
    {
      barcode: null,
      name: "Kırmızı Salkım Domates",
      imageUrl: "https://images.unsplash.com/photo-1595855759920-86582396756a?auto=format&fit=crop&w=500&q=80",
      unitId: unitKg.id,
      minQuantity: 0.5,
      stepSize: 0.25,
      brandId: brandYerli.id,
      categoryId: catSebze.id,
      subCategoryId: subPatates.id,
    },
    {
      barcode: null,
      name: "Yerli İthal Muz",
      imageUrl: "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?auto=format&fit=crop&w=500&q=80",
      unitId: unitKg.id,
      minQuantity: 0.5,
      stepSize: 0.25,
      brandId: brandYerli.id,
      categoryId: catMeyve.id,
      subCategoryId: subNarenciye.id,
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

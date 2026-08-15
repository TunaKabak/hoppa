import { PrismaClient } from "@prisma/client";
import bcrypt from "bcrypt";

const prisma = new PrismaClient();

// ============================================================================
// 4 ANA SEKTÖR PROFESYONEL VE HİYERARŞİK KATEGORİ AĞACI
// ============================================================================

export const richCategories = [
  // --------------------------------------------------------------------------
  // 🛒 1. MARKET (Süpermarket & Hızlı Market)
  // --------------------------------------------------------------------------
  {
    name: "Meyve & Sebze",
    shopType: "MARKET",
    color: "#E8F5E9",
    children: [
      "Taze Meyveler",
      "Taze Sebzeler",
      "Yeşillikler & Otlar",
      "Egzotik Meyveler",
      "Organik & Doğal"
    ]
  },
  {
    name: "Süt & Kahvaltılık",
    shopType: "MARKET",
    color: "#FFF8E1",
    children: [
      "Süt & Yoğurt",
      "Peynir Çeşitleri",
      "Yumurta",
      "Tereyağı & Margarin",
      "Zeytin & Reçel & Bal",
      "Kahvaltılık Gevrek & Ezmeler"
    ]
  },
  {
    name: "Fırın & Unlu Mamuller",
    shopType: "MARKET",
    color: "#EFEBE9",
    children: [
      "Ekmek Çeşitleri",
      "Simit & Poğaça & Börek",
      "Paket Ekmekler & Lavaş",
      "Unlu Tatlılar"
    ]
  },
  {
    name: "Et, Tavuk & Şarküteri",
    shopType: "MARKET",
    color: "#FFEBEE",
    children: [
      "Kırmızı Et (Dana/Kuzu)",
      "Beyaz Et (Tavuk/Hindi)",
      "Salam & Sucuk & Sosis",
      "Pastırma & Kavurma",
      "Deniz Ürünleri"
    ]
  },
  {
    name: "Temel Gıda & Bakliyat",
    shopType: "MARKET",
    color: "#FFF3E0",
    children: [
      "Pirinç & Bulgur & Bakliyat",
      "Sıvı Yağlar & Zeytinyağı",
      "Makarna & Erişte",
      "Un & İrmik & Şeker & Tuz",
      "Salça & Konserve & Soslar"
    ]
  },
  {
    name: "Atıştırmalık & Tatlı",
    shopType: "MARKET",
    color: "#FCE4EC",
    children: [
      "Çikolata & Gofret",
      "Bisküvi & Kek",
      "Cips & Çerez",
      "Şekerleme & Sakız",
      "Dondurma"
    ]
  },
  {
    name: "İçecekler",
    shopType: "MARKET",
    color: "#E0F7FA",
    children: [
      "Gazlı İçecekler",
      "Su & Maden Suyu",
      "Meyve Suyu & Soğuk Çay",
      "Çay & Kahve",
      "Ayran & Kefir & Şalgam"
    ]
  },
  {
    name: "Donuk & Hazır Gıda",
    shopType: "MARKET",
    color: "#E1F5FE",
    children: [
      "Dondurulmuş Sebze & Meyve",
      "Hazır Yemekler & Pizza & Hamur",
      "Donuk Et & Balık"
    ]
  },
  {
    name: "Deterjan & Ev Temizliği",
    shopType: "MARKET",
    color: "#EDE7F6",
    children: [
      "Çamaşır Yıkama",
      "Bulaşık Yıkama",
      "Ev & Yüzey Temizleyiciler",
      "Kağıt Ürünleri",
      "Oda Kokusu & Temizlik Gereçleri"
    ]
  },
  {
    name: "Kişisel Bakım & Kozmetik",
    shopType: "MARKET",
    color: "#F3E5F5",
    children: [
      "Şampuan & Saç Bakımı",
      "Duş Jeli & Sabun",
      "Ağız & Diş Bakımı",
      "Tıraş & Deodorant",
      "Cilt & Vücut Bakımı"
    ]
  },
  {
    name: "Bebek Dünyası",
    shopType: "MARKET",
    color: "#E8EAF6",
    children: [
      "Bebek Bezi & Islak Mendil",
      "Bebek Maması & Ek Gıda",
      "Bebek Bakım & Şampuan"
    ]
  },
  {
    name: "Evcil Hayvan",
    shopType: "MARKET",
    color: "#F1F8E9",
    children: [
      "Kedi Maması & Kumu",
      "Köpek Maması & Ödüller",
      "Kuş & Kemirgen Yemleri"
    ]
  },

  // --------------------------------------------------------------------------
  // 🍔 2. RESTORAN / YEMEK (Yemek & Restoran Menüleri)
  // --------------------------------------------------------------------------
  {
    name: "Burger & Sandviç",
    shopType: "RESTAURANT",
    color: "#FFF3E0",
    children: [
      "Gurme Burgerler",
      "Tavuk Burgerler",
      "Sandviç & Tost",
      "Mini / Slider Burgerler"
    ]
  },
  {
    name: "Pizza & İtalyan",
    shopType: "RESTAURANT",
    color: "#FFEBEE",
    children: [
      "Klasik Pizzalar",
      "Gurme / Özel Pizzalar",
      "Makarnalar & Penne",
      "Calzone & Focaccia"
    ]
  },
  {
    name: "Kebap, Döner & Izgara",
    shopType: "RESTAURANT",
    color: "#FBE9E7",
    children: [
      "Dürüm Döner & Porsiyon Döner",
      "Adana & Urfa Kebap",
      "Tavuk Şiş & Kanat",
      "Köfte & Karışık Izgara"
    ]
  },
  {
    name: "Pide & Lahmacun",
    shopType: "RESTAURANT",
    color: "#EFEBE9",
    children: [
      "Lahmacunlar",
      "Kıymalı & Kaşarlı Pideler",
      "Kuşbaşılı Pide",
      "Trabzon / Kapalı Pide"
    ]
  },
  {
    name: "Ev Yemekleri & Çorbalar",
    shopType: "RESTAURANT",
    color: "#FFF8E1",
    children: [
      "Günün Çorbaları",
      "Sulu & Zeytinyağlı Yemekler",
      "Pilavlar & Makarnalar",
      "Meze & Yan Ürünler"
    ]
  },
  {
    name: "Salata & Sağlıklı Beslenme",
    shopType: "RESTAURANT",
    color: "#E8F5E9",
    children: [
      "Fit / Diyet Salatalar",
      "Tavuklu & Ton Balıklı Salata",
      "Bowl & Sağlıklı Tabaklar",
      "Detoks İçecekleri"
    ]
  },
  {
    name: "Dünya Mutfağı & Sokak Lezzetleri",
    shopType: "RESTAURANT",
    color: "#EDE7F6",
    children: [
      "Taco & Meksika",
      "Noodle & Asya",
      "Çıtır Tavuk Kovaları",
      "Çiğ Köfte & Dürümler"
    ]
  },
  {
    name: "Tatlılar & Waffle",
    shopType: "RESTAURANT",
    color: "#FCE4EC",
    children: [
      "Waffle & Krep",
      "Şerbetli Tatlılar & Baklava",
      "Sütlü Tatlılar & Cheesecake",
      "Sufle & Pasta"
    ]
  },
  {
    name: "Kafe, İçecek & Kahve",
    shopType: "RESTAURANT",
    color: "#E0F7FA",
    children: [
      "Sıcak & Soğuk Kahveler",
      "Taze Sıkma Meyve Suları",
      "Milkshake & Smoothie",
      "Meşrubatlar"
    ]
  },

  // --------------------------------------------------------------------------
  // 💧 3. SU & İÇECEK (Damacana, Maden Suyu & Toptan İçecek)
  // --------------------------------------------------------------------------
  {
    name: "Damacana Su",
    shopType: "WATER",
    color: "#E1F5FE",
    children: [
      "19L Polikarbon Damacana",
      "15L / 19L Cam Damacana",
      "Boş Damacana Değişimi"
    ]
  },
  {
    name: "Pet Şişe & Çoklu Paketler",
    shopType: "WATER",
    color: "#E0F7FA",
    children: [
      "0.33L & 0.5L Koli Su",
      "1.5L & 5L Su Paketleri",
      "10L Pratik Su"
    ]
  },
  {
    name: "Doğal Maden Suyu & Soda",
    shopType: "WATER",
    color: "#E8F5E9",
    children: [
      "Sade Doğal Maden Suyu",
      "Meyve Aromalı Maden Suyu",
      "Gazoz & Tonik"
    ]
  },
  {
    name: "Koli & Toptan Meşrubat",
    shopType: "WATER",
    color: "#FFF3E0",
    children: [
      "Koli Gazlı İçecekler",
      "Koli Meyve Suyu & Soğuk Çay",
      "Koli Ayran & İçecekler"
    ]
  },
  {
    name: "Su Pompası & Ekipmanlar",
    shopType: "WATER",
    color: "#EDE7F6",
    children: [
      "Manuel El Pompası",
      "Şarjlı / Otomatik Damacana Pompası",
      "Su Sebili & Aksesuarlar"
    ]
  },

  // --------------------------------------------------------------------------
  // 🌹 4. ÇİÇEK & HEDİYE (Tasarım Çiçekler, Bitkiler & Hediyelik)
  // --------------------------------------------------------------------------
  {
    name: "Tasarım Buketler",
    shopType: "FLOWER",
    color: "#FCE4EC",
    children: [
      "Gül Buketleri",
      "Papatya & Kır Çiçekleri",
      "Lilyum & Şakayık",
      "Karışık Tasarım Buketler"
    ]
  },
  {
    name: "Saksı Çiçekleri & İç Mekan Bitkileri",
    shopType: "FLOWER",
    color: "#E8F5E9",
    children: [
      "Orkide Çeşitleri",
      "Sukulent & Kaktüs",
      "Barış Çiçeği & Bonsai",
      "Salon Bitkileri"
    ]
  },
  {
    name: "Kutuda & Vazoda Çiçekler",
    shopType: "FLOWER",
    color: "#FFF8E1",
    children: [
      "Silindir Kutuda Güller",
      "Cam Vazoda Aranjmanlar",
      "Işıklı / Özel Ahşap Kutulu Çiçekler"
    ]
  },
  {
    name: "Hediye & Özel Gün Setleri",
    shopType: "FLOWER",
    color: "#F3E5F5",
    children: [
      "Çikolatalı Çiçek Sepetleri",
      "Peluş Oyuncak & Çiçek",
      "Doğum Günü & Tebrik Setleri",
      "Hediye Kartları"
    ]
  },
  {
    name: "Kurutulmuş & Solmayan Çiçekler",
    shopType: "FLOWER",
    color: "#EFEBE9",
    children: [
      "Şoklanmış Solmayan Güller",
      "Kuru Çiçek Aranjmanları",
      "Teraryum Tasarımları"
    ]
  }
];

// ============================================================================
// TEMİZLEME VE TOHUMLAMA MOTORU
// ============================================================================

async function cleanStaleProductsAndCategories() {
  console.log("🧹 Veritabanındaki eski/geçici ürünler, opsiyonlar ve kategoriler temizleniyor...");

  try {
    // 1. Bağımlı alt kayıtları doğru hiyerarşik sırada temizle
    await prisma.favoriteProduct.deleteMany({});
    await prisma.orderItemOption.deleteMany({});
    await prisma.orderItem.deleteMany({});
    await prisma.paymentTransaction.deleteMany({});
    await prisma.couponUsage.deleteMany({});
    await prisma.review.deleteMany({});
    await prisma.order.deleteMany({});
    await prisma.productOption.deleteMany({});
    await prisma.productOptionGroup.deleteMany({});
    await prisma.product.deleteMany({});
    await prisma.globalProduct.deleteMany({});

    // 2. Kategorileri temizle (Önce alt kategoriler, sonra kök kategoriler)
    await prisma.category.deleteMany({
      where: { parentId: { not: null } }
    });
    await prisma.category.deleteMany({});

    console.log("✅ Eski ürün ve kategori verileri başarıyla temizlendi.");
  } catch (error: any) {
    console.error("⚠️ Temizleme sırasında hata:", error.message);
  }
}

async function seedUnits() {
  console.log("Seeding units...");
  const units = [
    { code: "ADET", nameTr: "Adet", nameEn: "Pieces" },
    { code: "KG", nameTr: "Kilogram", nameEn: "Kilogram" },
    { code: "GRAM", nameTr: "Gram", nameEn: "Gram" },
    { code: "LITRE", nameTr: "Litre", nameEn: "Liter" },
    { code: "PAKET", nameTr: "Paket", nameEn: "Package" },
    { code: "PORSIYON", nameTr: "Porsiyon", nameEn: "Portion" },
    { code: "DEMET", nameTr: "Demet", nameEn: "Bunch" },
    { code: "KOLI", nameTr: "Koli", nameEn: "Box" }
  ];

  for (const u of units) {
    await prisma.unit.upsert({
      where: { code: u.code },
      update: { nameTr: u.nameTr, nameEn: u.nameEn },
      create: { code: u.code, nameTr: u.nameTr, nameEn: u.nameEn }
    });
  }
  console.log("✅ Standart birimler başarıyla tohumlandı.");
}

async function seedRichCategories() {
  console.log("Seeding 4-sector professional hierarchical categories...");
  const crypto = require("crypto");

  for (const group of richCategories) {
    // 1. Kök kategori oluştur
    const root = await prisma.category.create({
      data: {
        id: crypto.randomUUID(),
        name: group.name,
        shopType: group.shopType,
        color: group.color,
        parentId: null
      }
    });

    // 2. Alt kategorileri toplu (createMany) oluştur
    if (group.children && group.children.length > 0) {
      await prisma.category.createMany({
        data: group.children.map(childName => ({
          id: crypto.randomUUID(),
          name: childName,
          shopType: group.shopType,
          color: group.color,
          parentId: root.id
        }))
      });
    }
  }
  console.log("✅ 4 ana sektör için tüm hiyerarşik kategori ağacı başarıyla tohumlandı.");
}

async function findCategoryByName(name: string, shopType: string): Promise<string> {
  const crypto = require("crypto");
  const cat = await prisma.category.findFirst({
    where: { 
      name: { contains: name, mode: "insensitive" },
      shopType: shopType
    }
  });
  if (cat) return cat.id;
  
  const newCat = await prisma.category.create({
    data: {
      id: crypto.randomUUID(),
      name: name,
      shopType: shopType
    }
  });
  return newCat.id;
}

async function seedShopWithProducts(
  email: string,
  businessName: string,
  type: string,
  phone: string,
  lat: number,
  lng: number,
  addressStr: string,
  campaignText: string | null,
  categoriesAndProducts: {
    categoryName: string;
    products: { name: string; price: number; description?: string }[];
  }[],
  ratings: number[],
  comments: string[],
  consumerId: string,
  passwordHash: string,
  unitAdetId: string
) {
  // 1. Create/Update Merchant
  const merchant = await prisma.merchant.upsert({
    where: { email },
    update: { status: "ACTIVE", phone, passwordHash, merchantType: type as any },
    create: {
      email,
      passwordHash,
      businessName,
      phone,
      merchantType: type as any,
      status: "ACTIVE",
      role: "merchant",
      agreedToTerms: true,
      ownerFirstName: "Test",
      ownerLastName: "Merchant"
    }
  });

  // 2. Create/Update Shop
  const shop = await prisma.shop.upsert({
    where: { merchantId: merchant.id },
    update: {
      name: businessName,
      description: `${businessName} Hoppa özel dükkanı.`,
      isActive: true,
      type: type as any,
      latitude: lat,
      longitude: lng,
      address: addressStr,
      campaignText: campaignText,
      deliveryRadiusKm: 15.0,
      minOrderAmount: 100.0,
      baseDeliveryFee: 20.0,
      freeDeliveryThreshold: 400.0
    },
    create: {
      merchantId: merchant.id,
      name: businessName,
      description: `${businessName} Hoppa özel dükkanı.`,
      address: addressStr,
      campaignText: campaignText,
      minOrderAmount: 100.0,
      isActive: true,
      type: type as any,
      latitude: lat,
      longitude: lng,
      deliveryRadiusKm: 15.0,
      baseDeliveryFee: 20.0,
      freeDeliveryThreshold: 400.0
    }
  });

  // 3. Create products
  for (const catGroup of categoriesAndProducts) {
    const categoryId = await findCategoryByName(catGroup.categoryName, type);
    for (const p of catGroup.products) {
      await prisma.product.create({
        data: {
          shopId: shop.id,
          categoryId,
          unitId: unitAdetId,
          name: p.name,
          regularPrice: p.price,
          price: p.price,
          stockQuantity: 100,
          description: p.description || "",
          isActive: true
        }
      });
    }
  }

  // 4. Create reviews & calculate averageRating
  await prisma.review.deleteMany({ where: { shopId: shop.id } });
  
  let totalRating = 0;
  for (let i = 0; i < ratings.length; i++) {
    const rating = ratings[i];
    const comment = comments[i] || null;

    let address = await prisma.address.findFirst({ where: { userId: consumerId } });
    if (!address) {
      address = await prisma.address.create({
        data: {
          userId: consumerId,
          title: "Ev",
          city: "Gazimağusa",
          district: "Karakol",
          fullAddress: "Karakol, Gazimağusa",
          latitude: lat,
          longitude: lng
        }
      });
    }

    const order = await prisma.order.create({
      data: {
        consumerId: consumerId,
        shopId: shop.id,
        addressId: address.id,
        status: "DELIVERED",
        totalAmount: 150.0,
        deliveryAddress: address.fullAddress,
        deliveryFee: 15.0
      }
    });

    await prisma.review.create({
      data: {
        shopId: shop.id,
        userId: consumerId,
        orderId: order.id,
        rating,
        serviceRating: rating,
        speedRating: rating,
        tasteRating: rating,
        comment,
        status: "APPROVED"
      }
    });
    totalRating += rating;
  }

  const avg = ratings.length > 0 ? Number((totalRating / ratings.length).toFixed(1)) : 5.0;
  await prisma.shop.update({
    where: { id: shop.id },
    data: {
      averageRating: avg,
      reviewCount: ratings.length,
      avgServiceRating: avg,
      avgSpeedRating: avg,
      avgTasteRating: avg
    }
  });

  return shop.id;
}

// ============================================================================
// ANA ÇALIŞTIRMA FONKSİYONU
// ============================================================================

async function main() {
  console.log("🚀 Hoppa Profesyonel Veritabanı ve Kategori Tohumlama Başlatılıyor...");

  // 1. ESKİ ÜRÜNLERİ VE KATEGORİLERİ TEMİZLE
  await cleanStaleProductsAndCategories();

  // 2. STANDART BİRİMLERİ TOHUMLA
  await seedUnits();
  const unitAdet = await prisma.unit.findUnique({ where: { code: "ADET" } });
  if (!unitAdet) throw new Error("ADET birimi bulunamadı!");

  // 3. 4 ANA SEKTÖR HİYERARŞİK KATEGORİ AĞACINI TOHUMLA
  await seedRichCategories();

  // 4. TEST TÜKETİCİ KULLANICISI
  const testConsumer = await prisma.user.upsert({
    where: { phone: "+905338880000" },
    update: { name: "Ahmet", surname: "Yılmaz" },
    create: {
      phone: "+905338880000",
      email: "ahmet@test.com",
      name: "Ahmet",
      surname: "Yılmaz",
      role: "user"
    }
  });

  const passwordHash = await bcrypt.hash("123456", 10);

  // 5. 4 ANA SEKTÖR TEMSİLCİ İŞLETMELERİ
  const shopsData = [
    // 🛒 MARKET
    {
      email: "magusasupermarket@test.com",
      name: "Gazimağusa Süpermarket",
      type: "MARKET",
      phone: "+905338881111",
      lat: 35.1250,
      lng: 33.9350,
      address: "Salamis Yolu No: 12, Gazimağusa",
      campaign: "200 TL üzeri sepette 30 TL İndirim!",
      categories: [
        {
          categoryName: "Meyve & Sebze",
          products: [
            { name: "Muz Yerli (Kg)", price: 45.0, description: "Taze yerli Anamur muzu" },
            { name: "Domates Salkım (Kg)", price: 35.0, description: "Kırmızı taze salkım domates" }
          ]
        },
        {
          categoryName: "Süt & Kahvaltılık",
          products: [
            { name: "Tam Yağlı Süt 1L", price: 38.0, description: "Günlük taze pastörize süt" },
            { name: "Hellim Peyniri 250g", price: 85.0, description: "Geleneksel Kıbrıs köy hellimi" }
          ]
        },
        {
          categoryName: "Fırın & Unlu Mamuller",
          products: [
            { name: "Taş Fırın Somun Ekmek", price: 15.0, description: "Sıcak çıtır fırın ekmeği" }
          ]
        }
      ],
      ratings: [5, 5, 4],
      comments: ["Hızlı market teslimatı.", "Ürünler çok taze geldi."]
    },

    // 🍔 RESTORAN / YEMEK
    {
      email: "magusakebap@test.com",
      name: "Mağusa Kebap & Döner Sarayı",
      type: "RESTAURANT",
      phone: "+905338882222",
      lat: 35.1200,
      lng: 33.9400,
      address: "İsmet İnönü Bulvarı No: 45, Gazimağusa",
      campaign: "Tüm Dürümlerde İkinciye %50 İndirim!",
      categories: [
        {
          categoryName: "Kebap, Döner & Izgara",
          products: [
            { name: "Özel Yaprak Et Döner Dürüm", price: 180.0, description: "Lavaş arası yaprak et döner, patates, domates" },
            { name: "Adana Kebap Porsiyon", price: 260.0, description: "Közlenmiş biber, domates ve pilav eşliğinde" },
            { name: "Izgara Köfte Porsiyon", price: 220.0, description: "Özel kasap köftesi, patates kızartması ile" }
          ]
        },
        {
          categoryName: "Pide & Lahmacun",
          products: [
            { name: "Çıtır Lahmacun", price: 75.0, description: "İnce hamur, yeşillik ve limon ile" },
            { name: "Kaşarlı Kıymalı Pide", price: 190.0, description: "Özel fırınlanmış çıtır pide" }
          ]
        },
        {
          categoryName: "Tatlılar & Waffle",
          products: [
            { name: "Fıstıklı Künefe", price: 120.0, description: "Sıcak şerbetli ve kaymaklı" }
          ]
        }
      ],
      ratings: [5, 4, 5],
      comments: ["Döneri çok lezzetli ve sıcaktı.", "Porsiyonlar oldukça doyurucu."]
    },

    // 🍕 RESTORAN 2 (Pizza & Burger)
    {
      email: "bellaitalia@test.com",
      name: "Bella Italia Pizza & Burger",
      type: "RESTAURANT",
      phone: "+905338885555",
      lat: 35.1280,
      lng: 33.9310,
      address: "Doğu Akdeniz Cad. No: 18, Gazimağusa",
      campaign: "Büyük Boy Pizzalarda Kola Hediye!",
      categories: [
        {
          categoryName: "Pizza & İtalyan",
          products: [
            { name: "Margarita Pizza (Büyük)", price: 220.0, description: "Mozerella, özel domates sosu, fesleğen" },
            { name: "Karışık Süper Pizza", price: 270.0, description: "Sucuk, salam, mantar, zeytin, mısır, mozerella" }
          ]
        },
        {
          categoryName: "Burger & Sandviç",
          products: [
            { name: "Double Cheeseburger Menü", price: 240.0, description: "2x100g dana köfte, cheddar, patates ve içecek" }
          ]
        }
      ],
      ratings: [5, 5],
      comments: ["Pizzası harika çıtırdı.", "Kurye çok hızlı getirdi."]
    },

    // 💧 SU & İÇECEK
    {
      email: "kuzeysu@test.com",
      name: "Kuzey Su & Damacana Dağıtım",
      type: "WATER",
      phone: "+905338883333",
      lat: 35.1300,
      lng: 33.9300,
      address: "Sanayi Bölgesi 2. Sokak, Gazimağusa",
      campaign: "İlk Damacana Siparişine Pompa Hediye!",
      categories: [
        {
          categoryName: "Damacana Su",
          products: [
            { name: "19L Doğal Kaynak Suyu Damacana", price: 55.0, description: "Doğal kaynak suyu, pH 7.8" },
            { name: "15L Cam Damacana Su", price: 75.0, description: "Sağlıklı cam damacana dolumu" }
          ]
        },
        {
          categoryName: "Pet Şişe & Çoklu Paketler",
          products: [
            { name: "0.5L Su Kolisi (24'lü)", price: 90.0, description: "24 adet 0.5L pet şişe" },
            { name: "5L Pet Şişe Su (4'lü Paket)", price: 80.0, description: "4 adet 5L pet şişe" }
          ]
        },
        {
          categoryName: "Su Pompası & Ekipmanlar",
          products: [
            { name: "Şarjlı Otomatik Damacana Pompası", price: 180.0, description: "USB ile şarj edilebilir dokunmatik pompa" }
          ]
        }
      ],
      ratings: [5, 5],
      comments: ["15 dakikada kapıdaydı.", "Suyu çok lezzetli ve yumuşak."]
    },

    // 🌹 ÇİÇEK & HEDİYE
    {
      email: "kardelencicek@test.com",
      name: "Kardelen Çiçek & Tasarım Hediyelik",
      type: "FLOWER",
      phone: "+905338884444",
      lat: 35.1230,
      lng: 33.9380,
      address: "Karakol Mah. Çiçek Sokak No: 7, Gazimağusa",
      campaign: "Sevgililer Gününe Özel Kırmızı Güllerde İndirim!",
      categories: [
        {
          categoryName: "Tasarım Buketler",
          products: [
            { name: "11 Kırmızı Gül Buketi", price: 450.0, description: "Taze ekvator kırmızı güller ve özel kraft ambalaj" },
            { name: "Renkli Papatya Buketi", price: 280.0, description: "Bahar kokulu taze kır papatyaları" }
          ]
        },
        {
          categoryName: "Saksı Çiçekleri & İç Mekan Bitkileri",
          products: [
            { name: "Çift Dallı Beyaz Orkide", price: 550.0, description: "Seramik saksıda asil beyaz orkide" },
            { name: "Sukulent Aranjman Bahçesi", price: 240.0, description: "Özel ahşap kasede 4'lü sukulent" }
          ]
        },
        {
          categoryName: "Hediye & Özel Gün Setleri",
          products: [
            { name: "Gurme Çikolata & Peluş Ayıcık Seti", price: 320.0, description: "Özel kutulu lezzet çikolataları ve sevimli ayıcık" }
          ]
        }
      ],
      ratings: [5, 4],
      comments: ["Çiçekler capcanlı ve çok taze ulaştı.", "Not kartı da çok özenli yazılmıştı."]
    }
  ];

  const seededIds: { [email: string]: string } = {};

  for (const s of shopsData) {
    const shopId = await seedShopWithProducts(
      s.email,
      s.name,
      s.type,
      s.phone,
      s.lat,
      s.lng,
      s.address,
      s.campaign,
      s.categories,
      s.ratings,
      s.comments,
      testConsumer.id,
      passwordHash,
      unitAdet.id
    );
    seededIds[s.email] = shopId;
  }

  // 6. AKTİF KAMPANYALAR/SPONSORLUKLAR
  const start = new Date();
  const end = new Date();
  end.setDate(end.getDate() + 30);

  await prisma.shopPromotion.deleteMany({});

  if (seededIds["magusasupermarket@test.com"]) {
    await prisma.shopPromotion.create({
      data: {
        shopId: seededIds["magusasupermarket@test.com"],
        promoType: "MAIN_SCREEN",
        startDate: start,
        endDate: end,
        isActive: true
      }
    });
  }

  if (seededIds["magusakebap@test.com"]) {
    await prisma.shopPromotion.create({
      data: {
        shopId: seededIds["magusakebap@test.com"],
        promoType: "MAIN_SCREEN",
        startDate: start,
        endDate: end,
        isActive: true
      }
    });
  }

  console.log("✅ Shop Promotions (Sponsorships) seeded successfully.");

  // 7. KURYELER İÇİN ARAÇ SEÇENEKLERİ
  const vehicleOptions = [
    { 
      code: "MOTORCYCLE", 
      nameTr: "Motosiklet", nameEn: "Motorcycle", nameRu: "Мотоцикл",
      subTr: "A1-A2 Ehliyet", subEn: "License A1-A2", subRu: "Права A1-A2",
      isActive: true 
    },
    { 
      code: "CAR", 
      nameTr: "Araba", nameEn: "Car", nameRu: "Автомобиль",
      subTr: "Kendi Aracım", subEn: "My Own", subRu: "Свой",
      isActive: true 
    },
    { 
      code: "COMPANY_MOTORCYCLE", 
      nameTr: "Araç İstiyorum", nameEn: "Vehicle Wanted", nameRu: "Нужен транспорт",
      subTr: "Şirket Motosu", subEn: "Company Motorcycle", subRu: "Мотоцикл компании",
      isActive: false 
    },
    { 
      code: "BICYCLE", 
      nameTr: "Bisiklet / E-Bike", nameEn: "Bicycle / E-Bike", nameRu: "Велосипед / Электровелосипед",
      subTr: "Ehliyet Gerekmez", subEn: "No License Required", subRu: "Права не нужны",
      isActive: true 
    }
  ];

  for (const opt of vehicleOptions) {
    await prisma.vehicleOption.upsert({
      where: { code: opt.code },
      update: {
        nameTr: opt.nameTr,
        nameEn: opt.nameEn,
        nameRu: opt.nameRu,
        subTr: opt.subTr,
        subEn: opt.subEn,
        subRu: opt.subRu,
        isActive: opt.isActive
      },
      create: {
        code: opt.code,
        nameTr: opt.nameTr,
        nameEn: opt.nameEn,
        nameRu: opt.nameRu,
        subTr: opt.subTr,
        subEn: opt.subEn,
        subRu: opt.subRu,
        isActive: opt.isActive
      }
    });
  }
  console.log("✅ Vehicle Options Seeded successfully.");

  // 8. SUPABASE REALTIME REPLİKASYONU
  try {
    await prisma.$executeRawUnsafe(
      'ALTER PUBLICATION supabase_realtime ADD TABLE "CourierLocation";'
    );
    console.log("✅ Supabase Realtime replication enabled for CourierLocation table.");
  } catch (err: any) {
    console.log("ℹ️ Supabase Realtime replication notice (likely already active):", err.message || err);
  }
}

main()
  .catch((e) => {
    console.error("Seed error:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

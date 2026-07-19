import { PrismaClient } from "@prisma/client";
import bcrypt from "bcrypt";

const prisma = new PrismaClient();

const richCategories = [
  // RESTAURANT (YEMEK)
  {
    name: "Kebaplar & Izgaralar",
    shopType: "RESTAURANT",
    children: ["Adana & Urfa", "Dürümler", "Tavuk Şiş", "Karışık Izgara"]
  },
  {
    name: "Pide & Lahmacun",
    shopType: "RESTAURANT",
    children: ["Lahmacun", "Kıymalı Pide", "Kaşarlı Pide", "Karışık Pide"]
  },
  {
    name: "Pizza & Fast Food",
    shopType: "RESTAURANT",
    children: ["Pizzalar", "Hamburgerler", "Patates Kızartması", "Sandviçler"]
  },
  {
    name: "Ev Yemekleri & Çorbalar",
    shopType: "RESTAURANT",
    children: ["Çorbalar", "Zeytinyağlılar", "Ana Yemekler", "Pilav & Makarna"]
  },
  {
    name: "Tatlılar",
    shopType: "RESTAURANT",
    children: ["Şerbetli Tatlılar", "Sütlü Tatlılar", "Pastalar"]
  },
  {
    name: "İçecekler",
    shopType: "RESTAURANT",
    children: ["Gazlı İçecekler", "Su & Ayran", "Meyve Suları"]
  },

  // MARKET
  {
    name: "Temel Gıda",
    shopType: "MARKET",
    children: ["Bakliyat", "Sıvı Yağlar", "Şeker & Tuz", "Un & Makarna"]
  },
  {
    name: "Süt & Kahvaltılık",
    shopType: "MARKET",
    children: ["Peynir", "Zeytin", "Yumurta", "Tereyağı & Margarin", "Süt"]
  },
  {
    name: "Atıştırmalık",
    shopType: "MARKET",
    children: ["Bisküvi & Kek", "Çikolata & Gofret", "Cips & Kuruyemiş"]
  },
  {
    name: "Fırın",
    shopType: "MARKET",
    children: ["Ekmek", "Simit & Poğaça", "Unlu Mamuller"]
  },
  {
    name: "İçecekler",
    shopType: "MARKET",
    children: ["Gazlı İçecekler", "Meyve Suları", "Çay & Kahve", "Su & Maden Suyu"]
  },
  {
    name: "Temizlik & Hijyen",
    shopType: "MARKET",
    children: ["Deterjanlar", "Kağıt Ürünleri", "Kişisel Bakım"]
  },
  {
    name: "Sebzeler",
    shopType: "MARKET",
    children: ["Yeşillikler", "Patates & Soğan", "Domates & Biber", "Mevsim Sebzeleri"]
  },
  {
    name: "Meyveler",
    shopType: "MARKET",
    children: ["Narenciye", "Egzotik Meyveler", "Mevsim Meyveleri"]
  },
  {
    name: "Kırmızı Et",
    shopType: "MARKET",
    children: ["Dana Eti", "Kuzu Eti", "Kıymalar"]
  },
  {
    name: "Beyaz Et",
    shopType: "MARKET",
    children: ["Tavuk Eti", "Hindi Eti"]
  },

  // WATER (SU)
  {
    name: "Damacana Su",
    shopType: "WATER",
    children: ["19L Damacana", "Cam Damacana"]
  },
  {
    name: "Pet Şişe Su",
    shopType: "WATER",
    children: ["5L Su", "1.5L Su", "0.5L Su"]
  },

  // FLOWER (ÇİÇEK)
  {
    name: "Canlı Çiçekler",
    shopType: "FLOWER",
    children: ["Saksı Çiçekleri", "Buketler", "Güller"]
  },
  {
    name: "Yapay Çiçekler & Hediyelikler",
    shopType: "FLOWER",
    children: ["Yapay Çiçekler", "Çikolata & Balon"]
  }
];

async function seedRichCategories() {
  console.log("Seeding rich hierarchical categories...");
  for (const group of richCategories) {
    let root = await prisma.category.findFirst({
      where: {
        name: group.name,
        shopType: group.shopType,
        parentId: null
      }
    });
    
    if (!root) {
      root = await prisma.category.create({
        data: {
          id: require('crypto').randomUUID(),
          name: group.name,
          shopType: group.shopType,
          parentId: null
        }
      });
    }
    
    for (const childName of group.children) {
      const child = await prisma.category.findFirst({
        where: {
          name: childName,
          shopType: group.shopType,
          parentId: root.id
        }
      });
      
      if (!child) {
        await prisma.category.create({
          data: {
            id: require('crypto').randomUUID(),
            name: childName,
            shopType: group.shopType,
            parentId: root.id
          }
        });
      }
    }
  }
  console.log("✅ Hierarchical categories seeded successfully.");
}

async function findCategoryByName(name: string, shopType: string): Promise<string> {
  const cat = await prisma.category.findFirst({
    where: { 
      name: { contains: name, mode: 'insensitive' },
      shopType: shopType
    }
  });
  if (cat) return cat.id;
  
  const newCat = await prisma.category.create({
    data: {
      id: require('crypto').randomUUID(),
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
    categoryName: string,
    products: { name: string, price: number, description?: string }[]
  }[],
  ratings: number[],
  comments: string[],
  consumerId: string,
  passwordHash: string,
  unitAdetId: string
) {
  // 1. Create Merchant
  const merchant = await prisma.merchant.upsert({
    where: { email },
    update: { status: "ACTIVE", phone, passwordHash },
    create: {
      email,
      passwordHash,
      businessName,
      phone,
      status: "ACTIVE",
      role: "merchant",
      agreedToTerms: true,
      ownerFirstName: "Test",
      ownerLastName: "Merchant"
    }
  });

  // 2. Create Shop
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
      const existing = await prisma.product.findFirst({
        where: { shopId: shop.id, name: p.name }
      });
      if (!existing) {
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
  }

  // 4. Create reviews & calculate averageRating
  const existingReviews = await prisma.review.findMany({ where: { shopId: shop.id } });
  if (existingReviews.length < ratings.length) {
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
          consumerId,
          shopId: shop.id,
          addressId: address.id,
          deliveryAddress: addressStr,
          totalAmount: 150.0,
          status: "DELIVERED",
          paymentMethod: "CASH_ON_DELIVERY",
          paymentStatus: "SUCCESS"
        }
      });

      await prisma.review.create({
        data: {
          rating,
          comment,
          userId: consumerId,
          shopId: shop.id,
          orderId: order.id
        }
      });
      totalRating += rating;
    }

    await prisma.shop.update({
      where: { id: shop.id },
      data: {
        averageRating: parseFloat((totalRating / ratings.length).toFixed(2)),
        reviewCount: ratings.length
      }
    });
  }

  console.log(`✅ Seeded Shop: ${businessName} (Rating: ${(ratings.reduce((a,b)=>a+b,0)/ratings.length).toFixed(1)})`);
  return shop.id;
}

async function main() {
  console.log("Cleaning old data...");
  await prisma.shopPromotion.deleteMany();
  await prisma.review.deleteMany();
  await prisma.orderItemOption.deleteMany();
  await prisma.orderItem.deleteMany();
  await prisma.paymentTransaction.deleteMany();
  await prisma.order.deleteMany();
  await prisma.product.deleteMany();
  await prisma.shop.deleteMany();
  await prisma.merchant.deleteMany();
  
  await prisma.address.deleteMany();
  await prisma.deviceToken.deleteMany();
  await prisma.savedCard.deleteMany();
  await prisma.favoriteProduct.deleteMany();
  await prisma.favoriteShop.deleteMany();
  await prisma.walletTransaction.deleteMany();
  await prisma.wallet.deleteMany();
  await prisma.courier.deleteMany();
  
  await prisma.user.deleteMany({ where: { role: { not: "SUPER_ADMIN" } } });
  console.log("✅ Database cleaned.");

  const passwordHash = await bcrypt.hash("123456", 12);

  // Seed rich categories
  await seedRichCategories();

  // 1. SUPER ADMIN OLUŞTUR
  const superAdmin = await prisma.user.upsert({
    where: { phone: "+905550000000" },
    update: { role: "SUPER_ADMIN" },
    create: {
      phone: "+905550000000",
      role: "SUPER_ADMIN",
      name: "Super",
      surname: "Admin",
    },
  });
  console.log("✅ Super Admin User Created:", superAdmin.phone);

  const adminMerchant = await prisma.merchant.upsert({
    where: { email: "admin@test.com" },
    update: {
      status: "ACTIVE",
      phone: "+905550000000",
      role: "super_admin",
    },
    create: {
      email: "admin@test.com",
      passwordHash: passwordHash,
      businessName: "Sistem Yönetimi",
      phone: "+905550000000",
      status: "ACTIVE",
      role: "super_admin",
      agreedToTerms: true,
      ownerFirstName: "Super",
      ownerLastName: "Admin",
    },
  });
  console.log("✅ Super Admin Merchant Account Created:", adminMerchant.email);

  // 2. KURYEYİ OLUŞTUR
  const courierUser = await prisma.user.create({
    data: {
      phone: "+905555555555",
      role: "courier",
      name: "Süleyman",
      surname: "Kurye",
    }
  });

  const defaultCourier = await prisma.courier.upsert({
    where: { phoneNumber: "+905555555555" },
    update: { userId: courierUser.id },
    create: {
      userId: courierUser.id,
      name: "Süleyman Kurye",
      phoneNumber: "+905555555555",
      vehiclePlate: "34 HO 9999",
      isActive: true,
    },
  });
  console.log("✅ Default Courier Created:", defaultCourier.name);

  // 3. TÜKETİCİ KULLANICISINI OLUŞTUR
  const testConsumer = await prisma.user.create({
    data: {
      phone: "+905553333333",
      role: "user",
      name: "Tuna",
      surname: "Kabak",
    },
  });
  console.log("✅ Consumer User Created:", testConsumer.name);

  // 4. BİRİMLERİ OLUŞTUR
  let unitAdet = await prisma.unit.findUnique({ where: { code: "ADET" } });
  if (!unitAdet) {
    unitAdet = await prisma.unit.create({ data: { code: "ADET", nameTr: "Adet", nameEn: "Pieces" } });
  }

  // 5. İŞLETME KATEGORİLERİ (Home Screen Buttons) OLUŞTUR
  const businessCategories = [
    { name: "Market", icon: "shopping_basket", color: "#00B359", subtitle: "Market alışverişi", avgDeliveryTime: "20-30 dk", badge: "popular", imageUrl: "/uploads/market_bg.png", order: 0 },
    { name: "Yemek", icon: "restaurant", color: "#E53935", subtitle: "Yemek siparişi", avgDeliveryTime: "25-35 dk", badge: "popular", imageUrl: "/uploads/restaurant_bg.png", order: 1 },
    { name: "Su", icon: "water_drop", color: "#0288D1", subtitle: "Su ve içecek", avgDeliveryTime: "15-25 dk", badge: null, imageUrl: "/uploads/su_bg.png", order: 2 },
    { name: "Çiçek", icon: "local_florist", color: "#EC407A", subtitle: "Çiçek siparişi", avgDeliveryTime: "30-45 dk", badge: null, imageUrl: "/uploads/cicek_bg.png", order: 3 },
  ];

  await prisma.businessCategory.deleteMany();
  for (const cat of businessCategories) {
    await prisma.businessCategory.create({
      data: cat
    });
  }
  console.log("✅ Business Categories seeded successfully.");

  // 6. KKTC KONUMLU DÜKKAN TOHUMLARINI BAŞLAT
  const shopsData = [
    // --- RESTAURANTS ---
    {
      email: "magusakebap@test.com",
      name: "Mağusa Kebap Dünyası",
      type: "RESTAURANT",
      phone: "+905338880001",
      lat: 35.1250,
      lng: 33.9380,
      address: "Gazi Mustafa Kemal Bulvarı, Gazimağusa",
      campaign: "Seçili Kebaplarda %15 İndirim!",
      categories: [
        {
          categoryName: "Kebaplar & Izgaralar",
          products: [
            { name: "Kuzu Şiş", price: 320.0, description: "Közlenmiş domates ve biber ile" },
            { name: "Adana Kebap", price: 290.0, description: "Lavaş ve soğan piyazı ile" }
          ]
        },
        {
          categoryName: "Pide & Lahmacun",
          products: [
            { name: "Kıymalı Pide", price: 180.0, description: "Kaşarlı ve kıymalı çıtır pide" },
            { name: "Antep Lahmacun", price: 80.0, description: "Bol malzemeli çıtır lahmacun" }
          ]
        },
        {
          categoryName: "Tatlılar",
          products: [
            { name: "Fıstıklı Künefe", price: 150.0, description: "Sıcak ve şerbetli künefe" }
          ]
        }
      ],
      ratings: [5, 5, 4],
      comments: ["Kebaplar enfes!", "Çok lezzetli ve hızlı geldi.", "Lahmacun sıcaktı."]
    },
    {
      email: "bogazicipide@test.com",
      name: "Yeniboğaziçi Pide & Lahmacun",
      type: "RESTAURANT",
      phone: "+905338880002",
      lat: 35.1950,
      lng: 33.9050,
      address: "Salamis Yolu, Yeniboğaziçi",
      campaign: "2 Lahmacun Alana 1 Ayran Bedava!",
      categories: [
        {
          categoryName: "Pide & Lahmacun",
          products: [
            { name: "Kuşbaşılı Pide", price: 200.0, description: "Taze kuzu eti ve kaşar ile" },
            { name: "Sade Lahmacun", price: 70.0, description: "Klasik çıtır lahmacun" }
          ]
        },
        {
          categoryName: "Pizza & Fast Food",
          products: [
            { name: "Karışık Pizza", price: 220.0, description: "Sucuk, sosis, mısır, zeytin" }
          ]
        },
        {
          categoryName: "Ev Yemekleri & Çorbalar",
          products: [
            { name: "Süzme Mercimek Çorbası", price: 80.0, description: "Kıtır ekmek ve limon ile" }
          ]
        }
      ],
      ratings: [5, 4],
      comments: ["Hızlı servis, güzel lahmacun.", "Pideler sıcak ve çıtırdı."]
    },
    {
      email: "iskelebalik@test.com",
      name: "İskele Sahil Balık & Meze",
      type: "RESTAURANT",
      phone: "+905338880003",
      lat: 35.2750,
      lng: 33.8950,
      address: "Sahil Yolu, İskele",
      campaign: "Mezelerde 3 Al 2 Öde Fırsatı!",
      categories: [
        {
          categoryName: "Kebaplar & Izgaralar",
          products: [
            { name: "Izgara Çipura", price: 380.0, description: "Akdeniz yeşillikleri ile" },
            { name: "Kalamar Tava", price: 250.0, description: "Tarator sos eşliğinde" }
          ]
        },
        {
          categoryName: "Ev Yemekleri & Çorbalar",
          products: [
            { name: "Balık Çorbası", price: 110.0, description: "Özel şef çorbası" }
          ]
        },
        {
          categoryName: "İçecekler",
          products: [
            { name: "Şalgam Suyu 1L", price: 40.0, description: "Acılı veya acısız şalgam" }
          ]
        }
      ],
      ratings: [5, 5],
      comments: ["Balıklar taptaze ve lezzetli.", "Kalamar harikaydı, servis başarılı."]
    },
    // --- MARKETS ---
    {
      email: "magusasupermarket@test.com",
      name: "Mağusa Merkez Süpermarket",
      type: "MARKET",
      phone: "+905338880004",
      lat: 35.1420,
      lng: 33.9180,
      address: "Karakol Bölgesi, Gazimağusa",
      campaign: "Temel Gıdada Büyük Hafta Sonu İndirimi!",
      categories: [
        {
          categoryName: "Temel Gıda",
          products: [
            { name: "Pilavlık Pirinç 1 Kg", price: 45.0, description: "Pilavlık ithal pirinç" },
            { name: "Sızma Zeytinyağı 1L", price: 290.0, description: "Kızıltepe soğuk sıkım zeytinyağı" }
          ]
        },
        {
          categoryName: "Süt & Kahvaltılık",
          products: [
            { name: "Ezine Peyniri 500g", price: 130.0, description: "Tam yağlı olgunlaştırılmış peynir" },
            { name: "Siyah Zeytin 500g", price: 95.0, description: "Gemlik doğal zeytin" }
          ]
        },
        {
          categoryName: "Atıştırmalık",
          products: [
            { name: "Sütlü Çikolata", price: 25.0, description: "Fıstıklı sütlü tablet çikolata" }
          ]
        }
      ],
      ratings: [5, 4, 5],
      comments: ["Aradığım her şey var.", "Kurye çok hızlı getirdi.", "Ürünler taze ve eksiksiz."]
    },
    {
      email: "bogazicimarket@test.com",
      name: "Yeniboğaziçi Koop Market",
      type: "MARKET",
      phone: "+905338880005",
      lat: 35.1980,
      lng: 33.9010,
      address: "Atatürk Caddesi, Yeniboğaziçi",
      campaign: "Manav Ürünlerinde Net %20 İndirim!",
      categories: [
        {
          categoryName: "Sebzeler",
          products: [
            { name: "Salkım Domates 1 Kg", price: 35.0, description: "Taze salkım sera domatesi" },
            { name: "Patates 1 Kg", price: 20.0, description: "Kızartmalık patates" }
          ]
        },
        {
          categoryName: "Meyveler",
          products: [
            { name: "Mandalina 1 Kg", price: 30.0, description: "Yerli sulu mandalina" }
          ]
        },
        {
          categoryName: "Fırın",
          products: [
            { name: "Köy Ekmeği", price: 25.0, description: "Taş fırında pişmiş köy ekmeği" }
          ]
        }
      ],
      ratings: [5, 5],
      comments: ["Sebze meyveler aşırı taze.", "Koop kalitesi tartışılmaz."]
    },
    {
      email: "iskelemarket@test.com",
      name: "İskele Long Beach Market",
      type: "MARKET",
      phone: "+905338880006",
      lat: 35.2300,
      lng: 33.9050,
      address: "Long Beach Bulvarı, İskele",
      campaign: "500 TL Üzeri Alışverişe Ücretsiz Kargo!",
      categories: [
        {
          categoryName: "Atıştırmalık",
          products: [
            { name: "Karışık Çerez 200g", price: 80.0, description: "Fındık, badem, kaju karışık" },
            { name: "Patates Cipsi Klasik", price: 35.0, description: "Aile boyu tuzlu patates cipsi" }
          ]
        },
        {
          categoryName: "İçecekler",
          products: [
            { name: "Soğuk Çay Şeftali 1.5L", price: 38.0, description: "Ferahlatıcı soğuk şeftali çayı" }
          ]
        },
        {
          categoryName: "Temizlik & Hijyen",
          products: [
            { name: "Sıvı Sabun 500ml", price: 45.0, description: "Nemlendirici zeytinyağlı sıvı sabun" }
          ]
        }
      ],
      ratings: [5, 4],
      comments: ["Hızlı ve temiz getirdiler.", "Long beach için cankurtaran."]
    },
    // --- WATER SHOPS ---
    {
      email: "magusaozsu@test.com",
      name: "Mağusa Özsu Damacana",
      type: "WATER",
      phone: "+905338880007",
      lat: 35.1300,
      lng: 33.9350,
      address: "Topçu Bulvarı, Gazimağusa",
      campaign: "İlk Damacana Siparişine Özel Depozito Bizden!",
      categories: [
        {
          categoryName: "Damacana Su",
          products: [
            { name: "19L Damacana Su", price: 75.0, description: "Polikarbonat damacana su dolumu" },
            { name: "Cam Damacana 19L", price: 95.0, description: "Doğal cam şişe damacana dolumu" }
          ]
        },
        {
          categoryName: "Pet Şişe Su",
          products: [
            { name: "5L Su", price: 25.0, description: "Pratik pet şişe su" }
          ]
        },
        {
          categoryName: "İçecekler",
          products: [
            { name: "Doğal Maden Suyu 6'lı", price: 45.0, description: "Kızılay doğal maden suyu" }
          ]
        }
      ],
      ratings: [5, 5, 5],
      comments: ["Servis süper hızlı, damacana temizdi.", "Su kalitesi çok iyi.", "Sıcak günde hızlıca getirdiler."]
    },
    {
      email: "bogazicisu@test.com",
      name: "Yeniboğaziçi Su Dağıtım",
      type: "WATER",
      phone: "+905338880008",
      lat: 35.1920,
      lng: 33.9080,
      address: "Salamis Sitesi Çevresi, Yeniboğaziçi",
      campaign: "3 Damacana Alana 1 Tane Bedava!",
      categories: [
        {
          categoryName: "Damacana Su",
          products: [
            { name: "19L Damacana Su", price: 75.0, description: "Yeniboğaziçi hızlı dolum" }
          ]
        },
        {
          categoryName: "Pet Şişe Su",
          products: [
            { name: "1.5L Su 6'lı Paket", price: 48.0, description: "6 adet 1.5L pet şişe" },
            { name: "0.5L Su 24'lü Koli", price: 75.0, description: "24 adet pratik 0.5L su" }
          ]
        },
        {
          categoryName: "İçecekler",
          products: [
            { name: "Limonata 1L", price: 40.0, description: "El yapımı ferah limonata" }
          ]
        }
      ],
      ratings: [5, 4],
      comments: ["Hızlı getirdiler.", "Limonatası efsane lezzetli."]
    },
    {
      email: "iskelecansu@test.com",
      name: "İskele Can Su",
      type: "WATER",
      phone: "+905338880009",
      lat: 35.2700,
      lng: 33.8900,
      address: "Belediye Caddesi, İskele",
      campaign: "Hızlı Teslimat Garantili Damacana!",
      categories: [
        {
          categoryName: "Damacana Su",
          products: [
            { name: "19L Damacana Su", price: 75.0, description: "Doğal kaynak suyu dolumu" }
          ]
        },
        {
          categoryName: "Pet Şişe Su",
          products: [
            { name: "5L Su 4'lü Paket", price: 90.0, description: "4 adet 5L pet şişe" }
          ]
        },
        {
          categoryName: "İçecekler",
          products: [
            { name: "Tonik 4'lü", price: 55.0, description: "Ferahlatıcı tonik paketi" }
          ]
        }
      ],
      ratings: [5, 5],
      comments: ["15 dakikada kapıdaydı.", "Çok kibar kurye."]
    },
    // --- FLOWER SHOPS ---
    {
      email: "magusacicek@test.com",
      name: "Mağusa Çiçek Bahçesi",
      type: "FLOWER",
      phone: "+905338880010",
      lat: 35.1350,
      lng: 33.9280,
      address: "Karakol Sokak, Gazimağusa",
      campaign: "Kırmızı Güllerde Net %25 İndirim!",
      categories: [
        {
          categoryName: "Canlı Çiçekler",
          products: [
            { name: "Kırmızı Gül Buketi (11 adet)", price: 450.0, description: "Taze kesilmiş güller" },
            { name: "Renkli Lale Buketi", price: 380.0, description: "Baharın habercisi laleler" }
          ]
        },
        {
          categoryName: "Yapay Çiçekler & Hediyelikler",
          products: [
            { name: "Peluş Ayıcık Hediyeli", price: 200.0, description: "Şirin beyaz ayıcık" }
          ]
        },
        {
          categoryName: "Fırın",
          products: [
            { name: "Çikolatalı Çilek Kutusu", price: 280.0, description: "Bitter çikolata kaplı çilekler" }
          ]
        }
      ],
      ratings: [5, 5, 4],
      comments: ["Buket çok özenliydi.", "Eşime sürpriz yaptık, çok sevdi.", "Güller taptazeydi."]
    },
    {
      email: "bogazicicicek@test.com",
      name: "Yeniboğaziçi Butik Çiçek",
      type: "FLOWER",
      phone: "+905338880011",
      lat: 35.2000,
      lng: 33.9000,
      address: "Salamis Yolu Çıkışı, Yeniboğaziçi",
      campaign: "Tüm Saksı Çiçeklerinde Toprak Hediyeli!",
      categories: [
        {
          categoryName: "Canlı Çiçekler",
          products: [
            { name: "Orkide Saksı (Çift Dallı)", price: 650.0, description: "Şık saksısında beyaz orkide" },
            { name: "Aloe Vera Saksı", price: 150.0, description: "Ev ve ofis için arındırıcı aloe vera" }
          ]
        },
        {
          categoryName: "Yapay Çiçekler & Hediyelikler",
          products: [
            { name: "Sonsuz Gül Fanus", price: 350.0, description: "solmayan şık fanus gülü" }
          ]
        },
        {
          categoryName: "Ev Yemekleri & Çorbalar",
          products: [
            { name: "Dekoratif Taş Saksı", price: 120.0, description: "Modern saksı" }
          ]
        }
      ],
      ratings: [5, 5],
      comments: ["Orkide harika paketlenmişti.", "Çok tatlı bir çiçekçi."]
    },
    {
      email: "iskeleflower@test.com",
      name: "İskele Papatya Çiçekçilik",
      type: "FLOWER",
      phone: "+905338880012",
      lat: 35.2780,
      lng: 33.8980,
      address: "Merkez Yolu, İskele",
      campaign: "Açılışa Özel Tüm Buketlerde %10 İndirim!",
      categories: [
        {
          categoryName: "Canlı Çiçekler",
          products: [
            { name: "Papatya Aşkı Buketi", price: 290.0, description: "Taze kır papatyaları" }
          ]
        },
        {
          categoryName: "Yapay Çiçekler & Hediyelikler",
          products: [
            { name: "Kokulu Mum Seti", price: 140.0, description: "Lavanta ve vanilya kokulu mumlar" }
          ]
        },
        {
          categoryName: "İçecekler",
          products: [
            { name: "Balon Buketi (3'lü)", price: 90.0, description: "folyo balonlar" }
          ]
        }
      ],
      ratings: [5, 4],
      comments: ["Hızlı ve güzel teslimat.", "Papatyalar çok güzel kokuyordu."]
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

  // 7. AKTİF KAMPANYALAR/SPONSORLUKLAR TOHUMLA
  const start = new Date();
  const end = new Date();
  end.setDate(end.getDate() + 30);

  await prisma.shopPromotion.create({
    data: {
      shopId: seededIds["magusakebap@test.com"],
      promoType: "MAIN_SCREEN",
      startDate: start,
      endDate: end,
      isActive: true
    }
  });

  await prisma.shopPromotion.create({
    data: {
      shopId: seededIds["magusasupermarket@test.com"],
      promoType: "MAIN_SCREEN",
      startDate: start,
      endDate: end,
      isActive: true
    }
  });

  await prisma.shopPromotion.create({
    data: {
      shopId: seededIds["bogazicipide@test.com"],
      promoType: "CATEGORY",
      startDate: start,
      endDate: end,
      isActive: true
    }
  });

  await prisma.shopPromotion.create({
    data: {
      shopId: seededIds["iskelemarket@test.com"],
      promoType: "CATEGORY",
      startDate: start,
      endDate: end,
      isActive: true
    }
  });

  console.log("✅ Shop Promotions (Sponsorships) seeded successfully.");

  // 8. KURYELER İÇİN ARAÇ SEÇENEKLERİNİ TOHUMLA
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
      nameTr: "Araç İstiyorum", nameEn: "Vehicle Wanted", nameRu: "Нужен transport",
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

  // 9. SUPABASE REALTIME REPLİKASYONUNU AKTİF ET
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

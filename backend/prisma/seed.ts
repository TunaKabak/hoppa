import { PrismaClient } from "@prisma/client";
import bcrypt from "bcrypt";

const prisma = new PrismaClient();

async function findCategoryByName(name: string, shopType: string): Promise<string> {
  const cat = await prisma.category.findFirst({
    where: { 
      name: { equals: name, mode: 'insensitive' },
      shopType: shopType
    }
  });
  if (cat) return cat.id;
  
  // Create if not found
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
      isActive: true,
      type: type as any,
      latitude: 35.1856,
      longitude: 33.3823,
      deliveryRadiusKm: 5.0,
      minOrderAmount: 100.0,
      baseDeliveryFee: 20.0,
      freeDeliveryThreshold: 400.0
    },
    create: {
      merchantId: merchant.id,
      name: businessName,
      description: `${businessName} Hoppa özel dükkanı.`,
      address: "Lefkoşa, KKTC",
      minOrderAmount: 100.0,
      isActive: true,
      type: type as any,
      latitude: 35.1856,
      longitude: 33.3823,
      deliveryRadiusKm: 5.0,
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
            city: "Lefkoşa",
            district: "Ortaköy",
            fullAddress: "Test Adresi",
            latitude: 35.1856,
            longitude: 33.3823
          }
        });
      }

      const order = await prisma.order.create({
        data: {
          consumerId,
          shopId: shop.id,
          addressId: address.id,
          deliveryAddress: "Ortaköy, Lefkoşa",
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
}

async function main() {
  console.log("Seeding database with Test Users and Shops...");

  const passwordHash = await bcrypt.hash("123456", 12);

  // 1. SUPER ADMIN OLUŞTUR (User tablosu)
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

  // 1.1 SUPER ADMIN MERCHANT HESABI OLUŞTUR (Merchant tablosu)
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

  // 2. HAZIR ONAYLI MERCHANT USER'I OLUŞTUR (User tablosunda)
  const merchantUser = await prisma.user.upsert({
    where: { phone: "+905551111111" },
    update: { role: "MERCHANT" },
    create: {
      phone: "+905551111111",
      role: "MERCHANT",
      name: "Test",
      surname: "Merchant",
    },
  });
  console.log("✅ Merchant User Created:", merchantUser.phone);

  // 3. MERCHANT MODELİ OLUŞTUR (Merchant tablosunda login olabilmesi için)
  const merchant = await prisma.merchant.upsert({
    where: { email: "merchant@test.com" },
    update: {
      status: "ACTIVE",
      phone: "+905551111111",
      passwordHash: passwordHash,
    },
    create: {
      email: "merchant@test.com",
      passwordHash: passwordHash,
      businessName: "Test Kebap & Lahmacun",
      phone: "+905551111111",
      status: "ACTIVE", // Onaylanmış
      role: "merchant",
      agreedToTerms: true,
      ownerFirstName: "Test",
      ownerLastName: "Merchant",
    },
  });
  console.log("✅ Merchant Account Created:", merchant.email);

  // 4. MERCHANT İÇİN ONAYLI VE AKTİF BİR DÜKKAN OLUŞTUR
  const testShop = await prisma.shop.upsert({
    where: { merchantId: merchant.id },
    update: { 
      isActive: true,
      type: "RESTAURANT",
      latitude: 35.1856,
      longitude: 33.3823,
      deliveryRadiusKm: 5.0,
      minOrderAmount: 150.0,
      minimumOrderAmount: 150.0,
      baseDeliveryFee: 30.0,
      freeDeliveryThreshold: 500.0,
    },
    create: {
      merchantId: merchant.id,
      name: "Test Kebap & Lahmacun",
      description: "E2E testleri için otomatik oluşturulmuş hazır dükkan.",
      address: "Lefkoşa, KKTC",
      minOrderAmount: 150.0,
      minimumOrderAmount: 150.0,
      baseDeliveryFee: 30.0,
      freeDeliveryThreshold: 500.0,
      isActive: true, // Dükkan siparişe açık
      type: "RESTAURANT",
      latitude: 35.1856,
      longitude: 33.3823,
      deliveryRadiusKm: 5.0,
    },
  });
  console.log("✅ Test Shop Created:", testShop.name);

  // 4.1 İLK 5 SİPARİŞ BEDAVA KAMPANYASI OLUŞTUR
  await prisma.campaign.deleteMany({
    where: { title: "İlk 5 Sipariş Bedava" }
  });
  const firstOrdersCampaign = await prisma.campaign.create({
    data: {
      title: "İlk 5 Sipariş Bedava",
      description: "Hoppa'ya özel ilk 5 siparişinizde teslimat ücreti bizden!",
      type: "FREE_DELIVERY_FIRST_ORDERS",
      isActive: true,
      maxUsesPerUser: 5,
      imageUrl: "https://images.unsplash.com/photo-1508962914676-134849a727f0?auto=format&fit=crop&w=600&q=80",
    }
  });
  console.log("✅ Campaign Created:", firstOrdersCampaign.title);

  // 5. YENİ BİR SÜPERMARKET MERCHANT OLUŞTUR
  const marketUser = await prisma.user.upsert({
    where: { phone: "+905552222222" },
    update: { role: "MERCHANT" },
    create: {
      phone: "+905552222222",
      role: "MERCHANT",
      name: "Test",
      surname: "MarketOwner",
    },
  });
  console.log("✅ Market Merchant User Created:", marketUser.phone);

  const marketMerchant = await prisma.merchant.upsert({
    where: { email: "market@test.com" },
    update: {
      status: "ACTIVE",
      phone: "+905552222222",
      passwordHash: passwordHash,
    },
    create: {
      email: "market@test.com",
      passwordHash: passwordHash,
      businessName: "Test Süpermarket",
      phone: "+905552222222",
      status: "ACTIVE",
      role: "merchant",
      agreedToTerms: true,
      ownerFirstName: "Test",
      ownerLastName: "Market",
      merchantType: "MARKET",
    },
  });
  console.log("✅ Market Merchant Account Created:", marketMerchant.email);

  // 6. MARKET İÇİN ONAYLI VE AKTİF BİR DÜKKAN OLUŞTUR
  const testMarketShop = await prisma.shop.upsert({
    where: { merchantId: marketMerchant.id },
    update: { 
      isActive: true,
      type: "MARKET",
      latitude: 35.1856,
      longitude: 33.3823,
      deliveryRadiusKm: 10.0,
    },
    create: {
      merchantId: marketMerchant.id,
      name: "Test Süpermarket",
      description: "E2E testleri için otomatik oluşturulmuş hazır market dükkanı.",
      address: "Lefkoşa, KKTC",
      minOrderAmount: 100.0,
      isActive: true, // Dükkan siparişe açık
      type: "MARKET",
      latitude: 35.1856,
      longitude: 33.3823,
      deliveryRadiusKm: 10.0,
    },
  });
  console.log("✅ Test Market Shop Created:", testMarketShop.name);

  // 7. SÜPERMARKET VE RESTORAN ALTINA ÜRÜNLERİ EKLE
  let unitAdet = await prisma.unit.findUnique({ where: { code: "ADET" } });
  if (!unitAdet) {
    unitAdet = await prisma.unit.create({ data: { code: "ADET", nameTr: "Adet", nameEn: "Pieces" } });
  }

  const catKebapId = await findCategoryByName("Kebaplar", "RESTAURANT");
  const catIcecekId = await findCategoryByName("İçecekler", "MARKET");
  const catSutId = await findCategoryByName("Süt & Kahvaltılık", "MARKET");
  const catFirinId = await findCategoryByName("Fırın", "MARKET");

  const restaurantProducts = [
    { name: "Adana Kebap", price: 280.0, stock: 99, description: "Közlenmiş domates ve biber ile", categoryId: catKebapId },
    { name: "Urfa Kebap", price: 280.0, stock: 99, description: "Közlenmiş domates ve biber ile", categoryId: catKebapId },
  ];

  const marketProducts = [
    { name: "1 Litre Su", price: 10.0, stock: 100, description: "Doğal kaynak suyu", categoryId: catIcecekId },
    { name: "Taze Ekmek", price: 15.0, stock: 50, description: "Günlük taze ekmek", categoryId: catFirinId },
    { name: "Günlük Süt", price: 45.0, stock: 30, description: "Pastörize günlük süt", categoryId: catSutId },
  ];

  for (const p of restaurantProducts) {
    const existing = await prisma.product.findFirst({
      where: { shopId: testShop.id, name: p.name }
    });
    if (!existing) {
      await prisma.product.create({
        data: {
          shopId: testShop.id,
          categoryId: p.categoryId,
          unitId: unitAdet.id,
          name: p.name,
          regularPrice: p.price,
          price: p.price,
          stockQuantity: p.stock,
          description: p.description,
          isActive: true,
        }
      });
    }
  }

  for (const p of marketProducts) {
    const existing = await prisma.product.findFirst({
      where: { shopId: testMarketShop.id, name: p.name }
    });
    if (!existing) {
      await prisma.product.create({
        data: {
          shopId: testMarketShop.id,
          categoryId: p.categoryId,
          unitId: unitAdet.id,
          name: p.name,
          regularPrice: p.price,
          price: p.price,
          stockQuantity: p.stock,
          description: p.description,
          isActive: true,
        }
      });
    }
  }
  console.log("✅ Shop Products Seeded successfully.");

  // 8. DEFAULT KURYEYİ OLUŞTUR
  const defaultCourier = await prisma.courier.upsert({
    where: { phoneNumber: "+905555555555" },
    update: {},
    create: {
      name: "Süleyman Kurye",
      phoneNumber: "+905555555555",
      vehiclePlate: "34 HO 9999",
      isActive: true,
    },
  });
  console.log("✅ Default Courier Created:", defaultCourier.name);

  // Create testConsumer user for writing reviews
  const testConsumer = await prisma.user.upsert({
    where: { phone: "+905553333333" },
    update: { role: "user" },
    create: {
      phone: "+905553333333",
      role: "user",
      name: "Tuna",
      surname: "Kabak",
    },
  });

  // Seed reviews for Test Kebap & Lahmacun
  const existingTestShopReviews = await prisma.review.findMany({ where: { shopId: testShop.id } });
  if (existingTestShopReviews.length === 0) {
    let address = await prisma.address.findFirst({ where: { userId: testConsumer.id } });
    if (!address) {
      address = await prisma.address.create({
        data: {
          userId: testConsumer.id,
          title: "Ev",
          city: "Lefkoşa",
          district: "Ortaköy",
          fullAddress: "Test Adresi",
          latitude: 35.1856,
          longitude: 33.3823
        }
      });
    }

    const order1 = await prisma.order.create({
      data: {
        consumerId: testConsumer.id,
        shopId: testShop.id,
        addressId: address.id,
        deliveryAddress: "Ortaköy, Lefkoşa",
        totalAmount: 280.0,
        status: "DELIVERED",
        paymentMethod: "CASH_ON_DELIVERY",
        paymentStatus: "SUCCESS"
      }
    });
    await prisma.review.create({
      data: {
        rating: 5,
        comment: "Mükemmel kebaplar, sıcacık geldi!",
        userId: testConsumer.id,
        shopId: testShop.id,
        orderId: order1.id
      }
    });

    const order2 = await prisma.order.create({
      data: {
        consumerId: testConsumer.id,
        shopId: testShop.id,
        addressId: address.id,
        deliveryAddress: "Ortaköy, Lefkoşa",
        totalAmount: 280.0,
        status: "DELIVERED",
        paymentMethod: "CASH_ON_DELIVERY",
        paymentStatus: "SUCCESS"
      }
    });
    await prisma.review.create({
      data: {
        rating: 4,
        comment: "Lezzetli ama biraz yavaştı.",
        userId: testConsumer.id,
        shopId: testShop.id,
        orderId: order2.id
      }
    });

    await prisma.shop.update({
      where: { id: testShop.id },
      data: {
        averageRating: 4.5,
        reviewCount: 2
      }
    });
  }

  // Seed reviews for Test Süpermarket
  const existingTestMarketReviews = await prisma.review.findMany({ where: { shopId: testMarketShop.id } });
  if (existingTestMarketReviews.length === 0) {
    let address = await prisma.address.findFirst({ where: { userId: testConsumer.id } });
    if (!address) {
      address = await prisma.address.create({
        data: {
          userId: testConsumer.id,
          title: "Ev",
          city: "Lefkoşa",
          district: "Ortaköy",
          fullAddress: "Test Adresi",
          latitude: 35.1856,
          longitude: 33.3823
        }
      });
    }

    const order = await prisma.order.create({
      data: {
        consumerId: testConsumer.id,
        shopId: testMarketShop.id,
        addressId: address.id,
        deliveryAddress: "Ortaköy, Lefkoşa",
        totalAmount: 70.0,
        status: "DELIVERED",
        paymentMethod: "CASH_ON_DELIVERY",
        paymentStatus: "SUCCESS"
      }
    });
    await prisma.review.create({
      data: {
        rating: 5,
        comment: "Hızlı servis, tüm ürünler eksiksiz geldi.",
        userId: testConsumer.id,
        shopId: testMarketShop.id,
        orderId: order.id
      }
    });

    await prisma.shop.update({
      where: { id: testMarketShop.id },
      data: {
        averageRating: 5.0,
        reviewCount: 1
      }
    });
  }

  // Seed other shops and reviews
  await seedShopWithProducts(
    "manav@test.com",
    "Taze Manavım",
    "GREENGROCER",
    "+905553334444",
    [
      {
        categoryName: "Meyve, Sebze",
        products: [
          { name: "Yerli Muz 1 Kg", price: 50.0, description: "Taze yerli muz" },
          { name: "Çeri Domates 500g", price: 30.0, description: "Tatlı çeri domates" },
          { name: "Çengelköy Salatalık 1 Kg", price: 25.0, description: "Kıtır kıtır salatalık" }
        ]
      }
    ],
    [5, 5, 4],
    ["Çok taze meyveler!", "Harika manav", "Hızlı ve taze"],
    testConsumer.id,
    passwordHash,
    unitAdet.id
  );

  await seedShopWithProducts(
    "kasap@test.com",
    "Kardeşler Kasap",
    "BUTCHER",
    "+905553335555",
    [
      {
        categoryName: "Kırmızı Et",
        products: [
          { name: "Dana Kıyma 1 Kg", price: 450.0, description: "Orta yağlı dana kıyma" },
          { name: "Dana Kuşbaşı 1 Kg", price: 480.0, description: "Yumuşak dana kuşbaşı" },
          { name: "Kuzu Pirzola 1 Kg", price: 650.0, description: "Taze kuzu pirzola" }
        ]
      }
    ],
    [5, 4],
    ["Etler çok kaliteli", "Temiz kasap"],
    testConsumer.id,
    passwordHash,
    unitAdet.id
  );

  await seedShopWithProducts(
    "su@test.com",
    "Hayat Su Lefkoşa",
    "WATER",
    "+905553336666",
    [
      {
        categoryName: "Damacana Su",
        products: [
          { name: "19 L Damacana Su", price: 70.0, description: "Hayat doğal kaynak suyu 19L" },
          { name: "0.5 L Pet Su 24'lü", price: 80.0, description: "24 adet 0.5L su paketi" }
        ]
      }
    ],
    [5, 5, 5],
    ["Hızlı servis!", "Güleryüzlü kurye", "Her zaman hızlı"],
    testConsumer.id,
    passwordHash,
    unitAdet.id
  );

  await seedShopWithProducts(
    "nuts@test.com",
    "Bahçeden Kuruyemiş",
    "MARKET",
    "+905553337777",
    [
      {
        categoryName: "Kuruyemişler",
        products: [
          { name: "Tuzlu Fıstık 250g", price: 60.0, description: "Taze kavrulmuş tuzlu fıstık" },
          { name: "Kaju 250g", price: 120.0, description: "Çifte kavrulmuş kaju" },
          { name: "Karışık Kuruyemiş 250g", price: 90.0, description: "Lüks karışık çerez" }
        ]
      }
    ],
    [4, 5],
    ["Çok taze kuruyemişler", "Tavsiye ederim"],
    testConsumer.id,
    passwordHash,
    unitAdet.id
  );

  await seedShopWithProducts(
    "coffee@test.com",
    "Espresso Lab Lefkoşa",
    "MARKET",
    "+905553338888",
    [
      {
        categoryName: "Kahveler",
        products: [
          { name: "Caffe Latte", price: 90.0, description: "Sıcak espresso lab latte" },
          { name: "Iced Americano", price: 80.0, description: "Buzlu ferahlatıcı americano" },
          { name: "Filtre Kahve", price: 70.0, description: "Demleme taze filtre kahve" }
        ]
      }
    ],
    [5, 4],
    ["Kahveler sıcak geldi", "Çok lezzetli aromalar"],
    testConsumer.id,
    passwordHash,
    unitAdet.id
  );

  await seedShopWithProducts(
    "flower@test.com",
    "Lefkoşa Çiçek Tasarım",
    "MARKET",
    "+905553339999",
    [
      {
        categoryName: "Çiçekler",
        products: [
          { name: "Kırmızı Gül Buketi", price: 400.0, description: "11 adet taze kırmızı gül" },
          { name: "Papatya Buketi", price: 250.0, description: "Taze kır papatyaları" },
          { name: "Orkide Saksı Çiçeği", price: 600.0, description: "Çift dallı beyaz orkide" }
        ]
      }
    ],
    [5, 5],
    ["Çok özenli buket", "Tam zamanında ulaştı"],
    testConsumer.id,
    passwordHash,
    unitAdet.id
  );

  // 8.5. SEED BUSINESS CATEGORIES
  const businessCategories = [
    { name: "Market", icon: "shopping_basket", color: "#00A651", subtitle: "Market alışverişi", avgDeliveryTime: "20-30 dk", badge: "popular", order: 0 },
    { name: "Restoran", icon: "restaurant", color: "#FF6B00", subtitle: "Yemek siparişi", avgDeliveryTime: "25-35 dk", badge: "popular", order: 1 },
    { name: "Su", icon: "water_drop", color: "#2196F3", subtitle: "Su ve içecek", avgDeliveryTime: "15-25 dk", badge: null, order: 2 },
    { name: "Kuruyemiş", icon: "grain", color: "#795548", subtitle: "Kuruyemiş çeşitleri", avgDeliveryTime: "20-30 dk", badge: "new", order: 3 },
    { name: "Kahve", icon: "coffee", color: "#4E342E", subtitle: "Kahve ve içecek", avgDeliveryTime: "15-20 dk", badge: null, order: 4 },
    { name: "Çiçek", icon: "local_florist", color: "#E91E63", subtitle: "Çiçek siparişi", avgDeliveryTime: "30-45 dk", badge: null, order: 5 },
    { name: "Manav", icon: "grain", color: "#4CAF50", subtitle: "Taze meyve ve sebze", avgDeliveryTime: "15-25 dk", badge: null, order: 6 },
    { name: "Kasap", icon: "restaurant", color: "#F44336", subtitle: "Taze et ürünleri", avgDeliveryTime: "20-30 dk", badge: "popular", order: 7 },
  ];

  for (const cat of businessCategories) {
    await prisma.businessCategory.upsert({
      where: { name: cat.name },
      update: {
        icon: cat.icon,
        color: cat.color,
        subtitle: cat.subtitle,
        avgDeliveryTime: cat.avgDeliveryTime,
        badge: cat.badge,
        order: cat.order,
      },
      create: {
        name: cat.name,
        icon: cat.icon,
        color: cat.color,
        subtitle: cat.subtitle,
        avgDeliveryTime: cat.avgDeliveryTime,
        badge: cat.badge ?? null,
        order: cat.order,
      },
    });
  }
  console.log("✅ Business Categories Seeded successfully.");

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

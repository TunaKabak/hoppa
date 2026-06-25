import { PrismaClient } from "@prisma/client";
import bcrypt from "bcrypt";

const prisma = new PrismaClient();

async function main() {
  console.log("Seeding database with Test Users...");

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
  console.log("✅ Super Admin Created:", superAdmin.phone);

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
  const passwordHash = await bcrypt.hash("123456", 12);
  const merchant = await prisma.merchant.upsert({
    where: { email: "merchant@test.com" },
    update: {
      status: "ACTIVE",
      phone: "+905551111111",
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
  const firstOrdersCampaign = await prisma.campaign.create({
    data: {
      title: "İlk 5 Sipariş Bedava",
      description: "Hoppa'ya özel ilk 5 siparişinizde teslimat ücreti bizden!",
      type: "FREE_DELIVERY_FIRST_ORDERS",
      isActive: true,
      maxUsesPerUser: 5,
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

  // 7. SÜPERMARKET ALTINA ÜRÜNLERİ EKLE
  const marketProducts = [
    { name: "1 Litre Su", price: 10.0, stock: 100, description: "Doğal kaynak suyu", category: "Su & İçecek", subCategory: "Su" },
    { name: "Taze Ekmek", price: 15.0, stock: 50, description: "Günlük taze ekmek", category: "Fırın", subCategory: "Ekmek" },
    { name: "Günlük Süt", price: 45.0, stock: 30, description: "Pastörize günlük süt", category: "Süt & Kahvaltılık", subCategory: "Süt" },
  ];

  for (const p of marketProducts) {
    // Kategori/Alt kategori bul veya oluştur
    let parentCat = await prisma.category.findFirst({ where: { name: p.category } });
    if (!parentCat) {
      parentCat = await prisma.category.create({ data: { name: p.category } });
    }
    
    let subCat = await prisma.category.findFirst({ where: { name: p.subCategory, parentId: parentCat.id } });
    if (!subCat) {
      subCat = await prisma.category.create({ data: { name: p.subCategory, parentId: parentCat.id } });
    }

    const existingProduct = await prisma.product.findFirst({
      where: { shopId: testMarketShop.id, name: p.name }
    });

    if (!existingProduct) {
      await prisma.product.create({
        data: {
          shopId: testMarketShop.id,
          categoryId: subCat.id,
          name: p.name,
          price: p.price,
          stock: p.stock,
          description: p.description,
          isActive: true,
        }
      });
    }
  }
  console.log("✅ Market Products Seeded successfully.");

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

  // 9. SUPABASE REALTIME REPLİKASYONUNU AKTİF ET
  try {
    await prisma.$executeRawUnsafe(
      'ALTER PUBLICATION supabase_realtime ADD TABLE "CourierLocation";'
    );
    console.log("✅ Supabase Realtime replication enabled for CourierLocation table.");
  } catch (err: any) {
    // Replikasyon zaten aktifse veya tablo yayında varsa hata yoksayılır
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

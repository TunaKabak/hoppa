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
    },
    create: {
      merchantId: merchant.id,
      name: "Test Kebap & Lahmacun",
      description: "E2E testleri için otomatik oluşturulmuş hazır dükkan.",
      address: "Lefkoşa, KKTC",
      minOrderAmount: 150.0,
      isActive: true, // Dükkan siparişe açık
      type: "RESTAURANT",
      latitude: 35.1856,
      longitude: 33.3823,
      deliveryRadiusKm: 5.0,
    },
  });
  console.log("✅ Test Shop Created:", testShop.name);

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
  // Çakışmayı/duplikasyonu önlemek için önce bu marketin ürünlerini temizleyelim
  await prisma.product.deleteMany({
    where: { shopId: testMarketShop.id }
  });

  const marketProducts = [
    { name: "1 Litre Su", price: 10.0, stock: 100, description: "Doğal kaynak suyu" },
    { name: "Taze Ekmek", price: 15.0, stock: 50, description: "Günlük taze ekmek" },
    { name: "Günlük Süt", price: 45.0, stock: 30, description: "Pastörize günlük süt" },
  ];

  for (const p of marketProducts) {
    await prisma.product.create({
      data: {
        shopId: testMarketShop.id,
        name: p.name,
        price: p.price,
        stock: p.stock,
        description: p.description,
        isActive: true,
      }
    });
  }
  console.log("✅ Market Products Seeded successfully.");
}

main()
  .catch((e) => {
    console.error("Seed error:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

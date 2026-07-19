import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const shops = await prisma.shop.findMany({
    include: {
      merchant: true
    }
  });
  console.log("=== SHOPS FULL DETAILS ===");
  for (const shop of shops) {
    if (shop.name.includes("Kebap") || shop.merchant.businessName.includes("Market") || shop.merchant.businessName.includes("Süpermarket")) {
      console.log(JSON.stringify({
        id: shop.id,
        name: shop.name,
        type: shop.type,
        isActive: shop.isActive,
        latitude: shop.latitude,
        longitude: shop.longitude,
        deliveryRadiusKm: shop.deliveryRadiusKm,
        merchantStatus: shop.merchant.status,
        merchantBusinessName: shop.merchant.businessName
      }, null, 2));
    }
  }
}

main().finally(() => prisma.$disconnect());

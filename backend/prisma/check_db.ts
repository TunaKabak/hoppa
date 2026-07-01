import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
async function main() {
  const shops = await prisma.shop.findMany({
    include: {
      _count: {
        select: { products: true }
      }
    }
  });
  console.log("SHOPS IN DB:");
  for (const s of shops) {
    console.log(`- Shop: ${s.name} (ID: ${s.id}, Type: ${s.type}) -> ${s._count.products} products`);
  }
}
main();

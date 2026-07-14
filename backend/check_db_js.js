const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function run() {
  const shopCount = await prisma.shop.count();
  const productCount = await prisma.product.count();
  console.log('--- DB STATS ---');
  console.log('Total Shops Count:', shopCount);
  console.log('Total Products Count:', productCount);

  const shops = await prisma.shop.findMany({
    select: {
      id: true,
      name: true,
      type: true,
      _count: {
        select: { products: true }
      }
    }
  });
  console.log('Shops product counts:');
  for (const s of shops) {
    console.log(`- Shop: "${s.name}" (Type: ${s.type}, ID: ${s.id}) -> Products: ${s._count.products}`);
  }
  process.exit(0);
}
run().catch(console.error);

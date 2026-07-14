const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function run() {
  const shopStats = await prisma.shop.findMany({
    select: {
      id: true,
      name: true,
      type: true,
      _count: {
        select: { products: true }
      }
    }
  });
  console.log(JSON.stringify(shopStats, null, 2));
  process.exit(0);
}
run();

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();
async function run() {
  const shops = await prisma.shop.findMany({
    include: { merchant: true }
  });
  console.log('Shops with Merchants:', JSON.stringify(shops, null, 2));
  process.exit(0);
}
run().catch(console.error);

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("Checking database...");
  const couriers = await prisma.courier.findMany();
  console.log("Couriers:", couriers);
  
  const locations = await prisma.courierLocation.findMany();
  console.log("Courier Locations:", locations);

  const activeOrders = await prisma.order.findMany({
    where: {
      status: { in: ["PREPARING", "ON_THE_WAY"] }
    }
  });
  console.log("Active Orders (PREPARING, ON_THE_WAY):", activeOrders);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

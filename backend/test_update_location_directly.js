const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const courierUserId = '5606241d-1cb2-441d-a895-badb9950f349'; // Süleyman Kurye's User ID
  const latitude = 35.1900;
  const longitude = 33.3850;
  const bearing = 90.0;

  // 1. Find courier
  const courier = await prisma.courier.findUnique({ where: { userId: courierUserId } });
  if (!courier) {
    console.error("Courier profile not found.");
    return;
  }
  console.log("Found courier:", courier);

  // 2. Perform upsert
  try {
    const location = await prisma.courierLocation.upsert({
      where: { id: courier.id }, // courier.id is 'bd0ce625-2a97-4625-9463-b0082d35335b'
      update: {
        latitude: parseFloat(latitude.toString()),
        longitude: parseFloat(longitude.toString()),
        bearing: parseFloat((bearing || 0.0).toString()),
        updatedAt: new Date()
      },
      create: {
        id: courier.id,
        courierId: courier.id,
        latitude: parseFloat(latitude.toString()),
        longitude: parseFloat(longitude.toString()),
        bearing: parseFloat((bearing || 0.0).toString())
      }
    });
    console.log("Upsert succeeded. Result:", location);
  } catch (error) {
    console.error("Upsert failed with error:", error);
  }
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

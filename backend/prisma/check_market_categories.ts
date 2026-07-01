import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
async function main() {
  const cat = await prisma.category.findFirst({ where: { name: { contains: "Fırın" } } });
  console.log("Fırın Category:", cat);
}
main();

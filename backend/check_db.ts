import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const merchants = await prisma.merchant.findMany();
  console.log("Merchants:", merchants);
  
  const admins = await prisma.user.findMany({ where: { role: 'super_admin' } });
  console.log("Admins:", admins);
}

main().finally(() => prisma.$disconnect());

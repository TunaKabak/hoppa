import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany();
  console.log("Users:", users);
  
  const otpCodes = await prisma.otpCode.findMany();
  console.log("OtpCodes:", otpCodes);
}

main().finally(() => prisma.$disconnect());

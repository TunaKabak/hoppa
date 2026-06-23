const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function test() {
  const phoneNumber = "+905488600455";
  const name = "Test";
  const surname = "User";

  try {
    console.log("Upserting user...");
    const user = await prisma.user.upsert({
      where: { phone: phoneNumber },
      create: {
        phone: phoneNumber,
        name: name || "Misafir",
        surname: surname || "Kullanıcı"
      },
      update: {
        lastLogin: new Date(),
        ...(name && { name }),
        ...(surname && { surname })
      }
    });
    console.log("Success:", user);
  } catch (e) {
    console.error("Error during upsert:", e);
  } finally {
    await prisma.$disconnect();
  }
}

test();

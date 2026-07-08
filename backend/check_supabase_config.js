const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log("Checking Supabase publication for CourierLocation...");
  const pubTables = await prisma.$queryRaw`
    SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
  `;
  console.log("Tables in supabase_realtime publication:", pubTables);

  console.log("\nChecking RLS status for CourierLocation...");
  const rlsStatus = await prisma.$queryRaw`
    SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public' AND tablename = 'CourierLocation';
  `;
  console.log("RLS Status:", rlsStatus);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());

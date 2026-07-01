import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
async function main() {
  const products = await prisma.product.findMany({
    where: { shopId: 'f1cc4475-5df4-41ed-988f-89dd95ff3bf6' },
    include: {
      category: true
    }
  });
  
  const categoryCounts: Record<string, number> = {};
  for (const p of products) {
    let current: any = p.category;
    let root: any = current;
    while (current && current.parentId) {
      const parent: any = await prisma.category.findUnique({ where: { id: current.parentId } });
      if (parent) {
        root = parent;
        current = parent;
      } else {
        break;
      }
    }
    const rootName = root ? root.name : "Genel";
    categoryCounts[rootName] = (categoryCounts[rootName] || 0) + 1;
  }
  console.log("PRODUCTS BY ROOT CATEGORY:");
  console.log(JSON.stringify(categoryCounts, null, 2));
}
main();

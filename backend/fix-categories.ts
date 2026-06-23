import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();
async function main() {
  const shop = await prisma.shop.findFirst({ where: { name: "Şehir Süpermarket" } });
  if (!shop) return;
  const products = await prisma.product.findMany({ where: { shopId: shop.id } });
  for (const p of products) {
    let catName = "Su & İçecek";
    let subCatName = "Su";
    if (p.name.includes("Ekmek")) { catName = "Fırın"; subCatName = "Ekmek"; }
    if (p.name.includes("Süt")) { catName = "Süt & Kahvaltılık"; subCatName = "Süt"; }
    
    let parentCat = await prisma.category.findFirst({ where: { name: catName } });
    if (!parentCat) { parentCat = await prisma.category.create({ data: { name: catName } }); }
    let subCat = await prisma.category.findFirst({ where: { name: subCatName, parentId: parentCat.id } });
    if (!subCat) { subCat = await prisma.category.create({ data: { name: subCatName, parentId: parentCat.id } }); }
    
    await prisma.product.update({ where: { id: p.id }, data: { categoryId: subCat.id } });
  }
  console.log("Fixed categories for existing dummy products!");
}
main();

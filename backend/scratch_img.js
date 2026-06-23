const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function fixUrls() {
  const oldUrl = 'http://127.0.0.1:3000';
  const newUrl = 'http://192.168.0.107:3000';

  // Fix Shop
  const shops = await prisma.shop.findMany();
  for (const shop of shops) {
    let changed = false;
    let data = {};
    if (shop.imageUrl && shop.imageUrl.includes(oldUrl)) {
      data.imageUrl = shop.imageUrl.replace(oldUrl, newUrl);
      changed = true;
    }
    if (shop.headerImageUrl && shop.headerImageUrl.includes(oldUrl)) {
      data.headerImageUrl = shop.headerImageUrl.replace(oldUrl, newUrl);
      changed = true;
    }
    if (changed) {
      await prisma.shop.update({ where: { id: shop.id }, data });
      console.log(`Updated shop ${shop.id}`);
    }
  }

  // Fix Product
  const products = await prisma.product.findMany();
  for (const p of products) {
    if (p.imageUrl && p.imageUrl.includes(oldUrl)) {
      await prisma.product.update({ 
        where: { id: p.id }, 
        data: { imageUrl: p.imageUrl.replace(oldUrl, newUrl) } 
      });
      console.log(`Updated product ${p.id}`);
    }
  }

  // Fix Category
  const cats = await prisma.category.findMany();
  for (const c of cats) {
    if (c.imageUrl && c.imageUrl.includes(oldUrl)) {
      await prisma.category.update({ 
        where: { id: c.id }, 
        data: { imageUrl: c.imageUrl.replace(oldUrl, newUrl) } 
      });
      console.log(`Updated category ${c.id}`);
    }
  }

  await prisma.$disconnect();
}
fixUrls().catch(console.error);

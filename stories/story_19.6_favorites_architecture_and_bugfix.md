Story 19.6 - Favoriler Mimarisi ve Ekran Onarımı Planı

Bu görev belgesi; Hoppa platformunda kullanıcıların hem favori işletmelerini (mağaza/restoran) hem de favori ürünlerini kaydedebileceği ilişkisel favori mimarisini kurmayı ve son şema güncellemesi sonrası kırılan favori ürün listeleme ekranını (Bugfix) tamamen onarmayı amaçlar.

🛠️ ADIM 1: Çift Kanallı Favori Şeması Tasarımı (Prisma)

backend/prisma/schema.prisma dosyamızı güncelleyerek hem favori ürünler hem de favori dükkanlar için indekslenmiş, performanslı iki yeni ilişkisel tablo tanımlıyoruz.

// backend/prisma/schema.prisma

// 1. Favori Ürünler Tablosu (Kullanıcı bazlı ürün hızlı erişimi)
model FavoriteProduct {
  id        String   @id @default(uuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  productId String
  product   Product  @relation(fields: [productId], references: [id], onDelete: Cascade)
  createdAt DateTime @default(now())

  @@unique([userId, productId])
  @@index([userId])
  @@index([productId])
}

// 2. Favori İşletmeler Tablosu (Kullanıcı bazlı dükkan hızlı erişimi)
model FavoriteShop {
  id        String   @id @default(uuid())
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  shopId    String
  shop      Shop     @relation(fields: [shopId], references: [id], onDelete: Cascade)
  createdAt DateTime @default(now())

  @@unique([userId, shopId])
  @@index([userId])
  @@index([shopId])
}

// 🚨 Not: User, Product ve Shop modellerine gerekli karşıt ilişkiler (relation fields) Prisma tarafından otomatik generate edilecektir.


🧠 ADIM 2: Backend Favori Kontrolörü Onarımı (FavoritesController.ts)

Mevcut getFavoriteProducts ve favori ekleme/çıkarma metodlarını en son 19.2 ilişkisel şemamızdaki (Unit, Category, GlobalProduct) JOIN yapılarına uydurarak güncelliyoruz. Görsel fallback mantığı burada da korunmaktadır.

// backend/src/controllers/FavoritesController.ts

import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

export class FavoritesController {
  
  // 1. Favori Ürünleri Listeleme (Dinamik 3NF JOIN ve Görsel Fallback Destekli)
  public static async getFavoriteProducts(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;

      // Kullanıcının favorilerindeki aktif ürünleri tüm ilişkileriyle çekiyoruz
      const favoriteRecords = await prisma.favoriteProduct.findMany({
        where: { userId },
        include: {
          product: {
            include: {
              unit: true,
              brand: true,
              category: true,
              subCategory: true,
              globalProduct: true, // Görsel fallback için master ürün JOIN edilir
            }
          }
        }
      });

      // Gelen ürünlere görsel fallback mantığını backend düzeyinde uyguluyoruz
      const products = favoriteRecords.map(fav => {
        const prod = fav.product;
        return {
          id: prod.id,
          name: prod.name,
          price: prod.price,
          // Dükkan özel resmi yoksa, global kütüphane resmini kullan
          imageUrl: prod.imageUrl || prod.globalProduct?.imageUrl || "/images/default-product.png",
          unit: prod.unit, // İlişkisel Unit nesnesi (ADET, KG vb.)
          minQuantity: prod.minQuantity,
          stepSize: prod.stepSize,
          trackStock: prod.trackStock,
          stockQuantity: prod.stockQuantity,
          shopId: prod.shopId,
        };
      });

      res.status(200).json({ error: false, data: products });
    } catch (error) {
      console.error("Favori ürünler çekilemedi:", error);
      res.status(500).json({ error: true, message: "Favori ürünler listelenirken hata oluştu." });
    }
  }

  // 2. Ürünü Favoriye Ekleme / Çıkarma (Toggle)
  public static async toggleFavoriteProduct(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const { productId } = req.body;

      if (!productId) {
        res.status(400).json({ error: true, message: "productId alanı zorunludur." });
        return;
      }

      // Zaten favoride mi kontrol et
      const existing = await prisma.favoriteProduct.findUnique({
        where: {
          userId_productId: { userId, productId }
        }
      });

      if (existing) {
        // Varsa favorilerden kaldır
        await prisma.favoriteProduct.delete({
          where: {
            userId_productId: { userId, productId }
          }
        });
        res.status(200).json({ error: false, isFavorite: false, message: "Ürün favorilerden çıkarıldı." });
      } else {
        // Yoksa favorilere ekle
        await prisma.favoriteProduct.create({
          data: { userId, productId }
        });
        res.status(200).json({ error: false, isFavorite: true, message: "Ürün favorilere eklendi." });
      }
    } catch (error) {
      console.error("Favori toggle işlemi başarısız:", error);
      res.status(500).json({ error: true, message: "İşlem gerçekleştirilirken hata oluştu." });
    }
  }
}


📱 ADIM 3: Flutter Favori Veri Çözümleme Onarımı

Tüketici uygulamasındaki favori ürün listesi endpoint çağrısını yeni 3NF JSON yapısına uyduruyoruz.

A. Repository Katmanı Güncellemesi (consumer_shop_repository.dart)

getFavoriteProducts metodunu, backend'in döndürdüğü dinamik listeyi Product modeline hatasız çözümleyecek (deserialization) hale getiriyoruz:

// apps/consumer_app/lib/apps/consumer/repositories/consumer_shop_repository.dart

Future<List<Product>> getFavoriteProducts() async {
  try {
    final response = await _apiClient.get('/api/consumer/favorites/products');
    
    if (response['error'] == false && response['data'] != null) {
      final List<dynamic> dataList = response['data'] as List;
      return dataList.map((item) => Product.fromMap(item as Map<String, dynamic>)).toList();
    }
    return [];
  } catch (e) {
    print("Favori ürünleri çekme hatası (Flutter): $e");
    return [];
  }
}


📢 Doğrulama Planı

Database Schema Güncellemesi:

cd backend && npx prisma db push && npx prisma generate


Backend Derleme Doğrulaması:

cd backend && npx tsc --noEmit


Flutter Analiz Doğrulaması:

cd apps/consumer_app && flutter analyze


Manuel Test Senaryosu:

Bir süpermarket ürününde bulunan kalp ikonuna basın.

"Favorilerim" sekmesini açın ve az önce favorilediğiniz ürünün stüdyo görseli, dinamik birimi ve güncel fiyatıyla pürüzsüzce ekrana düştüğünü doğrulayın.
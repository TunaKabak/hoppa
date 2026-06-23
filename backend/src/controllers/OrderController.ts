import { Request, Response } from "express";
import { PrismaClient, OrderStatus, PaymentMethod, PaymentStatus } from "@prisma/client";
import { PaymentRoutingService } from "../services/PaymentRoutingService";

const prisma = new PrismaClient();

export class OrderController {
  /**
   * Tüketici tarafından sipariş oluşturma (Checkout)
   */
  async createOrder(req: Request, res: Response) {
    try {
      const consumerId = req.user?.id;
      if (!consumerId) {
        return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik veya yetkisiz." });
      }

      const { shopId, items, deliveryAddress, addressId, notes, paymentMethod, cardDetails } = req.body;

      if (!shopId) {
        return res.status(400).json({ error: true, message: "Dükkan bilgisi (shopId) zorunludur." });
      }

      if (!items || !Array.isArray(items) || items.length === 0) {
        return res.status(400).json({ error: true, message: "Sipariş kalemleri (items) boş olamaz." });
      }

      // 1. Dükkanı bul ve aktiflik durumunu doğrula
      const shop = await prisma.shop.findUnique({
        where: { id: shopId }
      });

      if (!shop) {
        return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });
      }

      if (!shop.isActive) {
        return res.status(400).json({ error: true, message: "Dükkan şu anda kapalı, sipariş verilemez." });
      }

      // 2. Ürünlerin fiyatlarını veritabanından çek ve doğrula
      const productIds = items.map((item: any) => item.productId);
      const dbProducts = await prisma.product.findMany({
        where: {
          id: { in: productIds },
          shopId: shopId,
          isActive: true
        }
      });

      const dbProductMap = new Map(dbProducts.map(p => [p.id, p]));

      // Talep edilen tüm ürünlerin dükkanda aktif olarak bulunduğundan emin ol
      for (const item of items) {
        if (!dbProductMap.has(item.productId)) {
          return res.status(400).json({
            error: true,
            message: `Ürün bulunamadı veya dükkanda aktif değil: ${item.productId}`
          });
        }
        if (typeof item.quantity !== "number" || item.quantity <= 0) {
          return res.status(400).json({
            error: true,
            message: `Geçersiz ürün miktarı: ${item.productId}`
          });
        }
      }

      // 3. Toplam sipariş tutarını hesapla
      let totalAmount = 0;
      for (const item of items) {
        const product = dbProductMap.get(item.productId)!;
        const unitPrice = product.discountPrice ? Number(product.discountPrice) : Number(product.price);
        totalAmount += unitPrice * item.quantity;
      }

      // 4. Minimum dükkan sipariş limiti kontrolü
      const minAmount = Number(shop.minOrderAmount);
      if (totalAmount < minAmount) {
        return res.status(400).json({
          error: true,
          message: `Minimum sipariş tutarı (${minAmount} TL) karşılanmalıdır. Mevcut sipariş tutarı: ${totalAmount.toFixed(2)} TL.`
        });
      }

      // 5. Adres Çözümleme ve Snapshot Oluşturma
      let finalAddressId = addressId;
      let snapshotAddress = "";

      if (finalAddressId) {
        // addressId gönderildiyse, adresi DB'den bul ve snapshot'ını oluştur
        const userAddress = await prisma.address.findUnique({
          where: { id: finalAddressId }
        });

        if (!userAddress || userAddress.userId !== consumerId) {
          return res.status(400).json({ error: true, message: "Geçersiz veya yetkisiz adres bilgisi." });
        }

        if (userAddress.latitude == null || userAddress.longitude == null) {
          return res.status(400).json({ error: true, message: "Lütfen teslimat adresi için haritadan konum seçiniz." });
        }

        snapshotAddress = `${userAddress.title}: ${userAddress.fullAddress}${userAddress.district ? ' ' + userAddress.district : ''}${userAddress.city ? '/' + userAddress.city : ''}`;
      } else if (deliveryAddress && typeof deliveryAddress === "string") {
        // Direkt metin olarak adres girildiyse, veritabanına Address olarak kaydet/bul ve snapshot'ı metin yap
        let existingAddress = await prisma.address.findFirst({
          where: { userId: consumerId, fullAddress: deliveryAddress }
        });

        if (existingAddress) {
          finalAddressId = existingAddress.id;
          snapshotAddress = `${existingAddress.title}: ${existingAddress.fullAddress}`;
        } else {
          const newAddress = await prisma.address.create({
            data: {
              userId: consumerId,
              title: "Teslimat Adresi",
              fullAddress: deliveryAddress
            }
          });
          finalAddressId = newAddress.id;
          snapshotAddress = `Teslimat Adresi: ${deliveryAddress}`;
        }
      } else {
        return res.status(400).json({ error: true, message: "Sipariş için geçerli bir teslimat adresi belirtilmelidir." });
      }

      // 6. Prisma `$transaction` ile sipariş ve kalemleri kaydet
      const transactionResult = await prisma.$transaction(async (tx) => {
        const method = paymentMethod || "CASH_ON_DELIVERY";
        
        const createdOrder = await tx.order.create({
          data: {
            consumerId,
            shopId,
            addressId: finalAddressId,
            deliveryAddress: snapshotAddress, // immutable adres snapshot'ı
            totalAmount,
            deliveryFee: 0,
            status: "PENDING",
            customerNote: notes || null,
            paymentMethod: method,
            paymentStatus: "PENDING"
          }
        });

        const orderItemsData = items.map((item: any) => {
          const product = dbProductMap.get(item.productId)!;
          const unitPrice = product.discountPrice ? product.discountPrice : product.price;
          return {
            orderId: createdOrder.id,
            productId: item.productId,
            quantity: item.quantity,
            unitPrice
          };
        });

        await tx.orderItem.createMany({
          data: orderItemsData
        });

        let paymentUrl = undefined;

        if (method === "ONLINE_PAYMENT") {
           if (!cardDetails) {
             throw new Error("Online ödeme için kart bilgileri gereklidir.");
           }

           const routeResponse = await PaymentRoutingService.routePayment({
             orderId: createdOrder.id,
             amount: Number(totalAmount),
             cardDetails
           });

           await tx.paymentTransaction.create({
             data: {
               orderId: createdOrder.id,
               amount: routeResponse.amount,
               currency: routeResponse.currency,
               exchangeRate: routeResponse.exchangeRate,
               provider: routeResponse.provider,
               routingType: routeResponse.routingType,
               status: "PENDING",
               providerTxId: routeResponse.providerTxId
             }
           });

           paymentUrl = routeResponse.paymentUrl;
        }

        return { createdOrder, paymentUrl };
      });

      // Oluşturulan siparişi detaylıca döndür
      const fullOrder = await prisma.order.findUnique({
        where: { id: transactionResult.createdOrder.id },
        include: {
          shop: { select: { name: true, imageUrl: true } },
          items: {
            include: {
              product: { select: { name: true, imageUrl: true } }
            }
          }
        }
      });

      return res.status(201).json({ 
        error: false, 
        data: fullOrder,
        paymentUrl: transactionResult.paymentUrl
      });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  /**
   * Giriş yapan tüketicinin kendi sipariş geçmişi
   */
  async getConsumerOrders(req: Request, res: Response) {
    try {
      const consumerId = req.user?.id;
      if (!consumerId) {
        return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });
      }

      const orders = await prisma.order.findMany({
        where: { consumerId },
        include: {
          shop: { select: { name: true, imageUrl: true, type: true } },
          items: {
            include: {
              product: { select: { name: true, imageUrl: true } }
            }
          }
        },
        orderBy: { createdAt: "desc" }
      });

      return res.status(200).json({ error: false, data: orders });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  /**
   * Giriş yapan satıcının kendi dükkanına ait siparişler
   */
  async getMerchantOrders(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      if (!merchantId) {
        return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });
      }

      const shop = await prisma.shop.findUnique({
        where: { merchantId }
      });

      if (!shop) {
        return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });
      }

      const orders = await prisma.order.findMany({
        where: { shopId: shop.id },
        include: {
          consumer: { select: { name: true, surname: true, phone: true } },
          items: {
            include: {
              product: { select: { name: true, imageUrl: true } }
            }
          }
        },
        orderBy: { createdAt: "desc" }
      });

      return res.status(200).json({ error: false, data: orders });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  /**
   * Sipariş durumunun güncellenmesi (Satıcı/Yönetici için)
   */
  async updateOrderStatus(req: Request, res: Response) {
    try {
      const merchantId = req.user?.id;
      const role = req.user?.role;
      const orderId = req.params.id as string;
      const { status } = req.body;

      if (!merchantId) {
        return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });
      }

      if (!status || !Object.values(OrderStatus).includes(status)) {
        return res.status(400).json({ error: true, message: "Geçersiz veya eksik sipariş durumu (status)." });
      }

      const order = await prisma.order.findUnique({
        where: { id: orderId }
      });

      if (!order) {
        return res.status(404).json({ error: true, message: "Sipariş bulunamadı." });
      }

      // Yetki kontrolü: super_admin değilse, siparişin satıcının kendi dükkanına ait olması gerekir
      if (role !== "super_admin") {
        const shop = await prisma.shop.findUnique({
          where: { merchantId }
        });

        if (!shop || order.shopId !== shop.id) {
          return res.status(403).json({ error: true, message: "Bu siparişin durumunu güncelleme yetkiniz yok." });
        }
      }

      const updatedOrder = await prisma.order.update({
        where: { id: orderId },
        data: { status },
        include: {
          consumer: { select: { name: true, surname: true, phone: true } },
          items: {
            include: {
              product: { select: { name: true, imageUrl: true } }
            }
          }
        }
      });

      return res.status(200).json({ error: false, data: updatedOrder });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }
}

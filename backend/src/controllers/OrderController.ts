import { Request, Response } from "express";
import { PrismaClient, OrderStatus, PaymentMethod, PaymentStatus } from "@prisma/client";
import { PaymentRoutingService } from "../services/PaymentRoutingService";
import { CampaignService } from "../services/CampaignService";

const prisma = new PrismaClient();
const campaignService = new CampaignService();

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

      // GMT+3 Zaman Dilimi Kontrolü
      const now = new Date();
      const gmt3Time = new Date(now.toLocaleString("en-US", { timeZone: "Europe/Istanbul" }));
      const currentHour = gmt3Time.getHours();
      const currentMinute = gmt3Time.getMinutes();
      
      const days = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];
      const currentDayName = days[gmt3Time.getDay()];
      
      let isOpenRightNow = true;

      if (shop.workingHours && typeof shop.workingHours === 'object') {
        const wh = shop.workingHours as any;
        const todaySchedule = wh[currentDayName];
        if (todaySchedule) {
          if (todaySchedule.isOpen === false) {
             isOpenRightNow = false;
          } else if (todaySchedule.openTime && todaySchedule.closeTime) {
             const [openH, openM] = todaySchedule.openTime.split(':').map(Number);
             const [closeH, closeM] = todaySchedule.closeTime.split(':').map(Number);
             
             const currentTotalMins = currentHour * 60 + currentMinute;
             const openTotalMins = openH * 60 + openM;
             let closeTotalMins = closeH * 60 + closeM;
             
             if (closeTotalMins < openTotalMins) {
               // Ertesi güne sarkma durumu, örn: 08:00 - 02:00
               closeTotalMins += 24 * 60;
             }
             
             let checkMins = currentTotalMins;
             if (currentTotalMins < openTotalMins && closeTotalMins > 24 * 60) {
               checkMins += 24 * 60;
             }
             
             if (checkMins < openTotalMins || checkMins >= closeTotalMins) {
               isOpenRightNow = false;
             }
          }
        }
      } else {
        // Varsayılan kontrol: 08:00 - 22:00
        if (currentHour < 8 || currentHour >= 22) {
          isOpenRightNow = false;
        }
      }

      if (!isOpenRightNow) {
        return res.status(400).json({ error: true, message: "Dükkan şu an çalışma saatleri dışındadır. Lütfen daha sonra tekrar deneyiniz." });
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

        snapshotAddress = (deliveryAddress && typeof deliveryAddress === "string") 
          ? deliveryAddress 
          : `${userAddress.title}: ${userAddress.fullAddress}${userAddress.district ? ' ' + userAddress.district : ''}${userAddress.city ? '/' + userAddress.city : ''}`;
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
        
        // Backend Delivery Fee Calculation via Campaign Engine
        const deliveryResult = await campaignService.calculateDeliveryFee(consumerId, shop, totalAmount);
        
        const createdOrder = await tx.order.create({
          data: {
            consumerId,
            shopId,
            addressId: finalAddressId,
            deliveryAddress: snapshotAddress, // immutable adres snapshot'ı
            totalAmount,
            deliveryFee: deliveryResult.fee,
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

      // Send Push Notification asynchronously to Merchant
      if (shop.merchantId) {
        setImmediate(async () => {
          try {
            const { notificationService } = await import("../services/NotificationService");
            await notificationService.sendToMerchant(
              shop.merchantId,
              "Yeni Sipariş! 🚀",
              "Dükkanınıza yeni bir sipariş geldi. Hemen hazırlamaya başlayın!",
              { orderId: fullOrder?.id || transactionResult.createdOrder.id }
            );
          } catch (err) {
            console.error("Error triggering notification on new order:", err);
          }
        });
      }

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

      // Map frontend status values to Prisma Enum
      let upperStatus = status?.toUpperCase();
      if (upperStatus === "ON_WAY") {
        upperStatus = "ON_THE_WAY";
      }

      if (!upperStatus || !Object.values(OrderStatus).includes(upperStatus)) {
        return res.status(400).json({ error: true, message: `Geçersiz veya eksik sipariş durumu (status): ${status}` });
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

      let updatedPaymentStatus = undefined;
      if (upperStatus === "DELIVERED" && order.paymentMethod !== "ONLINE_PAYMENT") {
        updatedPaymentStatus = "SUCCESS";
      }

      const updatedOrder = await prisma.order.update({
        where: { id: orderId },
        data: { 
          status: upperStatus,
          ...(updatedPaymentStatus ? { paymentStatus: updatedPaymentStatus as PaymentStatus } : {})
        },
        include: {
          consumer: { select: { name: true, surname: true, phone: true } },
          items: {
            include: {
              product: { select: { name: true, imageUrl: true } }
            }
          }
        }
      });

      // Send Push Notification asynchronously
      setImmediate(async () => {
        try {
          const { notificationService } = await import("../services/NotificationService");
          let title = "Sipariş Güncellemesi";
          let body = `Siparişinizin durumu güncellendi: ${upperStatus}`;
          
          switch(upperStatus) {
            case "PREPARING":
              title = "Siparişiniz Hazırlanıyor 🍳";
              body = "Siparişiniz onaylandı ve hazırlanmaya başlandı.";
              break;
            case "ON_THE_WAY":
              title = "Kuryemiz Yola Çıktı! 🛵";
              body = "Siparişiniz sıcak sıcak geliyor.";
              break;
            case "READY_FOR_PICKUP":
              title = "Siparişiniz Hazır! 🛍️";
              body = "Siparişiniz hazır, gelip teslim alabilirsiniz.";
              break;
            case "DELIVERED":
              title = "Afiyet Olsun! 🎉";
              body = "Siparişiniz başarıyla teslim edildi.";
              break;
            case "CANCELLED":
              title = "Sipariş İptal Edildi ❌";
              body = "Siparişiniz maalesef iptal edildi.";
              break;
          }

          await notificationService.sendToUser(updatedOrder.consumerId, title, body, {
            orderId: updatedOrder.id,
            status: upperStatus
          });
        } catch (err) {
          console.error("Error triggering notification on order update:", err);
        }
      });

      return res.status(200).json({ error: false, data: updatedOrder });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }

  /**
   * Sipariş iptal işlemi (Tüketici veya Satıcı)
   */
  async cancelOrder(req: Request, res: Response) {
    try {
      const userId = req.user?.id;
      const role = req.user?.role;
      const orderId = req.params.id as string;
      const { cancelReason } = req.body;

      if (!userId || !role) {
        return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });
      }

      const order = await prisma.order.findUnique({
        where: { id: orderId },
        include: { shop: true }
      });

      if (!order) {
        return res.status(404).json({ error: true, message: "Sipariş bulunamadı." });
      }

      let cancelledBy = "";

      // Consumer cancellation rules
      if (role === "user") {
        if (order.consumerId !== userId) {
          return res.status(403).json({ error: true, message: "Yetkisiz erişim." });
        }
        if (order.status !== "PENDING") {
          return res.status(400).json({ error: true, message: "Sipariş onaylandığı için iptal edilemez." });
        }
        cancelledBy = "CONSUMER";
      } 
      // Merchant cancellation rules
      else if (role === "merchant") {
        if (order.shop.merchantId !== userId) {
          return res.status(403).json({ error: true, message: "Yetkisiz erişim." });
        }
        if (!["PENDING", "PREPARING", "ON_THE_WAY"].includes(order.status)) {
          return res.status(400).json({ error: true, message: "Sipariş şu anki durumunda iptal edilemez." });
        }
        if (!cancelReason) {
          return res.status(400).json({ error: true, message: "İptal nedeni belirtilmelidir." });
        }
        cancelledBy = "MERCHANT";
      } else {
        return res.status(403).json({ error: true, message: "Geçersiz rol." });
      }

      const updatedOrder = await prisma.order.update({
        where: { id: orderId },
        data: {
          status: "CANCELLED",
          cancelReason: cancelReason || "Kullanıcı tarafından iptal edildi",
          cancelledAt: new Date(),
          cancelledBy,
          ...(order.paymentMethod === "ONLINE_PAYMENT" ? { paymentStatus: "REFUNDED" } : {})
        }
      });

      // Send notifications based on who cancelled
      setImmediate(async () => {
        try {
          const { notificationService } = await import("../services/NotificationService");
          
          if (cancelledBy === "CONSUMER") {
            // Notify merchant
            if (order.shop.merchantId) {
              await notificationService.sendToMerchant(
                order.shop.merchantId,
                "Sipariş İptali ❌",
                "Müşteri henüz onaylanmayan siparişi iptal etti.",
                { orderId: order.id }
              );
            }
          } else if (cancelledBy === "MERCHANT") {
            // Notify consumer
            await notificationService.sendToUser(
              order.consumerId,
              "Sipariş İptal Edildi ❌",
              `Siparişiniz dükkan tarafından iptal edildi. Neden: ${cancelReason}`,
              { orderId: order.id }
            );
          }
        } catch (err) {
          console.error("Error triggering notification on cancel:", err);
        }
      });

      return res.status(200).json({ error: false, data: updatedOrder });
    } catch (error: any) {
      return res.status(500).json({ error: true, message: error.message });
    }
  }
}

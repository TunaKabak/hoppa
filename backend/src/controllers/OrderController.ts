import { Request, Response } from "express";
import { PrismaClient, OrderStatus, PaymentMethod, PaymentStatus } from "@prisma/client";
import { PaymentRoutingService } from "../services/PaymentRoutingService";
import { CampaignService } from "../services/CampaignService";
import { WalletService } from "../services/WalletService";
import { realtimeEventService } from "../services/RealtimeEventService";

const prisma = new PrismaClient();
const campaignService = new CampaignService();

const SAFE_MERCHANT_PUBLIC_SELECT = {
  id: true,
  businessName: true,
  phone: true,
  businessPhone: true,
  district: true,
  countryCode: true,
  status: true,
} as const;

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

      const { shopId, items, deliveryAddress, addressId, notes, paymentMethod, cardDetails, dontRingBell, leaveAtDoor, fulfillmentModel, referringSource, shopCampaignId, substitutionPreference, useWallet, walletAmount } = req.body;

      if (!shopId) {
        return res.status(400).json({ error: true, message: "Dükkan bilgisi (shopId) zorunludur." });
      }

      if (!items || !Array.isArray(items) || items.length === 0) {
        return res.status(400).json({ error: true, message: "Sipariş kalemleri (items) boş olamaz." });
      }

      // 1. Dükkanı bul ve aktiflik durumunu doğrula
      const shop = await prisma.shop.findUnique({
        where: { id: shopId },
        include: { merchant: { select: SAFE_MERCHANT_PUBLIC_SELECT } }
      });

      if (!shop) {
        return res.status(404).json({ error: true, message: "Dükkan bulunamadı." });
      }

      if (!shop.isActive) {
        return res.status(400).json({ error: true, message: "Dükkan şu anda kapalı, sipariş verilemez." });
      }

      // Ödeme Yöntemi Dükkan Destek Kontrolü
      if (shop.allowedPaymentMethods && shop.allowedPaymentMethods.length > 0) {
        const upperMethod = paymentMethod?.toUpperCase() as PaymentMethod;
        if (upperMethod !== "WALLET" && !shop.allowedPaymentMethods.includes(upperMethod)) {
          return res.status(400).json({
            error: true,
            message: `Bu işletme seçtiğiniz ödeme yöntemini (${paymentMethod}) kabul etmemektedir.`
          });
        }
      }

      // Teslimat Tipi (Fulfillment Model) Kontrolü
      const chosenFulfillment = fulfillmentModel || "PLATFORM_DELIVERY";
      const shopAllowedModels = (shop as any).allowedFulfillmentModels || ["PLATFORM_DELIVERY", "PICKUP"];
      if (!shopAllowedModels.includes(chosenFulfillment)) {
        return res.status(400).json({
          error: true,
          message: `Bu işletme seçtiğiniz teslimat/hizmet yöntemini (${chosenFulfillment}) desteklememektedir.`
        });
      }

      // Dinamik Zaman Dilimi Kontrolü (Yaz saati destekli)
      const countryCode = (shop as any).merchant?.countryCode || "TR";
      const tz = (countryCode === "CY" || countryCode === "KKTC") ? "Europe/Nicosia" : "Europe/Istanbul";

      const now = new Date();
      const formatter = new Intl.DateTimeFormat("en-US", {
        timeZone: tz,
        hour: "numeric",
        minute: "numeric",
        hour12: false,
        weekday: "long"
      });

      const parts = formatter.formatToParts(now);
      let currentHour = 0;
      let currentMinute = 0;
      let weekdayName = "";

      for (const part of parts) {
        if (part.type === "hour") {
          currentHour = parseInt(part.value, 10);
        } else if (part.type === "minute") {
          currentMinute = parseInt(part.value, 10);
        } else if (part.type === "weekday") {
          weekdayName = part.value.toLowerCase();
        }
      }

      let isOpenRightNow = true;

      if (shop.workingHours && typeof shop.workingHours === 'object') {
        const wh = shop.workingHours as any;
        const todaySchedule = wh[weekdayName];
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

      // 1.5. Kapıda Ödeme ve Temassız Teslimat Karşılıklı Dışlama Kontrolü (Business Rule)
      const isPayAtDoor = paymentMethod === "CASH_ON_DELIVERY" || paymentMethod === "CARD_ON_DELIVERY" || paymentMethod === "cash_on_delivery" || paymentMethod === "card_on_delivery";
      const isLeaveAtDoor = leaveAtDoor === true || leaveAtDoor === "true";
      if (isPayAtDoor && isLeaveAtDoor) {
        return res.status(400).json({ 
          error: true, 
          message: "Kapıda ödeme seçildiğinde temassız teslimat (Kapıya Bırak) yapılamaz." 
        });
      }

      // 2. Ürünlerin ve seçenek gruplarının fiyatlarını veritabanından çek ve doğrula
      const productIds = Array.from(new Set(items.map((item: any) => item.productId)));
      const dbProducts = await prisma.product.findMany({
        where: {
          id: { in: productIds },
          shopId: shopId,
          isActive: true
        },
        include: {
          optionGroups: {
            include: {
              options: {
                where: { isActive: true }
              }
            }
          }
        }
      });

      const dbProductMap = new Map(dbProducts.map(p => [p.id, p]));

      interface ResolvedOrderItemOption {
        groupName: string;
        name: string;
        price: number;
        quantity: number;
        actionType: "ADD" | "REMOVE";
        optionId: string;
      }

      const resolvedItems: Array<{
        productId: string;
        quantity: number;
        unitPrice: number;
        options: ResolvedOrderItemOption[];
      }> = [];

      // 3. Kalemleri ve opsiyonları DB fiyatları ile doğrula (client fiyatına asla güvenme)
      let totalAmount = 0;
      for (const item of items) {
        const product = dbProductMap.get(item.productId);
        if (!product) {
          return res.status(400).json({
            error: true,
            message: `Ürün bulunamadı veya dükkanda aktif değil: ${item.productId}`
          });
        }
        if (
          typeof item.quantity !== "number" ||
          !Number.isInteger(item.quantity) ||
          item.quantity < 1 ||
          item.quantity > 100
        ) {
          return res.status(400).json({
            error: true,
            message: `Geçersiz ürün miktarı (1-100 arası tam sayı olmalı): ${item.productId}`
          });
        }

        const baseProductPrice = Number(product.price);
        if (!Number.isFinite(baseProductPrice) || baseProductPrice < 0) {
          return res.status(400).json({
            error: true,
            message: `Geçersiz ürün taban fiyatı: ${product.name}`
          });
        }

        const dbOptionMap = new Map<
          string,
          {
            groupId: string;
            groupName: string;
            freeSelectionsCount: number;
            option: (typeof product.optionGroups)[number]["options"][number];
          }
        >();
        for (const group of product.optionGroups) {
          for (const opt of group.options) {
            dbOptionMap.set(opt.id, {
              groupId: group.id,
              groupName: group.name,
              freeSelectionsCount: group.freeSelectionsCount,
              option: opt,
            });
          }
        }

        const rawOptions = Array.isArray(item.options) ? item.options : [];
        if (item.options !== undefined && !Array.isArray(item.options)) {
          return res.status(400).json({
            error: true,
            message: `Geçersiz ürün seçeneği biçimi: ${item.productId}`
          });
        }

        const groupSelectionUnits = new Map<string, number>();
        const resolvedOptions: ResolvedOrderItemOption[] = [];
        let optionsPrice = 0;

        for (const opt of rawOptions) {
          const optionId = typeof opt?.optionId === "string" ? opt.optionId.trim() : "";
          const found = optionId ? dbOptionMap.get(optionId) : undefined;
          if (!found) {
            return res.status(400).json({
              error: true,
              message: `Ürün için geçersiz veya pasif seçenek kimliği: ${product.name}`
            });
          }

          const rawQty = opt?.quantity !== undefined ? Number(opt.quantity) : 1;
          if (!Number.isInteger(rawQty) || rawQty < 1 || rawQty > found.option.maxQuantity) {
            return res.status(400).json({
              error: true,
              message: `Seçenek adedi sınır dışında: ${found.option.name}`
            });
          }

          const actionType = opt?.actionType === "REMOVE" ? "REMOVE" : "ADD";
          if (actionType === "REMOVE" && !found.option.isRemovable) {
            return res.status(400).json({
              error: true,
              message: `Bu seçenek çıkarılamaz: ${found.option.name}`
            });
          }

          let totalOptionLinePrice = 0;
          if (actionType === "ADD") {
            const prevUnits = groupSelectionUnits.get(found.groupId) ?? 0;
            const nextUnits = prevUnits + rawQty;
            groupSelectionUnits.set(found.groupId, nextUnits);

            const freeLeft = Math.max(0, found.freeSelectionsCount - prevUnits);
            const paidUnits = Math.max(0, rawQty - freeLeft);
            const dbUnitOptionPrice = Math.max(0, Number(found.option.price));
            totalOptionLinePrice = Number((paidUnits * dbUnitOptionPrice).toFixed(2));
            optionsPrice += totalOptionLinePrice;
          }

          resolvedOptions.push({
            groupName: found.groupName,
            name: found.option.name,
            price: rawQty > 0 ? Number((totalOptionLinePrice / rawQty).toFixed(2)) : 0,
            quantity: rawQty,
            actionType,
            optionId: found.option.id,
          });
        }

        for (const group of product.optionGroups) {
          const activeCount = group.options.length;
          if (activeCount === 0) continue;
          const selectedCount = groupSelectionUnits.get(group.id) ?? 0;
          if (group.minSelections > 0 && selectedCount < group.minSelections) {
            return res.status(400).json({
              error: true,
              message: `"${product.name}" için "${group.name}" grubundan en az ${group.minSelections} seçim yapmalısınız.`
            });
          }
          if (group.maxSelections !== null && group.maxSelections > 0 && selectedCount > group.maxSelections) {
            return res.status(400).json({
              error: true,
              message: `"${product.name}" için "${group.name}" grubundan en fazla ${group.maxSelections} seçim yapabilirsiniz.`
            });
          }
        }

        const unitPrice = Number((baseProductPrice + optionsPrice).toFixed(2));
        if (!Number.isFinite(unitPrice) || unitPrice <= 0) {
          return res.status(400).json({
            error: true,
            message: `Ürün birim fiyatı sıfırdan büyük olmalıdır: ${product.name}`
          });
        }

        totalAmount += unitPrice * item.quantity;
        resolvedItems.push({
          productId: product.id,
          quantity: item.quantity,
          unitPrice,
          options: resolvedOptions,
        });
      }

      totalAmount = Number(totalAmount.toFixed(2));
      if (!Number.isFinite(totalAmount) || totalAmount <= 0) {
        return res.status(400).json({
          error: true,
          message: "Sipariş toplam tutarı geçersiz."
        });
      }

      // 4. Minimum dükkan sipariş limiti kontrolü (Story 49.1: Bloklanmıyor, kuryeli ise SOS uygulanıyor)

      // 5. Adres Çözümleme ve Snapshot Oluşturma
      let finalAddressId = addressId;
      let snapshotAddress = "";
      let userAddressObj: any = null;

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
        userAddressObj = userAddress;
      } else if (deliveryAddress && typeof deliveryAddress === "string") {
        // Direkt metin olarak adres girildiyse, veritabanına Address olarak kaydet/bul ve snapshot'ı metin yap
        let existingAddress = await prisma.address.findFirst({
          where: { userId: consumerId, fullAddress: deliveryAddress }
        });

        if (existingAddress) {
          finalAddressId = existingAddress.id;
          snapshotAddress = `${existingAddress.title}: ${existingAddress.fullAddress}`;
          userAddressObj = existingAddress;
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
          userAddressObj = newAddress;
        }
      } else {
        return res.status(400).json({ error: true, message: "Sipariş için geçerli bir teslimat adresi belirtilmelidir." });
      }

      // 5.5. Tahmini Teslimat Süresi Hesaplama (Null-Safe Haversine)
      let estimatedDeliveryDuration = 30; // Varsayılan süre

      if (
        shop &&
        shop.latitude != null &&
        shop.longitude != null &&
        userAddressObj &&
        userAddressObj.latitude != null &&
        userAddressObj.longitude != null
      ) {
        try {
          const R = 6371; // Earth's radius in km
          const dLat = (shop.latitude - userAddressObj.latitude) * Math.PI / 180;
          const dLng = (shop.longitude - userAddressObj.longitude) * Math.PI / 180;
          const a =
            Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(userAddressObj.latitude * Math.PI / 180) *
              Math.cos(shop.latitude * Math.PI / 180) *
              Math.sin(dLng / 2) *
              Math.sin(dLng / 2);
          const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
          const distance = R * c;
          estimatedDeliveryDuration = 20 + Math.round(distance * 4);
        } catch (err) {
          console.error("Haversine distance calculation error:", err);
          estimatedDeliveryDuration = 30; // Fallback
        }
      }

      const configuredBaseUrl = (process.env.PUBLIC_BASE_URL || "")
        .replace(/^["']|["']$/g, "")
        .trim()
        .replace(/\/+$/, "");
      if (!configuredBaseUrl && process.env.NODE_ENV === "production") {
        return res.status(500).json({
          error: true,
          message: "Sunucu ödeme geri dönüş adresi yapılandırılmamış.",
        });
      }
      const requestBaseUrl =
        configuredBaseUrl || `http://localhost:${process.env.PORT || 3000}`;

      // 6. Prisma `$transaction` ile sipariş ve kalemleri kaydet
      const transactionResult = await prisma.$transaction(async (tx) => {
        const method = paymentMethod || "CASH_ON_DELIVERY";

        // Backend Delivery Fee Calculation via Campaign Engine
        const deliveryResult = await campaignService.calculateDeliveryFee(consumerId, shop, totalAmount);
        let finalDeliveryFee = chosenFulfillment === "PICKUP" ? 0 : deliveryResult.fee;

        // Dinamik Komisyon Hesaplama
        let commissionRate = 0.05; // default 5%
        if (chosenFulfillment !== "PICKUP") {
          const now = new Date();
          const activePromotions = await tx.shopPromotion.findMany({
            where: {
              shopId,
              isActive: true,
              startDate: { lte: now },
              endDate: { gte: now }
            }
          });

          const hasMainScreen = activePromotions.some(p => p.promoType === "MAIN_SCREEN");
          const hasCategory = activePromotions.some(p => p.promoType === "CATEGORY");

          if (hasMainScreen) {
            commissionRate = 0.15;
          } else if (hasCategory) {
            commissionRate = 0.10;
          }
        }

        const commissionAmount = totalAmount * commissionRate;

        // Small Order Surcharge (SOS) - Story 49.1
        if (chosenFulfillment === "PLATFORM_DELIVERY" && totalAmount < Number(shop.minimumOrderLimit)) {
          const sos = 80 - 40 - (totalAmount * commissionRate);
          if (sos > 0) {
            finalDeliveryFee += sos;
          }
        }

        const createdOrder = await tx.order.create({
          data: {
            consumerId,
            shopId,
            addressId: finalAddressId,
            deliveryAddress: snapshotAddress, // immutable adres snapshot'ı
            totalAmount,
            deliveryFee: finalDeliveryFee,
            status: "PENDING",
            fulfillmentModel: chosenFulfillment as any,
            customerNote: notes || null,
            paymentMethod: method,
            paymentStatus: "PENDING",
            estimatedDeliveryDuration: estimatedDeliveryDuration,
            dontRingBell: dontRingBell === true || dontRingBell === "true",
            leaveAtDoor: leaveAtDoor === true || leaveAtDoor === "true",
            substitutionPreference: substitutionPreference || "SUBSTITUTE",
            commissionRate,
            commissionAmount,
            referringSource: referringSource || "ORGANIC",
            shopCampaignId: shopCampaignId || null
          }
        });

        for (const rItem of resolvedItems) {
          await tx.orderItem.create({
            data: {
              orderId: createdOrder.id,
              productId: rItem.productId,
              quantity: rItem.quantity,
              unitPrice: rItem.unitPrice,
              options: rItem.options.length > 0 ? {
                create: rItem.options.map((opt) => ({
                  groupName: opt.groupName,
                  name: opt.name,
                  price: opt.price,
                  quantity: opt.quantity,
                  actionType: opt.actionType,
                  optionId: opt.optionId
                }))
              } : undefined
            }
          });
        }

        let paymentUrl = undefined;

        const orderTotal = Number(totalAmount) + Number(finalDeliveryFee);
        let remainingAmount = orderTotal;
        let walletDeducted = 0;

        // Hoppa Cüzdan kullanımı (Switch açık veya yöntem WALLET ise)
        if (useWallet || method === "WALLET") {
          const wallet = await WalletService.getOrCreateWallet(consumerId, tx);
          const currentBalance = Number(wallet.balance);

          if (currentBalance > 0) {
            walletDeducted = Math.min(currentBalance, orderTotal);
            await WalletService.withdraw(
              consumerId,
              walletDeducted,
              `Sipariş Ödemesi (Sipariş No: ${createdOrder.id})`,
              tx
            );
            remainingAmount = orderTotal - walletDeducted;
          }
        }

        if (remainingAmount <= 0) {
          // Sipariş tamamen Hoppa Cüzdan ile ödendi
          await tx.order.update({
            where: { id: createdOrder.id },
            data: {
              paymentMethod: "WALLET",
              paymentStatus: "SUCCESS"
            }
          });
        } else if (method === "ONLINE_PAYMENT") {
          if (!cardDetails) {
            throw Object.assign(new Error("Online ödeme için kart özeti (BIN/token) gereklidir."), {
              statusCode: 400,
            });
          }
          if (cardDetails.cardNumber || cardDetails.cvc) {
            throw Object.assign(
              new Error(
                "Güvenlik (PCI-DSS) gereği tam kart numarası ve CVC kabul edilmez."
              ),
              { statusCode: 400 }
            );
          }

          const routeResponse = await PaymentRoutingService.routePayment({
            orderId: createdOrder.id,
            amount: remainingAmount,
            cardDetails,
            baseUrl: requestBaseUrl,
            customerIp: req.ip
          });

          await tx.paymentTransaction.create({
            data: {
              orderId: createdOrder.id,
              amount: routeResponse.amount,
              currency: routeResponse.currency,
              exchangeRate: routeResponse.exchangeRate,
              provider: routeResponse.provider,
              routingType: routeResponse.routingType,
              status: routeResponse.status,
              providerTxId: routeResponse.providerTxId
            }
          });

          paymentUrl = routeResponse.paymentUrl;
        } else if (method === "WALLET") {
          throw Object.assign(new Error("Hoppa Cüzdan bakiyeniz bu sipariş için yetersizdir."), {
            statusCode: 400,
          });
        }

        return { createdOrder, paymentUrl };
      });

      // Oluşturulan siparişi detaylıca döndür
      const fullOrder = await prisma.order.findUnique({
        where: { id: transactionResult.createdOrder.id },
        include: {
          shop: { select: { name: true, imageUrl: true } },
          address: true,
          items: {
            include: {
              product: { select: { name: true, imageUrl: true } },
              options: true
            }
          }
        }
      });

      const isPaymentConfirmedForMerchant =
        fullOrder?.paymentMethod !== "ONLINE_PAYMENT" ||
        fullOrder?.paymentStatus === "SUCCESS";

      // Send Push Notification asynchronously to Merchant only after payment confirmation (or offline/wallet payment)
      if (shop.merchantId && isPaymentConfirmedForMerchant) {
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

      try {
        const orderId = fullOrder?.id || transactionResult.createdOrder.id;
        const newOrderPayload = {
          orderId,
          shopId: shop.id,
          shopName: shop.name,
          consumerId,
          status: fullOrder?.status || transactionResult.createdOrder.status,
          paymentMethod: fullOrder?.paymentMethod || transactionResult.createdOrder.paymentMethod,
          paymentStatus: fullOrder?.paymentStatus || transactionResult.createdOrder.paymentStatus,
          totalAmount: Number(fullOrder?.totalAmount ?? transactionResult.createdOrder.totalAmount),
          deliveryFee: Number(fullOrder?.deliveryFee ?? transactionResult.createdOrder.deliveryFee),
          createdAt: (fullOrder?.createdAt || transactionResult.createdOrder.createdAt).toISOString()
        };
        if (isPaymentConfirmedForMerchant) {
          realtimeEventService.publishToShop(shop.id, "NEW_ORDER", newOrderPayload);
        }
        realtimeEventService.publishToUser(consumerId, "NEW_ORDER", newOrderPayload);
      } catch (sseError) {
        console.error("[OrderController.createOrder] SSE NEW_ORDER yayın hatası:", sseError);
      }

      return res.status(201).json({
        error: false,
        data: fullOrder,
        paymentUrl: transactionResult.paymentUrl
      });
    } catch (error: any) {
      const statusCode = typeof error?.statusCode === "number" ? error.statusCode : 500;
      if (statusCode >= 500) {
        console.error("[OrderController.createOrder] Hatası:", error);
      }
      return res.status(statusCode).json({
        error: true,
        message: statusCode < 500 ? error.message : "Sipariş oluşturulamadı.",
      });
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
          shop: {
            include: {
              merchant: { select: SAFE_MERCHANT_PUBLIC_SELECT }
            }
          },
          address: true,
          consumer: { select: { name: true, surname: true, phone: true } },
          courier: true,
          items: {
            include: {
              product: { select: { name: true, imageUrl: true } },
              options: true
            }
          },
          review: true
        },
        orderBy: { createdAt: "desc" }
      });

      return res.status(200).json({ error: false, data: orders });
    } catch (error: any) {
      console.error("[OrderController.getConsumerOrders] Hatası:", error);
      return res.status(500).json({ error: true, message: "Siparişler getirilemedi." });
    }
  }

  /**
   * Tüketici için canlı sipariş ve kurye takip verilerini getir
   * GET /api/consumer/orders/:id/tracking
   */
  async getOrderTracking(req: Request, res: Response) {
    try {
      const consumerId = req.user?.id;
      const id = String(req.params.id);

      if (!consumerId) {
        return res.status(401).json({ error: true, message: "Kullanıcı bilgisi eksik." });
      }

      const order = await prisma.order.findFirst({
        where: {
          id,
          consumerId,
        },
        include: {
          shop: {
            include: {
              merchant: { select: SAFE_MERCHANT_PUBLIC_SELECT },
            },
          },
          address: true,
          courier: {
            include: {
              locations: {
                orderBy: { updatedAt: 'desc' },
                take: 1,
              },
            },
          },
          items: {
            include: {
              product: { select: { name: true, imageUrl: true } },
              options: true,
            },
          },
        },
      });

      if (!order) {
        return res.status(404).json({ error: true, message: "Sipariş bulunamadı." });
      }

      const latestLocation = order.courier?.locations?.[0] || null;

      const trackingData = {
        order: {
          id: order.id,
          status: order.status,
          createdAt: order.createdAt,
          fulfillmentModel: order.fulfillmentModel,
          deliveryAddress: order.deliveryAddress,
          addressLatitude: order.address?.latitude || 35.1856,
          addressLongitude: order.address?.longitude || 33.3823,
          customerNote: order.customerNote,
          dontRingBell: order.dontRingBell,
          leaveAtDoor: order.leaveAtDoor,
          totalAmount: order.totalAmount,
          deliveryFee: order.deliveryFee,
        },
        shop: {
          id: order.shop.id,
          name: order.shop.name,
          imageUrl: order.shop.imageUrl,
          address: order.shop.address,
          latitude: order.shop.latitude || 35.1856,
          longitude: order.shop.longitude || 33.3823,
          phone: (order.shop as any).phone || (order.shop as any).merchant?.phone || '',
        },
        courier: order.courier ? {
          id: order.courier.id,
          name: order.courier.name,
          phoneNumber: order.courier.phoneNumber,
          vehiclePlate: order.courier.vehiclePlate,
          vehicleType: order.courier.vehicleType,
          isActive: order.courier.isActive,
          location: latestLocation ? {
            latitude: latestLocation.latitude,
            longitude: latestLocation.longitude,
            bearing: latestLocation.bearing,
            updatedAt: latestLocation.updatedAt,
          } : null,
        } : null,
      };

      return res.status(200).json({ error: false, data: trackingData });
    } catch (error: any) {
      console.error("Tracking fetch error:", error);
      return res.status(500).json({ error: true, message: "Takip verileri alınamadı." });
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
        where: {
          shopId: shop.id,
          OR: [
            { paymentMethod: { not: "ONLINE_PAYMENT" } },
            { paymentStatus: { in: ["SUCCESS", "REFUNDED"] } },
          ],
        },
        include: {
          shop: {
            include: {
              merchant: { select: SAFE_MERCHANT_PUBLIC_SELECT }
            }
          },
          address: true,
          consumer: { select: { name: true, surname: true, phone: true } },
          courier: true,
          items: {
            include: {
              product: { select: { name: true, imageUrl: true } },
              options: true
            }
          },
          review: true
        },
        orderBy: { createdAt: "desc" }
      });

      return res.status(200).json({ error: false, data: orders });
    } catch (error: any) {
      console.error("[OrderController.getMerchantOrders] Hatası:", error);
      return res.status(500).json({ error: true, message: "İşletme siparişleri getirilemedi." });
    }
  }

  private async findBestCourier(shopId: string, shopLat: number, shopLng: number): Promise<any> {
    const couriers = await prisma.courier.findMany({
      where: {
        status: "APPROVED",
        isActive: true
      },
      include: {
        shops: true,
        locations: {
          orderBy: { updatedAt: "desc" },
          take: 1
        },
        orders: {
          where: {
            status: {
              in: ["PREPARING", "READY_FOR_PICKUP", "ON_THE_WAY"]
            }
          }
        }
      }
    });

    const idleCouriers = couriers.filter(c => c.orders.length === 0);
    if (idleCouriers.length === 0) {
      return null;
    }

    const calculateDistance = (lat1: number, lon1: number, lat2: number, lon2: number) => {
      const R = 6371; // km
      const dLat = (lat2 - lat1) * Math.PI / 180;
      const dLon = (lon2 - lon1) * Math.PI / 180;
      const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      return R * c;
    };

    const dedicatedIdle = idleCouriers.filter(c => c.shops.some(s => s.shopId === shopId));
    if (dedicatedIdle.length > 0) {
      let bestCourier = dedicatedIdle[0];
      let minDistance = Infinity;
      for (const courier of dedicatedIdle) {
        if (courier.locations.length > 0) {
          const dist = calculateDistance(shopLat, shopLng, courier.locations[0].latitude, courier.locations[0].longitude);
          if (dist < minDistance) {
            minDistance = dist;
            bestCourier = courier;
          }
        }
      }
      return bestCourier;
    }

    let bestGeographicCourier = null;
    let minGeographicDistance = Infinity;

    for (const courier of idleCouriers) {
      if (courier.locations.length > 0) {
        const dist = calculateDistance(shopLat, shopLng, courier.locations[0].latitude, courier.locations[0].longitude);
        if (dist <= courier.maxServiceDistanceKm && dist < minGeographicDistance) {
          minGeographicDistance = dist;
          bestGeographicCourier = courier;
        }
      }
    }

    return bestGeographicCourier;
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

      let updateData: any = {
        status: upperStatus,
        ...(updatedPaymentStatus ? { paymentStatus: updatedPaymentStatus as PaymentStatus } : {})
      };

      if (upperStatus === "ON_THE_WAY") {
        const shop = await prisma.shop.findUnique({
          where: { id: order.shopId }
        });
        const shopLat = shop?.latitude || 35.1856;
        const shopLng = shop?.longitude || 33.3823;

        let courier = await this.findBestCourier(order.shopId, shopLat, shopLng);

        // Müsait kurye yoksa yalnızca geliştirme/sandbox ortamında mock kurye kullan (M-05: Prod'da asla sahte kayıt oluşturma)
        if (!courier && process.env.NODE_ENV !== "production") {
          courier = await prisma.courier.findFirst({
            where: { phoneNumber: "+905555555555" }
          });
          if (!courier) {
            let courierUser = await prisma.user.findUnique({
              where: { phone: "+905555555555" }
            });
            if (!courierUser) {
              courierUser = await prisma.user.create({
                data: {
                  phone: "+905555555555",
                  role: "courier",
                  name: "Süleyman",
                  surname: "Kurye"
                }
              });
            }
            courier = await prisma.courier.create({
              data: {
                userId: courierUser.id,
                name: "Süleyman Kurye",
                phoneNumber: "+905555555555",
                vehiclePlate: "34 HO 9999",
                isActive: true,
                status: "APPROVED"
              }
            });
          }
        }
        if (courier) {
          updateData.courierId = courier.id;
        }
      }

      const updatedOrder = await prisma.order.update({
        where: { id: orderId },
        data: updateData,
        include: {
          shop: {
            include: {
              merchant: { select: SAFE_MERCHANT_PUBLIC_SELECT }
            }
          },
          address: true,
          consumer: { select: { name: true, surname: true, phone: true } },
          courier: true,
          items: {
            include: {
              product: { select: { name: true, imageUrl: true } },
              options: true
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

          switch (upperStatus) {
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

      try {
        const statusPayload = {
          orderId: updatedOrder.id,
          shopId: updatedOrder.shopId,
          consumerId: updatedOrder.consumerId,
          status: updatedOrder.status,
          paymentStatus: updatedOrder.paymentStatus,
          courierId: updatedOrder.courierId ?? null
        };
        realtimeEventService.publishToShop(updatedOrder.shopId, "ORDER_STATUS_UPDATED", statusPayload);
        realtimeEventService.publishToUser(updatedOrder.consumerId, "ORDER_STATUS_UPDATED", statusPayload);
      } catch (sseError) {
        console.error("[OrderController.updateOrderStatus] SSE ORDER_STATUS_UPDATED yayın hatası:", sseError);
      }

      return res.status(200).json({ error: false, data: updatedOrder });
    } catch (error: any) {
      console.error("[OrderController.updateOrderStatus] Hatası:", error);
      return res.status(500).json({ error: true, message: "Sipariş durumu güncellenemedi." });
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
      if (role === "user" || role === "super_admin") {
        if (order.consumerId !== userId && role !== "super_admin") {
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

      const updatedOrder = await prisma.$transaction(async (tx) => {
        const allowedStatuses =
          role === "merchant"
            ? ["PENDING", "PREPARING", "ON_THE_WAY"]
            : ["PENDING"];

        const shouldMarkRefunded =
          order.paymentStatus === "SUCCESS" &&
          (order.paymentMethod === "ONLINE_PAYMENT" || order.paymentMethod === "WALLET");

        const claimed = await tx.order.updateMany({
          where: {
            id: orderId,
            status: { in: allowedStatuses as OrderStatus[] },
          },
          data: {
            status: "CANCELLED",
            cancelReason: cancelReason || "Kullanıcı tarafından iptal edildi",
            cancelledAt: new Date(),
            cancelledBy,
            ...(shouldMarkRefunded ? { paymentStatus: "REFUNDED" } : {}),
          },
        });

        if (claimed.count === 0) {
          throw Object.assign(
            new Error("Sipariş zaten iptal edilmiş veya mevcut durumunda iptal edilemez."),
            { statusCode: 409 }
          );
        }

        const orderTotal = Number(order.totalAmount) + Number(order.deliveryFee);

        if (order.paymentMethod === "WALLET" && order.paymentStatus === "SUCCESS") {
          await WalletService.refund(
            order.consumerId,
            orderTotal,
            `Sipariş İptal İadesi (Sipariş No: ${order.id})`,
            tx
          );
        } else {
          // Kısmi Hoppa Cüzdan kesintisi yapıldıysa (ör. Cüzdan + 3DS) cüzdandan düşülen tutarı tek seferlik iade et
          const wallet = await tx.wallet.findUnique({
            where: { userId: order.consumerId },
            select: { id: true },
          });
          if (wallet) {
            const orderMarker = `Sipariş No: ${order.id}`;
            const [withdrawTx, existingRefundTx] = await Promise.all([
              tx.walletTransaction.findFirst({
                where: {
                  walletId: wallet.id,
                  type: "WITHDRAW",
                  description: { contains: orderMarker },
                },
              }),
              tx.walletTransaction.findFirst({
                where: {
                  walletId: wallet.id,
                  type: "REFUND",
                  description: { contains: orderMarker },
                },
              }),
            ]);

            if (withdrawTx && !existingRefundTx) {
              const partialWalletAmount = Math.abs(Number(withdrawTx.amount));
              if (partialWalletAmount > 0) {
                await WalletService.refund(
                  order.consumerId,
                  partialWalletAmount,
                  `Sipariş İptal Cüzdan İadesi (Sipariş No: ${order.id})`,
                  tx
                );
              }
            }
          }
        }

        return await tx.order.findUniqueOrThrow({ where: { id: orderId } });
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

      try {
        const cancelPayload = {
          orderId: updatedOrder.id,
          shopId: updatedOrder.shopId,
          consumerId: updatedOrder.consumerId,
          status: updatedOrder.status,
          paymentStatus: updatedOrder.paymentStatus,
          cancelReason: updatedOrder.cancelReason,
          cancelledBy: updatedOrder.cancelledBy
        };
        realtimeEventService.publishToShop(updatedOrder.shopId, "ORDER_CANCELLED", cancelPayload);
        realtimeEventService.publishToUser(updatedOrder.consumerId, "ORDER_CANCELLED", cancelPayload);
      } catch (sseError) {
        console.error("[OrderController.cancelOrder] SSE ORDER_CANCELLED yayın hatası:", sseError);
      }

      return res.status(200).json({ error: false, data: updatedOrder });
    } catch (error: any) {
      const statusCode = typeof error?.statusCode === "number" ? error.statusCode : 500;
      if (statusCode >= 500) {
        console.error("[OrderController.cancelOrder] Hatası:", error);
      }
      return res.status(statusCode).json({
        error: true,
        message: statusCode < 500 ? error.message : "Sipariş iptal edilemedi.",
      });
    }
  }
}

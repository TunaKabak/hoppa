import { PrismaClient, Shop } from "@prisma/client";

const prisma = new PrismaClient();

export class CampaignService {
  /**
   * Calculates the final delivery fee based on the user's history,
   * active campaigns, and the shop's delivery pricing configuration.
   */
  async calculateDeliveryFee(userId: string, shop: Shop, cartAmount: number): Promise<{ fee: number, isCampaignApplied: boolean, campaignName?: string }> {
    // 1. Check for active FREE_DELIVERY campaigns (system-wide or allowed shops specific)
    const freeDeliveryCampaigns = await prisma.campaign.findMany({
      where: {
        discountType: "FREE_DELIVERY",
        isActive: true,
        OR: [
          { finishDate: null },
          { finishDate: { gte: new Date() } }
        ]
      },
      include: {
        allowedShops: true
      }
    });

    for (const camp of freeDeliveryCampaigns) {
      // Eğer kampanya tüm dükkanlar için geçerliyse (allowedShops boşsa) 
      // ya da sepet dükkanı allowedShops listesinde tanımlanmışsa kampanya uygulanır.
      const isShopAllowed = camp.allowedShops.length === 0 || 
                            camp.allowedShops.some(cs => cs.shopId === shop.id);
      
      if (isShopAllowed) {
        // Kullanıcının bu kampanyadan sipariş sayısını kontrol et
        const successfulOrdersCount = await prisma.order.count({
          where: {
            consumerId: userId,
            shopCampaignId: camp.id,
            status: {
              in: ["PREPARING", "ON_THE_WAY", "DELIVERED"]
            }
          }
        });

        if (successfulOrdersCount < camp.maxUsesPerUser) {
          return {
            fee: 0.0,
            isCampaignApplied: true,
            campaignName: camp.title
          };
        }
      }
    }

    // 2. Check for active FREE_DELIVERY_FIRST_ORDERS campaign (backward compatibility)
    const firstOrdersCampaign = await prisma.campaign.findFirst({
      where: {
        type: "FREE_DELIVERY_FIRST_ORDERS",
        isActive: true
      }
    });

    if (firstOrdersCampaign) {
      // Check user's successful order count
      const successfulOrdersCount = await prisma.order.count({
        where: {
          consumerId: userId,
          status: {
            in: ["PREPARING", "ON_THE_WAY", "DELIVERED"]
          }
        }
      });

      if (successfulOrdersCount < firstOrdersCampaign.maxUsesPerUser) {
        return {
          fee: 0.0,
          isCampaignApplied: true,
          campaignName: firstOrdersCampaign.title
        };
      }
    }

    // 2. No campaign applied, calculate standard shop delivery fee
    let fee = shop.baseDeliveryFee;

    if (shop.freeDeliveryThreshold && cartAmount >= shop.freeDeliveryThreshold) {
      fee = 0.0;
      return {
        fee,
        isCampaignApplied: true,
        campaignName: "Sepet Tutarı Nedeniyle Ücretsiz"
      };
    } else {
      if (shop.deliveryPricingType === "DISTANCE_BASED") {
        // Distance-based calculation can be added here later if needed
        fee = shop.baseDeliveryFee; 
      }
    }

    return {
      fee,
      isCampaignApplied: false
    };
  }
}

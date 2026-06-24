"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CampaignService = void 0;
const client_1 = require("@prisma/client");
const prisma = new client_1.PrismaClient();
class CampaignService {
    /**
     * Calculates the final delivery fee based on the user's history,
     * active campaigns, and the shop's delivery pricing configuration.
     */
    async calculateDeliveryFee(userId, shop, cartAmount) {
        // 1. Check for active FREE_DELIVERY_FIRST_ORDERS campaign
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
        }
        else {
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
exports.CampaignService = CampaignService;

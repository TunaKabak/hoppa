import { prisma } from "../config/db";
import { SystemConfigService } from "./SystemConfigService";

export class ReferralService {
  /**
   * Benzersiz 8 haneli bir davet kodu üretir.
   */
  static async generateReferralCode(): Promise<string> {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    let code = "";
    let isUnique = false;

    while (!isUnique) {
      code = "";
      for (let i = 0; i < 8; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
      }

      const existingUser = await prisma.user.findUnique({
        where: { referralCode: code }
      });

      if (!existingUser) {
        isUnique = true;
      }
    }

    return code;
  }

  /**
   * Kullanıcı için davet kodu tanımlar (eğer yoksa).
   */
  static async getOrCreateReferralCode(userId: string): Promise<string> {
    const user = await prisma.user.findUnique({
      where: { id: userId }
    });

    if (!user) throw new Error("Kullanıcı bulunamadı.");
    if (user.referralCode) return user.referralCode;

    const newCode = await this.generateReferralCode();
    await prisma.user.update({
      where: { id: userId },
      data: { referralCode: newCode }
    });

    return newCode;
  }

  /**
   * Davet ilişkisini kurar ve ödül kuponlarını oluşturur.
   */
  static async applyReferral(referredUserId: string, referralCode: string) {
    if (!referralCode) return;

    const referrer = await prisma.user.findUnique({
      where: { referralCode }
    });

    if (!referrer) {
      throw new Error("Geçersiz davet kodu.");
    }

    if (referrer.id === referredUserId) {
      throw new Error("Kendinizi davet edemezsiniz.");
    }

    // Zaten biri tarafından davet edilmiş mi kontrolü
    const referredUser = await prisma.user.findUnique({
      where: { id: referredUserId }
    });

    if (!referredUser) throw new Error("Kullanıcı bulunamadı.");
    if (referredUser.referredById) {
      throw new Error("Zaten bir davet kodu kullandınız.");
    }

    // Dinamik indirim tutarını çek (Örn: 100 TL)
    const bonusAmountStr = await SystemConfigService.getSetting("referral_bonus_amount", "100");
    const bonusAmount = parseFloat(bonusAmountStr);

    return await prisma.$transaction(async (tx) => {
      // 1. Davet edene kupon oluştur
      const referrerCouponCode = `INV-${referrer.referralCode}-${Math.floor(1000 + Math.random() * 9000)}`;
      const referrerCoupon = await tx.coupon.create({
        data: {
          code: referrerCouponCode,
          title: "Davet Ödül Kuponu",
          description: `Arkadaşınızı davet ettiğiniz için ${bonusAmount} TL indirim!`,
          discountType: "FIXED",
          discountValue: bonusAmount,
          minOrderAmount: 250.00,
          startDate: new Date(),
          endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 1 hafta
          isActive: true,
          isSystemCoupon: true
        }
      });

      // 2. Davet edilene (yeni üye) kupon oluştur
      const referredCouponCode = `WELCOME-${referredUserId.substring(0, 6).toUpperCase()}-${Math.floor(1000 + Math.random() * 9000)}`;
      const referredCoupon = await tx.coupon.create({
        data: {
          code: referredCouponCode,
          title: "Davet Hoş Geldin Kuponu",
          description: `Davetle üye olduğunuz için ${bonusAmount} TL hoş geldin indirimi!`,
          discountType: "FIXED",
          discountValue: bonusAmount,
          minOrderAmount: 250.00,
          startDate: new Date(),
          endDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 1 hafta
          isActive: true,
          isSystemCoupon: true
        }
      });

      // 3. User tablosunu güncelle (Davet eden ilişkisini kur)
      await tx.user.update({
        where: { id: referredUserId },
        data: { referredById: referrer.id }
      });

      // 4. Referral kaydı oluştur
      const referral = await tx.referral.create({
        data: {
          referrerId: referrer.id,
          referredId: referredUserId,
          couponId: referrerCoupon.id,
          referredCouponId: referredCoupon.id
        }
      });

      return referral;
    });
  }

  /**
   * Davet edilen arkadaşları listeler.
   */
  static async getReferrals(userId: string) {
    const referrals = await prisma.referral.findMany({
      where: { referrerId: userId }
    });

    const referredUserIds = referrals.map(r => r.referredId);
    
    const users = await prisma.user.findMany({
      where: {
        id: { in: referredUserIds }
      },
      select: {
        id: true,
        name: true,
        surname: true,
        phone: true,
        createdAt: true
      }
    });

    const completedOrders = await prisma.order.findMany({
      where: {
        consumerId: { in: referredUserIds },
        status: "DELIVERED"
      },
      select: {
        consumerId: true
      }
    });

    const completedSet = new Set(completedOrders.map(o => o.consumerId));

    return referrals.map(ref => {
      const u = users.find(user => user.id === ref.referredId);
      const isCompleted = completedSet.has(ref.referredId);
      return {
        id: ref.id,
        status: isCompleted ? "COMPLETED" : "PENDING",
        referredUser: u ? {
          name: u.name || "Hoppa",
          surname: u.surname || "Kullanıcısı",
          phone: u.phone,
          createdAt: u.createdAt
        } : null,
        createdAt: ref.createdAt
      };
    });
  }
}

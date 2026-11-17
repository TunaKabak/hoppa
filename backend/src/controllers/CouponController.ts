import { Request, Response } from 'express';
import { prisma } from '../config/db';

export class CouponController {

  // 1. Kullanılabilir Kuponları Listele
  public async getCoupons(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const now = new Date();

      // Tüm aktif kuponları ve referans sahipliklerini çek
      const [coupons, referrals] = await Promise.all([
        prisma.coupon.findMany({
          where: {
            isActive: true,
            startDate: { lte: now },
            endDate: { gte: now }
          },
          include: {
            allowedShops: { select: { shopId: true } },
            usages: {
              where: { userId }
            }
          }
        }),
        prisma.referral.findMany({
          where: {
            OR: [
              { couponId: { not: null } },
              { referredCouponId: { not: null } }
            ]
          },
          select: {
            referrerId: true,
            referredId: true,
            couponId: true,
            referredCouponId: true
          }
        })
      ]);

      const referralOwnerByCouponId = new Map<string, string>();
      for (const ref of referrals) {
        if (ref.couponId) referralOwnerByCouponId.set(ref.couponId, ref.referrerId);
        if (ref.referredCouponId) referralOwnerByCouponId.set(ref.referredCouponId, ref.referredId);
      }

      // Kullanım sınırı dolmamış ve başka kullanıcıya ait olmayan kuponları filtrele
      const availableCoupons = coupons.filter(coupon => {
        const ownerUserId = referralOwnerByCouponId.get(coupon.id);
        if (ownerUserId && ownerUserId !== userId) {
          return false;
        }
        const userUsageCount = coupon.usages.length;
        const limit = ownerUserId ? 1 : 5;
        return userUsageCount < limit;
      });

      res.status(200).json({ error: false, data: availableCoupons });
    } catch (error) {
      console.error("Coupon getCoupons error:", error);
      res.status(500).json({ error: true, message: "Kuponlar yüklenirken hata oluştu." });
    }
  }

  // 2. Sepete Kupon Uygula
  public async applyCoupon(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const { code, shopId, cartAmount } = req.body;

      const parsedCartAmount = Number(cartAmount);
      if (!code || !shopId || cartAmount === undefined || !Number.isFinite(parsedCartAmount) || parsedCartAmount <= 0) {
        res.status(400).json({ error: true, message: "Geçersiz veya eksik parametreler (code, shopId, cartAmount)." });
        return;
      }

      const now = new Date();
      const coupon = await prisma.coupon.findUnique({
        where: { code },
        include: {
          allowedShops: true,
          usages: { where: { userId } }
        }
      });

      if (!coupon || !coupon.isActive || coupon.startDate > now || coupon.endDate < now) {
        res.status(400).json({ error: true, message: "Geçersiz veya süresi dolmuş kupon kodu." });
        return;
      }

      // Referans kuponu IDOR koruması: Kişiye özel davet kuponunu yalnızca hak sahibi kullanabilir
      const linkedReferral = await prisma.referral.findFirst({
        where: {
          OR: [{ couponId: coupon.id }, { referredCouponId: coupon.id }]
        },
        select: {
          referrerId: true,
          referredId: true,
          couponId: true,
          referredCouponId: true
        }
      });

      if (linkedReferral) {
        const ownerId =
          linkedReferral.couponId === coupon.id
            ? linkedReferral.referrerId
            : linkedReferral.referredId;
        if (ownerId !== userId) {
          res.status(403).json({ error: true, message: "Bu davet kuponu başka bir kullanıcıya tanımlanmıştır." });
          return;
        }
      }

      // Kullanım sayısı kontrolü
      const maxUsagePerUser = linkedReferral ? 1 : 5;
      if (coupon.usages.length >= maxUsagePerUser) {
        res.status(400).json({ error: true, message: "Bu kuponu kullanım limitinizi doldurdunuz." });
        return;
      }

      // Minimum sepet tutarı kontrolü
      if (parsedCartAmount < coupon.minOrderAmount) {
        res.status(400).json({ error: true, message: `Bu kuponu kullanabilmek için sepet tutarı en az ${coupon.minOrderAmount} ₺ olmalıdır.` });
        return;
      }

      // İşletme kısıtlaması kontrolü
      // 1. Dükkan kuponu ise ve dükkan uyuşmuyorsa
      if (coupon.creatorShopId && coupon.creatorShopId !== shopId) {
        res.status(400).json({ error: true, message: "Bu kupon seçtiğiniz işletmede geçerli değildir." });
        return;
      }

      // 2. Sistem kuponu ise ve dükkan kısıtlaması varsa, dükkan listede mi?
      if (coupon.isSystemCoupon && coupon.allowedShops.length > 0) {
        const isAllowed = coupon.allowedShops.some(as => as.shopId === shopId);
        if (!isAllowed) {
          res.status(400).json({ error: true, message: "Bu kupon seçtiğiniz işletmede geçerli değildir." });
          return;
        }
      }

      // İndirim tutarını hesapla
      let discountAmount = 0;
      if (coupon.discountType === "PERCENTAGE") {
        discountAmount = (parsedCartAmount * coupon.discountValue) / 100;
        if (coupon.maxDiscountAmount && discountAmount > coupon.maxDiscountAmount) {
          discountAmount = coupon.maxDiscountAmount;
        }
      } else {
        // FIXED
        discountAmount = coupon.discountValue;
      }

      // İndirim sepet tutarından büyük olamaz
      if (discountAmount > parsedCartAmount) {
        discountAmount = parsedCartAmount;
      }

      const finalAmount = parsedCartAmount - discountAmount;

      res.status(200).json({
        error: false,
        data: {
          couponId: coupon.id,
          code: coupon.code,
          discountAmount: parseFloat(discountAmount.toFixed(2)),
          finalAmount: parseFloat(finalAmount.toFixed(2)),
          title: coupon.title
        },
        message: "Kupon başarıyla uygulandı!"
      });
    } catch (error) {
      console.error("Coupon applyCoupon error:", error);
      res.status(500).json({ error: true, message: "Kupon uygulanırken hata oluştu." });
    }
  }

  // 3. Hoşgeldin Kuponu Tanımlama (Yeni kayıt olan kullanıcıya)
  public static async provisionWelcomeCoupon(userId: string): Promise<void> {
    try {
      const welcomeCode = "WELCOME50";
      
      // WELCOME50 kuponu var mı kontrol et, yoksa oluştur
      let coupon = await prisma.coupon.findUnique({
        where: { code: welcomeCode }
      });

      if (!coupon) {
        const now = new Date();
        const future = new Date();
        future.setMonth(future.getMonth() + 12); // 1 yıl geçerli

        coupon = await prisma.coupon.create({
          data: {
            code: welcomeCode,
            title: "Hoş Geldin Kuponu",
            description: "İlk siparişine özel 50 TL Hoppa kuponu!",
            discountType: "FIXED",
            discountValue: 50.0,
            minOrderAmount: 150.0,
            startDate: now,
            endDate: future,
            isActive: true,
            isSystemCoupon: true
          }
        });
      }
      
      console.log(`Welcome coupon provisioned for user: ${userId}`);
    } catch (error) {
      console.error("Error provisioning welcome coupon:", error);
    }
  }
}

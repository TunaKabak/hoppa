import { Request, Response } from 'express';
import { prisma } from '../config/db';

export class CouponController {

  // 1. Kullanılabilir Kuponları Listele
  public async getCoupons(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const now = new Date();

      // Tüm aktif kuponları çek
      const coupons = await prisma.coupon.findMany({
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
      });

      // Kullanım sınırı dolmamış kuponları filtrele
      const availableCoupons = coupons.filter(coupon => {
        // Eğer kullanıcı bu kuponu max limit kadar kullandıysa gösterme
        const userUsageCount = coupon.usages.length;
        // Varsayılan limit 1 olsun (veritabanı alanını story_40'taki modelden aldık, modelde 1 yoksa config)
        const limit = 5; // default limit
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

      if (!code || !shopId || cartAmount === undefined) {
        res.status(400).json({ error: true, message: "Eksik parametreler (code, shopId, cartAmount)." });
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

      // Kullanım sayısı kontrolü
      if (coupon.usages.length >= 5) { // varsayılan limit 5
        res.status(400).json({ error: true, message: "Bu kuponu kullanım limitinizi doldurdunuz." });
        return;
      }

      // Minimum sepet tutarı kontrolü
      if (cartAmount < coupon.minOrderAmount) {
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
        discountAmount = (cartAmount * coupon.discountValue) / 100;
        if (coupon.maxDiscountAmount && discountAmount > coupon.maxDiscountAmount) {
          discountAmount = coupon.maxDiscountAmount;
        }
      } else {
        // FIXED
        discountAmount = coupon.discountValue;
      }

      // İndirim sepet tutarından büyük olamaz
      if (discountAmount > cartAmount) {
        discountAmount = cartAmount;
      }

      const finalAmount = cartAmount - discountAmount;

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

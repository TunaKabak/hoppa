import { prisma } from "../config/db";
import { WalletTransactionType } from "@prisma/client";

export class WalletService {
  /**
   * Kullanıcının cüzdanını getirir veya yoksa oluşturur.
   */
  static async getOrCreateWallet(userId: string, client: any = prisma) {
    let wallet = await client.wallet.findUnique({
      where: { userId },
      include: {
        transactions: {
          orderBy: { createdAt: "desc" }
        }
      }
    });

    if (!wallet) {
      wallet = await client.wallet.create({
        data: {
          userId,
          balance: 0.00
        },
        include: {
          transactions: true
        }
      });
    }

    return wallet;
  }

  /**
   * Cüzdana para yükler (DEPOSIT).
   */
  static async deposit(userId: string, amount: number, description = "Cüzdana Bakiye Yükleme", client: any = prisma) {
    if (amount <= 0) throw new Error("Yüklenecek tutar 0'dan büyük olmalıdır.");

    const execute = async (tx: any) => {
      const wallet = await tx.wallet.upsert({
        where: { userId },
        update: {
          balance: { increment: amount }
        },
        create: {
          userId,
          balance: amount
        }
      });

      await tx.walletTransaction.create({
        data: {
          walletId: wallet.id,
          amount,
          type: WalletTransactionType.DEPOSIT,
          description
        }
      });

      return wallet;
    };

    if (client === prisma) {
      return await prisma.$transaction(async (tx) => execute(tx));
    } else {
      return await execute(client);
    }
  }

  /**
   * Cüzdandan harcama yapar (WITHDRAW).
   */
  static async withdraw(userId: string, amount: number, description = "Cüzdan ile Ödeme", client: any = prisma) {
    if (amount <= 0) throw new Error("Harcama tutarı 0'dan büyük olmalıdır.");

    const execute = async (tx: any) => {
      const wallet = await tx.wallet.findUnique({
        where: { userId }
      });

      if (!wallet || Number(wallet.balance) < amount) {
        throw new Error("Cüzdan bakiyesi yetersiz.");
      }

      const updatedWallet = await tx.wallet.update({
        where: { userId },
        data: {
          balance: { decrement: amount }
        }
      });

      await tx.walletTransaction.create({
        data: {
          walletId: wallet.id,
          amount: -amount, // Harcama eksi olarak yansır
          type: WalletTransactionType.WITHDRAW,
          description
        }
      });

      return updatedWallet;
    };

    if (client === prisma) {
      return await prisma.$transaction(async (tx) => execute(tx));
    } else {
      return await execute(client);
    }
  }

  /**
   * Cüzdana iade yapar (REFUND).
   */
  static async refund(userId: string, amount: number, description = "Sipariş İadesi", client: any = prisma) {
    if (amount <= 0) throw new Error("İade tutarı 0'dan büyük olmalıdır.");

    const execute = async (tx: any) => {
      const wallet = await tx.wallet.upsert({
        where: { userId },
        update: {
          balance: { increment: amount }
        },
        create: {
          userId,
          balance: amount
        }
      });

      await tx.walletTransaction.create({
        data: {
          walletId: wallet.id,
          amount,
          type: WalletTransactionType.REFUND,
          description
        }
      });

      return wallet;
    };

    if (client === prisma) {
      return await prisma.$transaction(async (tx) => execute(tx));
    } else {
      return await execute(client);
    }
  }

  /**
   * Cüzdana ödül / Hoppa Para ekler (REFERRAL_BONUS veya REVIEW_BONUS).
   * @param expiryDays Ödülün geçerlilik süresi (gün olarak). undefined ise süresiz.
   */
  static async addReward(
    userId: string, 
    amount: number, 
    type: "REFERRAL_BONUS" | "REVIEW_BONUS",
    description: string,
    expiryDays?: number,
    client: any = prisma
  ) {
    if (amount <= 0) throw new Error("Ödül tutarı 0'dan büyük olmalıdır.");

    const expiresAt = expiryDays 
      ? new Date(Date.now() + expiryDays * 24 * 60 * 60 * 1000)
      : null;

    const execute = async (tx: any) => {
      const wallet = await tx.wallet.upsert({
        where: { userId },
        update: {
          balance: { increment: amount }
        },
        create: {
          userId,
          balance: amount
        }
      });

      await tx.walletTransaction.create({
        data: {
          walletId: wallet.id,
          amount,
          type,
          description,
          expiresAt
        }
      });

      return wallet;
    };

    if (client === prisma) {
      return await prisma.$transaction(async (tx) => execute(tx));
    } else {
      return await execute(client);
    }
  }

  /**
   * Süresi dolan Hoppa Paraları (Reward) cüzdan bakiyelerinden düşer.
   * Bu fonksiyon cron job tarafından periyodik olarak tetiklenmelidir.
   */
  static async processExpiredRewards() {
    const now = new Date();

    // 1. Süresi geçmiş ve henüz işlenmemiş bonus işlemleri bul
    const expiredTransactions = await prisma.walletTransaction.findMany({
      where: {
        expiresAt: { lt: now },
        isExpiredProcessed: false,
        type: { in: [WalletTransactionType.REFERRAL_BONUS, WalletTransactionType.REVIEW_BONUS] }
      },
      include: {
        wallet: true
      }
    });

    if (expiredTransactions.length === 0) {
      return;
    }

    console.log(`[WalletService] ${expiredTransactions.length} adet süresi dolmuş ödül işlemi tespit edildi. İşleniyor...`);

    // 2. Cüzdan bazında grupla ve bakiyeleri güncelle
    for (const tx of expiredTransactions) {
      try {
        await prisma.$transaction(async (prismaTx) => {
          const currentWallet = await prismaTx.wallet.findUnique({
            where: { id: tx.walletId }
          });

          if (!currentWallet) return;

          // Düşülecek tutar (cüzdan bakiyesini eksiye düşürmeyecek şekilde sınırla)
          const deductAmount = Math.min(Number(currentWallet.balance), Number(tx.amount));

          if (deductAmount > 0) {
            // Cüzdandan düş
            await prismaTx.wallet.update({
              where: { id: tx.walletId },
              data: {
                balance: { decrement: deductAmount }
              }
            });

            // Süre aşımı işlemini kaydet
            await prismaTx.walletTransaction.create({
              data: {
                walletId: tx.walletId,
                amount: -deductAmount,
                type: WalletTransactionType.WITHDRAW,
                description: `Süre Aşımı Nedeniyle Hediye Bakiye Düşümü (İşlem: ${tx.id})`
              }
            });
          }

          // İşlemi tamamlandı olarak işaretle
          await prismaTx.walletTransaction.update({
            where: { id: tx.id },
            data: { isExpiredProcessed: true }
          });
        });
      } catch (err) {
        console.error(`[WalletService] Hediye bakiye süre aşımı düşüm hatası (İşlem ID: ${tx.id}):`, err);
      }
    }

    console.log(`[WalletService] Süresi dolan ödül işlemleri başarıyla tamamlandı.`);
  }
}

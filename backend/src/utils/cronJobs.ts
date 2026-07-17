import cron from "node-cron";
import { MatchingEngine } from "../services/MatchingEngine";
import { WalletService } from "../services/WalletService";

export const initCronJobs = (): void => {
  // Her dakikada bir çalışacak zamanlayıcı
  cron.schedule("* * * * *", async () => {
    console.log("[CRON] Otomatik kurye atama taraması başlatılıyor...");
    await MatchingEngine.autoAssignOrders();
  });

  // Her gün gece yarısı 00:00'da çalışacak zamanlayıcı (Süresi dolan Hoppa Paraları temizler)
  cron.schedule("0 0 * * *", async () => {
    console.log("[CRON] Süresi dolan hediye bakiyelerinin tespiti ve düşümü başlatılıyor...");
    await WalletService.processExpiredRewards();
  });

  console.log("⏰ Cron Jobs initialized successfully.");
};

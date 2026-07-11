import cron from "node-cron";
import { MatchingEngine } from "../services/MatchingEngine";

export const initCronJobs = (): void => {
  // Her dakikada bir çalışacak zamanlayıcı
  cron.schedule("* * * * *", async () => {
    console.log("[CRON] Otomatik kurye atama taraması başlatılıyor...");
    await MatchingEngine.autoAssignOrders();
  });

  console.log("⏰ Cron Jobs initialized successfully.");
};

import { prisma } from "../config/db";

export class SystemConfigService {
  /**
   * Ayarı getirir, yoksa varsayılan değeri döner ve veritabanına kaydeder.
   */
  static async getSetting(key: string, defaultValue: string): Promise<string> {
    try {
      let config = await prisma.systemConfig.findUnique({
        where: { key }
      });

      if (!config) {
        config = await prisma.systemConfig.create({
          data: { key, value: defaultValue }
        });
      }

      return config.value;
    } catch (err) {
      console.error(`Error fetching system config for ${key}:`, err);
      return defaultValue;
    }
  }

  /**
   * Ayar değerini günceller.
   */
  static async updateSetting(key: string, value: string) {
    return await prisma.systemConfig.upsert({
      where: { key },
      update: { value },
      create: { key, value }
    });
  }
}

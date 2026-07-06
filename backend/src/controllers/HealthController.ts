import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export class HealthController {
  
  /**
   * Sunucu ve Supabase Veritabanı Sağlık Durumunu Kontrol Eder
   * GET /api/public/health
   */
  public static async checkHealth(req: Request, res: Response): Promise<void> {
    try {
      // Supabase / PostgreSQL bağlantısını en hafif SQL sorgusuyla test et
      await prisma.$queryRaw`SELECT 1`;

      res.status(200).json({
        error: false,
        status: "UP",
        database: "CONNECTED",
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      console.error("🚨 Sunucu Sağlık Kontrolü Başarısız:", error);
      
      res.status(503).json({
        error: true,
        status: "DOWN",
        database: "DISCONNECTED",
        message: "Veritabanı bağlantısı kurulamadı."
      });
    }
  }
}

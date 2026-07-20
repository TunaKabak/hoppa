import { Request, Response } from 'express';
import { BatchingService } from '../services/BatchingService';

export class FleetAIController {
  
  public async optimizeRoutes(req: Request, res: Response): Promise<void> {
    try {
      const optimizedBatches = await BatchingService.optimizeBatches();

      res.status(200).json({
        error: false,
        message: "Rota ve sipariş kümeleme (Batching) optimizasyonu başarıyla hesaplandı.",
        data: {
          timestamp: new Date(),
          totalBatchesCreated: optimizedBatches.length,
          batches: optimizedBatches
        }
      });
    } catch (error: any) {
      console.error("[FleetAIController.optimizeRoutes] Hatası:", error);
      res.status(500).json({
        error: true,
        message: "Lojistik optimizasyonu hesaplanırken hata oluştu.",
        details: error.message
      });
    }
  }
}

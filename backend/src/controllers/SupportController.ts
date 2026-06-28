import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Gemini API Yapılandırması (Gereksinim uyarınca runtime key kullanılır)
const apiKey = process.env.GEMINI_API_KEY || ""; 

export class SupportController {

  // Üstel geri çekilme (exponential backoff) fonksiyonu
  private static async fetchWithRetry(url: string, options: any, retries = 5, delay = 1000): Promise<any> {
    try {
      const response = await fetch(url, options);
      if (response.ok) return await response.json();
      
      if (retries > 0 && (response.status === 429 || response.status >= 500)) {
        await new Promise(resolve => setTimeout(resolve, delay));
        return await this.fetchWithRetry(url, options, retries - 1, delay * 2);
      }
      throw new Error(`HTTP Error: ${response.status} - ${response.statusText}`);
    } catch (error) {
      if (retries > 0) {
        await new Promise(resolve => setTimeout(resolve, delay));
        return await this.fetchWithRetry(url, options, retries - 1, delay * 2);
      }
      throw error;
    }
  }

  public static async chatWithAssistant(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const { message, activeOrderId } = req.body;

      if (!message) {
        res.status(400).json({ error: true, message: "Mesaj alanı boş bırakılamaz." });
        return;
      }

      // 🚨 MÜKEMMEL AKILLI BAĞLAM ENJEKSİYONU (Context Injection):
      // Kullanıcının varsa seçtiği veya son aktif siparişini veritabanından çekiyoruz
      let orderContext = "Kullanıcının şu anda aktif bir siparişi bulunmamaktadır.";
      if (activeOrderId) {
        const order = await prisma.order.findUnique({
          where: { id: activeOrderId },
          include: {
            shop: { select: { name: true } },
            items: {
              include: {
                product: { select: { name: true } }
              }
            }
          }
        });

        if (order && order.consumerId === userId) {
          orderContext = `
            Kullanıcının aktif sipariş detayları:
            - Sipariş ID: ${order.id}
            - İşletme Adı: ${order.shop.name}
            - Sipariş Durumu: ${order.status} (PENDING: Onay bekliyor, PREPARING: Hazırlanıyor, ON_THE_WAY: Kurye Yolda, READY_FOR_PICKUP: Gel Al Hazır, DELIVERED: Teslim edildi)
            - Sipariş Verilme Zamanı: ${order.createdAt}
            - Alınan Ürünler: ${order.items.map(i => `${i.product.name} (${i.quantity} adet)`).join(", ")}
            - Ödeme Tipi: ${order.paymentMethod}
          `;
        }
      }

      // Yapay zeka sistem talimatları (System Instruction)
      const systemInstruction = `
        Sen KKTC'nin yerel teslimat uygulaması Hoppa'nın akıllı yapay zeka asistanısın. Görevin, kullanıcılara siparişleri ve teslimat süreçleri hakkında Kıbrıslı samimiyeti ve yüksek profesyonellikle yardımcı olmaktır.
        
        ${orderContext}
        
        KURALLAR:
        1. Kullanıcının aktif siparişi "PREPARING" (Hazırlanıyor) aşamasındaysa ve iptal etmek istiyorsa, "Siparişiniz hazırlanmaya başladığı için otomatik iptal edemiyorum, ancak işletme ile görüşüp sizin için bilgi alabilirim" de.
        2. Sipariş "PENDING" (Onay bekliyor) aşamasındaysa, otomatik iptal hakkı olduğunu belirt ve iptal tetikleme yönlendirmesi yap.
        3. Sipariş gecikmişse ("ON_THE_WAY" durumunda ve süresi aşılmışsa), kuryenin canlı haritada ilerlediğini, gerekirse kurye ile direkt iletişime geçebileceğini belirt.
        4. Kıbrıs yerel ifadelerini (örneğin sıcakkanlı bir selamlama: "Merhaba sevgili dostum, nasılsın?") dengeli ve profesyonel kullan. Asla resmiyetten kopma ama aşırı soğuk da davranma.
      `;

      if (!apiKey) {
        res.status(200).json({
          error: false,
          reply: "Hoppa Asistan şu anda uykuda. Lütfen daha sonra tekrar deneyiniz. (API Key yapılandırılmamış)",
          detectedOrderId: activeOrderId || null
        });
        return;
      }

      // Gemini 2.5 Flash API Payload hazırlığı
      const stableModel = "gemini-2.5-flash";
      const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${stableModel}:generateContent?key=${apiKey}`;
      const payload = {
        contents: [
          {
            parts: [{ text: message }]
          }
        ],
        systemInstruction: {
          parts: [{ text: systemInstruction }]
        }
      };

      // API Çağrısı (Retry bacaklı)
      const responseData = await SupportController.fetchWithRetry(geminiUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });

      const aiResponseText = responseData.candidates?.[0]?.content?.parts?.[0]?.text || "Şu anda size yardımcı olamıyorum, lütfen biraz sonra tekrar deneyin.";

      res.status(200).json({
        error: false,
        reply: aiResponseText,
        detectedOrderId: activeOrderId || null
      });

    } catch (error) {
      console.error("Akıllı Asistan Hatası:", error);
      res.status(500).json({ error: true, message: "Hoppa Asistan şu anda uykuda. Lütfen daha sonra tekrar deneyiniz." });
    }
  }
}

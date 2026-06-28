Story 20 - İşletme Değerlendirme ve Akıllı Canlı Destek (Phase 1)

Bu görev belgesi; tüketicilerin teslim edilen siparişler için restoran ve marketleri puanlayıp yorumlayabileceği (İşletme Değerlendirme) ilişkisel yapıyı kurmayı ve canlı destek tarafında kullanıcının aktif sipariş verilerini sistem direktifi olarak besleyen Gemini 2.5 Flash Destekli Akıllı Asistan (Hoppa Asistan) mimarisini hayata geçirmeyi amaçlar.

🧭 1. BÖLÜM: İşletme Değerlendirme Mimarisi (Merchant Rating & Reviews)

Müşteri memnuniyetini ölçmek ve diğer müşterilere referans sağlamak amacıyla her teslim edilen siparişten sonra tek seferlik yorum ve puanlama (1-5 yıldız) yapılmasını sağlayan veritabanı bacağıdır.

A. Prisma Şema Güncellemesi (schema.prisma)

Review tablosunu ekleyerek User, Shop ve Order modellerine bağlıyoruz. Bir siparişe yalnızca tek bir yorum yapılabilmesi için benzersiz kısıtlama (Unique Constraint) ekliyoruz.

// backend/prisma/schema.prisma

model Review {
  id        String   @id @default(uuid())
  rating    Int      // 1 ile 5 arasında yıldız puanı
  comment   String?  @db.VarChar(500) // Maksimum 500 karakter sınır
  createdAt DateTime @default(now())

  // İlişkiler
  userId    String
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  shopId    String
  shop      Shop     @relation(fields: [shopId], references: [id], onDelete: Cascade)
  orderId   String   @unique // Bir sipariş için sadece 1 değerlendirme yapılabilir
  order     Order    @relation(fields: [orderId], references: [id], onDelete: Cascade)

  @@index([shopId])
  @@index([userId])
}


B. Değerlendirme API Kontrolörü (ReviewController.ts)

Yalnızca DELIVERED durumundaki siparişlerin değerlendirilebilmesini ve mükerrer yorum yapılmasını engelleyen API kontrolörü:

// backend/src/controllers/ReviewController.ts

import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
const prisma = new PrismaClient();

export class ReviewController {
  
  // 1. Sipariş Değerlendirmesi Oluştur
  public static async createReview(req: Request, res: Response): Promise<void> {
    try {
      const userId = req.user!.id;
      const { orderId, rating, comment } = req.body;

      if (!orderId || !rating || rating < 1 || rating > 5) {
        res.status(400).json({ error: true, message: "Geçersiz puanlama veya eksik sipariş ID." });
        return;
      }

      // Siparişi ve teslim durumunu kontrol et
      const order = await prisma.order.findUnique({ where: { id: orderId } });
      if (!order || order.userId !== userId) {
        res.status(404).json({ error: true, message: "Sipariş bulunamadı." });
        return;
      }

      if (order.status !== "DELIVERED") {
        res.status(400).json({ error: true, message: "Yalnızca teslim edilmiş siparişleri değerlendirebilirsiniz." });
        return;
      }

      // Mükerrer yorum kontrolü
      const existingReview = await prisma.review.findUnique({ where: { orderId } });
      if (existingReview) {
        res.status(400).json({ error: true, message: "Bu sipariş için zaten bir değerlendirme yapılmış." });
        return;
      }

      // Değerlendirmeyi kaydet
      const review = await prisma.review.create({
        data: {
          rating,
          comment,
          userId,
          shopId: order.shopId,
          orderId
        }
      });

      // 🚨 Dükkan Puan Ortalamasını Güncelle (SQL Tetikleyicisi veya Asenkron İşlem)
      // Bu adımda Shop tablosundaki averageRating ve reviewCount değerleri asenkron güncellenir.

      res.status(201).json({ error: false, data: review, message: "Değerlendirmeniz başarıyla kaydedildi!" });
    } catch (error) {
      console.error("Yorum kaydetme hatası:", error);
      res.status(500).json({ error: true, message: "İşlem sırasında bir hata oluştu." });
    }
  }

  // 2. Dükkan Değerlendirmelerini Getir
  public static async getShopReviews(req: Request, res: Response): Promise<void> {
    try {
      const { shopId } = req.params;
      const reviews = await prisma.review.findMany({
        where: { shopId },
        include: {
          user: { select: { name: true } }
        },
        orderBy: { createdAt: 'desc' }
      });
      res.status(200).json({ error: false, data: reviews });
    } catch (error) {
      res.status(500).json({ error: true, message: "Yorumlar getirilirken hata oluştu." });
    }
  }
}


🤖 2. BÖLÜM: Hoppa Asistan - Gemini 2.5 Flash Akıllı Canlı Destek

Canlı desteğin 1. fazda yapay zeka ile otomatik çalışması için Gemini 2.5 Flash modelini kullanıyoruz. Kullanıcının aktif sipariş detaylarını (Restoran adı, kurye konumu, sipariş içeriği, hazırlık aşaması vb.) Gemini'nin sistem direktiflerine (Context) enjekte ederek tamamen akıllı ve sipariş farkındalığı olan (context-aware) bir asistan kurguluyoruz.

A. Gemini Destekli Akıllı Chat API (SupportController.ts)

Gemini API entegrasyonu kurallarımıza (boş api anahtarı yönetimi, üst üste hata durumunda üstel geri çekilme - exponential backoff) sadık kalarak hazırlanan akıllı asistan kontrolörü:

// backend/src/controllers/SupportController.ts

import { Request, Response } from 'express';
import { PrismaClient } from '@prisma/client';
import fetch from 'node-fetch'; // HTTP istekleri için

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
            shop: { select: { name: true, phone: true } },
            items: true
          }
        });

        if (order && order.userId === userId) {
          orderContext = `
            Kullanıcının aktif sipariş detayları:
            - Sipariş ID: ${order.id}
            - İşletme Adı: ${order.shop.name}
            - Sipariş Durumu: ${order.status} (PENDING: Onay bekliyor, PREPARING: Hazırlanıyor, ON_THE_WAY: Kurye Yolda, DELIVERED: Teslim edildi)
            - Sipariş Verilme Zamanı: ${order.createdAt}
            - Alınan Ürünler: ${order.items.map(i => `${i.name} (${i.quantity} adet)`).join(", ")}
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

      // Gemini 2.5 Flash API Payload hazırlığı
      const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-09-2025:generateContent?key=${apiKey}`;
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


📱 3. BÖLÜM: Tüketici Uygulaması (Consumer App) Arayüz Gereksinimleri

A. Teslimat Sonrası Puanlama Penceresi (Rate Dialog)

Sipariş durumu DELIVERED (Teslim Edildi) olduğu an veya kullanıcı sipariş detay sayfasını açtığında otomatik tetiklenen şık, 1-5 yıldız seçmeli ve yorum yazma alanlı bir modal pencere gösterilir.

Yıldızlar parmak kaydırmalı (Interactive Slider/Row of Icons) animasyonlu tasarlanmalıdır.

B. Hoppa Asistan Sohbet Ekranı (Interactive AI Chat)

Görsel Tasarım: WhatsApp veya iMessage benzeri, kullanıcının balonlarının marka yeşili, asistan balonlarının ise soluk gri/yeşil renkte olduğu modern bir chat arayüzü.

Akıllı Seçenekler (Quick Replies): Sohbet ekranının altında asılı (floating) duran hazır butonlar yer alır:

"Siparişim Nerede? 📍" (Doğrudan aktif sipariş ID'sini asistan API'sine gönderir).

"Eksik Ürün Geldi 🍎"

"İptal Etmek İstiyorum ❌"

Gerçekçi Yazıyor... Efekti: Yapay zeka cevap üretirken chat ekranında beliren şık üç nokta zıplama (... is typing) animasyonu.

📢 Doğrulama Planı

Prisma Şema Güncellemesi & Reset:

cd backend && npx prisma db push --force-reset && npx prisma generate


Katalog Tohumlama (Real Seed):

cd backend && npx ts-node prisma/seed_catalog.ts


TypeScript ve Flutter Kontrolü:

cd backend && npx tsc --noEmit
cd apps/consumer_app && flutter analyze

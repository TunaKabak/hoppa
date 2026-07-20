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

  // Haversine formülü ile iki koordinat arası mesafe hesaplama (km)
  private static calculateHaversineDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
    const R = 6371; // Dünya yarıçapı (km)
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = 
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
      Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
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
      // Kullanıcının tüm aktif siparişlerini veritabanından çekiyoruz (Aynı anda birden fazla aktif sipariş olabilir)
      const activeOrders = await prisma.order.findMany({
        where: {
          consumerId: userId,
          status: {
            in: ["PENDING", "PREPARING", "ON_THE_WAY", "READY_FOR_PICKUP"]
          }
        },
        include: {
          shop: { select: { name: true, latitude: true, longitude: true } },
          address: { select: { latitude: true, longitude: true, title: true, fullAddress: true } },
          items: {
            include: {
              product: { select: { name: true } }
            }
          },
          courier: {
            include: {
              locations: {
                orderBy: { updatedAt: 'desc' },
                take: 1
              }
            }
          }
        },
        orderBy: { createdAt: 'desc' }
      });

      // Son tamamlanan/iptal edilen geçmiş sipariş
      const lastPastOrder = await prisma.order.findFirst({
        where: {
          consumerId: userId,
          status: {
            in: ["DELIVERED", "CANCELLED"]
          }
        },
        include: {
          shop: { select: { name: true } },
          items: {
            include: {
              product: { select: { name: true } }
            }
          }
        },
        orderBy: { createdAt: 'desc' }
      });

      let orderContext = "";
      if (activeOrders.length > 0) {
        orderContext += "Kullanıcının aktif siparişleri:\n" + activeOrders.map((order, idx) => {
          let courierContext = "";
          if (order.courier) {
            const latestLocation = order.courier.locations?.[0];
            if (latestLocation) {
              const courierLat = latestLocation.latitude;
              const courierLon = latestLocation.longitude;
              const shopLat = order.shop.latitude;
              const shopLon = order.shop.longitude;
              const destLat = order.address.latitude;
              const destLon = order.address.longitude;
              
              let distToShopStr = "Bilinmiyor";
              let distToCustomerStr = "Bilinmiyor";
              
              if (courierLat != null && courierLon != null && shopLat != null && shopLon != null) {
                const distToShop = SupportController.calculateHaversineDistance(courierLat, courierLon, shopLat, shopLon);
                distToShopStr = `${distToShop.toFixed(2)} km`;
              }
              
              if (courierLat != null && courierLon != null && destLat != null && destLon != null) {
                const distToCustomer = SupportController.calculateHaversineDistance(courierLat, courierLon, destLat, destLon);
                distToCustomerStr = `${distToCustomer.toFixed(2)} km`;
              }
              
              const lastUpdatedSecs = Math.round((Date.now() - new Date(latestLocation.updatedAt).getTime()) / 1000);
              
              courierContext = `\n          - Kurye Bilgisi: Atandı (${order.courier.name}, ${order.courier.phoneNumber})\n          - Kurye Konumu: En son ${lastUpdatedSecs} saniye önce güncellendi.\n          - Kuryenin Restorana/Markete Uzaklığı: ${distToShopStr}\n          - Kuryenin Teslimat Adresine Uzaklığı: ${distToCustomerStr}`;
            } else {
              courierContext = `\n          - Kurye Bilgisi: Atandı (${order.courier.name}, ${order.courier.phoneNumber}) fakat henüz konum sinyali alınamadı.`;
            }
          } else {
            courierContext = `\n          - Kurye Bilgisi: Henüz kurye atanmadı.`;
          }

          return `
          Sipariş #${idx + 1}:
          - İşletme Adı: ${order.shop.name}
          - Sipariş Durumu: ${order.status} (PENDING: Onay bekliyor, PREPARING: Hazırlanıyor, ON_THE_WAY: Kurye Yolda, READY_FOR_PICKUP: Gel Al Hazır)
          - Sipariş Zamanı: ${order.createdAt}
          - Ürünler: ${order.items.map(i => `${i.product.name} (${i.quantity} adet)`).join(", ")}
          - Ödeme Tipi: ${order.paymentMethod}${courierContext}`;
        }).join("\n");
      } else {
        orderContext += "Kullanıcının şu anda aktif bir siparişi bulunmamaktadır.\n";
      }

      if (lastPastOrder) {
        orderContext += `\nKullanıcının son geçmiş siparişi:\n` + `
          - İşletme Adı: ${lastPastOrder.shop.name}
          - Sipariş Durumu: ${lastPastOrder.status} (DELIVERED: Teslim Edildi, CANCELLED: İptal Edildi)
          - Sipariş Zamanı: ${lastPastOrder.createdAt}
          - Ürünler: ${lastPastOrder.items.map(i => `${i.product.name} (${i.quantity} adet)`).join(", ")}
          - İptal Nedeni (varsa): ${lastPastOrder.cancelReason || "Yok"}
        `;
      }

      // Yapay zeka sistem talimatları (System Instruction)
      const systemInstruction = `
        Sen KKTC'nin yerel teslimat uygulaması Hoppa'nın akıllı yapay zeka asistanısın. Görevin, kullanıcılara siparişleri ve teslimat süreçleri hakkında Kıbrıslı samimiyeti ve yüksek profesyonellikle yardımcı olmaktır.
        
        ${orderContext}
        
        KURALLAR:
        1. KESİNLİKLE UYULMASI GEREKEN GÜVENLİK KURALI: Kullanıcıya teknik/veritabanı sipariş ID'lerini (örn: UUID'ler, uzun hash kodları) doğrudan verme. Onlar yerine siparişleri işletme adlarıyla (örn: "Migros siparişiniz") veya "aktif siparişiniz" diyerek tanımla.
        2. KESİNLİKLE UYULMASI GEREKEN HİTAP KURALI: Kullanıcıya hitap ederken "canım", "gülüm", "tatlım", "güzelim", "canısı" gibi laubali, aşırı samimi ya da profesyonellik dışı kelimeler KESİNLİKLE kullanma. Sıcakkanlı, nazik ama saygılı ve kibar bir hitap tercih et (örn: "sevgili dostum", "sayın müşterimiz", veya sadece ismini biliyorsan "Ahmet Bey" gibi). Resmiyet ve samimiyet dengesini koru.
        3. Kullanıcının aktif siparişi "PREPARING" (Hazırlanıyor) aşamasındaysa ve iptal etmek istiyorsa, "Siparişiniz hazırlanmaya başladığı için otomatik iptal edemiyorum, ancak işletme ile görüşüp sizin için bilgi alabilirim" de.
        4. Sipariş "PENDING" (Onay bekliyor) aşamasındaysa, otomatik iptal hakkı olduğunu belirt ve iptal tetikleme yönlendirmesi yap.
        5. Sipariş gecikmişse ("ON_THE_WAY" durumunda ve süresi aşılmışsa), kuryenin canlı haritada ilerlediğini, gerekirse kurye ile direkt iletişime geçebileceğini belirt. Kuryenin güncel mesafe verisi (örn. restorana veya teslimat adresine uzaklığı) varsa bunu Kıbrıslı sıcaklığıyla ("Kuryemiz şu anda yoldadır be dostum, mesafesi yaklaşık...") kullanıcıyla paylaş.
        6. Kıbrıs yerel ifadelerini (örneğin sıcakkanlı bir selamlama: "Merhaba sevgili dostum, nasılsın?") dengeli ve profesyonel kullan. Asla resmiyetten kopma ama aşırı soğuk da davranma.
        7. SELAMLAMA VE GİRİŞ KURALI: Her yanıtına "Merhaba", "Hoş geldin" gibi selamlamalarla başlama. Eğer kullanıcının mesajı sadece selamlaşma içeriyorsa selamla karşılık ver. Ancak kullanıcı doğrudan bir soru veya sorun ilettiyse (örn: "siparişim nerede?", "eksik ürün var") selamlama kısmını atla ve doğrudan soruya yanıt ver.
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

      // 💾 Canlı destek görüşmesini veri tabanına logluyoruz
      try {
        await prisma.assistantChatLog.create({
          data: {
            userId,
            message,
            reply: aiResponseText,
            activeOrderId: activeOrderId || null
          }
        });
      } catch (logError) {
        console.error("Görüşme loglama hatası:", logError);
      }

      // Çoklu sipariş seçimi için seçenekleri hazırlıyoruz
      const allOrders = [...activeOrders, ...(lastPastOrder ? [lastPastOrder] : [])];
      const options = allOrders.length > 1 ? allOrders.map(o => ({
        id: o.id,
        label: `${o.shop.name} (${new Date(o.createdAt).toLocaleDateString('tr-TR', {day: '2-digit', month: 'long'})} ${new Date(o.createdAt).toLocaleTimeString('tr-TR', {hour: '2-digit', minute:'2-digit'})})`
      })) : undefined;

      res.status(200).json({
        error: false,
        message: "Asistan yanıtı başarıyla oluşturuldu.",
        data: {
          reply: aiResponseText,
          detectedOrderId: activeOrderId || null,
          options: options || null
        }
      });

    } catch (error) {
      console.error("Akıllı Asistan Hatası:", error);
      res.status(500).json({ error: true, message: "Hoppa Asistan şu anda uykuda. Lütfen daha sonra tekrar deneyiniz." });
    }
  }

  public static async parseVoiceCommand(req: Request, res: Response): Promise<void> {
    try {
      const { message } = req.body;

      if (!message) {
        res.status(400).json({ error: true, message: "Komut alanı boş bırakılamaz." });
        return;
      }

      const systemInstruction = `
        Sen Hoppa uygulamasının sesli komut işleme servisisin. Kullanıcının Türkçe olarak verdiği sesli komutu analiz edip uygun eylemi (action) ve parametrelerini (parameters) JSON formatında döndürmelisin.
        
        Desteklenen Eylemler (Actions):
        1. "ADD_TO_CART": Sepete ürün ekler. 
           - Parametreler: { productName: string (aranacak ürün adı, örn: "süt", "ekmek"), quantity: number (varsayılan 1) }
        2. "REMOVE_FROM_CART": Sepetten ürün çıkarır.
           - Parametreler: { productName: string (örn: "süt") }
        3. "CLEAR_CART": Sepeti tamamen temizler.
           - Parametreler: Yok {}
        4. "SEARCH_PRODUCT": Ürün arar.
           - Parametreler: { query: string (aranacak kelime) }
        5. "NAVIGATE": Belirli bir sayfaya yönlendirir.
           - Parametreler: { target: "home" | "cart" | "profile" | "orders" | "support" }
        6. "CHECKOUT": Ödeme/ödeme ekranına geçiş yapar.
           - Parametreler: Yok {}
        7. "CONFIRM_ORDER": Siparişi tamamlar/onaylar.
           - Parametreler: Yok {}
        8. "UNKNOWN": Komut anlaşılamadı veya yukarıdakilerden hiçbirine uymuyor.
           - Parametreler: Yok {}
           
        DÖNÜŞ FORMATI:
        Aşağıdaki JSON şemasına uygun tek bir JSON objesi döndür:
        {
          "action": "Eylem Adı (ADD_TO_CART, REMOVE_FROM_CART, CLEAR_CART, SEARCH_PRODUCT, NAVIGATE, CHECKOUT, CONFIRM_ORDER, UNKNOWN)",
          "parameters": { ... },
          "reply": "Kullanıcıya sesli veya yazılı verilecek Kıbrıs yerel ağzına yatkın sıcak, samimi ve profesyonel geri bildirim mesajı."
        }
      `;

      if (!apiKey) {
        res.status(200).json({
          error: false,
          data: {
            action: "UNKNOWN",
            parameters: {},
            reply: "Hoppa Sesli Asistan şu anda uykuda. Lütfen daha sonra tekrar deneyiniz."
          }
        });
        return;
      }

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
        },
        generationConfig: {
          responseMimeType: "application/json"
        }
      };

      const responseData = await SupportController.fetchWithRetry(geminiUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload)
      });

      const aiResponseText = responseData.candidates?.[0]?.content?.parts?.[0]?.text;
      
      let parsedResponse = {
        action: "UNKNOWN",
        parameters: {},
        reply: "Komutunuzu tam olarak anlayamadım sevgili dostum."
      };

      if (aiResponseText) {
        try {
          parsedResponse = JSON.parse(aiResponseText.trim());
        } catch (parseError) {
          console.error("Gemini JSON parse hatası:", parseError, aiResponseText);
        }
      }

      res.status(200).json({
        error: false,
        message: "Sesli komut başarıyla işlendi.",
        data: parsedResponse
      });

    } catch (error) {
      console.error("Sesli Asistan Hatası:", error);
      res.status(500).json({ 
        error: true, 
        message: "Sesli komut işlenirken bir hata oluştu." 
      });
    }
  }
}

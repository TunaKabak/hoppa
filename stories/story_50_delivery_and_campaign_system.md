📊 Hoppa Kampanya Slider Monetizasyonu ve Referrer-Based Komisyon Mimarisi

Bu döküman, işletmelerin (esnafın) kendi panellerinde oluşturacakları indirim kampanyalarının ve kuponların tüketici uygulamasındaki premium vitrin alanlarında (Slider/Carousel) listelenme kurallarını, ücretlendirme modellerini ve yazılım mimarisini analiz eder.

🏛️ 1. STRATEJİK DEĞERLENDİRME: REKLAM ALANLARI VE MONETİZASYON MATRİSİ

Kullanıcıyı uygulamadan soğutmayacak (ad-fatigue), esnafa "Satış Odaklı" (Pay-per-Performance) seçenekler sunacak ve Hoppa için kesintisiz B2B SaaS MRR (Aylık Tekrarlayan Gelir) üretecek hibrit modeli uyguluyoruz:

📊 Kampanya ve Slider Ücretlendirme Matrisi

Görünürlük Alanı

Esnaf Maliyet Modeli

Hoppa Komisyon Oranı

Stratejik Amacı (Neden Bu Model?)

Dükkan Detay Sayfası

🟢 Ücretsiz ($0\text{ TL}$)

Standart Esnaf Komisyonu ($\%5$ veya $\%15$)

Esnafı indirim yapmaya teşvik eder. Kullanıcının sepet dönüşüm oranını ($CR$) ve ortalama sepet tutarını ($AOV$) organik olarak yukarı çeker.

Kategori Slaytı (Hero Slider)

🟡 Sıfır Peşin Ödeme (Pay-per-Performance)

Dinamik Performans Komisyonu ($\%10$)

Esnaftan peşin para istemeden, sadece o kategorideki kampanya üzerinden satılan ürünlerden $\%10$ komisyon tahsil edilir. Küçük esnaf için risk sıfırdır.

Ana Sayfa Tepe Slaytı (Hero Carousel)

🟠 Haftalık Sabit Kira + Komisyon (Fixed + Variable)

Haftalık Fiks $2.500\text{ TL}$ + Standart Komisyon

En değerli vitrinimizdir. Sadece komisyonla ilerlemek tekelleşmeye yol açar. Peşin fiks kira, sadece ciddi ve kaliteli kampanyaların ana sayfaya çıkmasını garantiler.

🚪 2. GÜVENLİK VE ESTETİK KORUMASI: DESIGN-AS-A-SERVICE (DaaS)

Esnafların kendi hazırladıkları berbat, düşük çözünürlüklü veya pikselleşmiş kampanya afişlerini sisteme yükleyip uygulamanın premium arayüz estetiğini bozmasını engellemek için "Tasarım Hizmeti" modelini devreye alıyoruz:

Afiş Onay Mekanizması: Esnafın kendi yüklediği kampanya afişleri doğrudan yayına alınmaz. Admin onayına düşer.

Tasarım Desteği: Esnaf dilerse, kampanya başına fiks $250\text{ TL}$ tasarım hizmet bedeli ödeyerek Hoppa'nın profesyonel tasarım ekibine (veya şablon AI motorumuza) stüdyo kalitesinde, göz alıcı bir kampanya afişi hazırlatabilir. Bu, platform için harika bir mikro-gelir bacağıdır.

🛠️ 3. YAZILIM MİMARİSİ VE DATA FLOW (REFERRER ATTRIBUTION)

Sipariş oluşturulduğunda komisyonun reklam alanına göre doğru hesaplanabilmesi için, siparişin hangi kaynaktan (Ana Sayfa Slider, Kategori Slider veya Organik arama) gelerek tamamlandığını izleyen Attribution (Yönlendirme) Akışı kurgulanmıştır:

[Kullanıcı Kampanya Slider'ına Tıklar] ──► [Dükkana Giriş Yapılır (Referrer: 'MAIN_SLIDER')]
                                                                │
                                                                ▼
[Sipariş Sepet Adımı (Checkout)] ────────► [Sipariş Kaydedilir (referring_source: 'MAIN_SLIDER')]
                                                                │
                                                                ▼
[Hakediş Hesaplama (Earnings Engine)] ──► [Komisyon Dinamik Olarak %15 Olarak İşlenir]


A. Prisma Şeması Güncellemesi (schema.prisma)

Sipariş anındaki reklam kaynaklı hakedişleri kuruşu kuruşuna loglamak için veritabanına eklenecek alanlar:

model Order {
  id              String   @id @default(uuid())
  shopId          String
  shop            Shop     @relation(fields: [shopId], references: [id])
  sepetTutari     Decimal  @db.Decimal(10, 2)
  
  // Referrer (Yönlendirme) Alanları
  referringSource String   @default("ORGANIC") // "ORGANIC", "MAIN_SLIDER", "CATEGORY_SLIDER"
  campaignId      String?
  campaign        Campaign? @relation(fields: [campaignId], references: [id], onDelete: SetNull)
  
  // Dinamik Komisyon Alanları
  commissionRate  Decimal  @db.Decimal(5, 2) // Örn: 0.15 (Sipariş anında dondurulan oran)
  commissionAmount Decimal @db.Decimal(10, 2) // Kuruşu kuruşuna hesaplanan platform kârı
}

model Campaign {
  id          String   @id @default(uuid())
  title       String
  description String
  imageUrl    String   // Slaytta dönecek banner resim URL'si
  isActive    Boolean  @default(true)
  orders      Order[]
}

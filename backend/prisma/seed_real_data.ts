import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

// Target shop IDs from database
const MARKET_SHOP_ID = '75add0fc-ee26-4082-bf68-430dd57e7d34';
const RESTAURANT_SHOP_ID = '666d363f-5325-48b2-ad8d-ba7f09e9067b';

// Helper function to find or create a category
async function ensureCategory(name: string, shopType: string): Promise<string> {
  const existing = await prisma.category.findFirst({
    where: {
      name: { equals: name, mode: 'insensitive' },
      shopType: shopType
    }
  });

  if (existing) {
    return existing.id;
  }

  const created = await prisma.category.create({
    data: {
      id: require('crypto').randomUUID(),
      name: name,
      shopType: shopType,
    }
  });
  return created.id;
}

// 100+ Market Products data
const marketProducts = [
  // --- Süt & Kahvaltılık ---
  {
    name: "Sütaş Tam Yağlı Süt 1 L",
    description: "Doğal ve taze tam yağlı pastörize süt.",
    price: 34.50,
    discountRate: 0,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1550583724-b2692b85b150?w=500&auto=format&fit=crop&q=60",
    unitCode: "LITRE"
  },
  {
    name: "İçim Süzme Peynir 500 G",
    description: "Kahvaltıların vazgeçilmezi süzme beyaz peynir.",
    price: 89.90,
    discountRate: 10,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1486887396181-e0f686c39db5?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Pınar Kaşar Peyniri 400 G",
    description: "Tostlarda ve yemeklerde eriyen lezzetli kaşar peyniri.",
    price: 125.00,
    discountRate: 0,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1528256446066-2ae1a690220d?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Yörsan Süzme Yoğurt 1 Kg",
    description: "Kıvamı yerinde taze süzme yoğurt.",
    price: 98.50,
    discountRate: 15,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1488477181946-6428a0291777?w=500&auto=format&fit=crop&q=60",
    unitCode: "KG"
  },
  {
    name: "Nutella Kakaolu Fındık Kreması 630 G",
    description: "Eşsiz lezzetiyle Nutella sürülebilir çikolata.",
    price: 115.00,
    discountRate: 0,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Pınar Labne 400 G",
    description: "Yumuşacık kıvamı ve hafif lezzetiyle Pınar Labne.",
    price: 64.90,
    discountRate: 5,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1505394033241-483e64890c05?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Marmarabirlik Kuru Sele Zeytin 400 G",
    description: "Doğal salamura siyah zeytin, az tuzlu.",
    price: 110.00,
    discountRate: 0,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1469307726359-540700599021?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Balparmak Çiçek Balı 350 G",
    description: "Süzme çiçek balı, %100 doğal.",
    price: 145.00,
    discountRate: 20,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Tire Organik Yumurta 10'lu",
    description: "Büyük boy organik tavuk yumurtası.",
    price: 72.00,
    discountRate: 0,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1506976785307-8732e854ad03?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Sütaş Tereyağı 250 G",
    description: "Yemeklerinize lezzet katan saf süt tereyağı.",
    price: 105.00,
    discountRate: 0,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1589985270826-4b7bb135bc9d?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Namet Kangal Sucuk 250 G",
    description: "%100 dana etinden geleneksel ısıl işlem görmüş sucuk.",
    price: 179.00,
    discountRate: 15,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Banvit Kokteyl Sosis 360 G",
    description: "Pratik ve lezzetli piliç sosis.",
    price: 49.90,
    discountRate: 0,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1541532713592-79a0317b6b77?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Polonez Dana Salam 150 G",
    description: "İnce dilimlenmiş kaliteli dana salam.",
    price: 68.00,
    discountRate: 10,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1618040996337-56904b7850b9?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Koska Çilek Reçeli 380 G",
    description: "Taze çilek taneli geleneksel meyve reçeli.",
    price: 52.50,
    discountRate: 0,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1607623814075-e51df1bdc82f?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Tahin Koska 300 G",
    description: "%100 susamdan üretilen geleneksel tahin.",
    price: 78.00,
    discountRate: 0,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1621263764267-beabf4a21e42?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Koska Üzüm Pekmezi 380 G",
    description: "Enerji kaynağı doğal üzüm pekmezi.",
    price: 69.90,
    discountRate: 12,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "La Vache Qui Rit Üçgen Peynir 8'li",
    description: "Yumuşak sürülebilir porsiyon peynir.",
    price: 36.90,
    discountRate: 0,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1608686207856-001b95cf60ca?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Fora Kırma Yeşil Zeytin 400 G",
    description: "Ege yöresinin taze kırma yeşil zeytini.",
    price: 85.00,
    discountRate: 0,
    categoryName: "Süt & Kahvaltılık",
    imageUrl: "https://images.unsplash.com/photo-1541014741259-df5290dbf2f7?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },

  // --- Atıştırmalık ---
  {
    name: "Lays Klasik Patates Cipsi Süper Boy",
    description: "İncecik patates dilimlerinin çıtır kıvamı.",
    price: 38.00,
    discountRate: 0,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1566478989037-eec170784dcd?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Ruffles Tırtıklı Cips Mega Boy",
    description: "Maksimum çıtırlık, peynir ve soğan aromalı.",
    price: 45.00,
    discountRate: 10,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1613968789090-8d0f1a0b387a?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Eti Tadında Bitter Çikolata 60 G",
    description: "%60 yoğun kakao lezzetli bitter kare çikolata.",
    price: 24.00,
    discountRate: 0,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1548907040-4d42b52115ec?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Tadelle Fındıklı Bar 30 G",
    description: "Bol fındıklı ve sütlü çikolatalı bar.",
    price: 18.50,
    discountRate: 0,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1582170088993-9c1a162243d8?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "McVities Atıştırmalık Bisküvi 120 G",
    description: "Yulaflı ve çikolatalı İngiliz bisküvisi.",
    price: 32.00,
    discountRate: 0,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1558961303-fb4fac6c5858?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Tadım Kavrulmuş Fındık İçi 150 G",
    description: "Taze kavrulmuş çıtır fındık içi paketli.",
    price: 94.00,
    discountRate: 15,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1538332576187-e210d24f194e?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Tadım Antep Fıstığı 150 G",
    description: "Ana çıtlak lüks Antep fıstığı.",
    price: 135.00,
    discountRate: 0,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1600189020840-e9db189b37ab?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Oreo Çikolatalı Bisküvi 110 G",
    description: "Kremalı ve kakaolu efsanevi Oreo bisküvileri.",
    price: 28.90,
    discountRate: 0,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1551806235-6629bc245413?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Eti Negro Kakaolu Bisküvi 110 G",
    description: "Kakaolu çıtır bisküvi, vanilyalı krema.",
    price: 22.00,
    discountRate: 0,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Eti Crax Sade Çubuk Kraker 50 G",
    description: "Tuzlu çıtır atıştırmalık çubuk kraker.",
    price: 9.50,
    discountRate: 0,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1599490659273-e3b6900ed1ab?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Haribo Altın Ayıcık Jelibon 80 G",
    description: "Çeşitli meyve aromalı yumuşak şekerleme.",
    price: 24.50,
    discountRate: 10,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1581798459219-318e76aecc7b?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Snickers Çikolata Bar 50 G",
    description: "Karamelli, yer fıstıklı ve nuga dolgulu çikolata.",
    price: 19.90,
    discountRate: 0,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Toblerone Sütlü Çikolata 100 G",
    description: "Ballı ve badem nugalı ikonik İsviçre çikolatası.",
    price: 54.00,
    discountRate: 0,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kinder Bueno Gofret 43 G",
    description: "Fındık kremalı çıtır kaplamalı sütlü çikolatalı gofret.",
    price: 26.00,
    discountRate: 5,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Doritos Taco Baharatlı Cips Aile Boy",
    description: "Mısır cipsi, taco baharatı aromasıyla çıtır.",
    price: 42.00,
    discountRate: 0,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1518047601542-79f18c655718?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Tadım Karışık Kuruyemiş 150 G",
    description: "Fındık, badem, kaju ve leblebi karışımı.",
    price: 88.00,
    discountRate: 0,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1599599810769-bcde5a160d32?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Peyman Kabak Çekirdeği 150 G",
    description: "Tuzlu çıtır kabak çekirdeği.",
    price: 56.50,
    discountRate: 0,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1608797178974-15b35a61d121?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Cheetos Fıstıklı Cips 50 G",
    description: "Fıstıklı çıtır mısır çerezi.",
    price: 18.00,
    discountRate: 0,
    categoryName: "Atıştırmalık",
    imageUrl: "https://images.unsplash.com/photo-1566478989037-eec170784dcd?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },

  // --- Temel Gıda ---
  {
    name: "Yayla Pilavlık Pirinç 1 Kg",
    description: "Baldo pirinç, dolgun taneli ve lezzetli.",
    price: 68.00,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500&auto=format&fit=crop&q=60",
    unitCode: "KG"
  },
  {
    name: "Yayla Pilavlık Bulgur 1 Kg",
    description: "İri taneli sarı pilavlık bulgur.",
    price: 36.90,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1574316071802-0d684efa7bf5?w=500&auto=format&fit=crop&q=60",
    unitCode: "KG"
  },
  {
    name: "Tat Kırmızı Mercimek 1 Kg",
    description: "Çorbalara uygun taze kırmızı mercimek.",
    price: 49.90,
    discountRate: 10,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1547592165-e1d17fed6005?w=500&auto=format&fit=crop&q=60",
    unitCode: "KG"
  },
  {
    name: "Yudum Ayçiçek Yağı 2 L",
    description: "Hafif ve kokusuz kızartmalık ayçiçek yağı.",
    price: 110.00,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=500&auto=format&fit=crop&q=60",
    unitCode: "LITRE"
  },
  {
    name: "Komili Sızma Zeytinyağı 1 L",
    description: "Ege soğuk sıkım natürel sızma zeytinyağı.",
    price: 310.00,
    discountRate: 20,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=500&auto=format&fit=crop&q=60",
    unitCode: "LITRE"
  },
  {
    name: "Tat Domates Salçası 830 G",
    description: "Güneşte kurutulmuş kıvamlı domates salçası.",
    price: 74.00,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1607305387299-a3d9611cd46f?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Sinangil Buğday Unu 2 Kg",
    description: "Kek, börek ve ekmek yapımına uygun beyaz un.",
    price: 52.00,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=60",
    unitCode: "KG"
  },
  {
    name: "Barilla Spagetti Makarna 500 G",
    description: "İtalyan usulü durum buğdayı spagetti.",
    price: 29.50,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Barilla Penne Rigate 500 G",
    description: "Kalem makarna, sosları iyi tutan tırtıklı yapı.",
    price: 29.50,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Torku Küp Şeker 1 Kg",
    description: "%100 şeker pancarından üretilen sert küp şeker.",
    price: 44.00,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1581447101795-7abd69d7a228?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Billur Sofra Tuzu 750 G",
    description: "İyotlu rafine sofra tuzu, akışkan kapaklı.",
    price: 18.00,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1618260447714-5bfaff3b4c99?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Knorr Hazır Mercimek Çorbası 75 G",
    description: "Pratik kıvamlı hazır çorba karışımı.",
    price: 16.50,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1547592165-e1d17fed6005?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Calve Ketçap 400 G",
    description: "Lezzetli sıkmalı şişede tatlı ketçap.",
    price: 38.00,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1607305387299-a3d9611cd46f?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Calve Mayonez 350 G",
    description: "Kremamsı kıvamlı sıkmalı şişede mayonez.",
    price: 46.00,
    discountRate: 10,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1607305387299-a3d9611cd46f?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kemal Kükrer Elma Sirkesi 500 Ml",
    description: "Doğal fermantasyon elma sirkesi.",
    price: 54.00,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Duru Nohut 1 Kg",
    description: "Hızlı pişen iri taneli koçbaşı nohut.",
    price: 62.00,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1547592165-e1d17fed6005?w=500&auto=format&fit=crop&q=60",
    unitCode: "KG"
  },
  {
    name: "Duru Kuru Fasulye 1 Kg",
    description: "Sıra tipi lezzetli kuru fasulye.",
    price: 69.90,
    discountRate: 5,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop&q=60",
    unitCode: "KG"
  },
  {
    name: "SuperFresh Milföy Hamuru 1 Kg",
    description: "Dondurulmuş çıtır milföy katları.",
    price: 78.00,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },

  // --- Fırın ---
  {
    name: "Uno Tost Ekmeği 500 G",
    description: "Uzun süre taze kalan dilimli büyük tost ekmeği.",
    price: 36.00,
    discountRate: 0,
    categoryName: "Fırın",
    imageUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Sade Simit 1 Adet",
    description: "Susamlı çıtır sokak simiti, günlük taze.",
    price: 15.00,
    discountRate: 0,
    categoryName: "Fırın",
    imageUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Beyaz Ekmek 300 G",
    description: "Taş fırın yapımı çıtır çıtır ekmek.",
    price: 12.00,
    discountRate: 0,
    categoryName: "Fırın",
    imageUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Uno Sandviç Ekmeği 6'lı",
    description: "Yumuşacık sandviç ekmekleri paketi.",
    price: 32.50,
    discountRate: 0,
    categoryName: "Fırın",
    imageUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Tereyağlı Kruvasan 2'li",
    description: "Fırından taze çıkmış bol tereyağlı kat kat kruvasan.",
    price: 45.00,
    discountRate: 0,
    categoryName: "Fırın",
    imageUrl: "https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Çikolatalı Muffin",
    description: "İçi bol çikolata dolgulu yumuşak muffin kek.",
    price: 25.00,
    discountRate: 10,
    categoryName: "Fırın",
    imageUrl: "https://images.unsplash.com/photo-1607958996333-41aef7caefaa?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Uno Kepekli Ekmek 400 G",
    description: "Diyet ve sağlıklı yaşam için kepekli dilimli ekmek.",
    price: 34.00,
    discountRate: 0,
    categoryName: "Fırın",
    imageUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Peynirli Poğaça",
    description: "Günlük sıcak üretilen dereotlu peynirli poğaça.",
    price: 18.00,
    discountRate: 0,
    categoryName: "Fırın",
    imageUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kıymalı Kol Böreği 250 G",
    description: "Çıtır yufkalı bol kıyma harçlı kol böreği.",
    price: 65.00,
    discountRate: 0,
    categoryName: "Fırın",
    imageUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Uno Hamburger Ekmeği 4'lü",
    description: "Ev yapımı hamburgerler için ideal boy ekmek.",
    price: 29.90,
    discountRate: 0,
    categoryName: "Fırın",
    imageUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },

  // --- İçecekler ---
  {
    name: "Coca-Cola Orijinal Tat 1 L",
    description: "Klasik efsanevi ferahlatıcı kola lezzeti.",
    price: 28.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=500&auto=format&fit=crop&q=60",
    unitCode: "LITRE"
  },
  {
    name: "Fanta Portakal 1 L",
    description: "Yoğun meyve tadıyla ferahlatıcı gazlı içecek.",
    price: 26.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1624552184280-9e9631bbeee9?w=500&auto=format&fit=crop&q=60",
    unitCode: "LITRE"
  },
  {
    name: "Sprite Gazoz 1 L",
    description: "Limon ve misket limon aromalı ferahlık.",
    price: 26.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1625772290748-390939a9521d?w=500&auto=format&fit=crop&q=60",
    unitCode: "LITRE"
  },
  {
    name: "Coca-Cola Zero Sugar 1 L",
    description: "Şekersiz ve kalorisiz klasik Coca-Cola tadı.",
    price: 28.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1548907040-4d42b52115ec?w=500&auto=format&fit=crop&q=60",
    unitCode: "LITRE"
  },
  {
    name: "Lipton Ice Tea Şeftali 1 L",
    description: "Şeftali aromalı ferahlatıcı soğuk çay.",
    price: 27.00,
    discountRate: 10,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500&auto=format&fit=crop&q=60",
    unitCode: "LITRE"
  },
  {
    name: "Sütaş Ayran 1 L",
    description: "Doğal yoğurttan üretilmiş tuzlu kıvamlı ayran.",
    price: 24.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1541014741259-df5290dbf2f7?w=500&auto=format&fit=crop&q=60",
    unitCode: "LITRE"
  },
  {
    name: "Kızılay Maden Suyu 6x200 Ml",
    description: "Doğal zengin mineralli gazlı su.",
    price: 36.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1608885898957-a599fb16987f?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Cappy Karışık Meyve Suyu 1 L",
    description: "%100 çoklu meyve nektarı.",
    price: 32.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1622597467836-f3285f367e9c?w=500&auto=format&fit=crop&q=60",
    unitCode: "LITRE"
  },
  {
    name: "Erikli Su 5 L",
    description: "Uludağ kaynağından şişelenmiş doğal kaynak suyu.",
    price: 32.50,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1523362628745-0c100150b504?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Erikli Su 1.5 L",
    description: "Pratik boy doğal mineral zengin su.",
    price: 12.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1610970881699-44a55b4cfd87?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Red Bull Enerji İçeceği 250 Ml",
    description: "Bedeninizi ve zihninizi canlandıran içecek.",
    price: 48.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Çaykur Rize Turist Çayı 500 G",
    description: "Karadeniz'in taze toplanmış lezzetli yaprak çayı.",
    price: 98.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1597481499750-3e6b22637e12?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Nescafe Gold Kahve 100 G",
    description: "Özenle seçilmiş kahve çekirdeklerinden instant kahve.",
    price: 135.00,
    discountRate: 15,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Mehmet Efendi Türk Kahvesi 100 G",
    description: "Geleneksel ince çekilmiş taze Türk kahvesi.",
    price: 45.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Beypazarı Limonlu Soda 200 Ml",
    description: "Doğal limon aromalı gazlı maden suyu.",
    price: 7.50,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1608885898957-a599fb16987f?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Fuse Tea Limon 1 L",
    description: "Limon aromalı serinletici ice tea.",
    price: 27.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500&auto=format&fit=crop&q=60",
    unitCode: "LITRE"
  },

  // --- Temizlik & Hijyen ---
  {
    name: "Pril Limonlu Bulaşık Deterjanı 675 Ml",
    description: "Zorlu yağları çözen güçlü bulaşık deterjanı.",
    price: 42.50,
    discountRate: 0,
    categoryName: "Temizlik & Hijyen",
    imageUrl: "https://images.unsplash.com/photo-1607349913338-fca6f7fc42d0?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Ariel Parlak Renkler Toz Deterjan 1.5 Kg",
    description: "Renkliler için özel koruyucu toz çamaşır deterjanı.",
    price: 145.00,
    discountRate: 15,
    categoryName: "Temizlik & Hijyen",
    imageUrl: "https://images.unsplash.com/photo-1583947215259-38e31be8751f?w=500&auto=format&fit=crop&q=60",
    unitCode: "KG"
  },
  {
    name: "Yumoş Konsantre Yumuşatıcı 1440 Ml",
    description: "Çiçek bahçesi kokulu konsantre çamaşır yumuşatıcı.",
    price: 118.00,
    discountRate: 0,
    categoryName: "Temizlik & Hijyen",
    imageUrl: "https://images.unsplash.com/photo-1583947215259-38e31be8751f?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Domestos Çamaşır Suyu 750 Ml",
    description: "Maksimum hijyen sağlayan yoğun kıvamlı çamaşır suyu.",
    price: 52.00,
    discountRate: 0,
    categoryName: "Temizlik & Hijyen",
    imageUrl: "https://images.unsplash.com/photo-1584622650111-993a426fbf0a?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Solo Parfümlü Tuvalet Kağıdı 16'lı",
    description: "3 katlı, yumuşacık ve hoş kokulu tuvalet kağıdı.",
    price: 125.00,
    discountRate: 20,
    categoryName: "Temizlik & Hijyen",
    imageUrl: "https://images.unsplash.com/photo-1584622781564-1d987f7333c1?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Solo Dev Rulo Kağıt Havlu 2'li",
    description: "Ekstra emici ve dayanıklı çift katlı kağıt havlu.",
    price: 68.00,
    discountRate: 0,
    categoryName: "Temizlik & Hijyen",
    imageUrl: "https://images.unsplash.com/photo-1584622781564-1d987f7333c1?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Activex Sıvı Sabun Hassas 650 Ml",
    description: "Antibakteriyel formülüyle koruyucu sıvı el sabunu.",
    price: 49.90,
    discountRate: 0,
    categoryName: "Temizlik & Hijyen",
    imageUrl: "https://images.unsplash.com/photo-1608571423902-eed4a5ad8108?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Seda Islak Mendil Aile Boyu 100'lü",
    description: "Hassas ciltlere uygun alkolsüz ıslak havlu.",
    price: 28.00,
    discountRate: 0,
    categoryName: "Temizlik & Hijyen",
    imageUrl: "https://images.unsplash.com/photo-1584622781564-1d987f7333c1?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Colgate Üçlü Etki Diş Macunu 75 Ml",
    description: "Çürüklere karşı koruma, beyazlık ve ferah nefes.",
    price: 46.00,
    discountRate: 10,
    categoryName: "Temizlik & Hijyen",
    imageUrl: "https://images.unsplash.com/photo-1559599189-fe84dea4eb79?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Signal Diş Fırçası Orta 1 Adet",
    description: "Derinlemesine temizlik için tasarlanmış fırça kılları.",
    price: 32.00,
    discountRate: 0,
    categoryName: "Temizlik & Hijyen",
    imageUrl: "https://images.unsplash.com/photo-1559599189-fe84dea4eb79?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Elidor Şampuan Onarıcı Bakım 400 Ml",
    description: "Yıpranmış saçlar için kalsiyum ve keratin formüllü şampuan.",
    price: 74.90,
    discountRate: 0,
    categoryName: "Temizlik & Hijyen",
    imageUrl: "https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Duru Zeytinyağlı Katı Sabun 4x150 G",
    description: "Banyo ve el için doğal zeytinyağlı beyaz sabun.",
    price: 54.00,
    discountRate: 0,
    categoryName: "Temizlik & Hijyen",
    imageUrl: "https://images.unsplash.com/photo-1607006342411-9a3a10552b5f?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Nivea Erkek Deodorant Spray 150 Ml",
    description: "48 saat etkili ter önleyici koruma, leke bırakmaz.",
    price: 88.00,
    discountRate: 15,
    categoryName: "Temizlik & Hijyen",
    imageUrl: "https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Nivea Kadın Deodorant Spray 150 Ml",
    description: "Pürüzsüz koltuk altı ve ferah pudra kokusu.",
    price: 88.00,
    discountRate: 15,
    categoryName: "Temizlik & Hijyen",
    imageUrl: "https://images.unsplash.com/photo-1608248597279-f99d160bfcbc?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Finish Quantum Bulaşık Makinesi Tableti 50'li",
    description: "Zorlu kirleri parlatan güçlü makine tableti.",
    price: 245.00,
    discountRate: 0,
    categoryName: "Temizlik & Hijyen",
    imageUrl: "https://images.unsplash.com/photo-1607349913338-fca6f7fc42d0?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },

  // --- Manav ve Meyve / Sebze Eklentisi (Market Kapsamında Çeşitlilik İçin) ---
  {
    name: "Taze Muz Yerli 1 Kg",
    description: "Taze ve enerji kaynağı sarı yerli muz.",
    price: 74.90,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=500&auto=format&fit=crop&q=60",
    unitCode: "KG"
  },
  {
    name: "Amasya Elması 1 Kg",
    description: "Kırmızı çıtır lezzetli Amasya elması.",
    price: 38.50,
    discountRate: 10,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=500&auto=format&fit=crop&q=60",
    unitCode: "KG"
  },
  {
    name: "İthal Avokado 1 Adet",
    description: "Yemeye hazır kıvamda ithal avokado.",
    price: 34.00,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Salkım Domates 1 Kg",
    description: "Tarladan taze toplanmış salkım kırmızı domates.",
    price: 45.00,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1595855759920-86582396756a?w=500&auto=format&fit=crop&q=60",
    unitCode: "KG"
  },
  {
    name: "Çengelköy Salatalık 1 Kg",
    description: "Çıtır kütür taze Çengelköy salatalığı.",
    price: 32.00,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1604974653723-5e927c3850dc?w=500&auto=format&fit=crop&q=60",
    unitCode: "KG"
  },
  {
    name: "Kuru Soğan 1 Kg",
    description: "Yemeklerin vazgeçilmezi sarı kuru soğan.",
    price: 19.90,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1508747705729-e098578af33b?w=500&auto=format&fit=crop&q=60",
    unitCode: "KG"
  },
  {
    name: "Patates 1 Kg",
    description: "Kızartmalık ve yemeklik Afyon patatesi.",
    price: 24.50,
    discountRate: 5,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=500&auto=format&fit=crop&q=60",
    unitCode: "KG"
  },
  {
    name: "Taze Maydanoz 1 Demet",
    description: "Günlük taze toplanmış yeşil maydanoz.",
    price: 8.50,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1515600051222-7b5b7e28b18f?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Çilek Paket 500 G",
    description: "Taze kokulu lezzetli kırmızı çilek.",
    price: 58.00,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1464965911861-746a04b4bca6?w=500&auto=format&fit=crop&q=60",
    unitCode: "PAKET"
  },
  {
    name: "Karpuz (Bütün) 1 Adet",
    description: "Yaklaşık 6-8 kg ağırlığında tatlı kırmızı bütün karpuz.",
    price: 120.00,
    discountRate: 0,
    categoryName: "Temel Gıda",
    imageUrl: "https://images.unsplash.com/photo-1587049352846-4a222e784d38?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  }
];

// 100+ Restaurant Products data
const restaurantProducts = [
  // --- Kebaplar & Izgaralar ---
  {
    name: "Adana Kebap Porsiyon",
    description: "Özel zırh kıyması, pilav, közlenmiş biber ve domates ile.",
    price: 245.00,
    discountRate: 10,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1626824151741-f761d7634f19?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Urfa Kebap Porsiyon",
    description: "Acısız zırh kıyması, lavaş, soğan salatası ve közlenmiş sebzeler eşliğinde.",
    price: 245.00,
    discountRate: 0,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Tavuk Şiş Porsiyon",
    description: "Marine edilmiş piliç göğüs etleri, bulgur pilavı ve yeşilliklerle.",
    price: 185.00,
    discountRate: 0,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1608500218902-15b218d6e355?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kuzu Şiş Porsiyon",
    description: "Körpe kuzu eti parçaları, lavaş ve közlenmiş domates ile.",
    price: 320.00,
    discountRate: 15,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Karışık Izgara Lüks",
    description: "Adana kebap, tavuk şiş, kuzu şiş, kasap köfte ve pirzola karışımı.",
    price: 450.00,
    discountRate: 0,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1544025162-d76694265947?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Beyti Kebap",
    description: "Lavaşa sarılı kıyma kebabı, yoğurt, özel tereyağlı sos ile.",
    price: 290.00,
    discountRate: 0,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Ali Nazik Kebap",
    description: "Közlenmiş patlıcanlı süzme yoğurt yatağında sote dana eti.",
    price: 310.00,
    discountRate: 5,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kuzu Pirzola 4 Adet",
    description: "Izgara kuzu pirzolalar, kızarmış patates ve pilav eşliğinde.",
    price: 360.00,
    discountRate: 0,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1544025162-d76694265947?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Sac Tava Dana",
    description: "Sac üzerinde sotelenmiş dana eti, domates, biber ve baharatlar.",
    price: 275.00,
    discountRate: 0,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Çöp Şiş Porsiyon",
    description: "Küçük kuzu eti parçaları, bol baharat ve lavaş ile.",
    price: 280.00,
    discountRate: 10,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kasap Köfte Porsiyon",
    description: "Geleneksel kasap köftesi, patates kızartması ve pilav ile.",
    price: 195.00,
    discountRate: 0,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1585325701165-351af916e5ec?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Adana Dürüm",
    description: "Lavaş arasında Adana kebap, soğan, domates ve maydanoz.",
    price: 130.00,
    discountRate: 0,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1626824151741-f761d7634f19?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Tavuk Şiş Dürüm",
    description: "Lavaş arasında marine tavuk şiş, yeşillik ve patates.",
    price: 110.00,
    discountRate: 0,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1626824151741-f761d7634f19?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Dana Döner Dürüm",
    description: "Lavaş arasında yaprak et döner, domates ve patates.",
    price: 160.00,
    discountRate: 10,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1626824151741-f761d7634f19?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Tavuk Döner Dürüm",
    description: "Lavaş arasında yaprak piliç döner, turşu ve özel sos.",
    price: 115.00,
    discountRate: 0,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1626824151741-f761d7634f19?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "İskender Kebap",
    description: "Yaprak döner, tırnak pide yatağında, domates sosu ve tereyağı ile.",
    price: 295.00,
    discountRate: 0,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Tırnak Pide Porsiyon",
    description: "Izgaraların yanına sıcak servis edilen tırnak pide.",
    price: 25.00,
    discountRate: 0,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },

  // --- Pide & Lahmacun ---
  {
    name: "Çıtır Lahmacun",
    description: "Kıymalı ve baharatlı harçlı klasik çıtır fırın lahmacunu.",
    price: 55.00,
    discountRate: 0,
    categoryName: "Pide & Lahmacun",
    imageUrl: "https://images.unsplash.com/photo-1613564834644-a170848986a4?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kaşarlı Lahmacun",
    description: "Kıymalı harç ve üzerinde erimiş kaşar peyniriyle fırınlanmış.",
    price: 65.00,
    discountRate: 0,
    categoryName: "Pide & Lahmacun",
    imageUrl: "https://images.unsplash.com/photo-1613564834644-a170848986a4?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kıymalı Pide",
    description: "Geleneksel kıyma harçlı açık Karadeniz pidesi.",
    price: 160.00,
    discountRate: 10,
    categoryName: "Pide & Lahmacun",
    imageUrl: "https://images.unsplash.com/photo-1613564834644-a170848986a4?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kaşarlı Pide",
    description: "Bol kaşar peynirli açık fırın pidesi.",
    price: 150.00,
    discountRate: 0,
    categoryName: "Pide & Lahmacun",
    imageUrl: "https://images.unsplash.com/photo-1613564834644-a170848986a4?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Karışık Karadeniz Pidesi",
    description: "Kuşbaşılı, kıymalı ve kaşarlı zengin pide.",
    price: 195.00,
    discountRate: 0,
    categoryName: "Pide & Lahmacun",
    imageUrl: "https://images.unsplash.com/photo-1613564834644-a170848986a4?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kuşbaşılı Pide",
    description: "Körpe kuşbaşı kuzu eti ve biber domates harçlı açık pide.",
    price: 185.00,
    discountRate: 5,
    categoryName: "Pide & Lahmacun",
    imageUrl: "https://images.unsplash.com/photo-1613564834644-a170848986a4?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Sucuklu Kaşarlı Pide",
    description: "Dilim sucuk ve bol kaşar peynirli açık pide.",
    price: 175.00,
    discountRate: 0,
    categoryName: "Pide & Lahmacun",
    imageUrl: "https://images.unsplash.com/photo-1613564834644-a170848986a4?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kavurmalı Kaşarlı Pide",
    description: "Rize kavurması ve erimiş kaşar peynirli açık pide.",
    price: 210.00,
    discountRate: 0,
    categoryName: "Pide & Lahmacun",
    imageUrl: "https://images.unsplash.com/photo-1613564834644-a170848986a4?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kıymalı Kaşarlı Pide",
    description: "Kıyma harcı üzerine bol kaşarlı açık Karadeniz pidesi.",
    price: 175.00,
    discountRate: 0,
    categoryName: "Pide & Lahmacun",
    imageUrl: "https://images.unsplash.com/photo-1613564834644-a170848986a4?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kuşbaşılı Kaşarlı Pide",
    description: "Kuşbaşı et harcı üzerine bol kaşar peynirli açık pide.",
    price: 195.00,
    discountRate: 0,
    categoryName: "Pide & Lahmacun",
    imageUrl: "https://images.unsplash.com/photo-1613564834644-a170848986a4?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },

  // --- Pizza & Fast Food ---
  {
    name: "Pizza Margherita",
    description: "İtalyan domates sosu, mozzarella peyniri, taze fesleğen.",
    price: 170.00,
    discountRate: 0,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Pizza Pepperoni",
    description: "Mozzarella peyniri, bol dilim pepperoni sucuk ve domates sosu.",
    price: 210.00,
    discountRate: 12,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Karışık Süper Pizza",
    description: "Mantar, sucuk, sosis, zeytin, mısır, biber ve mozzarella peyniri.",
    price: 230.00,
    discountRate: 0,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Vejetaryen Lüks Pizza",
    description: "Közlenmiş patlıcan, kabak, biber, mantar, zeytin ve kekik.",
    price: 185.00,
    discountRate: 10,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Klasik Burger Menü",
    description: "120 g dana burger köftesi, patates kızartması ve kutu içecek ile.",
    price: 195.00,
    discountRate: 0,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Cheeseburger Tek",
    description: "120 g dana köfte, cheddar peyniri, karamelize soğan, turşu ve sos.",
    price: 165.00,
    discountRate: 0,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Double Cheddar Burger",
    description: "Çift kat dana köfte (240 g), çift cheddar peyniri, marul ve sos.",
    price: 245.00,
    discountRate: 15,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Çıtır Tavuk Burger",
    description: "Pane harçlı çıtır tavuk fileto, mayonez ve marul.",
    price: 135.00,
    discountRate: 0,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Barbekü Soslu Burger",
    description: "120 g dana köfte, füme et, cheddar, çıtır soğan ve barbekü sos.",
    price: 185.00,
    discountRate: 0,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Patates Kızartması Porsiyon",
    description: "Altın sarısı çıtır patatesler, ketçap ve mayonez ile.",
    price: 60.00,
    discountRate: 0,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Çıtır Soğan Halkası 10'lu",
    description: "Sıcak ve çıtır kaplamalı soğan halkaları.",
    price: 55.00,
    discountRate: 0,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Tavuk Nugget 8'li",
    description: "Çıtır pane kaplı tavuk parçaları ve sos.",
    price: 75.00,
    discountRate: 0,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kumru Sandviç",
    description: "Kumru ekmeğinde sucuk, sosis, salam, kaşar peyniri ve turşu.",
    price: 120.00,
    discountRate: 10,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Ayvalık Tostu Lüks",
    description: "Özel Ayvalık ekmeğinde bol malzeme ve kaşar.",
    price: 110.00,
    discountRate: 0,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Hot Dog Sandviç",
    description: "Sosis, hardal, ketçap ve kornişon turşu sandviç ekmeğinde.",
    price: 95.00,
    discountRate: 0,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Club Sandviç",
    description: "Üç kat tost ekmeğinde tavuk, jambon, yumurta, marul ve mayonez.",
    price: 145.00,
    discountRate: 0,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Çıtır Mozzarella Parmakları 6'lı",
    description: "Eriyen mozzarella dolgulu çıtır parmaklar.",
    price: 85.00,
    discountRate: 5,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },

  // --- Ev Yemekleri & Çorbalar ---
  {
    name: "Süzme Mercimek Çorbası",
    description: "Limon dilimi ve kıtır ekmekler ile sıcak servis.",
    price: 65.00,
    discountRate: 0,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1547592165-e1d17fed6005?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Ezogelin Çorbası",
    description: "Bulgur, pirinç ve nane sosu ile geleneksel lezzet.",
    price: 65.00,
    discountRate: 0,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1547592165-e1d17fed6005?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kelle Paça Çorbası",
    description: "Bol sarımsak ve sirke sosu ile terbiyeli kelle paça.",
    price: 110.00,
    discountRate: 0,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1547592165-e1d17fed6005?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Tavuk Suyu Çorbası",
    description: "Didiklenmiş tavuk etleri ve şehriyeli sıcak çorba.",
    price: 75.00,
    discountRate: 0,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1547592165-e1d17fed6005?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Etli Kuru Fasulye",
    description: "Geleneksel güveçte etli kuru fasulye.",
    price: 135.00,
    discountRate: 10,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Tereyağlı Pirinç Pilavı",
    description: "Nohutlu veya sade tane tane pirinç pilavı.",
    price: 65.00,
    discountRate: 0,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1586201375761-83865001e31c?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Meyhane Usulü Bulgur Pilavı",
    description: "Domates, biber ve soğanlı bulgur pilavı.",
    price: 60.00,
    discountRate: 0,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1574316071802-0d684efa7bf5?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Fırın Karnıyarık",
    description: "Kıymalı harç dolgulu köz patlıcan yemeği.",
    price: 145.00,
    discountRate: 0,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "İzmir Köfte Porsiyon",
    description: "Salçalı soslu fırınlanmış köfte ve patates.",
    price: 155.00,
    discountRate: 0,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1585325701165-351af916e5ec?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Zeytinyağlı Yaprak Sarma 6 Adet",
    description: "Limon dilimleriyle soğuk servis edilen zeytinyağlı sarma.",
    price: 85.00,
    discountRate: 15,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kıymalı Makarna Bolognese",
    description: "Özel kıymalı bolonez soslu İtalyan makarnası.",
    price: 140.00,
    discountRate: 0,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Makarna Fettuccine Alfredo",
    description: "Krema, mantar, tavuk göğsü dilimleri ve parmesan peyniri.",
    price: 165.00,
    discountRate: 0,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Izgara Tavuklu Sezar Salata",
    description: "Marul yaprakları, ızgara tavuk dilimleri, kruton ve Sezar sos.",
    price: 155.00,
    discountRate: 10,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Geleneksel Çoban Salatası",
    description: "Küp domates, salatalık, biber, zeytinyağı ve limon soslu.",
    price: 75.00,
    discountRate: 0,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Yoğurtlu Mantı Porsiyon",
    description: "Kayseri usulü etli mantı, süzme yoğurt ve tereyağlı nane sosu ile.",
    price: 185.00,
    discountRate: 0,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Fırın Kadınbudu Köfte 2 Adet",
    description: "Pirinç ve kıymalı köfte, yanında patates püresi ile.",
    price: 140.00,
    discountRate: 0,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1585325701165-351af916e5ec?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Zeytinyağlı Enginar Dolması",
    description: "Bezelye, patates, havuç garnitürlü zeytinyağlı enginar göbeği.",
    price: 95.00,
    discountRate: 0,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Hünkar Beğendi",
    description: "Köz patlıcanlı beğendi yatağında lokum gibi dana kuşbaşı.",
    price: 320.00,
    discountRate: 5,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },

  // --- Tatlılar ---
  {
    name: "Fıstıklı Cevizli Baklava Porsiyon",
    description: "4 dilim geleneksel çıtır baklava, şerbetli.",
    price: 120.00,
    discountRate: 0,
    categoryName: "Tatlılar",
    imageUrl: "https://images.unsplash.com/photo-1587314168485-3236d6710814?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Fırın Sütlaç Klasik",
    description: "Üzeri fırınlanmış enfes sütlü sütlaç tatlısı.",
    price: 75.00,
    discountRate: 0,
    categoryName: "Tatlılar",
    imageUrl: "https://images.unsplash.com/photo-1579372786545-d24232daf58c?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Fıstıklı Kadayıf",
    description: "Bol Antep fıstıklı tel kadayıf porsiyon.",
    price: 110.00,
    discountRate: 10,
    categoryName: "Tatlılar",
    imageUrl: "https://images.unsplash.com/photo-1587314168485-3236d6710814?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "San Sebastian Cheesecake",
    description: "Ortası akışkan yanık İspanyol cheesecake.",
    price: 130.00,
    discountRate: 0,
    categoryName: "Tatlılar",
    imageUrl: "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Çikolatalı Yoğun Pasta",
    description: "Kat kat çikolatalı ıslak kek ve krema dolgusu.",
    price: 115.00,
    discountRate: 0,
    categoryName: "Tatlılar",
    imageUrl: "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kazandibi Porsiyon",
    description: "Karuk dibi yanıklı sütlü saray tatlısı.",
    price: 75.00,
    discountRate: 0,
    categoryName: "Tatlılar",
    imageUrl: "https://images.unsplash.com/photo-1579372786545-d24232daf58c?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Tiramisu Klasik",
    description: "Mascarpone peynirli espresso soslu İtalyan tatlısı.",
    price: 125.00,
    discountRate: 15,
    categoryName: "Tatlılar",
    imageUrl: "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Çikolatalı Sufle",
    description: "İçi akışkan çikolatalı sufle, pudra şekeriyle.",
    price: 95.00,
    discountRate: 0,
    categoryName: "Tatlılar",
    imageUrl: "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Şekerpare 3 Adet",
    description: "Şerbetli fındıklı geleneksel şekerpare tatlısı.",
    price: 70.00,
    discountRate: 0,
    categoryName: "Tatlılar",
    imageUrl: "https://images.unsplash.com/photo-1587314168485-3236d6710814?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },

  // --- İçecekler ---
  {
    name: "Coca-Cola Kutu 330 Ml",
    description: "Soğuk ferahlatıcı kola lezzeti.",
    price: 32.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Coca-Cola Zero Kutu 330 Ml",
    description: "Sıfır şeker serinletici kola lezzeti.",
    price: 32.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1548907040-4d42b52115ec?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Fanta Kutu 330 Ml",
    description: "Meyveli serinletici portakal gazoz lezzeti.",
    price: 30.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1624552184280-9e9631bbeee9?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Sprite Kutu 330 Ml",
    description: "Soğuk limon aromalı gazoz.",
    price: 30.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1625772290748-390939a9521d?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Yayık Ayranı Porsiyon",
    description: "Köpüklü ev yapımı buz gibi yayık ayranı.",
    price: 25.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1541014741259-df5290dbf2f7?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Limonata Ev Yapımı",
    description: "Nane yaprakları ve taze sıkılmış limon ile soğuk limonata.",
    price: 45.00,
    discountRate: 10,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Şalgam Suyu Acılı 330 Ml",
    description: "Adana usulü acılı şalgam suyu.",
    price: 25.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Şalgam Suyu Acısız 330 Ml",
    description: "Klasik acısız şalgam suyu.",
    price: 25.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Taze Portakal Suyu",
    description: "Günlük taze sıkılmış portakallar, katkısız.",
    price: 55.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1622597467836-f3285f367e9c?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Maden Suyu Cam",
    description: "Soğuk cam şişede sade doğal mineralli maden suyu.",
    price: 18.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1608885898957-a599fb16987f?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Su Cam Şişe 330 Ml",
    description: "Soğuk premium cam şişede kaynak suyu.",
    price: 15.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1610970881699-44a55b4cfd87?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Fuzetea Şeftali Kutu",
    description: "Şeftali aromalı serinletici ice tea.",
    price: 30.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Tavuk Kanat Porsiyon",
    description: "Izgara piliç kanatları, bulgur pilavı ve közlenmiş biber ile.",
    price: 195.00,
    discountRate: 0,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1608500218902-15b218d6e355?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kuzu Ciğer Şiş Porsiyon",
    description: "Taze kuzu ciğeri parçaları, sumaklı soğan salatası ve sıcak lavaş ile.",
    price: 290.00,
    discountRate: 10,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Vali Kebabı Özel",
    description: "2 kişilik dev kebap tabağı: Adana, Urfa, tavuk şiş, köfte ve döner.",
    price: 590.00,
    discountRate: 0,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1544025162-d76694265947?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Sarma Beyti Kebabı",
    description: "Lavaşa sarılı kıyma kebabı dilimleri, soslu tereyağlı köz sebzeler.",
    price: 295.00,
    discountRate: 0,
    categoryName: "Kebaplar & Izgaralar",
    imageUrl: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kıymalı Yumurtalı Pide",
    description: "Kıyma harcı ve üzerinde taze fırınlanmış yumurta.",
    price: 180.00,
    discountRate: 0,
    categoryName: "Pide & Lahmacun",
    imageUrl: "https://images.unsplash.com/photo-1613564834644-a170848986a4?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Ispanaklı Peynirli Pide",
    description: "Kavrulmuş ıspanak ve beyaz peynir dolgulu Karadeniz pidesi.",
    price: 155.00,
    discountRate: 0,
    categoryName: "Pide & Lahmacun",
    imageUrl: "https://images.unsplash.com/photo-1613564834644-a170848986a4?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Kuşbaşılı Yumurtalı Pide",
    description: "Kuşbaşı et harcı üzerine taze fırınlanmış yumurta ile.",
    price: 200.00,
    discountRate: 0,
    categoryName: "Pide & Lahmacun",
    imageUrl: "https://images.unsplash.com/photo-1613564834644-a170848986a4?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Ton Balıklı Pizza",
    description: "Ton balığı, mısır, kırmızı soğan, zeytin ve mozzarella peyniri.",
    price: 220.00,
    discountRate: 0,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Barbekü Soslu Tavuklu Pizza",
    description: "Tavuk göğsü dilimleri, mantar, barbekü sos and mozzarella.",
    price: 215.00,
    discountRate: 0,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Jalapeno Biberli Acı Pizza",
    description: "Kıyma, jalapeno acı biber, mısır, soğan and mozzarella.",
    price: 220.00,
    discountRate: 15,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Mega Çıtır Kova",
    description: "4 çıtır kanat, 4 çıtır nugget, patates kızartması ve soslar.",
    price: 185.00,
    discountRate: 0,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Soğan Halkası 15'li",
    description: "Mega boy çıtır kaplamalı soğan halkaları.",
    price: 70.00,
    discountRate: 0,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Sigara Böreği Porsiyon (6 Adet)",
    description: "Çıtır yufka içinde lor peynirli ev yapımı sigara böreği.",
    price: 75.00,
    discountRate: 0,
    categoryName: "Pizza & Fast Food",
    imageUrl: "https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Zeytinyağlı Taze Fasulye",
    description: "Domates ve soğanla ağır ateşte pişmiş taze fasulye.",
    price: 95.00,
    discountRate: 0,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "İmambayıldı Porsiyon",
    description: "Zeytinyağlı bol domatesli soğanlı patlıcan yemeği.",
    price: 110.00,
    discountRate: 0,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Sıcak Etli Yaprak Sarma",
    description: "Kıymalı pirinçli yaprak sarmaları, üzerinde tereyağı sosu ve yoğurt ile.",
    price: 165.00,
    discountRate: 10,
    categoryName: "Ev Yemekleri & Çorbalar",
    imageUrl: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Fıstıklı Dürüm Tatlısı",
    description: "Yemyeşil bol Antep fıstıklı dürüm baklava.",
    price: 135.00,
    discountRate: 0,
    categoryName: "Tatlılar",
    imageUrl: "https://images.unsplash.com/photo-1587314168485-3236d6710814?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Saray Keşkülü",
    description: "Üzeri badem ve fıstık süslemeli sütlü keşkül tatlısı.",
    price: 80.00,
    discountRate: 0,
    categoryName: "Tatlılar",
    imageUrl: "https://images.unsplash.com/photo-1579372786545-d24232daf58c?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Supangle Çikolatalı",
    description: "Dibinde kek dilimi olan yoğun çikolatalı puding.",
    price: 80.00,
    discountRate: 0,
    categoryName: "Tatlılar",
    imageUrl: "https://images.unsplash.com/photo-1579372786545-d24232daf58c?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Muzlu Puding Magnolia",
    description: "Bebe bisküvili ve taze muz dilimli hafif krema tatlısı.",
    price: 90.00,
    discountRate: 5,
    categoryName: "Tatlılar",
    imageUrl: "https://images.unsplash.com/photo-1579372786545-d24232daf58c?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Karamelli Trileçe",
    description: "Üç farklı sütle ıslatılmış hafif Balkan tatlısı, karamel soslu.",
    price: 95.00,
    discountRate: 0,
    categoryName: "Tatlılar",
    imageUrl: "https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Sıkma Limonata Nane",
    description: "Soğuk cam bardakta taze nane yapraklı limonata.",
    price: 45.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Taze Sıkma Nar Suyu",
    description: "Katkısız %100 taze nar suyu, soğuk.",
    price: 65.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1622597467836-f3285f367e9c?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  },
  {
    name: "Sıcak Türk Çayı",
    description: "İnce belli cam bardakta demli sıcak çay.",
    price: 15.00,
    discountRate: 0,
    categoryName: "İçecekler",
    imageUrl: "https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500&auto=format&fit=crop&q=60",
    unitCode: "ADET"
  }
];

async function main() {
  console.log("🌱 Tohumlama başlatılıyor...");

  // 1. Ölçü Birimlerini (Unit) Bul veya Oluştur
  console.log("📐 Birimler kontrol ediliyor...");
  const unitAdet = await prisma.unit.upsert({
    where: { code: "ADET" },
    update: {},
    create: { code: "ADET", nameTr: "Adet", nameEn: "Pieces" }
  });
  const unitKg = await prisma.unit.upsert({
    where: { code: "KG" },
    update: {},
    create: { code: "KG", nameTr: "Kg", nameEn: "Kg" }
  });
  const unitLitre = await prisma.unit.upsert({
    where: { code: "LITRE" },
    update: {},
    create: { code: "LITRE", nameTr: "Litre", nameEn: "Liters" }
  });
  const unitPaket = await prisma.unit.upsert({
    where: { code: "PAKET" },
    update: {},
    create: { code: "PAKET", nameTr: "Paket", nameEn: "Pack" }
  });

  const getUnitId = (code: string) => {
    switch (code) {
      case "KG": return unitKg.id;
      case "LITRE": return unitLitre.id;
      case "PAKET": return unitPaket.id;
      default: return unitAdet.id;
    }
  };

  // 2. Markayı Bul veya Oluştur (Diğer)
  const defaultBrand = await prisma.brand.upsert({
    where: { name: "Diğer" },
    update: {},
    create: { name: "Diğer" }
  });

  // 3. Restoran Dükkanını Bul ve Güncelle (İsim Güncellemesi ve Aktiflik)
  console.log("🏪 Restoran dükkanı güncelleniyor...");
  const restaurantShop = await prisma.shop.update({
    where: { id: RESTAURANT_SHOP_ID },
    data: {
      name: "Test Kebap & Lahmacun",
      description: "Hoppa'nın en lezzetli kebap ve pideleri burada!",
      isActive: true,
      type: "RESTAURANT"
    }
  });
  console.log(`✅ Restoran Dükkanı güncellendi: ${restaurantShop.name}`);

  // 4. Market Dükkanının Aktifliğinden Emin Ol
  console.log("🏪 Market dükkanı güncelleniyor...");
  const marketShop = await prisma.shop.update({
    where: { id: MARKET_SHOP_ID },
    data: {
      isActive: true,
      type: "MARKET"
    }
  });
  console.log(`✅ Market Dükkanı aktifliği kontrol edildi: ${marketShop.name}`);

  // 5. Her İki Dükkandaki Eski Ürünleri Temizle (Önce ilişkili siparişleri temizle)
  console.log("🧹 Mevcut ürünler ve ilişkili siparişler temizleniyor...");
  
  // Hedef dükkanlardaki ürünlerin ID'lerini bul
  const productsToDelete = await prisma.product.findMany({
    where: {
      shopId: {
        in: [MARKET_SHOP_ID, RESTAURANT_SHOP_ID]
      }
    },
    select: { id: true }
  });
  const productIds = productsToDelete.map(p => p.id);

  if (productIds.length > 0) {
    // Bu ürünleri içeren OrderItem'ları bul
    const orderItems = await prisma.orderItem.findMany({
      where: {
        productId: { in: productIds }
      },
      select: { orderId: true }
    });
    const orderIds = Array.from(new Set(orderItems.map(oi => oi.orderId)));

    if (orderIds.length > 0) {
      console.log(`⚠️ Silinecek ürünlere ait ${orderIds.length} sipariş tespit edildi. Sipariş geçmişi temizleniyor...`);
      
      // Ödeme kayıtlarını sil
      await prisma.paymentTransaction.deleteMany({
        where: {
          orderId: { in: orderIds }
        }
      });
      
      // Siparişleri sil (OrderItem'lar cascade silinir)
      await prisma.order.deleteMany({
        where: {
          id: { in: orderIds }
        }
      });
    }
  }

  const deletedProductsCount = await prisma.product.deleteMany({
    where: {
      shopId: {
        in: [MARKET_SHOP_ID, RESTAURANT_SHOP_ID]
      }
    }
  });
  console.log(`🗑️ ${deletedProductsCount.count} adet eski dükkan ürünü silindi.`);

  // 6. MARKET Ürünlerini Ekle
  console.log(`📦 ${marketProducts.length} adet MARKET ürünü ekleniyor...`);
  for (const item of marketProducts) {
    const categoryId = await ensureCategory(item.categoryName, "MARKET");
    const unitId = getUnitId(item.unitCode);
    const barcode = `MK-${require('crypto').randomBytes(4).toString('hex').toUpperCase()}`;
    const sku = barcode;

    // A. GlobalProduct Oluştur
    const globalProduct = await prisma.globalProduct.create({
      data: {
        barcode,
        sku,
        name: item.name,
        prettyName: item.name.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
        imageUrl: item.imageUrl,
        description: item.description,
        unitId,
        brandId: defaultBrand.id,
        categoryId,
        shownPrice: item.price,
        regularPrice: item.price / (1 - (item.discountRate / 100)),
        discountRate: item.discountRate
      }
    });

    // B. Product Oluştur
    await prisma.product.create({
      data: {
        shopId: MARKET_SHOP_ID,
        categoryId,
        unitId,
        brandId: defaultBrand.id,
        globalProductId: globalProduct.id,
        barcode,
        name: item.name,
        imageUrl: item.imageUrl,
        description: item.description,
        regularPrice: item.price / (1 - (item.discountRate / 100)),
        price: item.price,
        discountRate: item.discountRate,
        stockQuantity: 100,
        isActive: true
      }
    });
  }

  // 7. RESTAURANT Ürünlerini Ekle
  console.log(`🍔 ${restaurantProducts.length} adet RESTAURANT ürünü ekleniyor...`);
  for (const item of restaurantProducts) {
    const categoryId = await ensureCategory(item.categoryName, "RESTAURANT");
    const unitId = getUnitId(item.unitCode);
    const barcode = `RS-${require('crypto').randomBytes(4).toString('hex').toUpperCase()}`;
    const sku = barcode;

    // A. GlobalProduct Oluştur
    const globalProduct = await prisma.globalProduct.create({
      data: {
        barcode,
        sku,
        name: item.name,
        prettyName: item.name.toLowerCase().replace(/[^a-z0-9]+/g, '-'),
        imageUrl: item.imageUrl,
        description: item.description,
        unitId,
        brandId: defaultBrand.id,
        categoryId,
        shownPrice: item.price,
        regularPrice: item.price / (1 - (item.discountRate / 100)),
        discountRate: item.discountRate
      }
    });

    // B. Product Oluştur
    await prisma.product.create({
      data: {
        shopId: RESTAURANT_SHOP_ID,
        categoryId,
        unitId,
        brandId: defaultBrand.id,
        globalProductId: globalProduct.id,
        barcode,
        name: item.name,
        imageUrl: item.imageUrl,
        description: item.description,
        regularPrice: item.price / (1 - (item.discountRate / 100)),
        price: item.price,
        discountRate: item.discountRate,
        stockQuantity: 100,
        isActive: true
      }
    });
  }

  console.log("✨ Tohumlama tamamlandı!");
}

main()
  .catch((e) => {
    console.error("🚨 Hata oluştu:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

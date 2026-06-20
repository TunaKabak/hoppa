import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const catalogProducts = [
  // --- SU & İÇECEK ---
  {
    barcode: "8690576029001",
    brand: "Erikli",
    name: "Doğal Kaynak Suyu 5L",
    category: "Su & İçecek",
    subCategory: "Su",
    imageUrl: "https://placehold.co/400x400/e3f2fd/0277bd?text=Erikli+5L",
    isWeighted: false,
    description: "Erikli eşsiz lezzetiyle doğal kaynak suyu."
  },
  {
    barcode: "8690576029002",
    brand: "Erikli",
    name: "Su 1.5L",
    category: "Su & İçecek",
    subCategory: "Su",
    imageUrl: "https://placehold.co/400x400/e3f2fd/0277bd?text=Erikli+1.5L",
    isWeighted: false,
    description: "Günlük su ihtiyacınız için pratik 1.5 litrelik pet şişe su."
  },
  {
    barcode: "8690576029003",
    brand: "Coca-Cola",
    name: "Original 2.5L",
    category: "Su & İçecek",
    subCategory: "Gazlı İçecek",
    imageUrl: "https://static.ticimax.cloud/cdn-cgi/image/width=-,quality=85/14610/uploads/urunresimleri/buyuk/kolacoca-cola161217coca-cola-25-lt-b37270.jpg",
    isWeighted: false,
    description: "Klasik efsane lezzetiyle 2.5 Litre Coca-Cola."
  },
  {
    barcode: "8690576029004",
    brand: "Coca-Cola",
    name: "Zero Sugar 1L",
    category: "Su & İçecek",
    subCategory: "Gazlı İçecek",
    imageUrl: "https://www.alphamega.com.cy/Files/Images/Products/781315.jpg",
    isWeighted: false,
    description: "Şekersiz efsane lezzet."
  },
  {
    barcode: "8690576029005",
    brand: "Fanta",
    name: "Portakal 2.5L",
    category: "Su & İçecek",
    subCategory: "Gazlı İçecek",
    imageUrl: "https://placehold.co/400x400/ff9800/ffffff?text=Fanta",
    isWeighted: false,
    description: "Portakal aromalı gazlı içecek."
  },
  {
    barcode: "8690576029006",
    brand: "Sprite",
    name: "Gazoz 2.5L",
    category: "Su & İçecek",
    subCategory: "Gazlı İçecek",
    imageUrl: "https://placehold.co/400x400/4caf50/ffffff?text=Sprite",
    isWeighted: false,
    description: "Limon ve misket limonu aromalı ferahlatıcı gazoz."
  },
  {
    barcode: "8690576029007",
    brand: "Beypazarı",
    name: "Doğal Maden Suyu 6'lı",
    category: "Su & İçecek",
    subCategory: "Maden Suyu",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/08040710/beypazari-maden-suyu-6x200-ml-ea0f41-1650x1650.jpg",
    isWeighted: false,
    description: "Zengin mineralli doğal maden suyu."
  },
  {
    barcode: "8690576029008",
    brand: "Red Bull",
    name: "Enerji İçeceği 250ml",
    category: "Su & İçecek",
    subCategory: "Enerji",
    imageUrl: "https://placehold.co/400x400/1a237e/ffeb3b?text=RedBull",
    isWeighted: false,
    description: "Zihni ve bedeni canlandırır."
  },
  {
    barcode: "8690576029009",
    brand: "Koop",
    name: "Ayran 1L",
    category: "Su & İçecek",
    subCategory: "Ayran & Şalgam",
    imageUrl: "https://www.kibrissanalmarket.com/wp-content/uploads/2021/08/koop-titanic-ayran-980ml-5087-600x600-1.jpg?x39403",
    isWeighted: false,
    description: "Geleneksel lezzetli taze ayran."
  },

  // --- MEYVE & SEBZE ---
  {
    barcode: "8690576029101",
    brand: "Yerli",
    name: "Muz (İthal) kg",
    category: "Meyve & Sebze",
    subCategory: "Meyve",
    imageUrl: "https://placehold.co/400x400/fff176/000000?text=Muz",
    isWeighted: true,
    description: "Taze ve lezzetli ithal muz."
  },
  {
    barcode: "8690576029102",
    brand: "Yerli",
    name: "Elma (Starking) kg",
    category: "Meyve & Sebze",
    subCategory: "Meyve",
    imageUrl: "https://placehold.co/400x400/ef5350/ffffff?text=Elma",
    isWeighted: true,
    description: "Kırmızı, kütür kütür Starking elma."
  },
  {
    barcode: "8690576029103",
    brand: "Yerli",
    name: "Domates (Salkım) kg",
    category: "Meyve & Sebze",
    subCategory: "Sebze",
    imageUrl: "https://placehold.co/400x400/f44336/ffffff?text=Domates",
    isWeighted: true,
    description: "Dalından taze salkım domates."
  },
  {
    barcode: "8690576029104",
    brand: "Yerli",
    name: "Salatalık (Çengel) kg",
    category: "Meyve & Sebze",
    subCategory: "Sebze",
    imageUrl: "https://placehold.co/400x400/66bb6a/ffffff?text=Salatalik",
    isWeighted: true,
    description: "Taptaze, çıtır Çengelköy salatalığı."
  },
  {
    barcode: "8690576029105",
    brand: "Kıbrıs",
    name: "Patates kg",
    category: "Meyve & Sebze",
    subCategory: "Sebze",
    imageUrl: "https://www.kibrissanalmarket.com/wp-content/uploads/2021/08/patates-kg-14fb.jpg?x39403",
    isWeighted: true,
    description: "Yerli lezzetli Kıbrıs patatesi."
  },
  {
    barcode: "8690576029106",
    brand: "Yerli",
    name: "Kuru Soğan kg",
    category: "Meyve & Sebze",
    subCategory: "Sebze",
    imageUrl: "https://placehold.co/400x400/ffe0b2/e65100?text=Sogan",
    isWeighted: true,
    description: "Yemeklerin vazgeçilmezi taze kuru soğan."
  },

  // --- ATIŞTIRMALIK ---
  {
    barcode: "8690576029201",
    brand: "Lays",
    name: "Klasik Patates Cipsi (Mega Boy)",
    category: "Atıştırmalık",
    subCategory: "Cips",
    imageUrl: "https://placehold.co/400x400/fff176/000000?text=Lays",
    isWeighted: false,
    description: "Klasik tuzlu çıtır patates cipsi."
  },
  {
    barcode: "8690576029202",
    brand: "Ruffles",
    name: "Peynir Soğan (Mega)",
    category: "Atıştırmalık",
    subCategory: "Cips",
    imageUrl: "https://placehold.co/400x400/2196f3/ffffff?text=Ruffles",
    isWeighted: false,
    description: "Tırtıklı peynir ve soğan aromalı patates cipsi."
  },
  {
    barcode: "8690576029203",
    brand: "Doritos",
    name: "Nacho Peynirli (Süper)",
    category: "Atıştırmalık",
    subCategory: "Cips",
    imageUrl: "https://placehold.co/400x400/ff5722/ffffff?text=Doritos",
    isWeighted: false,
    description: "Bol peynir aromalı çıtır üçgen mısır cipsi."
  },
  {
    barcode: "8690576029204",
    brand: "Ülker",
    name: "Çikolatalı Gofret 5'li Paket",
    category: "Atıştırmalık",
    subCategory: "Çikolata & Gofret",
    imageUrl: "https://placehold.co/400x400/d32f2f/ffffff?text=Ulker+Gofret",
    isWeighted: false,
    description: "Ülker Çikolatalı Gofret sevmeyen var mı?"
  },
  {
    barcode: "8690576029205",
    brand: "Eti",
    name: "Karam Gurme Bitter",
    category: "Atıştırmalık",
    subCategory: "Çikolata & Gofret",
    imageUrl: "https://placehold.co/400x400/212121/ffffff?text=Karam",
    isWeighted: false,
    description: "Bitter çikolata ve çikolatalı kremanın muazzam gurme uyumu."
  },
  {
    barcode: "8690576029206",
    brand: "Oreo",
    name: "Kremalı Bisküvi",
    category: "Atıştırmalık",
    subCategory: "Bisküvi & Kek",
    imageUrl: "https://placehold.co/400x400/01579b/ffffff?text=Oreo",
    isWeighted: false,
    description: "Süte bandırarak yenebilecek eşsiz kakaolu bisküvi."
  },

  // --- FIRIN ---
  {
    barcode: "8690576029301",
    brand: "Yerel Fırın",
    name: "Somun Ekmek 200g",
    category: "Fırın",
    subCategory: "Ekmek",
    imageUrl: "https://cdn2.a101.com.tr/dbmk89vnr/CALL/Image/get/vOsfLrRtD1_1024x1024.png",
    isWeighted: false,
    description: "Taze çıkmış sıcak çıtır somun ekmek."
  },
  {
    barcode: "8690576029302",
    brand: "Uno",
    name: "Büyük Tost Ekmeği",
    category: "Fırın",
    subCategory: "Ekmek",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/05051108/5051108_1-6606d7-1650x1650.jpg",
    isWeighted: false,
    description: "Tostlarınız için yumuşacık ve uzun ömürlü dilimli tost ekmeği."
  },
  {
    barcode: "8690576029303",
    brand: "Yerel Fırın",
    name: "Simit (Susamlı)",
    category: "Fırın",
    subCategory: "Unlu Mamül",
    imageUrl: "https://placehold.co/400x400/8d6e63/ffffff?text=Simit",
    isWeighted: false,
    description: "Gevrek susamlı sokak simidi."
  },

  // --- TEMEL GIDA ---
  {
    barcode: "8690576029401",
    brand: "Yudum",
    name: "Ayçiçek Yağı 1L",
    category: "Temel Gıda",
    subCategory: "Sıvı Yağ",
    imageUrl: "https://lazbakkal.ca/cdn/shop/products/Yudum-Sunflower-Oil-1-L-East-Market.jpg?v=1667155217",
    isWeighted: false,
    description: "Kızartmalar ve yemekler için hafif ayçiçek yağı."
  },
  {
    barcode: "8690576029402",
    brand: "Yayla",
    name: "Baldo Pirinç 1kg",
    category: "Temel Gıda",
    subCategory: "Bakliyat",
    imageUrl: "https://placehold.co/400x400/e0e0e0/000000?text=Yayla+Pirinc",
    isWeighted: false,
    description: "Tane tane pilavlar için Yayla Baldo Pirinç."
  },
  {
    barcode: "8690576029403",
    brand: "Barilla",
    name: "Burgu Makarna 500g",
    category: "Temel Gıda",
    subCategory: "Makarna",
    imageUrl: "https://placehold.co/400x400/1976d2/ffffff?text=Barilla",
    isWeighted: false,
    description: "Durum buğdayından İtalyan kalitesinde Barilla Makarna."
  },
  {
    barcode: "8690576029404",
    brand: "Tat",
    name: "Domates Salçası 830g",
    category: "Temel Gıda",
    subCategory: "Salça & Sos",
    imageUrl: "https://placehold.co/400x400/b71c1c/ffffff?text=Tat+Salca",
    isWeighted: false,
    description: "Yemeklerinize renk ve lezzet katan taze domates salçası."
  },
  {
    barcode: "8690576029405",
    brand: "Çaykur",
    name: "Rize Turist Çayı 1kg",
    category: "Temel Gıda",
    subCategory: "Çay & Kahve",
    imageUrl: "https://placehold.co/400x400/ffeb3b/b71c1c?text=Caykur",
    isWeighted: false,
    description: "Demli ve kokulu gerçek Rize turist çayı."
  },
  {
    barcode: "8690576029406",
    brand: "Söke",
    name: "Un 1kg",
    category: "Temel Gıda",
    subCategory: "Un & İrmik",
    imageUrl: "https://placehold.co/400x400/fff9c4/000000?text=Soke+Un",
    isWeighted: false,
    description: "Börek, poğaça ve kekler için kaliteli Söke Un."
  },

  // --- SÜT & KAHVALTILIK ---
  {
    barcode: "8690576029501",
    brand: "Koop",
    name: "Pastörize Süt 1L",
    category: "Süt & Kahvaltılık",
    subCategory: "Süt",
    imageUrl: "https://placehold.co/400x400/e3f2fd/0d47a1?text=Koop+Sut",
    isWeighted: false,
    description: "Doğal lezzeti korunmuş günlük pastörize süt."
  },
  {
    barcode: "8690576029502",
    brand: "Koop",
    name: "Hellim Peyniri 250g",
    category: "Süt & Kahvaltılık",
    subCategory: "Peynir",
    imageUrl: "https://placehold.co/400x400/fff9c4/fbc02d?text=Hellim",
    isWeighted: true,
    description: "Kıbrıs'ın tescilli enfes kızartmalık hellim peyniri."
  },
  {
    barcode: "8690576029503",
    brand: "İçim",
    name: "Taze Kaşar 400g",
    category: "Süt & Kahvaltılık",
    subCategory: "Peynir",
    imageUrl: "https://placehold.co/400x400/fff176/f57f17?text=Icim+Kasar",
    isWeighted: false,
    description: "Tostların ve yemeklerin vazgeçilmezi İçim Kaşar."
  }
];

async function main() {
  console.log("🌱 Global Ürün Kataloğu tohumlanıyor...");

  for (const item of catalogProducts) {
    await prisma.globalProduct.upsert({
      where: { barcode: item.barcode },
      update: {},
      create: item
    });
  }

  console.log("✅ Global Ürün Kataloğu başarıyla tohumlandı!");
}

main()
  .catch((e) => {
    console.error("Tohumlama hatası:", e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });

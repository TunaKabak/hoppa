import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const catalogProducts: any[] = [
  // --- SU & İÇECEK ---
  {
    barcode: "8690576029001",
    brand: "Erikli",
    name: "Doğal Kaynak Suyu 5L",
    category: "Su & İçecek",
    subCategory: "Su",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/01011505/erikli-dogal-kaynak-suyu-5-l-a4d1d9-1650x1650.jpg",
    isWeighted: false,
    description: "Erikli eşsiz lezzetiyle doğal kaynak suyu."
  },
  {
    barcode: "8690576029002",
    brand: "Erikli",
    name: "Su 1.5L",
    category: "Su & İçecek",
    subCategory: "Su",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/01010045/erikli-su-15-l-c8e9b6-1650x1650.jpg",
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
    imageUrl: "https://images.migrosone.com/sanalmarket/product/08011210/coca-cola-zero-sugar-1-l-cfb1ad-1650x1650.jpg",
    isWeighted: false,
    description: "Şekersiz efsane lezzet."
  },
  {
    barcode: "8690576029005",
    brand: "Fanta",
    name: "Portakal 2.5L",
    category: "Su & İçecek",
    subCategory: "Gazlı İçecek",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/08011403/fanta-portakal-arovali-gazli-icecek-25-l-25f0bf-1650x1650.jpg",
    isWeighted: false,
    description: "Portakal aromalı gazlı içecek."
  },
  {
    barcode: "8690576029006",
    brand: "Sprite",
    name: "Gazoz 2.5L",
    category: "Su & İçecek",
    subCategory: "Gazlı İçecek",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/08011603/sprite-gazoz-25-l-50a80e-1650x1650.jpg",
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
    imageUrl: "https://images.migrosone.com/sanalmarket/product/08050000/red-bull-energy-drink-250-ml-4a0bcf-1650x1650.jpg",
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
    imageUrl: "https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=500&auto=format&fit=crop",
    isWeighted: true,
    description: "Taze ve lezzetli ithal muz."
  },
  {
    barcode: "8690576029102",
    brand: "Yerli",
    name: "Elma (Starking) kg",
    category: "Meyve & Sebze",
    subCategory: "Meyve",
    imageUrl: "https://images.unsplash.com/photo-1560806887-1e4cd0b6cbd6?w=500&auto=format&fit=crop",
    isWeighted: true,
    description: "Kırmızı, kütür kütür Starking elma."
  },
  {
    barcode: "8690576029103",
    brand: "Yerli",
    name: "Domates (Salkım) kg",
    category: "Meyve & Sebze",
    subCategory: "Sebze",
    imageUrl: "https://images.unsplash.com/photo-1595855759920-86582396756a?w=500&auto=format&fit=crop",
    isWeighted: true,
    description: "Dalından taze salkım domates."
  },
  {
    barcode: "8690576029104",
    brand: "Yerli",
    name: "Salatalık (Çengel) kg",
    category: "Meyve & Sebze",
    subCategory: "Sebze",
    imageUrl: "https://images.unsplash.com/photo-1449300079323-02e209d9d3a6?w=500&auto=format&fit=crop",
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
    imageUrl: "https://images.unsplash.com/photo-1508747703725-719ae257c84a?w=500&auto=format&fit=crop",
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
    imageUrl: "https://images.migrosone.com/sanalmarket/product/05081515/lays-klasik-patates-cipsi-super-boy-107-g-5b4d1c-1650x1650.jpg",
    isWeighted: false,
    description: "Klasik tuzlu çıtır patates cipsi."
  },
  {
    barcode: "8690576029202",
    brand: "Ruffles",
    name: "Peynir Soğan (Mega)",
    category: "Atıştırmalık",
    subCategory: "Cips",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/05081702/ruffles-peynir-sogan-arovali-patates-cipsi-super-boy-107-g-ef6b52-1650x1650.jpg",
    isWeighted: false,
    description: "Tırtıklı peynir ve soğan aromalı patates cipsi."
  },
  {
    barcode: "8690576029203",
    brand: "Doritos",
    name: "Nacho Peynirli (Süper)",
    category: "Atıştırmalık",
    subCategory: "Cips",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/05081600/doritos-nacho-peynirli-misi-cipsi-super-boy-113-g-de1f4c-1650x1650.jpg",
    isWeighted: false,
    description: "Bol peynir aromalı çıtır üçgen mısır cipsi."
  },
  {
    barcode: "8690576029204",
    brand: "Ülker",
    name: "Çikolatalı Gofret 5'li Paket",
    category: "Atıştırmalık",
    subCategory: "Çikolata & Gofret",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/07044030/ulker-cikolatali-gofret-36-g-7cc2ce-1650x1650.jpg",
    isWeighted: false,
    description: "Ülker Çikolatalı Gofret sevmeyen var mı?"
  },
  {
    barcode: "8690576029205",
    brand: "Eti",
    name: "Karam Gurme Bitter",
    category: "Atıştırmalık",
    subCategory: "Çikolata & Gofret",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/07040188/eti-karam-gurme-bitter-cikolatali-gofret-50-g-a7c81d-1650x1650.jpg",
    isWeighted: false,
    description: "Bitter çikolata ve çikolatalı kremanın muazzam gurme uyumu."
  },
  {
    barcode: "8690576029206",
    brand: "Oreo",
    name: "Kremalı Bisküvi",
    category: "Atıştırmalık",
    subCategory: "Bisküvi & Kek",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/07050011/oreo-kremali-biskuvi-110-g-1e66c7-1650x1650.jpg",
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
    imageUrl: "https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=500&auto=format&fit=crop",
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
    imageUrl: "https://images.migrosone.com/sanalmarket/product/04050100/yudum-aycicek-yagi-1-l-8c7602-1650x1650.jpg",
    isWeighted: false,
    description: "Kızartmalar ve yemekler için hafif ayçiçek yağı."
  },
  {
    barcode: "8690576029402",
    brand: "Yayla",
    name: "Baldo Pirinç 1kg",
    category: "Temel Gıda",
    subCategory: "Bakliyat",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/01030018/yayla-baldo-pirinc-1-kg-4235e1-1650x1650.jpg",
    isWeighted: false,
    description: "Tane tane pilavlar için Yayla Baldo Pirinç."
  },
  {
    barcode: "8690576029403",
    brand: "Barilla",
    name: "Burgu Makarna 500g",
    category: "Temel Gıda",
    subCategory: "Makarna",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/04010103/barilla-burgu-makarna-fusilli-500-g-72b63f-1650x1650.jpg",
    isWeighted: false,
    description: "Durum buğdayından İtalyan kalitesinde Barilla Makarna."
  },
  {
    barcode: "8690576029404",
    brand: "Tat",
    name: "Domates Salçası 830g",
    category: "Temel Gıda",
    subCategory: "Salça & Sos",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/04250005/tat-domates-salcasi-830-g-2da7ff-1650x1650.jpg",
    isWeighted: false,
    description: "Yemeklerinize renk ve lezzet katan taze domates salçası."
  },
  {
    barcode: "8690576029405",
    brand: "Çaykur",
    name: "Rize Turist Çayı 1kg",
    category: "Temel Gıda",
    subCategory: "Çay & Kahve",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/03010118/caykur-rize-turist-cayi-1000-g-8a5e55-1650x1650.jpg",
    isWeighted: false,
    description: "Demli ve kokulu gerçek Rize turist çayı."
  },
  {
    barcode: "8690576029406",
    brand: "Söke",
    name: "Un 1kg",
    category: "Temel Gıda",
    subCategory: "Un & İrmik",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/04110000/soke-bugday-unu-1-kg-88e404-1650x1650.jpg",
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
    imageUrl: "https://images.migrosone.com/sanalmarket/product/11010010/sutas-tam-yagli-sut-1-l-90abed-1650x1650.jpg",
    isWeighted: false,
    description: "Doğal lezzeti korunmuş günlük pastörize süt."
  },
  {
    barcode: "8690576029502",
    brand: "Koop",
    name: "Hellim Peyniri 250g",
    category: "Süt & Kahvaltılık",
    subCategory: "Peynir",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/10040713/koop-hellim-peyniri-250-g-783dfa-1650x1650.jpg",
    isWeighted: true,
    description: "Kıbrıs'ın tescilli enfes kızartmalık hellim peyniri."
  },
  {
    barcode: "8690576029503",
    brand: "İçim",
    name: "Taze Kaşar 400g",
    category: "Süt & Kahvaltılık",
    subCategory: "Peynir",
    imageUrl: "https://images.migrosone.com/sanalmarket/product/10050212/icim-kasar-peyniri-400-g-2092f6-1650x1650.jpg",
    isWeighted: false,
    description: "Tostların ve yemeklerin vazgeçilmezi İçim Kaşar."
  }
];

const extraCategories = [
  {
    name: "Su & İçecek",
    sub: "Gazlı İçecek",
    brands: ["Coca-Cola", "Pepsi", "Fanta", "Sprite", "Yedigün"],
    items: ["Kutu Cola", "Pet Şişe Cola", "Kutu Gazoz", "Pet Şişe Gazoz", "Mandalina Aromalı Gazoz"],
    sizes: ["250ml", "330ml", "500ml", "1L", "1.5L", "2L", "2.5L"]
  },
  {
    name: "Atıştırmalık",
    sub: "Bisküvi & Kek",
    brands: ["Ülker", "Eti", "Oreo", "Milka", "Nestle"],
    items: ["Çikolatalı Gofret", "Kakaolu Bisküvi", "Kremalı Bisküvi", "Sütlü Çikolata", "Antep Fıstıklı Çikolata", "Kek", "Gofret"],
    sizes: ["30g", "50g", "80g", "100g", "120g", "150g", "200g"]
  },
  {
    name: "Temel Gıda",
    sub: "Makarna",
    brands: ["Filiz", "Barilla", "Nuhun Ankara", "Oba"],
    items: ["Spaghetti", "Burgu Makarna", "Fiyonk Makarna", "Kelebek Makarna", "Erişte", "Arpa Şehriye"],
    sizes: ["500g"]
  },
  {
    name: "Temel Gıda",
    sub: "Bakliyat",
    brands: ["Reis", "Duru", "Tat"],
    items: ["Kırmızı Mercimek", "Yeşil Mercimek", "Pilavlık Pirinç", "Nohut", "Kuru Fasulye", "Pilavlık Bulgur"],
    sizes: ["1kg", "2kg"]
  },
  {
    name: "Kişisel Bakım",
    sub: "Şampuan",
    brands: ["Elidor", "Pantene", "Head & Shoulders", "Clear", "Loreal"],
    items: ["Saç Bakım Şampuanı", "Kepeğe Karşı Etkili Şampuan", "Hacim Verici Şampuan", "Saç Kremi"],
    sizes: ["350ml", "400ml", "500ml", "600ml"]
  },
  {
    name: "Temizlik",
    sub: "Deterjan",
    brands: ["Ariel", "Omo", "Alo", "Persil"],
    items: ["Sıvı Deterjan", "Toz Deterjan", "Yumuşatıcı", "Leke Çıkarıcı"],
    sizes: ["1.5L", "3L", "4kg", "6kg"]
  },
  {
    name: "Meyve & Sebze",
    sub: "Meyve",
    brands: ["Bahçeden", "Yerli", "Antalya"],
    items: ["Amasya Elması", "İthal Muz", "Portakal", "Mandalina", "Çilek", "Armut", "Karpuz", "Kavun", "Üzüm", "Şeftali", "Erik"],
    sizes: ["1kg", "2kg", "500g"]
  },
  {
    name: "Meyve & Sebze",
    sub: "Sebze",
    brands: ["Bahçeden", "Yerli", "Antalya"],
    items: ["Tarla Domatesi", "Badem Salatalık", "Patates", "Kuru Soğan", "Sarımsak", "Çarliston Biber", "Kemer Patlıcan", "Sakız Kabak", "Ispanak", "Maydanoz", "Dereotu"],
    sizes: ["1kg", "500g", "Bag"]
  },
  {
    name: "Süt & Kahvaltılık",
    sub: "Peynir",
    brands: ["Sütaş", "Pınar", "Tahsildaroğlu", "İçim", "Ekici"],
    items: ["Süzme Peynir", "Taze Kaşar", "Klasik Beyaz Peynir", "Labne", "Eski Kaşar", "Örgü Peyniri", "Dil Peyniri"],
    sizes: ["200g", "400g", "500g", "600g", "1kg"]
  },
  {
    name: "Atıştırmalık",
    sub: "Cips",
    brands: ["Lays", "Ruffles", "Doritos", "Pringles", "Patos"],
    items: ["Klasik Cips", "Baharatlı Cips", "Peynirli Cips", "Yoğurtlu Cips", "Ketçaplı Cips"],
    sizes: ["Mega Boy", "Aile Boyu", "Süper Boy", "Standart"]
  }
];

const generatedProducts: any[] = [];
let barcodeCounter = 8690000000000;

for (const cat of extraCategories) {
  for (const brand of cat.brands) {
    for (const item of cat.items) {
      for (const size of cat.sizes) {
        barcodeCounter++;
        const barcode = barcodeCounter.toString();
        const cleanName = `${brand} ${item} ${size}`;
        let unit = "ADET";
        let isWeighted = false;
        let minQuantity = 1.0;
        let stepSize = 1.0;

        if (cat.name === "Meyve & Sebze") {
          unit = "KG";
          isWeighted = true;
          minQuantity = 0.5;
          stepSize = 0.25;
        }

        generatedProducts.push({
          barcode,
          brand,
          name: cleanName,
          category: cat.name,
          subCategory: cat.sub,
          imageUrl: `https://placehold.co/400x400/ffffff/000000?text=${encodeURIComponent(brand + "+" + item)}`,
          unit,
          minQuantity,
          stepSize,
          isWeighted,
          description: `${brand} kalitesiyle özenle üretilmiş ${cleanName}.`
        });
      }
    }
  }
}

catalogProducts.push(...generatedProducts);

async function main() {
  console.log(`🌱 Global Ürün Kataloğu tohumlanıyor... Toplam ${catalogProducts.length} ürün.`);

  // To speed up, we run in chunks of 50 parallel upserts
  const chunkSize = 50;
  for (let i = 0; i < catalogProducts.length; i += chunkSize) {
    const chunk = catalogProducts.slice(i, i + chunkSize);
    await Promise.all(
      chunk.map((item) =>
        prisma.globalProduct.upsert({
          where: { barcode: item.barcode },
          update: {
            unit: item.unit,
            minQuantity: item.minQuantity,
            stepSize: item.stepSize
          },
          create: item
        })
      )
    );
    console.log(`   Seeded ${Math.min(i + chunkSize, catalogProducts.length)} / ${catalogProducts.length} products...`);
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

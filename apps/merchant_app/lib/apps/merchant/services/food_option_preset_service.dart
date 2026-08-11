class FoodOptionPreset {
  final String id;
  final String title;
  final String category;
  final String description;
  final List<Map<String, dynamic>> optionGroups;

  const FoodOptionPreset({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.optionGroups,
  });
}

class FoodOptionPresetService {
  static List<FoodOptionPreset> getPresets() {
    return [
      const FoodOptionPreset(
        id: 'burger_preset',
        title: 'Burger Şablonu',
        category: 'Hamburger & Fast Food',
        description: 'Boyut, Pişme derecesi, çıkarılabilir içindekiler, ekstra peynir ve yan ürünler.',
        optionGroups: [
          {
            'name': 'Porsiyon / Boyut Seçimi',
            'description': 'Lütfen hamburger boyutunu seçiniz.',
            'type': 'VARIATION',
            'selectionType': 'RADIO',
            'minSelections': 1,
            'maxSelections': 1,
            'freeSelectionsCount': 0,
            'options': [
              {'name': 'Tek Köfte (150g)', 'price': 0.0, 'isDefault': true, 'isRemovable': false},
              {'name': 'Çift Köfte (300g)', 'price': 75.0, 'isDefault': false, 'isRemovable': false},
            ]
          },
          {
            'name': 'Köfte Pişme Derecesi',
            'description': 'Köftenizin nasıl pişmesini istersiniz?',
            'type': 'VARIATION',
            'selectionType': 'RADIO',
            'minSelections': 1,
            'maxSelections': 1,
            'freeSelectionsCount': 0,
            'options': [
              {'name': 'Orta Pişmiş', 'price': 0.0, 'isDefault': true, 'isRemovable': false},
              {'name': 'Çok Pişmiş', 'price': 0.0, 'isDefault': false, 'isRemovable': false},
            ]
          },
          {
            'name': 'Çıkarılacak Malzemeler',
            'description': 'İstemediğiniz malzemeleri çıkarabilirsiniz.',
            'type': 'INGREDIENT',
            'selectionType': 'CHECKBOX',
            'minSelections': 0,
            'maxSelections': 10,
            'freeSelectionsCount': 0,
            'options': [
              {'name': 'Soğan Olmasın', 'price': 0.0, 'isDefault': false, 'isRemovable': true},
              {'name': 'Domates Olmasın', 'price': 0.0, 'isDefault': false, 'isRemovable': true},
              {'name': 'Turşu Olmasın', 'price': 0.0, 'isDefault': false, 'isRemovable': true},
              {'name': 'Mayonez / Burger Sos Olmasın', 'price': 0.0, 'isDefault': false, 'isRemovable': true},
            ]
          },
          {
            'name': 'Ekstra Malzemeler',
            'description': 'Eklemek istediğiniz ekstra malzemeleri seçin.',
            'type': 'INGREDIENT',
            'selectionType': 'CHECKBOX',
            'minSelections': 0,
            'maxSelections': 5,
            'freeSelectionsCount': 0,
            'options': [
              {'name': 'Ekstra Cheddar Peyniri', 'price': 25.0, 'isDefault': false, 'isRemovable': false},
              {'name': 'Ekstra Dana Füme / Bacon', 'price': 35.0, 'isDefault': false, 'isRemovable': false},
              {'name': 'Ekstra Mantar & Karamelize Soğan', 'price': 20.0, 'isDefault': false, 'isRemovable': false},
            ]
          },
          {
            'name': 'Promosyonlu Yan Ürün & İçecek',
            'description': 'Burger yanına indirimli yan ürün veya içecek ekleyin.',
            'type': 'SIDE_PRODUCT',
            'selectionType': 'CHECKBOX',
            'minSelections': 0,
            'maxSelections': 3,
            'freeSelectionsCount': 0,
            'options': [
              {'name': 'Patates Kızartması (Orta)', 'price': 30.0, 'isDefault': false, 'isRemovable': false},
              {'name': 'Soğan Halkası (6 Adet)', 'price': 35.0, 'isDefault': false, 'isRemovable': false},
              {'name': 'Kutu Kola (330ml)', 'price': 25.0, 'isDefault': false, 'isRemovable': false},
              {'name': 'Açık Ayran (300ml)', 'price': 15.0, 'isDefault': false, 'isRemovable': false},
            ]
          }
        ]
      ),
      const FoodOptionPreset(
        id: 'pizza_preset',
        title: 'Pizza Şablonu',
        category: 'Pizza & Pide',
        description: 'Boyut, Hamur tipi, çıkarılabilir malzeme ve sos hakları.',
        optionGroups: [
          {
            'name': 'Pizza Boyutu',
            'description': 'Lütfen pizza boyutunu seçiniz.',
            'type': 'VARIATION',
            'selectionType': 'RADIO',
            'minSelections': 1,
            'maxSelections': 1,
            'freeSelectionsCount': 0,
            'options': [
              {'name': 'Küçük Boy (22cm)', 'price': 0.0, 'isDefault': true, 'isRemovable': false},
              {'name': 'Orta Boy (28cm)', 'price': 45.0, 'isDefault': false, 'isRemovable': false},
              {'name': 'Büyük Boy (34cm)', 'price': 85.0, 'isDefault': false, 'isRemovable': false},
            ]
          },
          {
            'name': 'Hamur Tipi & Kenar',
            'description': 'Hamur ve kenar tercihinizi belirleyin.',
            'type': 'VARIATION',
            'selectionType': 'RADIO',
            'minSelections': 1,
            'maxSelections': 1,
            'freeSelectionsCount': 0,
            'options': [
              {'name': 'Klasik Hamur', 'price': 0.0, 'isDefault': true, 'isRemovable': false},
              {'name': 'İnce Hamur (Thin Crust)', 'price': 0.0, 'isDefault': false, 'isRemovable': false},
              {'name': 'Peynir Dolgulu Kenar', 'price': 35.0, 'isDefault': false, 'isRemovable': false},
            ]
          },
          {
            'name': 'Çıkarılacak Malzemeler',
            'description': 'Tariften çıkartmak istediğiniz malzemeler.',
            'type': 'INGREDIENT',
            'selectionType': 'CHECKBOX',
            'minSelections': 0,
            'maxSelections': 10,
            'freeSelectionsCount': 0,
            'options': [
              {'name': 'Mantar Olmasın', 'price': 0.0, 'isDefault': false, 'isRemovable': true},
              {'name': 'Siyah Zeytin Olmasın', 'price': 0.0, 'isDefault': false, 'isRemovable': true},
              {'name': 'Yeşil Biber Olmasın', 'price': 0.0, 'isDefault': false, 'isRemovable': true},
              {'name': 'Mısır Olmasın', 'price': 0.0, 'isDefault': false, 'isRemovable': true},
            ]
          },
          {
            'name': 'Sos Seçimi (İlk 2 Sos Ücretiz)',
            'description': 'Pizza yanında verilecek soslar.',
            'type': 'EXTRA',
            'selectionType': 'CHECKBOX',
            'minSelections': 0,
            'maxSelections': 5,
            'freeSelectionsCount': 2,
            'options': [
              {'name': 'Ketçap', 'price': 5.0, 'isDefault': true, 'isRemovable': false},
              {'name': 'Mayonez', 'price': 5.0, 'isDefault': true, 'isRemovable': false},
              {'name': 'Sarımsaklı Mayonez', 'price': 8.0, 'isDefault': false, 'isRemovable': false},
              {'name': 'Acı Sos', 'price': 8.0, 'isDefault': false, 'isRemovable': false},
              {'name': 'Ranch Sos', 'price': 10.0, 'isDefault': false, 'isRemovable': false},
            ]
          }
        ]
      ),
      const FoodOptionPreset(
        id: 'doner_preset',
        title: 'Döner & Kebap Şablonu',
        category: 'Döner & Kebap',
        description: 'Porsiyon, lavaş/ekmek, yeşillik ve ayran seçenekleri.',
        optionGroups: [
          {
            'name': 'Porsiyon & Servis Tipi',
            'description': 'Lütfen servis tipini seçiniz.',
            'type': 'VARIATION',
            'selectionType': 'RADIO',
            'minSelections': 1,
            'maxSelections': 1,
            'freeSelectionsCount': 0,
            'options': [
              {'name': 'Standart Dürüm Lavaş', 'price': 0.0, 'isDefault': true, 'isRemovable': false},
              {'name': 'Tombik Ekmek', 'price': 0.0, 'isDefault': false, 'isRemovable': false},
              {'name': 'Porsiyon (Tabakta 150g)', 'price': 45.0, 'isDefault': false, 'isRemovable': false},
              {'name': '1.5 Porsiyon (Tabakta 225g)', 'price': 80.0, 'isDefault': false, 'isRemovable': false},
            ]
          },
          {
            'name': 'Yeşillik & Garnitür Tercihi',
            'description': 'İstemediğiniz yeşilliklerin tikini kaldırın.',
            'type': 'INGREDIENT',
            'selectionType': 'CHECKBOX',
            'minSelections': 0,
            'maxSelections': 10,
            'freeSelectionsCount': 0,
            'options': [
              {'name': 'Soğan Olmasın', 'price': 0.0, 'isDefault': false, 'isRemovable': true},
              {'name': 'Domates Olmasın', 'price': 0.0, 'isDefault': false, 'isRemovable': true},
              {'name': 'Maydanoz Olmasın', 'price': 0.0, 'isDefault': false, 'isRemovable': true},
              {'name': 'Sumak / Baharat Olmasın', 'price': 0.0, 'isDefault': false, 'isRemovable': true},
            ]
          },
          {
            'name': 'İçecek & Yan Ürünler',
            'description': 'Döner yanına soğuk içecek veya yan ürün ekleyin.',
            'type': 'SIDE_PRODUCT',
            'selectionType': 'CHECKBOX',
            'minSelections': 0,
            'maxSelections': 3,
            'freeSelectionsCount': 0,
            'options': [
              {'name': 'Yayık Ayran (300ml)', 'price': 15.0, 'isDefault': false, 'isRemovable': false},
              {'name': 'Acılı Şalgam Suyu', 'price': 15.0, 'isDefault': false, 'isRemovable': false},
              {'name': 'Kutu Kola', 'price': 25.0, 'isDefault': false, 'isRemovable': false},
              {'name': 'Künefe / Tatlı Ekstrası', 'price': 65.0, 'isDefault': false, 'isRemovable': false},
            ]
          }
        ]
      ),
      const FoodOptionPreset(
        id: 'beverage_preset',
        title: 'İçecek & Kahve Şablonu',
        category: 'Kahve & İçecek',
        description: 'Boyut, süt tipi, şeker oranı ve buz tercihi.',
        optionGroups: [
          {
            'name': 'İçecek Boyutu',
            'description': 'İçecek boyutu seçiniz.',
            'type': 'VARIATION',
            'selectionType': 'RADIO',
            'minSelections': 1,
            'maxSelections': 1,
            'freeSelectionsCount': 0,
            'options': [
              {'name': 'Small (Küçük)', 'price': 0.0, 'isDefault': true, 'isRemovable': false},
              {'name': 'Medium (Orta)', 'price': 15.0, 'isDefault': false, 'isRemovable': false},
              {'name': 'Large (Büyük)', 'price': 25.0, 'isDefault': false, 'isRemovable': false},
            ]
          },
          {
            'name': 'Şeker & Buz Tercihi',
            'description': 'Sıcaklık ve şeker oranını seçin.',
            'type': 'EXTRA',
            'selectionType': 'RADIO',
            'minSelections': 0,
            'maxSelections': 1,
            'freeSelectionsCount': 0,
            'options': [
              {'name': 'Buzsuz', 'price': 0.0, 'isDefault': false, 'isRemovable': false},
              {'name': 'Az Buzlu', 'price': 0.0, 'isDefault': false, 'isRemovable': false},
              {'name': 'Bol Buzlu', 'price': 0.0, 'isDefault': true, 'isRemovable': false},
            ]
          }
        ]
      )
    ];
  }
}

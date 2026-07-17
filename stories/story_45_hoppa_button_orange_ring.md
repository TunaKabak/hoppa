# Story #45: Hoppa Butonu Turuncu Halka İyileştirmesi

## Teknik Tasarım ve Kapsam

Bu hikaye, Hoppa uygulamasının ana gezinti (bottom navigation) çubuğunun merkezinde yer alan `hoppa_button.png` görselinin, Hoppa kurumsal kimliğine ve logosuna tam uyum sağlayacak şekilde yeniden tasarlanmasını amaçlar. Mevcut turuncu halkanın daha canlı, modern ve dikkat çekici bir hale getirilmesi hedeflenmektedir.

### 1. Tasarım Kuralları ve Kurumsal Kimlik
* **Canlılık:** Butondaki turuncu halkanın mat görüntüsü giderilecek, marka kimliğindeki canlı, parlayan turuncu tonları kullanılacaktır.
* **Derinlik ve Stil:** Premium 3D claymation/glossy tarzı korunarak halkaya hafif bir neon ışıma ve gölge efekti eklenecektir.
* **Merkez İkon:** Yeşil Hoppa simgesinin bütünlüğü ve beyaz dairesel buton zemini korunacaktır.

### 2. Yenilenecek Görsel Yolları
Uygulama genelinde kullanılan buton görseli iki konumda güncellenecektir:
1. `apps/consumer_app/assets/images/hoppa_button.png` (Tüketici uygulamasının yerel asset'i)
2. `assets/images/hoppa_button.png` (Global paylaşılan asset)

## Doğrulama Protokolü
* Üretilen yeni buton görselinin belirtilen konumlara başarıyla kaydedildiği doğrulanır.
* Görsel formatının (PNG) ve boyutunun (< 2MB) standartlara uygun olduğu doğrulanır.
* Tüketici uygulamasının statik analiz (`flutter analyze`) testini geçtiği doğrulanır.

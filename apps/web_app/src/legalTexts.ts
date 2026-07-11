export interface LegalSection {
  title?: string;
  text: string[];
}

export interface LegalDoc {
  title: string;
  sections: LegalSection[];
}

export interface LegalTexts {
  privacy: LegalDoc;
  kvkk: LegalDoc;
  cookie: LegalDoc;
}

export const legalTexts: Record<'tr' | 'en' | 'ru', LegalTexts> = {
  tr: {
    privacy: {
      title: "Gizlilik Politikası",
      sections: [
        {
          title: "1. Giriş",
          text: [
            "Bu Gizlilik Politikası, Hoppa (Bundan böyle \"Hoppa\" veya \"Platform\" olarak anılacaktır) web sitesini (hoppanow.com) ve mobil uygulamalarını (Tüketici, Üye İşyeri, Kurye) kullanan siz değerli kullanıcılarımızın kişisel verilerinin gizliliğini ve güvenliğini korumak amacıyla hazırlanmıştır.",
            "Hoppa, Kuzey Kıbrıs Türk Cumhuriyeti Anayasası’nın 19. Maddesi (Özel Hayatın Gizliliği) ile KKTC 89/2007 Sayılı Kişisel Verilerin Korunması Yasası ve Türkiye Cumhuriyeti 6698 Sayılı Kişisel Verilerin Korunması Kanunu (KVKK) çerçevesinde veri sorumlusu sıfatıyla hareket etmektedir."
          ]
        },
        {
          title: "2. Hangi Kişisel Verilerinizi İşliyoruz?",
          text: [
            "Platformumuzu kullanımınız esnasında aşağıdaki kategorilerdeki verileriniz işlenmektedir:",
            "• Kimlik Bilgileri: Adınız, soyadınız.",
            "• İletişim Bilgileri: Telefon numaranız, e-posta adresiniz.",
            "• Konum Bilgileri: Siparişinizin teslimatı ve kuryelerin canlı takibi amacıyla (yalnızca izniniz dahilinde) GPS konum verileriniz.",
            "• Teslimat ve Sipariş Bilgileri: Sipariş ettiğiniz ürünler, teslimat adresiniz, sipariş notlarınız ve alışveriş geçmişiniz.",
            "• Finansal Bilgiler: Ödeme işlemleri için kullanılan kartların tokenize edilmiş bilgileri (Ödeme altyapısı sağlayıcımız tarafından güvenli şekilde saklanmakta olup Hoppa sunucularında tam kart bilgileri tutulmamaktadır).",
            "• İşlem Güvenliği ve Cihaz Bilgileri: IP adresiniz, cihaz modeliniz, işletim sisteminiz, uygulama içi loglar ve oturum bilgileri."
          ]
        },
        {
          title: "3. Kişisel Verilerin İşlenme Amaçları",
          text: [
            "Kişisel verileriniz aşağıdaki amaçlarla işlenmektedir:",
            "• Platform üyelik işlemlerinin gerçekleştirilmesi,",
            "• Siparişlerin alınması, hazırlanması ve kuryeler vasıtasıyla teslimatının sağlanması,",
            "• Canlı kurye takibi ve teslimat rotası optimizasyonu,",
            "• Ödeme işlemlerinin güvenli bir şekilde gerçekleştirilmesi,",
            "• Müşteri destek hizmetlerinin sunulması ve şikayet/taleplerinizin çözümlenmesi,",
            "• Hizmet kalitemizin artırılması, analiz ve geliştirme çalışmalarının yapılması,",
            "• Mevzuattan kaynaklanan hukuki yükümlülüklerin yerine getirilmesi."
          ]
        },
        {
          title: "4. Kişisel Verilerin Yurt Dışına Aktarılması",
          text: [
            "Hoppa, veri depolama ve bulut bilişim hizmetleri için uluslararası altyapı sağlayıcılarını (Firebase, Google Cloud vb.) ve veri tabanı sunucularını kullanmaktadır. Bu sunucular KKTC sınırları dışında (Türkiye veya Avrupa Birliği ülkelerinde) yer alabilmektedir. Kişisel verilerinizin KKTC dışına aktarılması, 89/2007 Sayılı Yasa’nın sınır ötesi veri aktarımına ilişkin kuralları uyarınca açık rızanıza veya yasada öngörülen istisnai hallere dayanarak gerçekleştirilmektedir."
          ]
        },
        {
          title: "5. Veri Güvenliği",
          text: [
            "Kişisel verilerinizin yetkisiz kişilerce erişilmesini, değiştirilmesini veya ifşa edilmesini önlemek amacıyla sektör standartlarında şifreleme (SSL/TLS), HTTPS protokolleri, rate limiting, veri tabanı erişim yetkilendirmeleri ve güvenlik testleri uygulanmaktadır."
          ]
        },
        {
          title: "6. Haklarınız",
          text: [
            "KKTC 89/2007 Sayılı Yasa ve TC 6698 Sayılı KVKK uyarınca aşağıdaki haklara sahipsiniz:",
            "• Kişisel verilerinizin işlenip işlenmediğini öğrenme,",
            "• İşlenmişse buna ilişkin bilgi talep etme,",
            "• İşlenme amacını ve amacına uygun kullanılıp kullanılmadığını öğrenme,",
            "• Eksik veya yanlış işlenmişse düzeltilmesini isteme,",
            "• Yasaların öngördüğü şartlar çerçevesinde verilerinizin silinmesini veya yok edilmesini isteme,",
            "• Verilerinizin aktarıldığı üçüncü kişileri bilme,",
            "• Verilerinizin otomatik sistemler vasıtasıyla analiz edilmesi suretiyle aleyhinize bir sonucun ortaya çıkmasına itiraz etme."
          ]
        },
        {
          title: "7. İletişim",
          text: [
            "Gizlilik Politikası ile ilgili her türlü soru, görüş veya hak talepleriniz için bizimle iletişime geçebilirsiniz:",
            "E-posta: support@hoppanow.com",
            "Adres: Yeni Boğaziçi, Gazimağusa, KKTC"
          ]
        }
      ]
    },
    kvkk: {
      title: "KVKK Aydınlatma Metni",
      sections: [
        {
          title: "Veri Sorumlusu",
          text: [
            "Veri Sorumlusu: Hoppa Technology and Consultant Limited (Kayıt No: MTR-XXXX)",
            "Adres: Yeni Boğaziçi, Gazimağusa, KKTC",
            "E-posta: support@hoppanow.com",
            "Bu Aydınlatma Metni, Kuzey Kıbrıs Türk Cumhuriyeti’nde yürürlükte olan 89/2007 Sayılı Kişisel Verilerin Korunması Yasası (Madde 12 - Bilgi Verme Yükümlülüğü) ve Türkiye Cumhuriyeti’nde yürürlükte olan 6698 Sayılı Kişisel Verilerin Korunması Kanunu (Madde 10 - Aydınlatma Yükümlülüğü) uyarınca, Hoppa kullanıcılarını bilgilendirmek amacıyla hazırlanmıştır."
          ]
        },
        {
          title: "1. Kişisel Verilerin Elde Edilme Yöntemleri ve Hukuki Sebepleri",
          text: [
            "Kişisel verileriniz; web sitemiz, mobil uygulamalarımız, çağrı merkezimiz, canlı destek kanallarımız ve e-posta yazışmaları aracılığıyla elektronik ortamda toplanmaktadır.",
            "Verileriniz, aşağıdaki hukuki sebeplere dayanılarak işlenmektedir:",
            "• Bir sözleşmenin kurulması veya ifasıyla doğrudan doğruya ilgili olması: Siparişlerin teslimi ve ödeme işlemlerinin yapılması (89/2007 Yasa md. 6(1)(b) / 6698 Kanun md. 5(2)(c)),",
            "• Veri sorumlusunun hukuki yükümlülüğünü yerine getirebilmesi: KKTC Vergi Dairesi, Polis Genel Müdürlüğü veya yetkili diğer idari kurumların yasal taleplerine uyulması (89/2007 Yasa md. 6(1)(c) / 6698 Kanun md. 5(2)(ç)),",
            "• İlgili kişinin açık rızasının/muvafakatinin bulunması: Konum tabanlı kurye takibi hizmeti, pazarlama ve profil oluşturma faaliyetleri ile yurt dışına veri aktarımı (89/2007 Yasa md. 5 / 6698 Kanun md. 5(1))."
          ]
        },
        {
          title: "2. İşlenen Kişisel Verilerin Kimlere ve Hangi Amaçla Aktarılabileceği",
          text: [
            "Kişisel verileriniz, yukarıda belirtilen amaçların gerçekleştirilmesi doğrultusunda ve yasal sınırlar çerçevesinde:",
            "• Siparişlerin hazırlanabilmesi amacıyla Üye İşyerlerine (Restoran, Market vb.),",
            "• Teslimatın gerçekleştirilebilmesi amacıyla Serbest/Sözleşmeli Kuryelere,",
            "• Ödeme işlemlerinin güvenle tamamlanabilmesi için Lisanslı Ödeme Kuruluşlarına,",
            "• Bilgi işlem ve altyapı hizmetlerinin sağlanabilmesi amacıyla Sunucu ve Bulut Altyapısı Sağlayıcılarına,",
            "• Yasal zorunluluklar kapsamında KKTC ve TC Yetkili Kamu Kurum ve Kuruluşlarına aktarılabilecektir."
          ]
        },
        {
          title: "3. İlgili Kişi Olarak Haklarınız ve Başvuru Usulü",
          text: [
            "89/2007 Sayılı Yasa’nın 14. Maddesi ve 6698 Sayılı Kanun’un 11. Maddesi kapsamındaki haklarınızı kullanmak için, kimliğinizi teyit edici belgeler ile birlikte yazılı dilekçenizi yukarıda belirtilen şirket adresimize elden teslim edebilir veya güvenli elektronik imzanız ile ya da sistemimizde kayıtlı e-posta adresiniz üzerinden support@hoppanow.com adresine iletebilirsiniz. Başvurularınız en geç 30 (otuz) gün içerisinde ücretsiz olarak sonuçlandırılacaktır."
          ]
        }
      ]
    },
    cookie: {
      title: "Çerez Politikası",
      sections: [
        {
          title: "Giriş",
          text: [
            "Hoppa olarak, web sitemizin (hoppanow.com) verimli çalışmasını sağlamak ve siz değerli ziyaretçilerimize daha iyi bir kullanıcı deneyimi sunabilmek adına çerezler (cookies) kullanmaktayız. Bu Çerez Politikası, çerezlerin ne olduğunu, hangi çerez türlerini kullandığımızı ve çerez tercihlerinizi nasıl yönetebileceğinizi açıklamak amacıyla KKTC 89/2007 Sayılı Kişisel Verilerin Korunması Yasası ile 6/2012 Sayılı Elektronik Haberleşme Yasası çerçevesinde hazırlanmıştır."
          ]
        },
        {
          title: "1. Çerez (Cookie) Nedir?",
          text: [
            "Çerezler, bir web sitesini ziyaret ettiğinizde cihazınıza (bilgisayar, akıllı telefon, tablet vb.) kaydedilen küçük metin dosyalarıdır. Çerezler, web sitesinin sizi tanımasına, oturum açma bilgilerinizi hatırlamasına ve sitenin kullanımını analiz ederek kullanıcı deneyimini iyileştirmesine yardımcı olur."
          ]
        },
        {
          title: "2. Kullandığımız Çerez Türleri",
          text: [
            "Web sitemizde aşağıdaki amaçlarla çerezler kullanılmaktadır:",
            "• Zorunlu (Temel) Çerezler: Sitemizin çalışması için zorunlu olan çerezlerdir. Oturum açma, güvenlik doğrulama, sepet bilgileri gibi temel işlevleri yürütür. Bu çerezler olmadan sitenin bazı bölümleri çalışamaz.",
            "• Fonksiyonel Çerezler: Dil tercihlerinizi, bölge seçiminizi (örn: KKTC) ve siteyi tekrar ziyaret ettiğinizde kişiselleştirilmiş ayarlarınızı hatırlamak amacıyla kullanılır.",
            "• Analitik ve Performans Çerezleri: Sitemizi kaç kişinin ziyaret ettiğini, hangi sayfaların daha çok tıklandığını anlamamıza yardımcı olur. Bu çerezler anonim olarak veri toplar.",
            "• Hedefleme ve Reklam Çerezleri: İlgi alanlarınıza yönelik reklamlar sunmak ve reklam kampanyalarının etkililiğini ölçmek amacıyla üçüncü taraf servisler (Google, Facebook vb.) tarafından yerleştirilebilir."
          ]
        },
        {
          title: "3. Çerezlerin Hukuki Sebebi",
          text: [
            "Zorunlu çerezler dışındaki çerezler (fonksiyonel, analitik ve reklam çerezleri), siteye ilk girişinizde karşınıza çıkan çerez onay bandı aracılığıyla vereceğiniz açık rızanıza dayanılarak işlenmektedir."
          ]
        },
        {
          title: "4. Çerezleri Nasıl Kontrol Edebilir veya Silebilirsiniz?",
          text: [
            "Çerez kullanımını dilediğiniz zaman sınırlandırabilir veya tamamen engelleyebilirsiniz. Bunun için tarayıcınızın (Google Chrome, Safari, Mozilla Firefox vb.) ayarlarından çerez yönetim panelini kullanabilirsiniz. Ancak, zorunlu çerezlerin engellenmesi durumunda sitemizin bazı özelliklerinin çalışmayabileceğini hatırlatmak isteriz."
          ]
        }
      ]
    }
  },
  en: {
    privacy: {
      title: "Privacy Policy",
      sections: [
        {
          title: "1. Introduction",
          text: [
            "This Privacy Policy has been prepared to protect the privacy and security of the personal data of our valued users using the Hoppa website (hoppanow.com) and mobile applications (Consumer, Merchant, Courier).",
            "Hoppa acts as the data controller within the scope of Article 19 of the Constitution of the Turkish Republic of Northern Cyprus (TRNC) (Privacy of Private Life), the TRNC Law No. 89/2007 on the Protection of Personal Data, and the Law No. 6698 on the Protection of Personal Data (KVKK) of the Republic of Turkey."
          ]
        },
        {
          title: "2. Which Personal Data Do We Process?",
          text: [
            "During your use of our Platform, the following categories of data are processed:",
            "• Identity Information: Your name, surname.",
            "• Contact Information: Your phone number, email address.",
            "• Location Information: Your GPS location data for delivery and live tracking of couriers (only with your permission).",
            "• Delivery and Order Information: Products ordered, delivery address, order notes, and purchase history.",
            "• Financial Information: Tokenized information of cards used for transactions (stored securely by our payment gateway provider; full card information is not stored on Hoppa servers).",
            "• Transaction Security and Device Information: Your IP address, device model, operating system, in-app logs, and session details."
          ]
        },
        {
          title: "3. Purposes of Processing Personal Data",
          text: [
            "Your personal data is processed for the following purposes:",
            "• Carrying out Platform membership procedures,",
            "• Receiving, preparing, and delivering orders via couriers,",
            "• Live courier tracking and delivery route optimization,",
            "• Performing secure payment transactions,",
            "• Providing customer support services and resolving your requests/complaints,",
            "• Improving our service quality, conducting analysis, and development activities,",
            "• Fulfilling legal obligations arising from the legislation."
          ]
        },
        {
          title: "4. Transfer of Personal Data Abroad",
          text: [
            "Hoppa utilizes international infrastructure providers (Firebase, Google Cloud, etc.) and database servers for data storage and cloud computing services. These servers may be located outside the TRNC (such as Turkey or European Union countries). The transfer of your personal data outside the TRNC is carried out based on your explicit consent in accordance with the cross-border data transfer rules of Law No. 89/2007 or exceptions provided by law."
          ]
        },
        {
          title: "5. Data Security",
          text: [
            "Industry-standard encryption (SSL/TLS), HTTPS protocols, rate limiting, database access authorizations, and security tests are applied to prevent unauthorized access, alteration, or disclosure of your personal data."
          ]
        },
        {
          title: "6. Your Rights",
          text: [
            "In accordance with TRNC Law No. 89/2007 and Turkish KVKK No. 6698, you have the following rights:",
            "• Learning whether your personal data is processed,",
            "• Requesting information if processed,",
            "• Learning the purpose of processing and whether it is used appropriately,",
            "• Requesting correction if incomplete or incorrectly processed,",
            "• Requesting erasure or destruction of your data within the framework of conditions provided by law,",
            "• Knowing the third parties to whom your data is transferred,",
            "• Objecting to the occurrence of a result against you by analyzing your data exclusively through automated systems."
          ]
        },
        {
          title: "7. Contact",
          text: [
            "You can contact us for any questions, opinions, or right requests regarding the Privacy Policy:",
            "Email: support@hoppanow.com",
            "Address: Yeni Boğaziçi, Gazimağusa, TRNC"
          ]
        }
      ]
    },
    kvkk: {
      title: "GDPR & KVKK Clarification Text",
      sections: [
        {
          title: "Data Controller",
          text: [
            "Data Controller: Hoppa Technology and Consultant Limited (Reg No: MTR-XXXX)",
            "Address: Yeni Boğaziçi, Gazimağusa, TRNC",
            "Email: support@hoppanow.com",
            "This Clarification Text has been prepared to inform Hoppa users in accordance with the Law No. 89/2007 on the Protection of Personal Data (Article 12 - Obligation to Inform) in force in the Turkish Republic of Northern Cyprus and the Law No. 6698 on the Protection of Personal Data (Article 10 - Obligation to Inform) in force in the Republic of Turkey."
          ]
        },
        {
          title: "1. Methods and Legal Grounds for Obtaining Personal Data",
          text: [
            "Your personal data is collected electronically through our website, mobile applications, call center, live support channels, and email correspondence.",
            "Your data is processed based on the following legal grounds:",
            "• Directly related to the establishment or performance of a contract: Delivery of orders and payment transactions (Law No. 89/2007 Art. 6(1)(b) / Law No. 6698 Art. 5(2)(c)),",
            "• Compliance with a legal obligation of the data controller: Complying with legal requests of the TRNC Tax Office, Police General Directorate, or other authorized administrative institutions (Law No. 89/2007 Art. 6(1)(c) / Law No. 6698 Art. 5(2)(ç)),",
            "• Presence of explicit consent of the data subject: Location-based courier tracking service, marketing and profiling activities, and data transfer abroad (Law No. 89/2007 Art. 5 / Law No. 6698 Art. 5(1))."
          ]
        },
        {
          title: "2. To Whom and For What Purpose Personal Data Can Be Transferred",
          text: [
            "In line with the realization of the above-mentioned purposes and within legal limits, your personal data may be transferred to:",
            "• Member Merchants (Restaurants, Markets, etc.) to prepare orders,",
            "• Freelance/Contracted Couriers to carry out the delivery,",
            "• Licensed Payment Institutions to complete payments securely,",
            "• Server and Cloud Infrastructure Providers to provide information processing and infrastructure services,",
            "• TRNC and TR Authorized Public Institutions and Organizations within the scope of legal obligations."
          ]
        },
        {
          title: "3. Your Rights as a Data Subject and Application Procedure",
          text: [
            "To exercise your rights under Article 14 of Law No. 89/2007 and Article 11 of Law No. 6698, you can hand-deliver your written petition with documents verifying your identity to our company address above, or send it with a secure electronic signature or via your email registered in our system to support@hoppanow.com. Your applications will be concluded free of charge within 30 (thirty) days at the latest."
          ]
        }
      ]
    },
    cookie: {
      title: "Cookie Policy",
      sections: [
        {
          title: "Introduction",
          text: [
            "As Hoppa, we use cookies to ensure that our website (hoppanow.com) works efficiently and to provide a better user experience to our valued visitors. This Cookie Policy has been prepared in accordance with the TRNC Law No. 89/2007 on the Protection of Personal Data and the Electronic Communications Law No. 6/2012 to explain what cookies are, which types of cookies we use, and how you can manage your cookie preferences."
          ]
        },
        {
          title: "1. What is a Cookie?",
          text: [
            "Cookies are small text files saved on your device (computer, smartphone, tablet, etc.) when you visit a website. Cookies help the website recognize you, remember your login information, and improve the user experience by analyzing site usage."
          ]
        },
        {
          title: "2. Types of Cookies We Use",
          text: [
            "Cookies are used on our website for the following purposes:",
            "• Mandatory (Essential) Cookies: These are mandatory cookies for our site to work. It performs basic functions such as login, security verification, and shopping cart information. Without these cookies, some parts of the site cannot function.",
            "• Functional Cookies: Used to remember your language preferences, region selection (e.g., TRNC), and personalized settings when you visit the site again.",
            "• Analytical and Performance Cookies: Helps us understand how many people visit our site and which pages are clicked more. These cookies collect data anonymously.",
            "• Targeting and Advertising Cookies: May be placed by third-party services (Google, Facebook, etc.) to present ads directed to your interests and measure the effectiveness of advertising campaigns."
          ]
        },
        {
          title: "3. Legal Ground of Cookies",
          text: [
            "Cookies other than mandatory cookies (functional, analytical, and advertising cookies) are processed based on your explicit consent given through the cookie consent banner that appears when you first enter the site."
          ]
        },
        {
          title: "4. How Can You Control or Delete Cookies?",
          text: [
            "You can limit or completely block the use of cookies at any time. For this, you can use the cookie management panel in the settings of your browser (Google Chrome, Safari, Mozilla Firefox, etc.). However, we would like to remind you that if mandatory cookies are blocked, some features of our site may not work."
          ]
        }
      ]
    }
  },
  ru: {
    privacy: {
      title: "Политика конфиденциальности",
      sections: [
        {
          title: "1. Введение",
          text: [
            "Настоящая Политика конфиденциальности подготовлена для защиты конфиденциальности и безопасности персональных данных наших уважаемых пользователей, использующих веб-сайт Hoppa (hoppanow.com) и мобильные приложения (Покупатель, Продавец, Курьер).",
            "Hoppa выступает в качестве контроллера данных в рамках статьи 19 Конституции Турецкой Республики Северного Кипра (ТРСК) (Конфиденциальность личной жизни), Закона ТРСК № 89/2007 «О защите персональных данных» и Закона Турецкой Республики № 6698 «О защите персональных данных» (KVKK)."
          ]
        },
        {
          title: "2. Какие персональные данные мы обрабатываем?",
          text: [
            "Во время использования нашей Платформы обрабатываются следующие категории ваших данных:",
            "• Идентификационные данные: Ваше имя, фамилия.",
            "• Контактные данные: Ваш номер телефона, адрес электронной почты.",
            "• Данные о местоположении: Данные GPS вашего местоположения для доставки заказа и отслеживания курьеров в реальном времени (только с вашего разрешения).",
            "• Данные о доставке и заказах: Заказанные товары, адрес доставки, примечания к заказу и история покупок.",
            "• Финансовые данные: Токенизированные данные карт, используемых для транзакций (хранятся в безопасности нашим провайдером платежных систем; полные данные карт не сохраняются на серверах Hoppa).",
            "• Безопасность транзакций и информация об устройстве: Ваш IP-адрес, модель устройства, операционная система, логи внутри приложения и детали сессии."
          ]
        },
        {
          title: "3. Цели обработки персональных данных",
          text: [
            "Ваши персональные данные обрабатываются для следующих целей:",
            "• Выполнение процедур членства на Платформе,",
            "• Прием, подготовка и доставка заказов через курьеров,",
            "• Отслеживание курьеров в реальном времени и оптимизация маршрутов доставки,",
            "• Проведение безопасных платежных транзакций,",
            "• Предоставление услуг поддержки клиентов и разрешение ваших запросов/жалоб,",
            "• Повышение качества наших услуг, проведение анализа и развитие платформы,",
            "• Выполнение юридических обязательств, вытекающих из законодательства."
          ]
        },
        {
          title: "4. Передача персональных данных за границу",
          text: [
            "Hoppa использует международных провайдеров инфраструктуры (Firebase, Google Cloud и др.) и серверы баз данных для хранения данных и услуг облачных вычислений. Эти серверы могут находиться за пределами ТРСК (например, в Турции или странах Европейского Союза). Передача ваших персональных данных за пределы ТРСК осуществляется на основании вашего явного согласия в соответствии с правилами трансграничной передачи данных Закона ТРСК № 89/2007 или исключениями, предусмотренными законом."
          ]
        },
        {
          title: "5. Безопасность данных",
          text: [
            "Шифрование отраслевого стандарта (SSL/TLS), протоколы HTTPS, ограничение частоты запросов (rate limiting), авторизация доступа к базе данных и тесты безопасности применяются для предотвращения несанкционированного доступа, изменения или раскрытия ваших персональных данных."
          ]
        },
        {
          title: "6. Ваши права",
          text: [
            "В соответствии с Законом ТРСК № 89/2007 и Законом ТР № 6698 вы имеете следующие права:",
            "• Узнать, обрабатываются ли ваши персональные данные,",
            "• Запросить информацию, если они обрабатываются,",
            "• Узнать цели обработки и их надлежащее использование,",
            "• Запросить исправление в случае неполной или неверной обработки,",
            "• Запросить удаление или уничтожение ваших данных в рамках условий, предусмотренных законом,",
            "• Знать третьих лиц, которым передаются ваши данные,",
            "• Возражать против принятия решений против вас на основе анализа ваших данных исключительно с помощью автоматизированных систем."
          ]
        },
        {
          title: "7. Контакты",
          text: [
            "Вы можете связаться с нами по любым вопросам, мнениям или запросам прав относительно Политики конфиденциальности:",
            "Электронная почта: support@hoppanow.com",
            "Адрес: Yeni Boğaziçi, Gazimağusa, ТРСК"
          ]
        }
      ]
    },
    kvkk: {
      title: "Разъяснительный текст о защите данных (KVKK)",
      sections: [
        {
          title: "Контроллер данных",
          text: [
            "Контроллер данных: Hoppa Technology and Consultant Limited (Рег. №: MTR-XXXX)",
            "Адрес: Yeni Boğaziçi, Gazimağusa, ТРСК",
            "Электронная почта: support@hoppanow.com",
            "Настоящий Разъяснительный текст подготовлен для информирования пользователей Hoppa в соответствии с Законом № 89/2007 «О защите персональных данных» (Статья 12 - Обязательство по информированию), действующим в Турецкой Республике Северного Кипра, и Законом № 6698 «О защите персональных данных» (Статья 10 - Обязательство по информированию), действующим в Турецкой Республике."
          ]
        },
        {
          title: "1. Методы и законные основания для получения персональных данных",
          text: [
            "Ваши персональные данные собираются в электронном виде через наш веб-сайт, мобильные приложения, колл-центр, каналы поддержки в реальном времени и переписку по электронной почте.",
            "Ваши данные обрабатываются на следующих законных основаниях:",
            "• Прямо связано с заключением или исполнением договора: доставка заказов и платежные транзакции (Закон № 89/2007 ст. 6(1)(b) / Закон № 6698 ст. 5(2)(c)),",
            "• Соблюдение юридических обязательств контроллера данных: соблюдение законных требований Налоговой службы ТРСК, Главного управления полиции или других уполномоченных административных учреждений (Закон № 89/2007 ст. 6(1)(c) / Закон № 6698 ст. 5(2)(ç)),",
            "• Наличие явного согласия субъекта данных: служба отслеживания курьеров на основе геолокации, маркетинговая деятельность и профилирование, а также передача данных за границу (Закон № 89/2007 ст. 5 / Закон № 6698 ст. 5(1))."
          ]
        },
        {
          title: "2. Кому и с какой целью могут быть переданы персональные данные",
          text: [
            "В соответствии с реализацией вышеуказанных целей и в рамках закона, ваши персональные данные могут быть переданы:",
            "• Продавцам (ресторанам, маркетам и т. д.) для подготовки заказов,",
            "• Независимым/контрактным курьерам для осуществления доставки,",
            "• Лицензированным платежным учреждениям для безопасного завершения платежей,",
            "• Провайдерам серверов и облачной инфраструктуры для предоставления услуг обработки данных и инфраструктуры,",
            "• Уполномоченным государственным учреждениям и организациям ТРСК и ТР в рамках юридических обязательств."
          ]
        },
        {
          title: "3. Ваши права как субъекта данных и процедура подачи заявления",
          text: [
            "Чтобы воспользоваться своими правами в соответствии со статьей 14 Закона № 89/2007 и статьей 11 Закона № 6698, вы можете лично доставить письменное заявление с документами, подтверждающими вашу личность, по нашему адресу компании, указанному выше, или отправить его с безопасной электронной подписью или через ваш адрес электронной почты, зарегистрированный в нашей системе, на адрес support@hoppanow.com. Ваши заявления будут рассмотрены бесплатно не позднее чем в течение 30 (того) дней."
          ]
        }
      ]
    },
    cookie: {
      title: "Политика использования файлов cookie",
      sections: [
        {
          title: "Введение",
          text: [
            "Как Hoppa, мы используем файлы cookie, чтобы наш веб-сайт (hoppanow.com) работал эффективно и обеспечивал лучший пользовательский опыт для наших уважаемых посетителей. Настоящая Полика использования файлов cookie подготовлена в соответствии с Законом ТРСК № 89/2007 «О защите персональных данных» и Законом об электронных коммуникациях № 6/2012, чтобы объяснить, что такое файлы cookie, какие типы файлов cookie мы используем и как вы можете управлять своими предпочтениями в отношении файлов cookie."
          ]
        },
        {
          title: "1. Что такое файл cookie?",
          text: [
            "Файлы cookie — это небольшие текстовые файлы, сохраняемые на вашем устройстве (компьютере, смартфоне, планшете и т. д.) при посещении веб-сайта. Файлы cookie помогают веб-сайту распознавать вас, запоминать вашу информацию для входа и улучшать пользовательский опыт, анализируя использование сайта."
          ]
        },
        {
          title: "2. Типы файлов cookie, которые мы используем",
          text: [
            "Файлы cookie используются на нашем веб-сайте для следующих целей:",
            "• Обязательные (основные) файлы cookie: эти файлы необходимы для работы нашего сайта. Они выполняют основные функции, такие как вход в систему, проверка безопасности и корзина покупок. Без этих файлов некоторые разделы сайта не смогут работать.",
            "• Функциональные файлы cookie: используются для запоминания ваших языковых предпочтений, выбора региона (например, ТРСК) и индивидуальных настроек при повторном посещении сайта.",
            "• Аналитические и эксплуатационные файлы cookie: помогают нам понять, сколько человек посещают наш сайт и на какие страницы кликают чаще. Эти файлы собирают данные анонимно.",
            "• Целевые и рекламные файлы cookie: могут размещаться сторонними службами (Google, Facebook и др.) для показа рекламы, соответствующей вашим интересам, и оценки эффективности рекламных кампаний."
          ]
        },
        {
          title: "3. Законные основания использования файлов cookie",
          text: [
            "Файлы cookie, отличные от обязательных (функциональные, аналитические и рекламные), обрабатываются на основании вашего явного согласия, выраженного через баннер согласия на использование файлов cookie, который появляется при первом посещении сайта."
          ]
        },
        {
          title: "4. Как контролировать или удалять файлы cookie?",
          text: [
            "Вы можете в любое время ограничить или полностью заблокировать использование файлов cookie. Для этого вы можете использовать панель управления файлами cookie в настройках вашего браузера (Google Chrome, Safari, Mozilla Firefox и др.). Однако мы хотим напомнить вам, что если обязательные файлы cookie будут заблокированы, некоторые функции нашего сайта могут не работать."
          ]
        }
      ]
    }
  }
};

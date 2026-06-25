import React, { useState, useEffect, useRef } from 'react';
import {
    ShoppingBag,
    MapPin,
    Clock,
    ShieldCheck,
    ChevronRight,
    Star,
    Search,
    ArrowLeft,
    Coffee,
    Droplet,
    Sparkles,
    Phone,
    Truck,
    Store,
    Download,
    Check,
    Smartphone,
    MessageSquare,
    Gift,
    Plus,
    Minus,
    CreditCard,
    User,
    Menu,
    X,
    ExternalLink
} from 'lucide-react';

// Mock Veritabanı - Uygulama simülatörü ve sayfa için
const CATEGORIES = [
    { id: 'market', title: 'Market', badge: 'POPÜLER', icon: '🛒', desc: 'Taze sebze, meyve ve temel gıdalar', bg: 'bg-orange-50' },
    { id: 'restoran', title: 'Restoran', badge: 'POPÜLER', icon: '🍝', desc: 'En sevdiğin yerel lezzetler kapında', bg: 'bg-red-50' },
    { id: 'su', title: 'Su', badge: null, icon: '💧', desc: 'Damacana ve pet şişe su siparişi', bg: 'bg-blue-50' },
    { id: 'kuruyemis', title: 'Kuruyemiş', badge: 'YENİ', icon: '🌰', desc: 'Taze kavrulmuş kuruyemiş çeşitleri', bg: 'bg-yellow-50' },
    { id: 'kahve', title: 'Kahve', badge: null, icon: '☕', desc: 'Sıcak ve soğuk kahve çeşitleri', bg: 'bg-amber-50' },
    { id: 'cicek', title: 'Çiçek', badge: null, icon: '🌸', desc: 'Özel günler için taze aranjmanlar', bg: 'bg-pink-50' }
];

const PRODUCTS = [
    { id: 'madensuyu', name: 'Doğal Maden Suyu 6\'lı', price: 75.00, brand: 'Beypazarı', category: 'su', image: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3', desc: 'Beypazarı Doğal Maden Suyu, mineral zengini yapısıyla her an taze hissettirir.' },
    { id: 'aycicekyagi', name: 'Ayçiçek Yağı 1L', price: 90.00, brand: 'Yudum', category: 'market', image: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3', desc: 'Yüksek kalite standartlarında üretilmiş yemeklik sıvı yağ.' },
    { id: 'ekmek', name: 'Somun Ekmek 200g', price: 25.00, brand: 'Taş Fırın', category: 'market', image: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3', desc: 'Günlük taze pişmiş, çıtır çıtır somun ekmek.' },
    { id: 'patates', name: 'Patates kg', price: 49.99, brand: 'Hoppa Tarım', category: 'market', image: 'https://images.unsplash.com/photo-1518977676601-b53f82aba655?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3', desc: 'Özenle seçilmiş, yemeklik taze yerli patates.' },
    { id: 'zerosugar', name: 'Zero Sugar 1L', price: 79.99, brand: 'Coca-Cola', category: 'su', image: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3', desc: 'Şekersiz ve kalorisiz serinlik.' },
    { id: 'ayran', name: 'Ayran 1L', price: 79.99, brand: 'Sütaş', category: 'market', image: 'https://images.unsplash.com/photo-1528750994863-dd0fd4e7bab6?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3', desc: 'Geleneksel kıvamda, ferahlatıcı lezzet.' }
];

export default function App({ initialTab = 'user' }: { initialTab?: string }) {
    // Tanıtım Sayfası State'leri
    const [activeTab, setActiveTab] = useState(initialTab); // user, partner, driver
    const [contactSubmitted, setContactSubmitted] = useState(false);
    const [partnerSubmitted, setPartnerSubmitted] = useState(false);
    const [courierSubmitted, setCourierSubmitted] = useState(false);
    const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

    // Telefon Simülatörü State'leri
    const [simScreen, setSimScreen] = useState('splash'); // splash, categories, store_list, store_detail, product_detail, checkout, order_status
    const [simCart, setSimCart] = useState([
        { id: 'aycicekyagi', name: 'Ayçiçek Yağı 1L', price: 90.00, qty: 1 },
        { id: 'madensuyu', name: 'Doğal Maden Suyu 6\'lı', price: 75.00, qty: 1 }
    ]);
    const [simProduct, setSimProduct] = useState(PRODUCTS[0]);
    const [simOrderNote, setSimOrderNote] = useState('bez poşet olsun');
    const [simPaymentMethod, setSimPaymentMethod] = useState('kapida_nakit'); // kapida_nakit, online_kart, kapida_kart
    const [simDeliveryMethod, setSimDeliveryMethod] = useState('eve_teslim'); // eve_teslim, gel_al
    const [simDeliveryTime, setSimDeliveryTime] = useState('hemen'); // hemen, randevulu
    const [scooterPos, setScooterPos] = useState(0); // 0 ile 100 arası kurye konumu
    const [orderStep, setOrderStep] = useState(2); // 0: Onay Bekliyor, 1: Hazırlanıyor, 2: Yolda, 3: Teslim Edildi
    const [showToast, setShowToast] = useState(false);
    const [toastMessage, setToastMessage] = useState('');

    // Simülatör kurye animasyonu
    useEffect(() => {
        let interval: ReturnType<typeof setInterval> | undefined;
        if (simScreen === 'order_status') {
            interval = setInterval(() => {
                setScooterPos((prev) => {
                    if (prev >= 100) {
                        setOrderStep(3);
                        return 100;
                    }
                    const next = prev + 1;
                    if (next === 25) setOrderStep(1);
                    if (next === 60) setOrderStep(2);
                    return next;
                });
            }, 300);
        } else {
            setScooterPos(0);
            setOrderStep(2);
        }
        return () => clearInterval(interval);
    }, [simScreen]);

    // Toast gösterme fonksiyonu
    const triggerToast = (msg: string) => {
        setToastMessage(msg);
        setShowToast(true);
        setTimeout(() => setShowToast(false), 2000);
    };

    // Sepet hesaplama
    const cartSubtotal = simCart.reduce((sum, item) => sum + (item.price * item.qty), 0);
    const cartTotal = cartSubtotal; // Teslimat ücretsiz

    const updateCartQty = (id: string, change: number) => {
        setSimCart(prev => {
            const existing = prev.find(item => item.id === id);
            if (!existing) {
                if (change > 0) {
                    const prod = PRODUCTS.find(p => p.id === id);
                    return [...prev, { id, name: prod!.name, price: prod!.price, qty: 1 }];
                }
                return prev;
            }
            const newQty = existing.qty + change;
            if (newQty <= 0) {
                triggerToast(`${existing.name} sepetten çıkarıldı`);
                return prev.filter(item => item.id !== id);
            }
            return prev.map(item => item.id === id ? { ...item, qty: newQty } : item);
        });
    };

    const getProductQty = (id: string) => {
        const found = simCart.find(item => item.id === id);
        return found ? found.qty : 0;
    };

    return (
        <div className="min-h-screen bg-slate-50 text-slate-800 font-sans antialiased selection:bg-emerald-500 selection:text-white">

            {/* HEADER */}
            <header className="sticky top-0 z-50 bg-white/90 backdrop-blur-md border-b border-slate-100 transition-all">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="flex items-center justify-between h-20">
                        {/* Logo */}
                        <div className="flex items-center cursor-pointer" onClick={() => setSimScreen('splash')}>
                            <img src="/logo-color.png" alt="Hoppa Logo" className="h-10 w-auto object-contain" />
                            <span className="text-xs font-semibold text-emerald-600 ml-2 bg-emerald-50 px-2 py-0.5 rounded-full">
                                now.com
                            </span>
                        </div>

                        {/* Masaüstü Navigasyon */}
                        <nav className="hidden md:flex items-center space-x-8">
                            <a href="#features" className="font-medium text-slate-600 hover:text-emerald-600 transition-colors">Özellikler</a>
                            <a href="#how-it-works" className="font-medium text-slate-600 hover:text-emerald-600 transition-colors">Nasıl Çalışır?</a>
                            <a href="#interactive-demo" className="font-medium text-slate-600 hover:text-emerald-600 transition-colors bg-emerald-50 text-emerald-700 px-3 py-1 rounded-full text-sm animate-pulse">Uygulamayı Dene</a>
                            <a href="#partners" onClick={() => setActiveTab('user')} className="font-medium text-slate-600 hover:text-emerald-600 transition-colors">İş Ortaklığı</a>
                            <a href="#partners" onClick={() => setActiveTab('partner')} className="font-medium text-slate-600 hover:text-emerald-600 transition-colors">Kurye Ol</a>
                        </nav>

                        {/* App Store / CTA */}
                        <div className="hidden lg:flex items-center space-x-3">
                            <a
                                href="#interactive-demo"
                                className="bg-emerald-600 hover:bg-emerald-700 text-white px-5 py-2.5 rounded-full font-semibold transition-all duration-300 shadow-lg shadow-emerald-600/20 text-sm hover:scale-105 active:scale-95"
                            >
                                Hemen Sipariş Ver
                            </a>
                        </div>

                        {/* Mobil Menü Butonu */}
                        <div className="md:hidden">
                            <button
                                onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                                className="p-2 rounded-lg text-slate-600 hover:bg-slate-100 transition-colors focus:outline-none"
                            >
                                {mobileMenuOpen ? <X size={24} /> : <Menu size={24} />}
                            </button>
                        </div>
                    </div>
                </div>

                {/* Mobil Menü İçeriği */}
                {mobileMenuOpen && (
                    <div className="md:hidden bg-white border-t border-slate-100 py-4 px-6 space-y-3 shadow-xl">
                        <a
                            href="#features"
                            onClick={() => setMobileMenuOpen(false)}
                            className="block font-medium py-2 text-slate-700 hover:text-emerald-600 transition-colors"
                        >
                            Özellikler
                        </a>
                        <a
                            href="#how-it-works"
                            onClick={() => setMobileMenuOpen(false)}
                            className="block font-medium py-2 text-slate-700 hover:text-emerald-600 transition-colors"
                        >
                            Nasıl Çalışır?
                        </a>
                        <a
                            href="#interactive-demo"
                            onClick={() => setMobileMenuOpen(false)}
                            className="block font-medium py-2 text-emerald-600 hover:text-emerald-700 font-bold transition-colors"
                        >
                            Uygulamayı Dene (Canlı Simülatör)
                        </a>
                        <a
                            href="#partners"
                            onClick={() => {
                                setMobileMenuOpen(false);
                                setActiveTab('user');
                            }}
                            className="block font-medium py-2 text-slate-700 hover:text-emerald-600 transition-colors"
                        >
                            İş Ortaklığı
                        </a>
                        <a
                            href="#partners"
                            onClick={() => {
                                setMobileMenuOpen(false);
                                setActiveTab('partner');
                            }}
                            className="block font-medium py-2 text-slate-700 hover:text-emerald-600 transition-colors"
                        >
                            Kurye Ol
                        </a>
                        <div className="pt-2">
                            <a
                                href="#interactive-demo"
                                onClick={() => setMobileMenuOpen(false)}
                                className="block w-full text-center bg-emerald-600 text-white py-3 rounded-xl font-bold"
                            >
                                Simülatörü Başlat
                            </a>
                        </div>
                    </div>
                )}
            </header>

            {/* HERO SECTION */}
            <section className="relative overflow-hidden pt-12 pb-24 lg:pt-20 lg:pb-32 bg-gradient-to-b from-white via-emerald-50/20 to-transparent">

                {/* Dekoratif Arka Plan Işıkları */}
                <div className="absolute top-1/4 left-1/10 w-96 h-96 bg-orange-300/20 rounded-full blur-3xl -z-10"></div>
                <div className="absolute top-1/3 right-1/10 w-96 h-96 bg-emerald-300/10 rounded-full blur-3xl -z-10"></div>

                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-8 items-center">

                        {/* Sol Sütun - Marka Vaadi & Mesajı */}
                        <div className="lg:col-span-7 space-y-8 text-center lg:text-left">
                            <div className="inline-flex items-center space-x-2 bg-orange-50 border border-orange-100 text-orange-700 px-4 py-2 rounded-full text-xs sm:text-sm font-semibold tracking-wide">
                                <Sparkles size={16} className="text-orange-500 animate-spin" style={{ animationDuration: '4s' }} />
                                <span>Gazimağusa&apos;nın En Yeni, En Hızlı Pazaryeri Platformu!</span>
                            </div>

                            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight text-slate-900 leading-tight">
                                Siparişin <span className="text-transparent bg-clip-text bg-gradient-to-r from-orange-500 to-amber-600">En Kısa Yolu</span> <br className="hidden sm:inline" />
                                Saniyeler İçinde Kapında.
                            </h1>

                            <p className="text-lg text-slate-600 max-w-2xl mx-auto lg:mx-0 leading-relaxed">
                                Hoppa ile mutfaktaki eksiklerden canının çektiği sıcak yemeğe, damacana sudan taze çiçeklere kadar her şey dakikalar içinde kapında. Canlı kurye takibiyle siparişinin nerede olduğunu anlık izle.
                            </p>

                            {/* Hızlı İstatistikler */}
                            <div className="grid grid-cols-3 gap-4 py-2 max-w-md mx-auto lg:mx-0">
                                <div className="p-3 bg-white/80 backdrop-blur-sm rounded-2xl border border-slate-100 shadow-sm text-center">
                                    <div className="text-2xl font-bold text-emerald-600">25-45</div>
                                    <div className="text-xs text-slate-500">Dakikada Teslimat</div>
                                </div>
                                <div className="p-3 bg-white/80 backdrop-blur-sm rounded-2xl border border-slate-100 shadow-sm text-center">
                                    <div className="text-2xl font-bold text-orange-500">100%</div>
                                    <div className="text-xs text-slate-500">Güvenli Ödeme</div>
                                </div>
                                <div className="p-3 bg-white/80 backdrop-blur-sm rounded-2xl border border-slate-100 shadow-sm text-center">
                                    <div className="text-2xl font-bold text-slate-800">4.8★</div>
                                    <div className="text-xs text-slate-500">Kullanıcı Puanı</div>
                                </div>
                            </div>

                            {/* İndirme Butonları */}
                            <div className="flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-4">
                                <a
                                    href="#interactive-demo"
                                    className="w-full sm:w-auto bg-slate-900 hover:bg-slate-800 text-white px-8 py-4 rounded-2xl font-bold flex items-center justify-center space-x-3 shadow-xl transition-all duration-300 hover:-translate-y-1 active:translate-y-0"
                                >
                                    <Smartphone size={20} />
                                    <span>Şimdi Canlı Dene</span>
                                </a>
                                <a
                                    href="#partners"
                                    onClick={() => setActiveTab('user')}
                                    className="w-full sm:w-auto bg-white hover:bg-slate-50 text-slate-800 border border-slate-200 px-8 py-4 rounded-2xl font-bold flex items-center justify-center space-x-2 transition-all duration-300 hover:border-slate-300"
                                >
                                    <Store size={20} className="text-emerald-600" />
                                    <span>İşletme Girişi</span>
                                </a>
                            </div>

                            {/* Güvenceler */}
                            <div className="flex flex-wrap justify-center lg:justify-start items-center gap-6 pt-4 text-xs font-semibold text-slate-500">
                                <span className="flex items-center space-x-1.5">
                                    <ShieldCheck size={16} className="text-emerald-600" />
                                    <span>Kredi Kartı veya Kapıda Ödeme</span>
                                </span>
                                <span className="flex items-center space-x-1.5">
                                    <Clock size={16} className="text-emerald-600" />
                                    <span>7/24 Kesintisiz Destek</span>
                                </span>
                            </div>
                        </div>

                        {/* Sağ Sütun - Büyük Görsel / Hızlı Simülatör Tanıtımı */}
                        <div className="lg:col-span-5 relative flex justify-center">
                            {/* Arkadaki Grafik Ögeleri */}
                            <div className="absolute inset-0 bg-gradient-to-tr from-emerald-100 to-orange-100 rounded-3xl -rotate-6 scale-95 opacity-50 -z-20"></div>
                            <div className="absolute inset-0 bg-emerald-600/5 rounded-3xl rotate-3 scale-100 -z-10"></div>

                            {/* Tanıtım Kartı */}
                            <div className="bg-white/90 backdrop-blur-md p-6 rounded-3xl shadow-2xl border border-slate-100 max-w-sm w-full relative">
                                <div className="flex items-center justify-between mb-4 pb-4 border-b border-slate-100">
                                    <div className="flex items-center space-x-3">
                                        <div className="bg-emerald-100 text-emerald-800 p-2.5 rounded-xl">
                                            <Truck size={20} />
                                        </div>
                                        <div>
                                            <h4 className="font-bold text-slate-800 leading-none">Aktif Sipariş Takibi</h4>
                                            <span className="text-xs text-slate-500">Şehir Süpermarket</span>
                                        </div>
                                    </div>
                                    <span className="bg-orange-50 text-orange-700 px-2.5 py-1 rounded-full text-xs font-bold animate-pulse">Yolda</span>
                                </div>

                                {/* Kurye Bilgisi */}
                                <div className="space-y-4">
                                    <div className="bg-slate-50 p-3.5 rounded-2xl flex items-center justify-between">
                                        <div className="flex items-center space-x-3">
                                            <div className="w-10 h-10 rounded-full bg-slate-200 flex items-center justify-center text-xl">
                                                🛵
                                            </div>
                                            <div>
                                                <div className="text-xs text-slate-400">Kuryeniz</div>
                                                <div className="text-sm font-bold text-slate-800">Ahmet Y.</div>
                                            </div>
                                        </div>
                                        <span className="text-emerald-600 text-xs font-bold bg-emerald-50 px-2 py-1 rounded-lg">5 Dk Sonra</span>
                                    </div>

                                    {/* Küçük Yol */}
                                    <div className="relative pt-4 pb-2">
                                        <div className="h-1 w-full bg-slate-200 rounded-full"></div>
                                        <div className="absolute top-3.5 left-0 h-1 bg-emerald-500 rounded-full" style={{ width: '70%' }}></div>
                                        <div className="absolute top-1 right-1/4 text-xl transform -translate-x-1/2 animate-bounce">🛵</div>
                                        <div className="flex justify-between text-[10px] text-slate-400 font-semibold pt-1">
                                            <span>Marketten Alındı</span>
                                            <span>Kapınızda</span>
                                        </div>
                                    </div>

                                    <a
                                        href="#interactive-demo"
                                        className="block w-full text-center bg-emerald-600 hover:bg-emerald-700 text-white font-bold py-3.5 rounded-2xl text-sm shadow-md transition-all hover:shadow-lg"
                                    >
                                        Canlı Deneyimi Başlat
                                    </a>
                                </div>
                            </div>
                        </div>

                    </div>
                </div>
            </section>

            {/* BENZERSİZ DEĞER ÖNERİSİ / ÖZELLİKLER */}
            <section id="features" className="py-24 bg-white border-y border-slate-100">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

                    <div className="text-center max-w-3xl mx-auto space-y-4 mb-16">
                        <h2 className="text-xs uppercase font-extrabold tracking-widest text-emerald-600">Neden Hoppa?</h2>
                        <p className="text-3xl sm:text-4xl font-extrabold text-slate-900 tracking-tight">
                            Alışveriş Alışkanlıklarınızı Baştan Yazıyoruz
                        </p>
                        <p className="text-slate-500">
                            Uygulamamızı geliştirmek için en ince ayrıntıları düşündük. İşte her siparişte hissedeceğiniz fark:
                        </p>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-3 gap-8">

                        {/* Kart 1 */}
                        <div className="p-8 rounded-3xl bg-slate-50 border border-slate-100/50 hover:bg-white hover:shadow-2xl hover:shadow-slate-200/50 transition-all duration-300 group">
                            <div className="w-14 h-14 rounded-2xl bg-orange-100 text-orange-600 flex items-center justify-center text-2xl font-bold mb-6 transition-transform group-hover:scale-110">
                                ⚡
                            </div>
                            <h3 className="text-xl font-bold text-slate-900 mb-3">Siparişin En Kısa Yolu</h3>
                            <p className="text-slate-600 leading-relaxed">
                                Gazimağusa genelinde kurduğumuz akıllı dağıtım ağı sayesinde siparişleriniz hiçbir gecikmeye uğramadan, doğrudan en yakın noktadan yola çıkar.
                            </p>
                        </div>

                        {/* Kart 2 */}
                        <div className="p-8 rounded-3xl bg-slate-50 border border-slate-100/50 hover:bg-white hover:shadow-2xl hover:shadow-slate-200/50 transition-all duration-300 group">
                            <div className="w-14 h-14 rounded-2xl bg-emerald-100 text-emerald-600 flex items-center justify-center text-2xl font-bold mb-6 transition-transform group-hover:scale-110">
                                📍
                            </div>
                            <h3 className="text-xl font-bold text-slate-900 mb-3">Canlı Kurye Takibi</h3>
                            <p className="text-slate-600 leading-relaxed">
                                "Kurye nerede kaldı?" endişesine son. Siparişinizin onaylandığı andan kapınıza ulaştığı ana kadar her hareketi haritada canlı ve şeffafça izleyin.
                            </p>
                        </div>

                        {/* Kart 3 */}
                        <div className="p-8 rounded-3xl bg-slate-50 border border-slate-100/50 hover:bg-white hover:shadow-2xl hover:shadow-slate-200/50 transition-all duration-300 group">
                            <div className="w-14 h-14 rounded-2xl bg-blue-100 text-blue-600 flex items-center justify-center text-2xl font-bold mb-6 transition-transform group-hover:scale-110">
                                🛍️
                            </div>
                            <h3 className="text-xl font-bold text-slate-900 mb-3">Yüzlerce Çeşit, Tek Sepet</h3>
                            <p className="text-slate-600 leading-relaxed">
                                Market ihtiyaçlarınız, taze fırın ekmeği, damacana su veya akşam yemeği menüsü. Farklı kategorilerdeki her şeyi tek tıkla sepetinize ekleyin.
                            </p>
                        </div>

                    </div>
                </div>
            </section>

            {/* NASIL ÇALIŞIR? */}
            <section id="how-it-works" className="py-24 bg-slate-50">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

                    <div className="text-center max-w-2xl mx-auto space-y-4 mb-20">
                        <h2 className="text-xs uppercase font-extrabold tracking-widest text-orange-600">Basit ve Etkili</h2>
                        <p className="text-3xl sm:text-4xl font-extrabold text-slate-900">3 Adımda Kolay Sipariş</p>
                        <p className="text-slate-500">Hoppa ile ihtiyacınıza ulaşmak işte bu kadar kolay ve zahmetsiz.</p>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-3 gap-12 relative">
                        {/* Bağlantı Çizgisi */}
                        <div className="hidden md:block absolute top-1/5 left-[15%] right-[15%] h-0.5 bg-gradient-to-r from-orange-300 to-emerald-300 -z-10"></div>

                        {/* Adım 1 */}
                        <div className="text-center space-y-4 bg-white p-8 rounded-3xl shadow-sm border border-slate-100 relative">
                            <div className="absolute -top-6 left-1/2 transform -translate-x-1/2 w-12 h-12 bg-orange-500 text-white font-black rounded-2xl flex items-center justify-center text-lg shadow-lg shadow-orange-500/20">
                                1
                            </div>
                            <div className="text-4xl pt-2">📱</div>
                            <h4 className="font-extrabold text-lg text-slate-900">Kategorini Seç</h4>
                            <p className="text-sm text-slate-500">
                                Market, restoran, su, çiçek veya kuruyemiş kategorilerinden dilediğini seçip ürünleri incele.
                            </p>
                        </div>

                        {/* Adım 2 */}
                        <div className="text-center space-y-4 bg-white p-8 rounded-3xl shadow-sm border border-slate-100 relative">
                            <div className="absolute -top-6 left-1/2 transform -translate-x-1/2 w-12 h-12 bg-emerald-600 text-white font-black rounded-2xl flex items-center justify-center text-lg shadow-lg shadow-emerald-600/20">
                                2
                            </div>
                            <div className="text-4xl pt-2">🛒</div>
                            <h4 className="font-extrabold text-lg text-slate-900">Sepetini Doldur</h4>
                            <p className="text-sm text-slate-500">
                                Güvenli ödeme altyapımızla ister kredi kartıyla online, ister kapıda nakit veya kartla siparişini tamamla.
                            </p>
                        </div>

                        {/* Adım 3 */}
                        <div className="text-center space-y-4 bg-white p-8 rounded-3xl shadow-sm border border-slate-100 relative">
                            <div className="absolute -top-6 left-1/2 transform -translate-x-1/2 w-12 h-12 bg-slate-900 text-white font-black rounded-2xl flex items-center justify-center text-lg shadow-lg shadow-slate-900/20">
                                3
                            </div>
                            <div className="text-4xl pt-2">🛵</div>
                            <h4 className="font-extrabold text-lg text-slate-900">Canlı Takip Et</h4>
                            <p className="text-sm text-slate-500">
                                Kuryenin çıkış anından kapına gelene kadarki yolculuğunu harita üzerinden heyecanla takip et.
                            </p>
                        </div>

                    </div>
                </div>
            </section>

            {/* INTERAKTIF SIMÜLATÖR BÖLÜMÜ (CANLI UYGULAMA DENEYİMİ) */}
            <section id="interactive-demo" className="py-24 bg-gradient-to-br from-slate-900 to-slate-950 text-white relative overflow-hidden">

                {/* Dekoratif Işıklar */}
                <div className="absolute -top-24 -left-24 w-96 h-96 bg-emerald-600/20 rounded-full blur-3xl"></div>
                <div className="absolute -bottom-24 -right-24 w-96 h-96 bg-orange-600/10 rounded-full blur-3xl"></div>

                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">

                    <div className="grid grid-cols-1 lg:grid-cols-12 gap-16 items-center">

                        {/* Sol Taraf: Açıklama ve Yönlendirme */}
                        <div className="lg:col-span-6 space-y-8 text-center lg:text-left">
                            <div className="inline-flex items-center space-x-2 bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 px-4 py-1.5 rounded-full text-sm font-bold">
                                <span>CANLI INTERAKTİF DEMO</span>
                            </div>

                            <h2 className="text-4xl sm:text-5xl font-black tracking-tight leading-tight">
                                Hoppa Uygulamasını <br />
                                <span className="text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 to-amber-300">Şimdi Test Edin!</span>
                            </h2>

                            <p className="text-slate-300 text-lg leading-relaxed">
                                Sağdaki telefon simülatörünü kullanarak sipariş akışımızı birebir deneyimleyebilirsiniz. Kategorileri gezin, sepete ekleme yapın ve siparişi tamamlayarak "Kurye Canlı Takip" ekranının nasıl çalıştığını izleyin!
                            </p>

                            {/* Simülatör Kontrolleri */}
                            <div className="space-y-4 pt-4 hidden sm:block">
                                <h4 className="font-bold text-slate-200">Hızlı Ekran Geçişleri</h4>
                                <div className="flex flex-wrap gap-2 justify-center lg:justify-start">
                                    <button
                                        onClick={() => setSimScreen('splash')}
                                        className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${simScreen === 'splash' ? 'bg-orange-500 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'}`}
                                    >
                                        1. Başlangıç (Splash)
                                    </button>
                                    <button
                                        onClick={() => setSimScreen('categories')}
                                        className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${simScreen === 'categories' ? 'bg-orange-500 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'}`}
                                    >
                                        2. Kategoriler
                                    </button>
                                    <button
                                        onClick={() => setSimScreen('store_detail')}
                                        className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${simScreen === 'store_detail' ? 'bg-orange-500 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'}`}
                                    >
                                        3. Mağaza & Ürünler
                                    </button>
                                    <button
                                        onClick={() => setSimScreen('checkout')}
                                        className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${simScreen === 'checkout' ? 'bg-orange-500 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'}`}
                                    >
                                        4. Ödeme / Onay
                                    </button>
                                    <button
                                        onClick={() => setSimScreen('order_status')}
                                        className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${simScreen === 'order_status' ? 'bg-orange-500 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'}`}
                                    >
                                        5. Canlı Takip 🛵
                                    </button>
                                </div>
                            </div>

                            {/* Kullanıcı Geribildirimi / Pop-up */}
                            <div className="bg-slate-800/80 border border-slate-700/50 p-5 rounded-2xl flex items-start space-x-4 max-w-md mx-auto lg:mx-0">
                                <div className="text-3xl">💡</div>
                                <div className="text-left space-y-1">
                                    <h5 className="font-bold text-sm text-slate-100">İpucu</h5>
                                    <p className="text-xs text-slate-400">
                                        Ödeme ekranında kapıda nakit veya kart seçeneklerini değiştirebilir, kurye takip ekranında canlı simülasyonu izleyebilirsiniz.
                                    </p>
                                </div>
                            </div>
                        </div>

                        {/* SAĞ TARAF: TELEFON SİMÜLATÖRÜ */}
                        <div className="lg:col-span-6 flex justify-center relative">

                            {/* Telefon Kasası (Bezel) */}
                            <div className="w-[370px] h-[760px] bg-slate-900 rounded-[50px] p-3.5 border-[6px] border-slate-800 shadow-[0_0_50px_rgba(16,185,129,0.15)] relative flex flex-col overflow-hidden text-slate-800 select-none">

                                {/* Kamera Çentiği (Dynamic Island taklidi) */}
                                <div className="absolute top-4 left-1/2 transform -translate-x-1/2 w-28 h-6 bg-slate-900 rounded-full z-50 flex items-center justify-between px-4">
                                    <div className="w-2.5 h-2.5 bg-slate-800 rounded-full"></div>
                                    <div className="w-12 h-1 bg-slate-800 rounded-full"></div>
                                </div>

                                {/* SİMÜLATÖR EKRAN ALANI */}
                                <div className="w-full h-full bg-slate-50 rounded-[38px] overflow-hidden flex flex-col relative pt-7 font-sans">

                                    {/* Ekran İçi Bildirim (Toast) */}
                                    {showToast && (
                                        <div className="absolute top-12 left-4 right-4 bg-slate-900/95 backdrop-blur text-white text-xs py-2.5 px-4 rounded-xl z-50 shadow-lg text-center font-semibold animate-bounce">
                                            {toastMessage}
                                        </div>
                                    )}

                                    {/* 1. SPLASH EKRANI */}
                                    {simScreen === 'splash' && (
                                        <div className="absolute inset-0 bg-white flex flex-col items-center justify-between p-8 z-20">
                                            <div></div>
                                            <div className="text-center space-y-4">
                                                {/* Logo */}
                                                <div className="flex items-center justify-center">
                                                    <img src="/logo-square-orange.png" alt="Hoppa Logo" className="w-24 h-24 object-contain rounded-3xl shadow-md" />
                                                </div>
                                                <p className="text-orange-500 font-bold text-xs tracking-wider">
                                                    Siparişin en kısa yolu.
                                                </p>
                                            </div>

                                            <div className="w-full space-y-4 mb-4">
                                                {/* Yükleniyor Barı */}
                                                <div className="space-y-1.5 text-center">
                                                    <div className="w-3/4 bg-slate-100 h-1.5 rounded-full mx-auto overflow-hidden relative">
                                                        <div className="absolute top-0 bottom-0 left-0 bg-emerald-600 w-2/3 rounded-full animate-pulse"></div>
                                                    </div>
                                                    <span className="text-[10px] text-slate-400 block">Yükleniyor...</span>
                                                </div>

                                                <button
                                                    onClick={() => setSimScreen('categories')}
                                                    className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-bold py-3 rounded-xl text-sm transition-all shadow-md shadow-emerald-600/10"
                                                >
                                                    Hızlı Giriş Yap
                                                </button>
                                            </div>
                                        </div>
                                    )}

                                    {/* SİMÜLATÖR HEADER (Splash dışındaki ekranlar için ortak) */}
                                    {simScreen !== 'splash' && (
                                        <div className="bg-white border-b border-slate-100 px-4 py-2.5 flex items-center justify-between sticky top-0 z-10 shadow-sm">
                                            <div className="flex items-center space-x-2">
                                                {simScreen !== 'categories' ? (
                                                    <button
                                                        onClick={() => {
                                                            if (simScreen === 'store_detail') setSimScreen('categories');
                                                            if (simScreen === 'product_detail') setSimScreen('store_detail');
                                                            if (simScreen === 'delivery_info') setSimScreen('store_detail');
                                                            if (simScreen === 'checkout') setSimScreen('delivery_info');
                                                            if (simScreen === 'order_status') setSimScreen('categories');
                                                        }}
                                                        className="p-1 rounded-full hover:bg-slate-100 text-slate-700"
                                                    >
                                                        <ArrowLeft size={18} />
                                                    </button>
                                                ) : (
                                                    <div className="w-6 h-6 rounded-full bg-orange-100 flex items-center justify-center text-xs">🍊</div>
                                                )}
                                                <span className="text-xs font-bold text-slate-800">
                                                    {simScreen === 'categories' && 'Merhaba, Test User'}
                                                    {simScreen === 'store_detail' && 'Şehir Süpermarket'}
                                                    {simScreen === 'product_detail' && 'Ürün Detayı'}
                                                    {simScreen === 'delivery_info' && 'Teslimat Bilgileri'}
                                                    {simScreen === 'checkout' && 'Ödeme ve Onay'}
                                                    {simScreen === 'order_status' && 'Sipariş Detayı'}
                                                </span>
                                            </div>

                                            {/* Sağ İkon (Sepet durumu veya Profil) */}
                                            <div className="flex items-center space-x-2">
                                                {simScreen !== 'order_status' && simScreen !== 'checkout' && simScreen !== 'delivery_info' && (
                                                    <button
                                                        onClick={() => {
                                                            if (simCart.length > 0) setSimScreen('delivery_info');
                                                            else triggerToast('Önce sepetinize ürün ekleyin!');
                                                        }}
                                                        className="relative p-1.5 rounded-full hover:bg-slate-100 text-slate-700"
                                                    >
                                                        <ShoppingBag size={16} />
                                                        {simCart.length > 0 && (
                                                            <span className="absolute -top-1 -right-1 bg-orange-500 text-white text-[9px] w-4 h-4 rounded-full flex items-center justify-center font-bold">
                                                                {simCart.reduce((sum, item) => sum + item.qty, 0)}
                                                            </span>
                                                        )}
                                                    </button>
                                                )}
                                                <div className="w-6 h-6 rounded-full bg-slate-100 flex items-center justify-center">
                                                    <User size={12} className="text-slate-600" />
                                                </div>
                                            </div>
                                        </div>
                                    )}

                                    {/* 2. KATEGORİLER EKRANI */}
                                    {simScreen === 'categories' && (
                                        <div className="flex-1 overflow-y-auto p-4 space-y-4">
                                            {/* Üst Karşılama ve Konum */}
                                            <div className="flex items-center justify-between bg-white p-3 rounded-2xl border border-slate-100 shadow-sm">
                                                <div className="flex items-center space-x-2">
                                                    <span className="text-emerald-600">📍</span>
                                                    <div className="text-left">
                                                        <div className="text-[10px] text-slate-400 font-semibold leading-none">Teslimat Adresi</div>
                                                        <span className="text-xs font-bold text-slate-700">Ev - Yeni Boğaziçi</span>
                                                    </div>
                                                </div>
                                                <span className="text-xs text-slate-400">▼</span>
                                            </div>

                                            {/* Başlık */}
                                            <div className="text-left">
                                                <h4 className="text-sm font-bold text-slate-800">İşletme Kategorisi</h4>
                                            </div>

                                            {/* Kategoriler Grid */}
                                            <div className="grid grid-cols-2 gap-3">
                                                {CATEGORIES.map((cat) => (
                                                    <div
                                                        key={cat.id}
                                                        onClick={() => cat.id === 'market' || cat.id === 'su' ? setSimScreen('store_detail') : triggerToast(`${cat.title} kategorisi şu an simülatörde kapalıdır.`)}
                                                        className="bg-white p-3 rounded-2xl border border-slate-100 shadow-sm flex flex-col justify-between items-start h-28 cursor-pointer relative hover:border-emerald-500/50 hover:shadow-md transition-all group"
                                                    >
                                                        {cat.badge && (
                                                            <span className="absolute top-2 right-2 bg-orange-500 text-white text-[8px] px-1.5 py-0.5 rounded-full font-black">
                                                                {cat.badge}
                                                            </span>
                                                        )}
                                                        <div className="text-2xl">{cat.icon}</div>
                                                        <div className="text-left">
                                                            <div className="text-xs font-bold text-slate-800">{cat.title}</div>
                                                            <div className="text-[8px] text-slate-400 line-clamp-1">{cat.desc}</div>
                                                        </div>
                                                    </div>
                                                ))}
                                            </div>

                                            {/* Alt Bilgi Banner */}
                                            <div className="bg-gradient-to-r from-orange-500 to-amber-500 p-3 rounded-2xl text-white text-left space-y-1">
                                                <div className="text-xs font-bold">%20 İlk Sipariş İndirimi!</div>
                                                <p className="text-[9px] text-orange-50/80">Yeni üyelere özel tüm marketlerde geçerli indirim kodu: HOPPA20</p>
                                            </div>
                                        </div>
                                    )}

                                    {/* 3. MAĞAZA DETAY / ÜRÜNLER LİSTESİ */}
                                    {simScreen === 'store_detail' && (
                                        <div className="flex-1 overflow-y-auto flex flex-col">

                                            {/* Üst Mağaza Bannerı */}
                                            <div className="relative h-28 bg-slate-300">
                                                <img
                                                    src="https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3"
                                                    alt="Şehir Süpermarket"
                                                    className="w-full h-full object-cover"
                                                />
                                                <div className="absolute inset-0 bg-black/35"></div>

                                                {/* Geri Butonu */}
                                                <div className="absolute top-2 left-2 flex items-center space-x-1.5 bg-white/95 backdrop-blur px-2 py-1 rounded-xl text-xs font-bold shadow-sm">
                                                    <span className="text-emerald-600">★</span>
                                                    <span>4.8</span>
                                                </div>
                                            </div>

                                            {/* Mağaza Bilgileri */}
                                            <div className="p-4 bg-white border-b border-slate-100 text-left space-y-2">
                                                <div className="flex items-center justify-between">
                                                    <h4 className="text-sm font-extrabold text-slate-800">Şehir Süpermarket</h4>
                                                    <span className="text-[10px] text-emerald-600 font-bold bg-emerald-50 px-2 py-0.5 rounded">Açık</span>
                                                </div>
                                                <p className="text-[10px] text-slate-400">Market • Dörtyol, Yeni Boğaziçi, Gazimağusa</p>

                                                {/* Hızlı Detaylar */}
                                                <div className="grid grid-cols-3 gap-1 pt-1 border-t border-slate-50 text-center">
                                                    <div className="py-1">
                                                        <span className="text-[9px] text-slate-400 block">Min. Tutar</span>
                                                        <span className="text-xs font-bold text-slate-700">100 ₺</span>
                                                    </div>
                                                    <div className="py-1 border-x border-slate-100">
                                                        <span className="text-[9px] text-slate-400 block">Süre</span>
                                                        <span className="text-xs font-bold text-slate-700">30-45 dk</span>
                                                    </div>
                                                    <div className="py-1">
                                                        <span className="text-[9px] text-slate-400 block">Mesafe</span>
                                                        <span className="text-xs font-bold text-slate-700">0.0 km</span>
                                                    </div>
                                                </div>
                                            </div>

                                            {/* Kategori Filtreleri */}
                                            <div className="px-4 py-2 flex space-x-1.5 overflow-x-auto bg-white border-b border-slate-50">
                                                <span className="bg-emerald-600 text-white text-[10px] px-3 py-1 rounded-full font-bold whitespace-nowrap">Tümü</span>
                                                <span className="bg-slate-100 text-slate-600 text-[10px] px-3 py-1 rounded-full font-medium whitespace-nowrap">Temel Gıda</span>
                                                <span className="bg-slate-100 text-slate-600 text-[10px] px-3 py-1 rounded-full font-medium whitespace-nowrap">Meyve & Sebze</span>
                                                <span className="bg-slate-100 text-slate-600 text-[10px] px-3 py-1 rounded-full font-medium whitespace-nowrap">Atıştırmalık</span>
                                            </div>

                                            {/* Ürünler Grid */}
                                            <div className="p-3 grid grid-cols-2 gap-3">
                                                {PRODUCTS.map((prod) => {
                                                    const inCartQty = getProductQty(prod.id);
                                                    return (
                                                        <div
                                                            key={prod.id}
                                                            className="bg-white rounded-2xl border border-slate-100 p-2 shadow-sm flex flex-col justify-between cursor-pointer group"
                                                        >
                                                            <div onClick={() => { setSimProduct(prod); setSimScreen('product_detail'); }} className="relative h-24 bg-slate-100 rounded-xl overflow-hidden mb-2">
                                                                <img src={prod.image} alt={prod.name} className="w-full h-full object-cover group-hover:scale-105 transition-transform" />
                                                            </div>
                                                            <div onClick={() => { setSimProduct(prod); setSimScreen('product_detail'); }} className="text-left mb-2">
                                                                <div className="text-[9px] font-semibold text-slate-400">{prod.brand}</div>
                                                                <h5 className="text-[11px] font-bold text-slate-800 line-clamp-1">{prod.name}</h5>
                                                                <div className="text-xs font-extrabold text-emerald-600 mt-1">{prod.price.toFixed(2)} ₺</div>
                                                            </div>

                                                            {/* Ekleme/Çıkarma Butonları */}
                                                            <div className="mt-auto">
                                                                {inCartQty > 0 ? (
                                                                    <div className="flex items-center justify-between bg-emerald-50 text-emerald-800 rounded-xl p-1 text-xs font-bold">
                                                                        <button
                                                                            onClick={() => updateCartQty(prod.id, -1)}
                                                                            className="w-6 h-6 rounded-lg bg-white flex items-center justify-center text-slate-700 shadow-sm active:scale-90"
                                                                        >
                                                                            -
                                                                        </button>
                                                                        <span>{inCartQty}</span>
                                                                        <button
                                                                            onClick={() => updateCartQty(prod.id, 1)}
                                                                            className="w-6 h-6 rounded-lg bg-emerald-600 text-white flex items-center justify-center shadow-sm active:scale-90"
                                                                        >
                                                                            +
                                                                        </button>
                                                                    </div>
                                                                ) : (
                                                                    <button
                                                                        onClick={() => {
                                                                            updateCartQty(prod.id, 1);
                                                                            triggerToast(`${prod.name} sepete eklendi`);
                                                                        }}
                                                                        className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-bold py-1.5 rounded-xl text-[10px] transition-all flex items-center justify-center space-x-1"
                                                                    >
                                                                        <span>Sepete Ekle</span>
                                                                    </button>
                                                                )}
                                                            </div>
                                                        </div>
                                                    );
                                                })}
                                            </div>

                                            {/* Sepete Git Sabit Barı */}
                                            {simCart.length > 0 && (
                                                <div className="p-3 bg-white border-t border-slate-100 mt-auto sticky bottom-0 flex items-center justify-between shadow-lg">
                                                    <div className="text-left">
                                                        <span className="text-[9px] text-slate-400 block font-semibold">Toplam</span>
                                                        <span className="text-sm font-extrabold text-emerald-600">{cartTotal.toFixed(2)} ₺</span>
                                                    </div>
                                                    <button
                                                        onClick={() => setSimScreen('delivery_info')}
                                                        className="bg-orange-500 hover:bg-orange-600 text-white font-bold px-6 py-2 rounded-xl text-xs flex items-center space-x-1.5 shadow-md shadow-orange-500/10 transition-all active:scale-95"
                                                    >
                                                        <span>Siparişi Tamamla</span>
                                                        <span>➔</span>
                                                    </button>
                                                </div>
                                            )}

                                        </div>
                                    )}

                                    {/* 4. ÜRÜN DETAY EKRANI */}
                                    {simScreen === 'product_detail' && (
                                        <div className="flex-1 overflow-y-auto flex flex-col p-4 space-y-4">

                                            {/* Ürün Görseli */}
                                            <div className="relative h-48 bg-white rounded-2xl border border-slate-100 overflow-hidden flex items-center justify-center">
                                                <img src={simProduct.image} alt={simProduct.name} className="w-full h-full object-cover" />
                                                <button
                                                    onClick={() => setSimScreen('store_detail')}
                                                    className="absolute top-2 left-2 w-8 h-8 rounded-full bg-white/90 backdrop-blur shadow-sm flex items-center justify-center text-slate-800"
                                                >
                                                    ‹
                                                </button>
                                            </div>

                                            {/* Ürün Künyesi */}
                                            <div className="text-left space-y-2">
                                                <span className="bg-slate-100 text-slate-600 text-[9px] px-2 py-0.5 rounded-full font-bold">
                                                    {simProduct.brand}
                                                </span>
                                                <h4 className="text-sm font-extrabold text-slate-800">{simProduct.name}</h4>
                                                <div className="text-lg font-black text-emerald-600">{simProduct.price.toFixed(2)} ₺ <span className="text-[10px] text-slate-400 font-normal">/ adet</span></div>
                                            </div>

                                            {/* Ürün Açıklaması */}
                                            <div className="text-left space-y-1.5 border-t border-slate-100 pt-3">
                                                <h5 className="text-xs font-bold text-slate-700">Ürün Açıklaması</h5>
                                                <p className="text-[10px] text-slate-500 leading-relaxed">{simProduct.desc}</p>
                                            </div>

                                            {/* Alt Sepet Kontrolü */}
                                            <div className="mt-auto border-t border-slate-100 pt-4 flex items-center justify-between">
                                                <div className="flex items-center space-x-3 bg-slate-100 rounded-xl p-1">
                                                    <button
                                                        onClick={() => updateCartQty(simProduct.id, -1)}
                                                        className="w-8 h-8 rounded-lg bg-white flex items-center justify-center text-slate-700 font-bold active:scale-90 shadow-sm"
                                                    >
                                                        -
                                                    </button>
                                                    <span className="text-xs font-bold px-1">{getProductQty(simProduct.id)}</span>
                                                    <button
                                                        onClick={() => updateCartQty(simProduct.id, 1)}
                                                        className="w-8 h-8 rounded-lg bg-white flex items-center justify-center text-slate-700 font-bold active:scale-90 shadow-sm"
                                                    >
                                                        +
                                                    </button>
                                                </div>

                                                <button
                                                    onClick={() => {
                                                        if (getProductQty(simProduct.id) === 0) updateCartQty(simProduct.id, 1);
                                                        setSimScreen('store_detail');
                                                        triggerToast('Sepetiniz güncellendi!');
                                                    }}
                                                    className="bg-emerald-600 hover:bg-emerald-700 text-white font-bold px-6 py-3 rounded-xl text-xs transition-all flex items-center space-x-2"
                                                >
                                                    <ShoppingBag size={14} />
                                                    <span>Sepete Ekle</span>
                                                </button>
                                            </div>

                                        </div>
                                    )}

                                    {/* 4.5 TESLİMAT BİLGİLERİ EKRANI */}
                                    {simScreen === 'delivery_info' && (
                                        <div className="flex-1 overflow-y-auto flex flex-col p-4 space-y-4">
                                            {/* Teslimat Yöntemi */}
                                            <div className="space-y-2 text-left">
                                                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider flex items-center space-x-1">
                                                    <span>🚚</span>
                                                    <span>Teslimat Yöntemi</span>
                                                </span>
                                                <div className="bg-slate-100 p-1 rounded-xl grid grid-cols-2 gap-1">
                                                    <button
                                                        onClick={() => setSimDeliveryMethod('eve_teslim')}
                                                        className={`py-2 rounded-lg text-xs font-bold transition-all ${simDeliveryMethod === 'eve_teslim' ? 'bg-white text-emerald-600 shadow-sm' : 'text-slate-500'}`}
                                                    >
                                                        Eve Teslim
                                                    </button>
                                                    <button
                                                        onClick={() => setSimDeliveryMethod('gel_al')}
                                                        className={`py-2 rounded-lg text-xs font-bold transition-all ${simDeliveryMethod === 'gel_al' ? 'bg-white text-emerald-600 shadow-sm' : 'text-slate-500'}`}
                                                    >
                                                        Gel Al
                                                    </button>
                                                </div>
                                            </div>

                                            {/* Teslimat Adresi */}
                                            <div className="space-y-2 text-left">
                                                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider flex items-center space-x-1">
                                                    <span>📍</span>
                                                    <span>{simDeliveryMethod === 'eve_teslim' ? 'Teslimat Adresi' : 'Mağaza Adresi'}</span>
                                                </span>
                                                <div className="bg-white p-3 rounded-2xl border border-slate-100 shadow-sm flex items-start space-x-3">
                                                    <div className="bg-emerald-50 text-emerald-600 p-2 rounded-xl flex-shrink-0">
                                                        {simDeliveryMethod === 'eve_teslim' ? '🏠' : '🏬'}
                                                    </div>
                                                    <div className="space-y-0.5">
                                                        <div className="text-xs font-bold text-slate-800">
                                                            {simDeliveryMethod === 'eve_teslim' ? 'Ev' : 'Şehir Süpermarket'}
                                                        </div>
                                                        <p className="text-[10px] text-slate-500 leading-tight">
                                                            {simDeliveryMethod === 'eve_teslim' ? 'Yeni Boğaziçi, Gazimağusa' : 'Dörtyol, Yeni Boğaziçi, Gazimağusa'}
                                                        </p>
                                                    </div>
                                                </div>
                                                <span className="text-[9px] text-slate-400 block leading-tight">
                                                    {simDeliveryMethod === 'eve_teslim' ? 'Teslimat adresini değiştirmek için lütfen ana sayfaya dönünüz.' : 'Lütfen siparişinizi almak için mağaza adresine gidiniz.'}
                                                </span>
                                            </div>

                                            {/* İletişim */}
                                            <div className="space-y-2 text-left">
                                                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider flex items-center space-x-1">
                                                    <span>📞</span>
                                                    <span>İletişim</span>
                                                </span>
                                                <div className="bg-white p-3 rounded-2xl border border-slate-100 shadow-sm flex items-center justify-between">
                                                    <div className="flex items-center space-x-3">
                                                        <div className="bg-emerald-50 text-emerald-600 p-2 rounded-xl">
                                                            📞
                                                        </div>
                                                        <div>
                                                            <div className="text-[10px] text-slate-400 font-semibold leading-none">İrtibat Numarası</div>
                                                            <span className="text-xs font-bold text-slate-800">
                                                                {simDeliveryMethod === 'eve_teslim' ? '0533 876 54 32' : '0533 123 45 67'}
                                                            </span>
                                                        </div>
                                                    </div>
                                                    <span className="text-slate-400">🔒</span>
                                                </div>
                                            </div>

                                            {/* Teslimat Zamanı */}
                                            <div className="space-y-2 text-left">
                                                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider flex items-center space-x-1">
                                                    <span>🕒</span>
                                                    <span>{simDeliveryMethod === 'eve_teslim' ? 'Teslimat Zamanı' : 'Hazırlanma Zamanı'}</span>
                                                </span>
                                                <div className="bg-slate-100 p-1 rounded-xl grid grid-cols-2 gap-1">
                                                    <button
                                                        onClick={() => setSimDeliveryTime('hemen')}
                                                        className={`py-2 rounded-lg text-xs font-bold transition-all ${simDeliveryTime === 'hemen' ? 'bg-white text-emerald-600 shadow-sm' : 'text-slate-500'}`}
                                                    >
                                                        Hemen
                                                    </button>
                                                    <button
                                                        onClick={() => setSimDeliveryTime('randevulu')}
                                                        className={`py-2 rounded-lg text-xs font-bold transition-all ${simDeliveryTime === 'randevulu' ? 'bg-white text-emerald-600 shadow-sm' : 'text-slate-500'}`}
                                                    >
                                                        Randevulu
                                                    </button>
                                                </div>
                                            </div>

                                            {/* Tahmini Süre Banner */}
                                            <div className="bg-emerald-50 border border-emerald-100 p-3.5 rounded-2xl flex items-center space-x-3 text-left">
                                                <span className="text-xl animate-bounce">🚀</span>
                                                <div>
                                                    <div className="text-[10px] text-emerald-800 font-semibold leading-none">
                                                        {simDeliveryMethod === 'eve_teslim' ? 'Tahmini Teslimat Süresi' : 'Tahmini Hazırlanma Süresi'}
                                                    </div>
                                                    <span className="text-xs font-bold text-emerald-700">
                                                        {simDeliveryMethod === 'eve_teslim' ? '25 - 45 Dakika' : '15 - 20 Dakika'}
                                                    </span>
                                                </div>
                                             </div>

                                             {/* Ödemeye Geç Butonu */}
                                             <button
                                                 onClick={() => setSimScreen('checkout')}
                                                 className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-black py-4 rounded-2xl text-xs tracking-wider uppercase shadow-lg shadow-emerald-600/10 transition-all active:scale-95 mt-auto"
                                             >
                                                 Ödemeye Geç
                                             </button>
                                         </div>
                                     )}

                                    {/* 5. ÖDEME VE ONAY EKRANI */}
                                    {simScreen === 'checkout' && (
                                        <div className="flex-1 overflow-y-auto flex flex-col p-4 space-y-4">

                                            {/* Sipariş Notu Girişi */}
                                            <div className="bg-white p-3.5 rounded-2xl border border-slate-100 shadow-sm text-left space-y-2">
                                                <label className="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">Sipariş Notu</label>
                                                <input
                                                    type="text"
                                                    value={simOrderNote}
                                                    onChange={(e) => setSimOrderNote(e.target.value)}
                                                    placeholder="Ürünler poşetsiz olsun, kapıya asın vb..."
                                                    className="w-full bg-slate-50 border border-slate-100 rounded-xl p-2.5 text-xs text-slate-700 focus:outline-none focus:border-emerald-500"
                                                />
                                            </div>

                                            {/* Teslimat Zamanı Bilgisi */}
                                            <div className="bg-white p-3.5 rounded-2xl border border-slate-100 shadow-sm text-left flex items-center justify-between">
                                                <div>
                                                    <span className="text-[9px] text-slate-400 block font-semibold">Teslimat Yöntemi</span>
                                                    <span className="text-xs font-extrabold text-slate-700">
                                                        {simDeliveryMethod === 'eve_teslim' ? 'Eve Teslimat' : 'Gel Al'} ({simDeliveryTime === 'hemen' ? 'Hemen' : 'Randevulu'})
                                                    </span>
                                                </div>
                                                <span className="text-xs text-emerald-600 font-bold bg-emerald-50 px-2 py-0.5 rounded">
                                                    {simDeliveryMethod === 'eve_teslim' ? '25-45 Dk' : '15-20 Dk'}
                                                </span>
                                            </div>

                                            {/* Ödeme Yöntemi Seçimi */}
                                            <div className="bg-white p-3.5 rounded-2xl border border-slate-100 shadow-sm text-left space-y-3">
                                                <label className="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">Ödeme Yöntemi</label>

                                                <div className="grid grid-cols-2 gap-2">
                                                    <button
                                                        onClick={() => setSimPaymentMethod('online_kart')}
                                                        className={`p-2.5 rounded-xl border text-center flex flex-col items-center justify-center space-y-1 transition-all ${simPaymentMethod === 'online_kart' ? 'border-emerald-500 bg-emerald-50/50 text-emerald-800 font-bold' : 'border-slate-100 text-slate-500 hover:bg-slate-50'}`}
                                                    >
                                                        <span className="text-sm">💳</span>
                                                        <span className="text-[10px]">Kredi / Banka Kartı</span>
                                                    </button>

                                                    <button
                                                        onClick={() => setSimPaymentMethod('kapida_nakit')}
                                                        className={`p-2.5 rounded-xl border text-center flex flex-col items-center justify-center space-y-1 transition-all ${simPaymentMethod === 'kapida_nakit' ? 'border-emerald-500 bg-emerald-50/50 text-emerald-800 font-bold' : 'border-slate-100 text-slate-500 hover:bg-slate-50'}`}
                                                    >
                                                        <span className="text-sm">💵</span>
                                                        <span className="text-[10px]">Kapıda Ödeme</span>
                                                    </button>
                                                </div>

                                                {/* Alt Ödeme Detayı (Kapıda ödeme ise nakit mi kart mı?) */}
                                                {simPaymentMethod === 'kapida_nakit' && (
                                                    <div className="pt-2 border-t border-slate-50 flex space-x-2">
                                                        <span className="bg-emerald-50 text-emerald-800 text-[9px] px-2.5 py-1 rounded-lg font-bold border border-emerald-200">
                                                            💵 Kapıda Nakit
                                                        </span>
                                                        <span className="bg-slate-50 text-slate-400 text-[9px] px-2.5 py-1 rounded-lg font-semibold cursor-not-allowed">
                                                            💳 Kapıda Kredi Kartı
                                                        </span>
                                                    </div>
                                                )}
                                            </div>

                                            {/* Sipariş Özeti */}
                                            <div className="bg-white p-3.5 rounded-2xl border border-slate-100 shadow-sm text-left space-y-3">
                                                <div className="flex justify-between items-center pb-2 border-b border-slate-50">
                                                    <span className="text-xs font-bold text-slate-800">Sipariş Özeti</span>
                                                    <span className="text-[10px] text-slate-400 font-semibold">{simCart.reduce((sum, item) => sum + item.qty, 0)} Ürün</span>
                                                </div>

                                                <div className="space-y-1.5 text-xs text-slate-600">
                                                    {simCart.map((item) => (
                                                        <div key={item.id} className="flex justify-between">
                                                            <span>{item.qty}x {item.name}</span>
                                                            <span>{(item.price * item.qty).toFixed(2)} ₺</span>
                                                        </div>
                                                    ))}
                                                </div>

                                                <div className="pt-2 border-t border-slate-100 space-y-1 text-xs">
                                                    <div className="flex justify-between text-slate-500">
                                                        <span>Ara Toplam</span>
                                                        <span>{cartSubtotal.toFixed(2)} ₺</span>
                                                    </div>
                                                    <div className="flex justify-between text-emerald-600 font-semibold">
                                                        <span>Teslimat Ücreti</span>
                                                        <span>Ücretsiz</span>
                                                    </div>
                                                    <div className="flex justify-between text-sm font-extrabold text-slate-800 pt-1.5">
                                                        <span>GENEL TOPLAM</span>
                                                        <span>{cartTotal.toFixed(2)} ₺</span>
                                                    </div>
                                                </div>
                                            </div>

                                            {/* Siparişi Tamamla Butonu */}
                                            <button
                                                onClick={() => setSimScreen('order_status')}
                                                className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-black py-4 rounded-2xl text-xs tracking-wider uppercase shadow-lg shadow-emerald-600/10 transition-all active:scale-95"
                                            >
                                                Siparişi Tamamla
                                            </button>

                                        </div>
                                    )}

                                    {/* 6. SİPARİŞ DURUMU / CANLI HARİTA TAKİBİ */}
                                    {simScreen === 'order_status' && (
                                        <div className="flex-1 overflow-y-auto flex flex-col p-4 space-y-4">

                                            {/* Sipariş Durum Timeline'ı */}
                                            <div className="bg-white p-4 rounded-2xl border border-slate-100 shadow-sm text-left space-y-4">
                                                <h5 className="text-xs font-bold text-slate-800 leading-none">Sipariş Durumu</h5>

                                                {/* Timeline Çizgisi */}
                                                <div className="relative pt-2 pb-1">
                                                    {/* Yatay Arka Çizgi */}
                                                    <div className="h-1 bg-slate-100 w-full rounded-full"></div>
                                                    {/* İlerleyen Çizgi */}
                                                    <div
                                                        className="absolute top-3 left-0 h-1 bg-emerald-500 rounded-full transition-all duration-300"
                                                        style={{ width: `${(orderStep / 3) * 100}%` }}
                                                    ></div>

                                                    {/* Durum Noktaları */}
                                                    <div className="flex justify-between items-center -mt-2.5 relative z-10">
                                                        {/* Onay Bekliyor */}
                                                        <div className="flex flex-col items-center">
                                                            <span className={`w-4 h-4 rounded-full flex items-center justify-center text-[8px] font-bold ${orderStep >= 0 ? 'bg-emerald-500 text-white' : 'bg-slate-200'}`}>
                                                                {orderStep >= 0 ? '✓' : '1'}
                                                            </span>
                                                            <span className="text-[8px] mt-1 font-bold text-slate-600">Onay</span>
                                                        </div>

                                                        {/* Hazırlanıyor */}
                                                        <div className="flex flex-col items-center">
                                                            <span className={`w-4 h-4 rounded-full flex items-center justify-center text-[8px] font-bold ${orderStep >= 1 ? 'bg-emerald-500 text-white' : 'bg-slate-200'}`}>
                                                                {orderStep >= 1 ? '✓' : '2'}
                                                            </span>
                                                            <span className="text-[8px] mt-1 font-bold text-slate-600">Hazırlanıyor</span>
                                                        </div>

                                                        {/* Yolda */}
                                                        <div className="flex flex-col items-center">
                                                            <span className={`w-4 h-4 rounded-full flex items-center justify-center text-[8px] font-bold ${orderStep >= 2 ? 'bg-emerald-500 text-white' : 'bg-slate-200'}`}>
                                                                {orderStep >= 2 ? '✓' : '3'}
                                                            </span>
                                                            <span className="text-[8px] mt-1 font-bold text-slate-600">Yolda</span>
                                                        </div>

                                                        {/* Teslim Edildi */}
                                                        <div className="flex flex-col items-center">
                                                            <span className={`w-4 h-4 rounded-full flex items-center justify-center text-[8px] font-bold ${orderStep >= 3 ? 'bg-emerald-500 text-white' : 'bg-slate-200'}`}>
                                                                {orderStep >= 3 ? '✓' : '4'}
                                                            </span>
                                                            <span className="text-[8px] mt-1 font-bold text-slate-600">Teslimat</span>
                                                        </div>
                                                    </div>
                                                </div>

                                                {/* Sipariş Tarihi / ID */}
                                                <div className="text-center pt-2 border-t border-slate-50 space-y-1">
                                                    <div className="text-[9px] text-slate-400">25 Jun 2026, 17:43</div>
                                                    <div className="text-[10px] font-bold text-slate-700">Sipariş No: #FD6FE83B</div>
                                                </div>

                                                {/* Takip / Yol Tarifi Butonu */}
                                                {simDeliveryMethod === 'eve_teslim' ? (
                                                    <div className="bg-emerald-600 text-white p-3.5 rounded-xl text-center font-bold text-xs flex items-center justify-center space-x-2 relative overflow-hidden shadow-md shadow-emerald-600/10">
                                                        <span className="animate-bounce">🛵</span>
                                                        <span>Kuryeyi Canlı Takip Et</span>
                                                    </div>
                                                ) : (
                                                    <div className="bg-orange-500 text-white p-3.5 rounded-xl text-center font-bold text-xs flex items-center justify-center space-x-2 relative overflow-hidden shadow-md shadow-orange-500/10">
                                                        <span>📍</span>
                                                        <span>Mağaza Yol Tarifi Al</span>
                                                    </div>
                                                )}
                                            </div>

                                            {/* CANLI DETAYLI SİMÜLASYON HARİTASI (CANVAS veya SVG ile Tasarlanmış Şık Harita) */}
                                            <div className="h-44 bg-slate-100 rounded-2xl relative overflow-hidden border border-slate-200 text-left">

                                                {/* Harita Arka Plan Deseni (Yollar vb) */}
                                                <div className="absolute inset-0 opacity-20">
                                                    <div className="absolute top-1/3 left-0 right-0 h-4 bg-slate-400"></div>
                                                    <div className="absolute top-2/3 left-0 right-0 h-4 bg-slate-400"></div>
                                                    <div className="absolute left-1/3 top-0 bottom-0 w-4 bg-slate-400"></div>
                                                    <div className="absolute left-2/3 top-0 bottom-0 w-4 bg-slate-400"></div>
                                                </div>

                                                {/* Başlangıç Noktası (Sol) */}
                                                <div className="absolute top-8 left-10 bg-white p-1.5 rounded-xl border border-slate-300 shadow-sm z-10 text-center">
                                                    <span className="text-sm">{simDeliveryMethod === 'eve_teslim' ? '🏬' : '🏠'}</span>
                                                    <span className="text-[7px] block font-black text-slate-700">
                                                        {simDeliveryMethod === 'eve_teslim' ? 'MARKET' : 'EVİNİZ'}
                                                    </span>
                                                </div>

                                                {/* Bitiş Noktası (Sağ) */}
                                                <div className="absolute bottom-8 right-10 bg-emerald-50 p-1.5 rounded-xl border border-emerald-300 shadow-sm z-10 text-center">
                                                    <span className="text-sm">{simDeliveryMethod === 'eve_teslim' ? '🏠' : '🏬'}</span>
                                                    <span className="text-[7px] block font-black text-emerald-700">
                                                        {simDeliveryMethod === 'eve_teslim' ? 'EVİNİZ' : 'MAĞAZA'}
                                                    </span>
                                                </div>

                                                {/* Hareket Eden Simge (Kurye / Alıcı) */}
                                                <div
                                                    className="absolute text-2xl transition-all duration-300 z-20"
                                                    style={{
                                                        left: `${20 + (scooterPos * 0.5)}%`,
                                                        top: `${20 + (scooterPos * 0.45)}%`
                                                    }}
                                                >
                                                    {simDeliveryMethod === 'eve_teslim' ? '🛵' : '🚗'}
                                                </div>

                                                {/* Canlı Bilgilendirme Kutucuğu */}
                                                <div className="absolute bottom-2 left-2 right-2 bg-white/90 backdrop-blur-sm p-1.5 rounded-lg border border-slate-200/50 text-[9px] font-bold text-slate-800 text-center">
                                                    {simDeliveryMethod === 'eve_teslim' ? (
                                                        orderStep === 3 ? "🎉 Siparişiniz Teslim Edildi! Teşekkürler." : "🛵 Ahmet Y. siparişinizle yola çıktı, size yaklaşıyor!"
                                                    ) : (
                                                        orderStep === 3 ? "🎉 Siparişiniz Hazırlandı, Teslim Alındı! Teşekkürler." : "⏳ Siparişiniz hazırlanıyor, yola çıkmak üzere hazırlanabilirsiniz!"
                                                    )}
                                                </div>
                                            </div>

                                            {/* Sipariş İçeriği Özeti */}
                                            <div className="bg-white p-3.5 rounded-2xl border border-slate-100 shadow-sm text-left space-y-2">
                                                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">Sipariş İçeriği</span>
                                                <div className="space-y-2">
                                                    {simCart.map((item) => (
                                                        <div key={item.id} className="flex justify-between text-xs">
                                                            <span className="text-slate-600 font-medium">
                                                                <span className="text-orange-500 font-bold bg-orange-50 px-1.5 py-0.5 rounded mr-1.5 text-[9px]">{item.qty}x</span>
                                                                {item.name}
                                                            </span>
                                                            <span className="font-extrabold text-slate-800">{item.price.toFixed(2)} ₺</span>
                                                        </div>
                                                    ))}
                                                </div>
                                            </div>

                                            {/* Not ve Toplam */}
                                            <div className="bg-white p-3.5 rounded-2xl border border-slate-100 shadow-sm text-left space-y-3">
                                                {simOrderNote && (
                                                    <div className="bg-yellow-50/50 p-2.5 rounded-xl border border-yellow-100">
                                                        <span className="text-[9px] text-yellow-800 font-bold uppercase block">Sipariş Notunuz</span>
                                                        <p className="text-[10px] text-slate-600 italic">&quot;{simOrderNote}&quot;</p>
                                                    </div>
                                                )}

                                                <div className="flex justify-between items-center pt-2 border-t border-slate-100">
                                                    <span className="text-xs font-bold text-slate-500">Ödenen Tutar:</span>
                                                    <span className="text-sm font-extrabold text-orange-600">{cartTotal.toFixed(2)} ₺</span>
                                                </div>
                                            </div>

                                            {/* Simülatörü Sıfırla Butonu */}
                                            <button
                                                onClick={() => {
                                                    setSimScreen('categories');
                                                    setSimCart([]);
                                                }}
                                                className="w-full bg-slate-100 hover:bg-slate-200 text-slate-700 font-bold py-3 rounded-xl text-[11px] transition-all"
                                            >
                                                Yeni Sipariş Deneyimi Başlat
                                            </button>

                                        </div>
                                    )}

                                    {/* SİMÜLATÖR HOME BAR */}
                                    <div className="h-6 w-full bg-white flex items-center justify-center sticky bottom-0 border-t border-slate-100">
                                        <div className="w-32 h-1 bg-slate-300 rounded-full"></div>
                                    </div>

                                </div>
                            </div>

                        </div>

                    </div>
                </div>
            </section>

            {/* İŞ ORTAKLARI VE KURYELER İÇİN ÖZEL BAŞVURU SEKMESİ */}
            <section id="partners" className="py-24 bg-white">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

                    <div className="text-center max-w-3xl mx-auto space-y-4 mb-16">
                        <h2 className="text-xs uppercase font-extrabold tracking-widest text-emerald-600">Birlikte Büyüyelim</h2>
                        <p className="text-3xl sm:text-4xl font-extrabold text-slate-900">Hoppa Ekosistemine Katılın</p>
                        <p className="text-slate-500">
                            İster işletmenizin satışlarını katlayın, ister ekibimizin bir parçası olarak kazanç elde edin.
                        </p>
                    </div>

                    {/* Sekme Seçenekleri */}
                    <div className="flex justify-center mb-12">
                        <div className="bg-slate-100 p-1.5 rounded-2xl flex space-x-1">
                            <button
                                onClick={() => setActiveTab('user')}
                                className={`px-6 py-3 rounded-xl text-xs sm:text-sm font-bold transition-all ${activeTab === 'user' ? 'bg-emerald-600 text-white shadow' : 'text-slate-600 hover:text-slate-950'}`}
                            >
                                İşletme Ortağı Ol
                            </button>
                            <button
                                onClick={() => setActiveTab('partner')}
                                className={`px-6 py-3 rounded-xl text-xs sm:text-sm font-bold transition-all ${activeTab === 'partner' ? 'bg-emerald-600 text-white shadow' : 'text-slate-600 hover:text-slate-950'}`}
                            >
                                Kurye Olarak Başvur
                            </button>
                        </div>
                    </div>

                    <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">

                        {/* Form ve Detaylar */}
                        {activeTab === 'user' ? (
                            <>
                                <div className="lg:col-span-6 space-y-6 text-left">
                                    <div className="bg-emerald-50 text-emerald-800 p-3 rounded-2xl inline-block font-bold text-xs">
                                        KOBİ & RESTORANLAR İÇİN
                                    </div>
                                    <h3 className="text-2xl sm:text-3xl font-black text-slate-900 leading-tight">
                                        Hoppa Mağazası Olun, Müşteri Portföyünüzü Katlayın
                                    </h3>
                                    <p className="text-slate-600">
                                        Süpermarket, kasap, manav, restoran veya su bayisi olmanız fark etmez. Hoppa ile tüm Gazimağusa genelindeki dijital müşterilere anında ulaşın. Kolay panel yönetimiyle menülerinizi, fiyatlarınızı düzenleyin ve siparişleri takip edin.
                                    </p>

                                    <div className="space-y-3.5 pt-2">
                                        <div className="flex items-start space-x-3 text-sm text-slate-700">
                                            <span className="text-emerald-600 font-bold">✓</span>
                                            <span>Düşük komisyon oranları ve hızlı ödeme periyotları</span>
                                        </div>
                                        <div className="flex items-start space-x-3 text-sm text-slate-700">
                                            <span className="text-emerald-600 font-bold">✓</span>
                                            <span>Hoppa kurye ağıyla veya kendi kuryenizle teslimat yapma özgürlüğü</span>
                                        </div>
                                        <div className="flex items-start space-x-3 text-sm text-slate-700">
                                            <span className="text-emerald-600 font-bold">✓</span>
                                            <span>Mağazanıza özel dijital reklam ve pazarlama desteği</span>
                                        </div>
                                    </div>
                                </div>

                                <div className="lg:col-span-6">
                                    <div className="bg-slate-50 p-8 rounded-3xl border border-slate-100 shadow-xl shadow-slate-100 text-left">
                                        {partnerSubmitted ? (
                                            <div className="text-center py-12 space-y-4">
                                                <div className="w-16 h-16 bg-emerald-100 text-emerald-800 rounded-full flex items-center justify-center text-2xl mx-auto">
                                                    ✓
                                                </div>
                                                <h4 className="text-xl font-bold text-slate-800">Başvurunuz Alındı!</h4>
                                                <p className="text-sm text-slate-500">
                                                    Uzman ekibimiz 24 saat içinde sizinle iletişime geçerek iş ortaklığı sürecini başlatacaktır.
                                                </p>
                                            </div>
                                        ) : (
                                            <form onSubmit={(e) => { e.preventDefault(); setPartnerSubmitted(true); }} className="space-y-4">
                                                <h4 className="font-extrabold text-lg text-slate-900 mb-2">Başvuru Formu</h4>

                                                <div>
                                                    <label className="text-xs font-bold text-slate-500 mb-1.5 block">İşletme Adı</label>
                                                    <input required type="text" placeholder="Örn: Şehir Süpermarket" className="w-full bg-white border border-slate-200 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600" />
                                                </div>

                                                <div className="grid grid-cols-2 gap-4">
                                                    <div>
                                                        <label className="text-xs font-bold text-slate-500 mb-1.5 block">Yetkili Adı Soyadı</label>
                                                        <input required type="text" placeholder="Örn: Ali Yılmaz" className="w-full bg-white border border-slate-200 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600" />
                                                    </div>
                                                    <div>
                                                        <label className="text-xs font-bold text-slate-500 mb-1.5 block">Telefon Numarası</label>
                                                        <input required type="tel" placeholder="Örn: 0533..." className="w-full bg-white border border-slate-200 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600" />
                                                    </div>
                                                </div>

                                                <div>
                                                    <label className="text-xs font-bold text-slate-500 mb-1.5 block">Kategori</label>
                                                    <select className="w-full bg-white border border-slate-200 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600">
                                                        <option>Süpermarket / Bakkal</option>
                                                        <option>Restoran / Cafe</option>
                                                        <option>Su Bayisi</option>
                                                        <option>Kuruyemiş / Tatlı</option>
                                                        <option>Diğer</option>
                                                    </select>
                                                </div>

                                                <button type="submit" className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-bold py-4 rounded-xl text-sm shadow-md transition-all">
                                                    İş Ortaklığı Başvurusunu Tamamla
                                                </button>
                                            </form>
                                        )}
                                    </div>
                                </div>
                            </>
                        ) : (
                            <>
                                <div className="lg:col-span-6 space-y-6 text-left">
                                    <div className="bg-orange-50 text-orange-800 p-3 rounded-2xl inline-block font-bold text-xs">
                                        KURYELER İÇİN
                                    </div>
                                    <h3 className="text-2xl sm:text-3xl font-black text-slate-900 leading-tight">
                                        Kendi Saatlerini Seç, Hoppa ile Kazanç Elde Et!
                                    </h3>
                                    <p className="text-slate-600">
                                        Özgürce çalışmak ve Gazimağusa sokaklarında güvenli sürüş yaparken gelir elde etmek ister misiniz? Hoppa ile tam zamanlı, yarı zamanlı veya sadece haftalık programınıza göre kuryelik yapabilirsiniz.
                                    </p>

                                    <div className="space-y-3.5 pt-2">
                                        <div className="flex items-start space-x-3 text-sm text-slate-700">
                                            <span className="text-orange-500 font-bold">✓</span>
                                            <span>Haftalık düzenli, yüksek kazanç garantisi</span>
                                        </div>
                                        <div className="flex items-start space-x-3 text-sm text-slate-700">
                                            <span className="text-orange-500 font-bold">✓</span>
                                            <span>Esnek çalışma saatleri ve kurye destek sigortası</span>
                                        </div>
                                        <div className="flex items-start space-x-3 text-sm text-slate-700">
                                            <span className="text-orange-500 font-bold">✓</span>
                                            <span>Akıllı yönlendirme algoritmamızla minimum sürüş, maksimum sipariş</span>
                                        </div>
                                    </div>
                                </div>

                                <div className="lg:col-span-6">
                                    <div className="bg-slate-50 p-8 rounded-3xl border border-slate-100 shadow-xl shadow-slate-100 text-left">
                                        {courierSubmitted ? (
                                            <div className="text-center py-12 space-y-4">
                                                <div className="w-16 h-16 bg-emerald-100 text-emerald-800 rounded-full flex items-center justify-center text-2xl mx-auto">
                                                    ✓
                                                </div>
                                                <h4 className="text-xl font-bold text-slate-800">Başvurunuz Alındı!</h4>
                                                <p className="text-sm text-slate-500">
                                                    Kurye operasyon ekibimiz başvurunuzu değerlendirerek sizinle en kısa sürede iletişime geçecektir.
                                                </p>
                                            </div>
                                        ) : (
                                            <form onSubmit={(e) => { e.preventDefault(); setCourierSubmitted(true); }} className="space-y-4">
                                                <h4 className="font-extrabold text-lg text-slate-900 mb-2">Kurye Başvuru Formu</h4>

                                                <div className="grid grid-cols-2 gap-4">
                                                    <div>
                                                        <label className="text-xs font-bold text-slate-500 mb-1.5 block">Adınız Soyadınız</label>
                                                        <input required type="text" placeholder="Örn: Can Demir" className="w-full bg-white border border-slate-200 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600" />
                                                    </div>
                                                    <div>
                                                        <label className="text-xs font-bold text-slate-500 mb-1.5 block">Telefon Numaranız</label>
                                                        <input required type="tel" placeholder="Örn: 0533..." className="w-full bg-white border border-slate-200 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600" />
                                                    </div>
                                                </div>

                                                <div>
                                                    <label className="text-xs font-bold text-slate-500 mb-1.5 block">Araç Tipi</label>
                                                    <select className="w-full bg-white border border-slate-200 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600">
                                                        <option>Motosiklet (Kendi Aracım)</option>
                                                        <option>Araba (Kendi Aracım)</option>
                                                        <option>Araç İstiyorum (Şirket Motosikleti)</option>
                                                    </select>
                                                </div>

                                                <div>
                                                    <label className="text-xs font-bold text-slate-500 mb-1.5 block">Ehliyet Durumu</label>
                                                    <select className="w-full bg-white border border-slate-200 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600">
                                                        <option>Motosiklet Ehliyetim Var</option>
                                                        <option>B Sınıfı Ehliyetim Var</option>
                                                        <option>Yok / Almayı Düşünüyorum</option>
                                                    </select>
                                                </div>

                                                <button type="submit" className="w-full bg-orange-500 hover:bg-orange-600 text-white font-bold py-4 rounded-xl text-sm shadow-md transition-all">
                                                    Kurye Başvurusunu Gönder
                                                </button>
                                            </form>
                                        )}
                                    </div>
                                </div>
                            </>
                        )}

                    </div>

                </div>
            </section>

            {/* İLETİŞİM & LOKAL DESTEK */}
            <section id="contact" className="py-20 bg-slate-50 border-t border-slate-100">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-center">

                        <div className="text-left space-y-6">
                            <h3 className="text-3xl font-extrabold text-slate-900">
                                Sorularınız mı Var? <br />
                                Müşteri Hizmetlerimizle İletişime Geçin
                            </h3>
                            <p className="text-slate-600 leading-relaxed">
                                Kuzey Kıbrıs genelinde yerel ve dinamik bir destek ekibiyle çalışıyoruz. Siparişleriniz, üyelikleriniz veya partnerlik süreçlerinizle ilgili her an bize yazabilir ya da arayabilirsiniz.
                            </p>

                            <div className="space-y-4 pt-2">
                                <div className="flex items-center space-x-4">
                                    <div className="w-12 h-12 rounded-xl bg-white border border-slate-200 flex items-center justify-center text-emerald-600">
                                        <Phone size={20} />
                                    </div>
                                    <div>
                                        <span className="text-xs text-slate-400 block font-semibold">Müşteri Destek Hattı</span>
                                        <a href="tel:05338765432" className="text-sm font-bold text-slate-800 hover:text-emerald-600">0533 876 54 32</a>
                                    </div>
                                </div>

                                <div className="flex items-center space-x-4">
                                    <div className="w-12 h-12 rounded-xl bg-white border border-slate-200 flex items-center justify-center text-emerald-600">
                                        <MapPin size={20} />
                                    </div>
                                    <div>
                                        <span className="text-xs text-slate-400 block font-semibold">Ofis Adresi</span>
                                        <span className="text-sm font-bold text-slate-800">Yeni Boğaziçi, Gazimağusa / KKTC</span>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* İletişim Formu */}
                        <div className="bg-white p-8 rounded-3xl border border-slate-100 shadow-xl text-left">
                            {contactSubmitted ? (
                                <div className="text-center py-12 space-y-4">
                                    <div className="w-16 h-16 bg-emerald-100 text-emerald-800 rounded-full flex items-center justify-center text-2xl mx-auto">
                                        ✓
                                    </div>
                                    <h4 className="text-xl font-bold text-slate-800">Mesajınız Gönderildi!</h4>
                                    <p className="text-sm text-slate-500">
                                        Ekibimiz en geç birkaç saat içerisinde verdiğiniz iletişim adresinden size geri dönüş sağlayacaktır.
                                    </p>
                                </div>
                            ) : (
                                <form onSubmit={(e) => { e.preventDefault(); setContactSubmitted(true); }} className="space-y-4">
                                    <h4 className="font-extrabold text-lg text-slate-900 mb-2">Hızlı Mesaj Gönder</h4>

                                    <div>
                                        <label className="text-xs font-bold text-slate-500 mb-1.5 block">Adınız Soyadınız</label>
                                        <input required type="text" placeholder="Örn: Ahmet Can" className="w-full bg-slate-50 border border-slate-100 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600" />
                                    </div>

                                    <div>
                                        <label className="text-xs font-bold text-slate-500 mb-1.5 block">E-Posta Adresiniz</label>
                                        <input required type="email" placeholder="Örn: ahmet@example.com" className="w-full bg-slate-50 border border-slate-100 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600" />
                                    </div>

                                    <div>
                                        <label className="text-xs font-bold text-slate-500 mb-1.5 block">Mesajınız</label>
                                        <textarea required rows={4} placeholder="Nasıl yardımcı olabiliriz?" className="w-full bg-slate-50 border border-slate-100 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600"></textarea>
                                    </div>

                                    <button type="submit" className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-bold py-4 rounded-xl text-sm shadow-md transition-all">
                                        Gönder
                                    </button>
                                </form>
                            )}
                        </div>

                    </div>
                </div>
            </section>

            {/* FOOTER */}
            <footer className="bg-slate-900 text-white pt-16 pb-8 border-t border-slate-800">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

                    <div className="grid grid-cols-1 md:grid-cols-4 gap-8 pb-12 border-b border-slate-800">

                        {/* Logo ve Hakkında */}
                        <div className="space-y-4 text-left">
                            <div className="flex items-center">
                                <img src="/logo-color.png" alt="Hoppa Logo" className="h-10 w-auto object-contain brightness-0 invert" />
                            </div>
                            <p className="text-xs text-slate-400 leading-relaxed">
                                Gazimağusa&apos;nın her noktasına süper hızlı, güvenli ve canlı takip sistemli sipariş ulaştıran yerel dijital pazaryeri platformunuz.
                            </p>
                        </div>

                        {/* Hızlı Linkler */}
                        <div className="text-left space-y-3">
                            <h4 className="text-xs font-extrabold uppercase tracking-widest text-slate-400">Kurumsal</h4>
                            <ul className="space-y-2 text-xs text-slate-300">
                                <li><a href="#features" className="hover:text-emerald-400 transition-colors">Biz Kimiz?</a></li>
                                <li><a href="#partners" onClick={() => setActiveTab('user')} className="hover:text-emerald-400 transition-colors">Mağaza İş Ortaklığı</a></li>
                                <li><a href="#partners" onClick={() => setActiveTab('partner')} className="hover:text-emerald-400 transition-colors">Kuryelik Başvurusu</a></li>
                                <li><a href="#contact" className="hover:text-emerald-400 transition-colors">Kullanıcı Sözleşmesi</a></li>
                            </ul>
                        </div>

                        {/* İletişim Bilgileri */}
                        <div className="text-left space-y-3">
                            <h4 className="text-xs font-extrabold uppercase tracking-widest text-slate-400">İletişim</h4>
                            <ul className="space-y-2 text-xs text-slate-300">
                                <li>Destek: support@hoppanow.com</li>
                                <li>Halkla İlişkiler: pr@hoppanow.com</li>
                                <li>Telefon: +90 533 876 54 32</li>
                                <li>Adres: Yeni Boğaziçi, Gazimağusa, KKTC</li>
                            </ul>
                        </div>

                        {/* Mobil Mağazalar */}
                        <div className="text-left space-y-3">
                            <h4 className="text-xs font-extrabold uppercase tracking-widest text-slate-400">Uygulamayı İndir</h4>
                            <div className="space-y-2">
                                <a
                                    href="#interactive-demo"
                                    className="bg-slate-800 hover:bg-slate-750 text-white text-[10px] px-4 py-2.5 rounded-xl font-bold flex items-center justify-center space-x-2 border border-slate-700"
                                >
                                    <span>App Store&apos;dan İndir</span>
                                </a>
                                <a
                                    href="#interactive-demo"
                                    className="bg-slate-800 hover:bg-slate-750 text-white text-[10px] px-4 py-2.5 rounded-xl font-bold flex items-center justify-center space-x-2 border border-slate-700"
                                >
                                    <span>Google Play&apos;den Alın</span>
                                </a>
                            </div>
                        </div>

                    </div>

                    <div className="pt-8 flex flex-col sm:flex-row items-center justify-between text-xs text-slate-400 space-y-4 sm:space-y-0">
                        <span>© 2026 Hoppa (hoppanow.com). Tüm Hakları Saklıdır.</span>
                        <div className="flex space-x-4">
                            <a href="#privacy" className="hover:text-slate-200 transition-colors">Gizlilik Politikası</a>
                            <a href="#data-protection" className="hover:text-slate-200 transition-colors">KVKK Aydınlatma Metni</a>
                            <a href="#cookie-policy" className="hover:text-slate-200 transition-colors">Çerez Politikası</a>
                        </div>
                    </div>

                </div>
            </footer>

        </div>
    );
}
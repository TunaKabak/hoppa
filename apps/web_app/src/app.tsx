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
import { translations } from './translations';

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
    const [locale, setLocale] = useState<'tr' | 'en' | 'ru'>('tr');

    useEffect(() => {
        const saved = localStorage.getItem('hoppa_locale');
        if (saved && (saved === 'tr' || saved === 'en' || saved === 'ru')) {
            setLocale(saved);
        }
    }, []);

    const changeLocale = (lang: 'tr' | 'en' | 'ru') => {
        setLocale(lang);
        localStorage.setItem('hoppa_locale', lang);
    };

    const t = (key: keyof typeof translations['tr']) => {
        const activeTranslations = translations[locale] || translations['tr'];
        return activeTranslations[key] || translations['tr'][key] || '';
    };

    const getCategoryTitle = (id: string) => {
        const key = `category_${id}_title` as keyof typeof translations['tr'];
        return t(key);
    };

    const getCategoryDesc = (id: string) => {
        const key = `category_${id}_desc` as keyof typeof translations['tr'];
        return t(key);
    };

    const getProductFieldName = (id: string, field: 'name' | 'brand' | 'desc') => {
        const key = `product_${id}_${field}` as keyof typeof translations['tr'];
        return t(key);
    };

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

    // Section scroll animations (Intersection Observer)
    useEffect(() => {
        const observer = new IntersectionObserver(
            (entries) => {
                entries.forEach((entry) => {
                    if (entry.isIntersecting) {
                        entry.target.classList.add('visible');
                    }
                });
            },
            { threshold: 0.05 }
        );
        const targets = document.querySelectorAll('.scroll-animate');
        targets.forEach((target) => observer.observe(target));
        return () => {
            targets.forEach((target) => observer.unobserve(target));
        };
    }, []);

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
                triggerToast(`${getProductFieldName(id, 'name')} ${t('sim_toast_removed')}`);
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
                        <div className="flex items-center cursor-pointer" onClick={() => { setSimScreen('splash'); window.scrollTo({ top: 0, behavior: 'smooth' }); }}>
                            <img src="/logo-color.png" alt="Hoppa Logo" className="h-10 w-auto object-contain" />
                            <span className="text-xs font-semibold text-emerald-600 ml-2 bg-emerald-50 px-2 py-0.5 rounded-full">
                                now.com
                            </span>
                        </div>

                        {/* Masaüstü Navigasyon */}
                        <nav className="hidden md:flex items-center space-x-8">
                            <a href="#features" className="font-medium text-slate-600 hover:text-emerald-600 transition-colors">{t('nav_features')}</a>
                            <a href="#how-it-works" className="font-medium text-slate-600 hover:text-emerald-600 transition-colors">{t('nav_how_it_works')}</a>
                            <a href="#interactive-demo" className="font-medium text-slate-600 hover:text-emerald-600 transition-colors bg-emerald-50 text-emerald-700 px-3 py-1 rounded-full text-sm animate-pulse">{t('nav_try_app')}</a>
                            <a href="#partners" onClick={() => setActiveTab('user')} className="font-medium text-slate-600 hover:text-emerald-600 transition-colors">{t('nav_partnerships')}</a>
                            <a href="#partners" onClick={() => setActiveTab('partner')} className="font-medium text-slate-600 hover:text-emerald-600 transition-colors">{t('nav_courier')}</a>
                        </nav>

                        {/* App Store / CTA & Dil Seçici */}
                        <div className="hidden lg:flex items-center space-x-4">
                            <a
                                href="#interactive-demo"
                                className="bg-emerald-600 hover:bg-emerald-700 text-white px-5 py-2.5 rounded-full font-semibold transition-all duration-300 shadow-lg shadow-emerald-600/20 text-sm hover:scale-105 active:scale-95 animate-none"
                            >
                                {t('nav_order_now')}
                            </a>

                            <div className="flex items-center space-x-1 bg-slate-50 border border-slate-200 rounded-full px-1.5 py-1 text-xs font-bold text-slate-600">
                                <button onClick={() => changeLocale('tr')} className={`px-2 py-0.5 rounded-full transition-colors ${locale === 'tr' ? 'bg-white text-emerald-600 shadow-sm' : 'hover:text-slate-900'}`}>TR</button>
                                <button onClick={() => changeLocale('en')} className={`px-2 py-0.5 rounded-full transition-colors ${locale === 'en' ? 'bg-white text-emerald-600 shadow-sm' : 'hover:text-slate-900'}`}>EN</button>
                                <button onClick={() => changeLocale('ru')} className={`px-2 py-0.5 rounded-full transition-colors ${locale === 'ru' ? 'bg-white text-emerald-600 shadow-sm' : 'hover:text-slate-900'}`}>RU</button>
                            </div>
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
                            {t('nav_features')}
                        </a>
                        <a
                            href="#how-it-works"
                            onClick={() => setMobileMenuOpen(false)}
                            className="block font-medium py-2 text-slate-700 hover:text-emerald-600 transition-colors"
                        >
                            {t('nav_how_it_works')}
                        </a>
                        <a
                            href="#interactive-demo"
                            onClick={() => setMobileMenuOpen(false)}
                            className="block font-medium py-2 text-emerald-600 hover:text-emerald-700 font-bold transition-colors"
                        >
                            {t('nav_try_demo')}
                        </a>
                        <a
                            href="#partners"
                            onClick={() => {
                                setMobileMenuOpen(false);
                                setActiveTab('user');
                            }}
                            className="block font-medium py-2 text-slate-700 hover:text-emerald-600 transition-colors"
                        >
                            {t('nav_partnerships')}
                        </a>
                        <a
                            href="#partners"
                            onClick={() => {
                                setMobileMenuOpen(false);
                                setActiveTab('partner');
                            }}
                            className="block font-medium py-2 text-slate-700 hover:text-emerald-600 transition-colors"
                        >
                            {t('nav_courier')}
                        </a>
                        <div className="pt-2">
                            <a
                                href="#interactive-demo"
                                onClick={() => setMobileMenuOpen(false)}
                                className="block w-full text-center bg-emerald-600 text-white py-3 rounded-xl font-bold"
                            >
                                {t('nav_start_simulator')}
                            </a>
                        </div>
                        <div className="pt-3 border-t border-slate-100 flex justify-between items-center">
                            <span className="text-[10px] text-slate-400 font-bold tracking-wider">LANG / DİL / ЯЗЫК</span>
                            <div className="flex items-center space-x-0.5 bg-slate-50 border border-slate-200 rounded-full px-1 py-0.5 text-xs font-bold text-slate-600">
                                <button onClick={() => { changeLocale('tr'); setMobileMenuOpen(false); }} className={`px-2 py-0.5 rounded-full transition-colors ${locale === 'tr' ? 'bg-white text-emerald-600 shadow-sm' : 'hover:text-slate-900'}`}>TR</button>
                                <button onClick={() => { changeLocale('en'); setMobileMenuOpen(false); }} className={`px-2 py-0.5 rounded-full transition-colors ${locale === 'en' ? 'bg-white text-emerald-600 shadow-sm' : 'hover:text-slate-900'}`}>EN</button>
                                <button onClick={() => { changeLocale('ru'); setMobileMenuOpen(false); }} className={`px-2 py-0.5 rounded-full transition-colors ${locale === 'ru' ? 'bg-white text-emerald-600 shadow-sm' : 'hover:text-slate-900'}`}>RU</button>
                            </div>
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
                                <span>{t('hero_sparkles')}</span>
                            </div>

                            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight text-slate-900 leading-tight">
                                {t('hero_title_1')} <span className="text-transparent bg-clip-text bg-gradient-to-r from-orange-500 to-amber-600">{t('hero_title_2')}</span> <br className="hidden sm:inline" />
                                {t('hero_title_3')}
                            </h1>

                            <p className="text-lg text-slate-600 max-w-2xl mx-auto lg:mx-0 leading-relaxed">
                                {t('hero_description')}
                            </p>

                            {/* Hızlı İstatistikler */}
                            <div className="grid grid-cols-3 gap-4 py-2 max-w-md mx-auto lg:mx-0">
                                <div className="p-3 bg-white/80 backdrop-blur-sm rounded-2xl border border-slate-100 shadow-sm text-center">
                                    <div className="text-2xl font-bold text-emerald-600">25-45</div>
                                    <div className="text-xs text-slate-500">{t('hero_stat_delivery_title')}</div>
                                </div>
                                <div className="p-3 bg-white/80 backdrop-blur-sm rounded-2xl border border-slate-100 shadow-sm text-center">
                                    <div className="text-2xl font-bold text-orange-500">100%</div>
                                    <div className="text-xs text-slate-500">{t('hero_stat_payment_title')}</div>
                                </div>
                                <div className="p-3 bg-white/80 backdrop-blur-sm rounded-2xl border border-slate-100 shadow-sm text-center">
                                    <div className="text-2xl font-bold text-slate-800">4.8★</div>
                                    <div className="text-xs text-slate-500">{t('hero_stat_rating_title')}</div>
                                </div>
                            </div>

                            {/* İndirme Butonları */}
                            <div className="flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-4">
                                <a
                                    href="#interactive-demo"
                                    className="w-full sm:w-auto bg-slate-900 hover:bg-slate-800 text-white px-8 py-4 rounded-2xl font-bold flex items-center justify-center space-x-3 shadow-xl transition-all duration-300 hover:-translate-y-1 active:translate-y-0"
                                >
                                    <Smartphone size={20} />
                                    <span>{t('hero_btn_try_live')}</span>
                                </a>
                                <a
                                    href="#partners"
                                    onClick={() => setActiveTab('user')}
                                    className="w-full sm:w-auto bg-white hover:bg-slate-50 text-slate-800 border border-slate-200 px-8 py-4 rounded-2xl font-bold flex items-center justify-center space-x-2 transition-all duration-300 hover:border-slate-300"
                                >
                                    <Store size={20} className="text-emerald-600" />
                                    <span>{t('hero_btn_business_login')}</span>
                                </a>
                            </div>

                            {/* Güvenceler */}
                            <div className="flex flex-wrap justify-center lg:justify-start items-center gap-6 pt-4 text-xs font-semibold text-slate-500">
                                <span className="flex items-center space-x-1.5">
                                    <ShieldCheck size={16} className="text-emerald-600" />
                                    <span>{t('hero_badge_payment')}</span>
                                </span>
                                <span className="flex items-center space-x-1.5">
                                    <Clock size={16} className="text-emerald-600" />
                                    <span>{t('hero_badge_support')}</span>
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
                                            <h4 className="font-bold text-slate-800 leading-none">{t('active_tracking_title')}</h4>
                                            <span className="text-xs text-slate-500">{t('active_tracking_store')}</span>
                                        </div>
                                    </div>
                                    <span className="bg-orange-50 text-orange-700 px-2.5 py-1 rounded-full text-xs font-bold animate-pulse">{t('active_tracking_status')}</span>
                                </div>

                                {/* Kurye Bilgisi */}
                                <div className="space-y-4">
                                    <div className="bg-slate-50 p-3.5 rounded-2xl flex items-center justify-between">
                                        <div className="flex items-center space-x-3">
                                            <div className="w-10 h-10 rounded-full bg-slate-200 flex items-center justify-center text-xl">
                                                🛵
                                            </div>
                                            <div>
                                                <div className="text-xs text-slate-400">{t('active_tracking_courier')}</div>
                                                <div className="text-sm font-bold text-slate-800">Ahmet Y.</div>
                                            </div>
                                        </div>
                                        <span className="text-emerald-600 text-xs font-bold bg-emerald-50 px-2 py-1 rounded-lg">{t('active_tracking_time')}</span>
                                    </div>

                                    {/* Küçük Yol */}
                                    <div className="relative pt-4 pb-2">
                                        <div className="h-1 w-full bg-slate-200 rounded-full"></div>
                                        <div className="absolute top-3.5 left-0 h-1 bg-emerald-500 rounded-full" style={{ width: '70%' }}></div>
                                        <div className="absolute top-1 right-1/4 text-xl transform -translate-x-1/2 animate-bounce">🛵</div>
                                        <div className="flex justify-between text-[10px] text-slate-400 font-semibold pt-1">
                                            <span>{t('active_tracking_step_1')}</span>
                                            <span>{t('active_tracking_step_2')}</span>
                                        </div>
                                    </div>

                                    <a
                                        href="#interactive-demo"
                                        className="block w-full text-center bg-emerald-600 hover:bg-emerald-700 text-white font-bold py-3.5 rounded-2xl text-sm shadow-md transition-all hover:shadow-lg"
                                    >
                                        {t('active_tracking_btn')}
                                    </a>
                                </div>
                            </div>
                        </div>

                    </div>
                </div>
            </section>

            {/* BENZERSİZ DEĞER ÖNERİSİ / ÖZELLİKLER */}
            <section id="features" className="py-24 bg-white border-y border-slate-100 scroll-animate">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

                    <div className="text-center max-w-3xl mx-auto space-y-4 mb-16">
                        <h2 className="text-xs uppercase font-extrabold tracking-widest text-emerald-600">{t('why_hoppa_label')}</h2>
                        <p className="text-3xl sm:text-4xl font-extrabold text-slate-900 tracking-tight">
                            {t('why_hoppa_title')}
                        </p>
                        <p className="text-slate-500">
                            {t('why_hoppa_description')}
                        </p>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-3 gap-8">

                        {/* Kart 1 */}
                        <div className="p-8 rounded-3xl bg-slate-50 border border-slate-100/50 hover:bg-white hover:shadow-2xl hover:shadow-slate-200/50 transition-all duration-300 group">
                            <div className="w-14 h-14 rounded-2xl bg-orange-100 text-orange-600 flex items-center justify-center text-2xl font-bold mb-6 transition-transform group-hover:scale-110">
                                ⚡
                            </div>
                            <h3 className="text-xl font-bold text-slate-900 mb-3">{t('why_hoppa_card1_title')}</h3>
                            <p className="text-slate-600 leading-relaxed">
                                {t('why_hoppa_card1_desc')}
                            </p>
                        </div>

                        {/* Kart 2 */}
                        <div className="p-8 rounded-3xl bg-slate-50 border border-slate-100/50 hover:bg-white hover:shadow-2xl hover:shadow-slate-200/50 transition-all duration-300 group">
                            <div className="w-14 h-14 rounded-2xl bg-emerald-100 text-emerald-600 flex items-center justify-center text-2xl font-bold mb-6 transition-transform group-hover:scale-110">
                                📍
                            </div>
                            <h3 className="text-xl font-bold text-slate-900 mb-3">{t('why_hoppa_card2_title')}</h3>
                            <p className="text-slate-600 leading-relaxed">
                                {t('why_hoppa_card2_desc')}
                            </p>
                        </div>

                        {/* Kart 3 */}
                        <div className="p-8 rounded-3xl bg-slate-50 border border-slate-100/50 hover:bg-white hover:shadow-2xl hover:shadow-slate-200/50 transition-all duration-300 group">
                            <div className="w-14 h-14 rounded-2xl bg-blue-100 text-blue-600 flex items-center justify-center text-2xl font-bold mb-6 transition-transform group-hover:scale-110">
                                🛍️
                            </div>
                            <h3 className="text-xl font-bold text-slate-900 mb-3">{t('why_hoppa_card3_title')}</h3>
                            <p className="text-slate-600 leading-relaxed">
                                {t('why_hoppa_card3_desc')}
                            </p>
                        </div>

                    </div>
                </div>
            </section>

            {/* NASIL ÇALIŞIR? */}
            <section id="how-it-works" className="py-24 bg-slate-50 scroll-animate">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

                    <div className="text-center max-w-2xl mx-auto space-y-4 mb-20">
                        <h2 className="text-xs uppercase font-extrabold tracking-widest text-orange-600">{t('how_label')}</h2>
                        <p className="text-3xl sm:text-4xl font-extrabold text-slate-900">{t('how_title')}</p>
                        <p className="text-slate-500">{t('how_description')}</p>
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
                            <h4 className="font-extrabold text-lg text-slate-900">{t('how_step1_title')}</h4>
                            <p className="text-sm text-slate-500">
                                {t('how_step1_desc')}
                            </p>
                        </div>

                        {/* Adım 2 */}
                        <div className="text-center space-y-4 bg-white p-8 rounded-3xl shadow-sm border border-slate-100 relative">
                            <div className="absolute -top-6 left-1/2 transform -translate-x-1/2 w-12 h-12 bg-emerald-600 text-white font-black rounded-2xl flex items-center justify-center text-lg shadow-lg shadow-emerald-600/20">
                                2
                            </div>
                            <div className="text-4xl pt-2">🛒</div>
                            <h4 className="font-extrabold text-lg text-slate-900">{t('how_step2_title')}</h4>
                            <p className="text-sm text-slate-500">
                                {t('how_step2_desc')}
                            </p>
                        </div>

                        {/* Adım 3 */}
                        <div className="text-center space-y-4 bg-white p-8 rounded-3xl shadow-sm border border-slate-100 relative">
                            <div className="absolute -top-6 left-1/2 transform -translate-x-1/2 w-12 h-12 bg-slate-900 text-white font-black rounded-2xl flex items-center justify-center text-lg shadow-lg shadow-slate-900/20">
                                3
                            </div>
                            <div className="text-4xl pt-2">🛵</div>
                            <h4 className="font-extrabold text-lg text-slate-900">{t('how_step3_title')}</h4>
                            <p className="text-sm text-slate-500">
                                {t('how_step3_desc')}
                            </p>
                        </div>

                    </div>
                </div>
            </section>

            {/* INTERAKTIF SIMÜLATÖR BÖLÜMÜ (CANLI UYGULAMA DENEYİMİ) */}
            <section id="interactive-demo" className="py-24 bg-gradient-to-br from-slate-900 to-slate-950 text-white relative overflow-hidden scroll-animate">

                {/* Dekoratif Işıklar */}
                <div className="absolute -top-24 -left-24 w-96 h-96 bg-emerald-600/20 rounded-full blur-3xl"></div>
                <div className="absolute -bottom-24 -right-24 w-96 h-96 bg-orange-600/10 rounded-full blur-3xl"></div>

                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">

                    <div className="grid grid-cols-1 lg:grid-cols-12 gap-16 items-center">

                        {/* Sol Taraf: Açıklama ve Yönlendirme */}
                        <div className="lg:col-span-6 space-y-8 text-center lg:text-left">
                            <div className="inline-flex items-center space-x-2 bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 px-4 py-1.5 rounded-full text-sm font-bold">
                                <span>{t('demo_label')}</span>
                            </div>

                            <h2 className="text-4xl sm:text-5xl font-black tracking-tight leading-tight">
                                {t('demo_title').split(' ')[0]} <br />
                                <span className="text-transparent bg-clip-text bg-gradient-to-r from-emerald-400 to-amber-300">
                                    {t('demo_title').substring(t('demo_title').indexOf(' ') + 1)}
                                </span>
                            </h2>

                            <p className="text-slate-300 text-lg leading-relaxed">
                                {t('demo_desc')}
                            </p>

                            {/* Simülatör Kontrolleri */}
                            <div className="space-y-4 pt-4 hidden sm:block">
                                <h4 className="font-bold text-slate-200">{t('demo_controls_title')}</h4>
                                <div className="flex flex-wrap gap-2 justify-center lg:justify-start">
                                    <button
                                        onClick={() => setSimScreen('splash')}
                                        className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${simScreen === 'splash' ? 'bg-orange-500 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'}`}
                                    >
                                        {t('demo_screen_1')}
                                    </button>
                                    <button
                                        onClick={() => setSimScreen('categories')}
                                        className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${simScreen === 'categories' ? 'bg-orange-500 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'}`}
                                    >
                                        {t('demo_screen_2')}
                                    </button>
                                    <button
                                        onClick={() => setSimScreen('store_detail')}
                                        className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${simScreen === 'store_detail' ? 'bg-orange-500 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'}`}
                                    >
                                        {t('demo_screen_3')}
                                    </button>
                                    <button
                                        onClick={() => setSimScreen('checkout')}
                                        className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${simScreen === 'checkout' ? 'bg-orange-500 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'}`}
                                    >
                                        {t('demo_screen_4')}
                                    </button>
                                    <button
                                        onClick={() => setSimScreen('order_status')}
                                        className={`px-4 py-2 rounded-xl text-xs font-bold transition-all ${simScreen === 'order_status' ? 'bg-orange-500 text-white' : 'bg-slate-800 text-slate-300 hover:bg-slate-700'}`}
                                    >
                                        {t('demo_screen_5')}
                                    </button>
                                </div>
                            </div>

                            {/* Kullanıcı Geribildirimi / Pop-up */}
                            <div className="bg-slate-800/80 border border-slate-700/50 p-5 rounded-2xl flex items-start space-x-4 max-w-md mx-auto lg:mx-0">
                                <div className="text-3xl">💡</div>
                                <div className="text-left space-y-1">
                                    <h5 className="font-bold text-sm text-slate-100">{t('demo_tip_title')}</h5>
                                    <p className="text-xs text-slate-400">
                                        {t('demo_tip_desc')}
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
                                                    {t('sim_splash_tagline')}
                                                </p>
                                            </div>

                                            <div className="w-full space-y-4 mb-4">
                                                {/* Yükleniyor Barı */}
                                                <div className="space-y-1.5 text-center">
                                                    <div className="w-3/4 bg-slate-100 h-1.5 rounded-full mx-auto overflow-hidden relative">
                                                        <div className="absolute top-0 bottom-0 left-0 bg-emerald-600 w-2/3 rounded-full animate-pulse"></div>
                                                    </div>
                                                    <span className="text-[10px] text-slate-400 block">{t('sim_splash_loading')}</span>
                                                </div>

                                                <button
                                                    onClick={() => setSimScreen('categories')}
                                                    className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-bold py-3 rounded-xl text-sm transition-all shadow-md shadow-emerald-600/10"
                                                >
                                                    {t('sim_splash_btn')}
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
                                                    {simScreen === 'categories' && t('sim_header_welcome')}
                                                    {simScreen === 'store_detail' && t('sim_header_store')}
                                                    {simScreen === 'product_detail' && t('sim_header_product_detail')}
                                                    {simScreen === 'delivery_info' && t('sim_header_delivery_info')}
                                                    {simScreen === 'checkout' && t('sim_header_checkout')}
                                                    {simScreen === 'order_status' && t('sim_header_order_status')}
                                                </span>
                                            </div>

                                            {/* Sağ İkon (Sepet durumu veya Profil) */}
                                            <div className="flex items-center space-x-2">
                                                {simScreen !== 'order_status' && simScreen !== 'checkout' && simScreen !== 'delivery_info' && (
                                                    <button
                                                        onClick={() => {
                                                            if (simCart.length > 0) setSimScreen('delivery_info');
                                                            else triggerToast(t('sim_toast_empty_cart'));
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
                                                        <div className="text-[10px] text-slate-400 font-semibold leading-none">{t('sim_delivery_address')}</div>
                                                        <span className="text-xs font-bold text-slate-700">{t('sim_address_home')}</span>
                                                    </div>
                                                </div>
                                                <span className="text-xs text-slate-400">▼</span>
                                            </div>

                                            {/* Başlık */}
                                            <div className="text-left">
                                                <h4 className="text-sm font-bold text-slate-800">{t('sim_cat_heading')}</h4>
                                            </div>

                                            {/* Kategoriler Grid */}
                                            <div className="grid grid-cols-2 gap-3">
                                                {CATEGORIES.map((cat) => {
                                                    const badgeText = cat.badge === 'POPÜLER' ? (locale === 'tr' ? 'POPÜLER' : locale === 'en' ? 'POPULAR' : 'ПОПУЛЯРНО') : cat.badge === 'YENİ' ? (locale === 'tr' ? 'YENİ' : locale === 'en' ? 'NEW' : 'НОВОЕ') : cat.badge;
                                                    return (
                                                        <div
                                                            key={cat.id}
                                                            onClick={() => cat.id === 'market' || cat.id === 'su' ? setSimScreen('store_detail') : triggerToast(`${getCategoryTitle(cat.id)} ${t('sim_cat_inactive_toast')}`)}
                                                            className="bg-white p-3 rounded-2xl border border-slate-100 shadow-sm flex flex-col justify-between items-start h-28 cursor-pointer relative hover:border-emerald-500/50 hover:shadow-md transition-all group"
                                                        >
                                                            {cat.badge && (
                                                                <span className="absolute top-2 right-2 bg-orange-500 text-white text-[8px] px-1.5 py-0.5 rounded-full font-black">
                                                                    {badgeText}
                                                                </span>
                                                            )}
                                                            <div className="text-2xl">{cat.icon}</div>
                                                            <div className="text-left">
                                                                <div className="text-xs font-bold text-slate-800">{getCategoryTitle(cat.id)}</div>
                                                                <div className="text-[8px] text-slate-400 line-clamp-1">{getCategoryDesc(cat.id)}</div>
                                                            </div>
                                                        </div>
                                                    );
                                                })}
                                            </div>

                                            {/* Alt Bilgi Banner */}
                                            <div className="bg-gradient-to-r from-orange-500 to-amber-500 p-3 rounded-2xl text-white text-left space-y-1">
                                                <div className="text-xs font-bold">{t('sim_banner_title')}</div>
                                                <p className="text-[9px] text-orange-50/80">{t('sim_banner_desc')}</p>
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
                                                    <h4 className="text-sm font-extrabold text-slate-800">{t('sim_header_store')}</h4>
                                                    <span className="text-[10px] text-emerald-600 font-bold bg-emerald-50 px-2 py-0.5 rounded">{t('sim_store_open')}</span>
                                                </div>
                                                <p className="text-[10px] text-slate-400">{t('sim_store_desc')}</p>

                                                {/* Hızlı Detaylar */}
                                                <div className="grid grid-cols-3 gap-1 pt-1 border-t border-slate-50 text-center">
                                                    <div className="py-1">
                                                        <span className="text-[9px] text-slate-400 block">{t('sim_store_min')}</span>
                                                        <span className="text-xs font-bold text-slate-700">100 ₺</span>
                                                    </div>
                                                    <div className="py-1 border-x border-slate-100">
                                                        <span className="text-[9px] text-slate-400 block">{t('sim_store_time')}</span>
                                                        <span className="text-xs font-bold text-slate-700">{t('sim_store_time_val')}</span>
                                                    </div>
                                                    <div className="py-1">
                                                        <span className="text-[9px] text-slate-400 block">{t('sim_store_dist')}</span>
                                                        <span className="text-xs font-bold text-slate-700">0.0 km</span>
                                                    </div>
                                                </div>
                                            </div>

                                            {/* Kategori Filtreleri */}
                                            <div className="px-4 py-2 flex space-x-1.5 overflow-x-auto bg-white border-b border-slate-50">
                                                <span className="bg-emerald-600 text-white text-[10px] px-3 py-1 rounded-full font-bold whitespace-nowrap">{t('sim_store_all')}</span>
                                                <span className="bg-slate-100 text-slate-600 text-[10px] px-3 py-1 rounded-full font-medium whitespace-nowrap">{t('sim_store_cat1')}</span>
                                                <span className="bg-slate-100 text-slate-600 text-[10px] px-3 py-1 rounded-full font-medium whitespace-nowrap">{t('sim_store_cat2')}</span>
                                                <span className="bg-slate-100 text-slate-600 text-[10px] px-3 py-1 rounded-full font-medium whitespace-nowrap">{t('sim_store_cat3')}</span>
                                            </div>

                                            {/* Ürünler Grid */}
                                            <div className="p-3 grid grid-cols-2 gap-3">
                                                {PRODUCTS.map((prod) => {
                                                    const inCartQty = getProductQty(prod.id);
                                                    const productName = getProductFieldName(prod.id, 'name');
                                                    const productBrand = getProductFieldName(prod.id, 'brand');
                                                    return (
                                                        <div
                                                            key={prod.id}
                                                            className="bg-white rounded-2xl border border-slate-100 p-2 shadow-sm flex flex-col justify-between cursor-pointer group"
                                                        >
                                                            <div onClick={() => { setSimProduct(prod); setSimScreen('product_detail'); }} className="relative h-24 bg-slate-100 rounded-xl overflow-hidden mb-2">
                                                                <img src={prod.image} alt={productName} className="w-full h-full object-cover group-hover:scale-105 transition-transform" />
                                                            </div>
                                                            <div onClick={() => { setSimProduct(prod); setSimScreen('product_detail'); }} className="text-left mb-2">
                                                                <div className="text-[9px] font-semibold text-slate-400">{productBrand}</div>
                                                                <h5 className="text-[11px] font-bold text-slate-800 line-clamp-1">{productName}</h5>
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
                                                                            triggerToast(`${productName} ${t('sim_toast_added')}`);
                                                                        }}
                                                                        className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-bold py-1.5 rounded-xl text-[10px] transition-all flex items-center justify-center space-x-1"
                                                                    >
                                                                        <span>{t('sim_add_to_cart')}</span>
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
                                                        <span className="text-[9px] text-slate-400 block font-semibold">{t('sim_cart_total_lbl')}</span>
                                                        <span className="text-sm font-extrabold text-emerald-600">{cartTotal.toFixed(2)} ₺</span>
                                                    </div>
                                                    <button
                                                        onClick={() => setSimScreen('delivery_info')}
                                                        className="bg-orange-500 hover:bg-orange-600 text-white font-bold px-6 py-2 rounded-xl text-xs flex items-center space-x-1.5 shadow-md shadow-orange-500/10 transition-all active:scale-95"
                                                    >
                                                        <span>{t('sim_cart_btn_checkout')}</span>
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
                                                <img src={simProduct.image} alt={getProductFieldName(simProduct.id, 'name')} className="w-full h-full object-cover" />
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
                                                    {getProductFieldName(simProduct.id, 'brand')}
                                                </span>
                                                <h4 className="text-sm font-extrabold text-slate-800">{getProductFieldName(simProduct.id, 'name')}</h4>
                                                <div className="text-lg font-black text-emerald-600">{simProduct.price.toFixed(2)} ₺ <span className="text-[10px] text-slate-400 font-normal">{t('sim_product_unit')}</span></div>
                                            </div>

                                            {/* Ürün Açıklaması */}
                                            <div className="text-left space-y-1.5 border-t border-slate-100 pt-3">
                                                <h5 className="text-xs font-bold text-slate-700">{t('sim_product_desc_lbl')}</h5>
                                                <p className="text-[10px] text-slate-500 leading-relaxed">{getProductFieldName(simProduct.id, 'desc')}</p>
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
                                                        triggerToast(t('sim_toast_cart_updated'));
                                                    }}
                                                    className="bg-emerald-600 hover:bg-emerald-700 text-white font-bold px-6 py-3 rounded-xl text-xs transition-all flex items-center space-x-2"
                                                >
                                                    <ShoppingBag size={14} />
                                                    <span>{t('sim_add_to_cart')}</span>
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
                                                    <span>{t('sim_delivery_method')}</span>
                                                </span>
                                                <div className="bg-slate-100 p-1 rounded-xl grid grid-cols-2 gap-1">
                                                    <button
                                                        onClick={() => setSimDeliveryMethod('eve_teslim')}
                                                        className={`py-2 rounded-lg text-xs font-bold transition-all ${simDeliveryMethod === 'eve_teslim' ? 'bg-white text-emerald-600 shadow-sm' : 'text-slate-500'}`}
                                                    >
                                                        {t('sim_delivery_method_home')}
                                                    </button>
                                                    <button
                                                        onClick={() => setSimDeliveryMethod('gel_al')}
                                                        className={`py-2 rounded-lg text-xs font-bold transition-all ${simDeliveryMethod === 'gel_al' ? 'bg-white text-emerald-600 shadow-sm' : 'text-slate-500'}`}
                                                    >
                                                        {t('sim_delivery_method_pickup')}
                                                    </button>
                                                </div>
                                            </div>

                                            {/* Teslimat Adresi */}
                                            <div className="space-y-2 text-left">
                                                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider flex items-center space-x-1">
                                                    <span>📍</span>
                                                    <span>{simDeliveryMethod === 'eve_teslim' ? t('sim_delivery_address') : t('sim_store_address')}</span>
                                                </span>
                                                <div className="bg-white p-3 rounded-2xl border border-slate-100 shadow-sm flex items-start space-x-3">
                                                    <div className="bg-emerald-50 text-emerald-600 p-2 rounded-xl flex-shrink-0">
                                                        {simDeliveryMethod === 'eve_teslim' ? '🏠' : '🏬'}
                                                    </div>
                                                    <div className="space-y-0.5">
                                                        <div className="text-xs font-bold text-slate-800">
                                                            {simDeliveryMethod === 'eve_teslim' ? t('sim_address_home_val') : t('sim_header_store')}
                                                        </div>
                                                        <p className="text-[10px] text-slate-500 leading-tight">
                                                            {simDeliveryMethod === 'eve_teslim' ? t('contact_office_val') : t('sim_store_desc')}
                                                        </p>
                                                    </div>
                                                </div>
                                                <span className="text-[9px] text-slate-400 block leading-tight">
                                                    {simDeliveryMethod === 'eve_teslim' ? t('sim_delivery_home_warn') : t('sim_delivery_pickup_warn')}
                                                </span>
                                            </div>

                                            {/* İletişim */}
                                            <div className="space-y-2 text-left">
                                                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider flex items-center space-x-1">
                                                    <span>📞</span>
                                                    <span>{t('sim_contact_lbl')}</span>
                                                </span>
                                                <div className="bg-white p-3 rounded-2xl border border-slate-100 shadow-sm flex items-center justify-between">
                                                    <div className="flex items-center space-x-3">
                                                        <div className="bg-emerald-50 text-emerald-600 p-2 rounded-xl">
                                                            📞
                                                        </div>
                                                        <div>
                                                            <div className="text-[10px] text-slate-400 font-semibold leading-none">{t('sim_contact_phone_lbl')}</div>
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
                                                    <span>{simDeliveryMethod === 'eve_teslim' ? t('sim_time_delivery') : t('sim_time_prepare')}</span>
                                                </span>
                                                <div className="bg-slate-100 p-1 rounded-xl grid grid-cols-2 gap-1">
                                                    <button
                                                        onClick={() => setSimDeliveryTime('hemen')}
                                                        className={`py-2 rounded-lg text-xs font-bold transition-all ${simDeliveryTime === 'hemen' ? 'bg-white text-emerald-600 shadow-sm' : 'text-slate-500'}`}
                                                    >
                                                        {t('sim_time_now')}
                                                    </button>
                                                    <button
                                                        onClick={() => setSimDeliveryTime('randevulu')}
                                                        className={`py-2 rounded-lg text-xs font-bold transition-all ${simDeliveryTime === 'randevulu' ? 'bg-white text-emerald-600 shadow-sm' : 'text-slate-500'}`}
                                                    >
                                                        {t('sim_time_scheduled')}
                                                    </button>
                                                </div>
                                            </div>

                                            {/* Tahmini Süre Banner */}
                                            <div className="bg-emerald-50 border border-emerald-100 p-3.5 rounded-2xl flex items-center space-x-3 text-left">
                                                <span className="text-xl animate-bounce">🚀</span>
                                                <div>
                                                    <div className="text-[10px] text-emerald-800 font-semibold leading-none">
                                                        {simDeliveryMethod === 'eve_teslim' ? t('sim_eta_delivery_lbl') : t('sim_eta_prepare_lbl')}
                                                    </div>
                                                    <span className="text-xs font-bold text-emerald-700">
                                                        {simDeliveryMethod === 'eve_teslim' ? t('sim_eta_delivery_val') : t('sim_eta_prepare_val')}
                                                    </span>
                                                </div>
                                            </div>

                                             {/* Ödemeye Geç Butonu */}
                                             <button
                                                 onClick={() => setSimScreen('checkout')}
                                                 className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-black py-4 rounded-2xl text-xs tracking-wider uppercase shadow-lg shadow-emerald-600/10 transition-all active:scale-95 mt-auto"
                                             >
                                                 {t('sim_checkout_proceed')}
                                             </button>
                                         </div>
                                     )}

                                    {/* 5. ÖDEME VE ONAY EKRANI */}
                                    {simScreen === 'checkout' && (
                                        <div className="flex-1 overflow-y-auto flex flex-col p-4 space-y-4">

                                            {/* Sipariş Notu Girişi */}
                                            <div className="bg-white p-3.5 rounded-2xl border border-slate-100 shadow-sm text-left space-y-2">
                                                <label className="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">{t('sim_checkout_note_lbl')}</label>
                                                <input
                                                    type="text"
                                                    value={simOrderNote}
                                                    onChange={(e) => setSimOrderNote(e.target.value)}
                                                    placeholder={t('sim_checkout_note_placeholder')}
                                                    className="w-full bg-slate-50 border border-slate-100 rounded-xl p-2.5 text-xs text-slate-700 focus:outline-none focus:border-emerald-500"
                                                />
                                            </div>

                                            {/* Teslimat Zamanı Bilgisi */}
                                            <div className="bg-white p-3.5 rounded-2xl border border-slate-100 shadow-sm text-left flex items-center justify-between">
                                                <div>
                                                    <span className="text-[9px] text-slate-400 block font-semibold">{t('sim_delivery_method')}</span>
                                                    <span className="text-xs font-extrabold text-slate-700">
                                                        {simDeliveryMethod === 'eve_teslim' ? t('sim_checkout_delivery_home') : t('sim_checkout_delivery_pickup')} ({simDeliveryTime === 'hemen' ? t('sim_time_now') : t('sim_time_scheduled')})
                                                    </span>
                                                </div>
                                                <span className="text-xs text-emerald-600 font-bold bg-emerald-50 px-2 py-0.5 rounded">
                                                    {simDeliveryMethod === 'eve_teslim' ? (locale === 'tr' ? '25-45 Dk' : locale === 'en' ? '25-45 Min' : '25-45 мин') : (locale === 'tr' ? '15-20 Dk' : locale === 'en' ? '15-20 Min' : '15-20 мин')}
                                                </span>
                                            </div>

                                            {/* Ödeme Yöntemi Seçimi */}
                                            <div className="bg-white p-3.5 rounded-2xl border border-slate-100 shadow-sm text-left space-y-3">
                                                <label className="text-[10px] font-bold text-slate-500 uppercase tracking-wider block">{t('sim_checkout_pay_method')}</label>

                                                <div className="grid grid-cols-2 gap-2">
                                                    <button
                                                        onClick={() => setSimPaymentMethod('online_kart')}
                                                        className={`p-2.5 rounded-xl border text-center flex flex-col items-center justify-center space-y-1 transition-all ${simPaymentMethod === 'online_kart' ? 'border-emerald-500 bg-emerald-50/50 text-emerald-800 font-bold' : 'border-slate-100 text-slate-500 hover:bg-slate-50'}`}
                                                    >
                                                        <span className="text-sm">💳</span>
                                                        <span className="text-[10px]">{t('sim_checkout_pay_card')}</span>
                                                    </button>

                                                    <button
                                                        onClick={() => setSimPaymentMethod('kapida_nakit')}
                                                        className={`p-2.5 rounded-xl border text-center flex flex-col items-center justify-center space-y-1 transition-all ${simPaymentMethod === 'kapida_nakit' ? 'border-emerald-500 bg-emerald-50/50 text-emerald-800 font-bold' : 'border-slate-100 text-slate-500 hover:bg-slate-50'}`}
                                                    >
                                                        <span className="text-sm">💵</span>
                                                        <span className="text-[10px]">{t('sim_checkout_pay_cash')}</span>
                                                    </button>
                                                </div>

                                                {/* Alt Ödeme Detayı (Kapıda ödeme ise nakit mi kart mı?) */}
                                                {simPaymentMethod === 'kapida_nakit' && (
                                                    <div className="pt-2 border-t border-slate-50 flex space-x-2">
                                                        <span className="bg-emerald-50 text-emerald-800 text-[9px] px-2.5 py-1 rounded-lg font-bold border border-emerald-200">
                                                            {t('sim_checkout_pay_cash_val')}
                                                        </span>
                                                        <span className="bg-slate-50 text-slate-400 text-[9px] px-2.5 py-1 rounded-lg font-semibold cursor-not-allowed">
                                                            {t('sim_checkout_pay_card_val')}
                                                        </span>
                                                    </div>
                                                )}
                                            </div>

                                            {/* Sipariş Özeti */}
                                            <div className="bg-white p-3.5 rounded-2xl border border-slate-100 shadow-sm text-left space-y-3">
                                                <div className="flex justify-between items-center pb-2 border-b border-slate-50">
                                                    <span className="text-xs font-bold text-slate-800">{t('sim_checkout_summary_title')}</span>
                                                    <span className="text-[10px] text-slate-400 font-semibold">{simCart.reduce((sum, item) => sum + item.qty, 0)} {t('sim_checkout_items_count')}</span>
                                                </div>

                                                <div className="space-y-1.5 text-xs text-slate-600">
                                                    {simCart.map((item) => (
                                                        <div key={item.id} className="flex justify-between">
                                                            <span>{item.qty}x {getProductFieldName(item.id, 'name')}</span>
                                                            <span>{(item.price * item.qty).toFixed(2)} ₺</span>
                                                        </div>
                                                    ))}
                                                </div>

                                                <div className="pt-2 border-t border-slate-100 space-y-1 text-xs">
                                                    <div className="flex justify-between text-slate-500">
                                                        <span>{t('sim_checkout_subtotal')}</span>
                                                        <span>{cartSubtotal.toFixed(2)} ₺</span>
                                                    </div>
                                                    <div className="flex justify-between text-emerald-600 font-semibold">
                                                        <span>{t('sim_checkout_shipping')}</span>
                                                        <span>{t('sim_checkout_shipping_free')}</span>
                                                    </div>
                                                    <div className="flex justify-between text-sm font-extrabold text-slate-800 pt-1.5">
                                                        <span>{t('sim_checkout_total')}</span>
                                                        <span>{cartTotal.toFixed(2)} ₺</span>
                                                    </div>
                                                </div>
                                            </div>

                                            {/* Siparişi Tamamla Butonu */}
                                            <button
                                                onClick={() => setSimScreen('order_status')}
                                                className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-black py-4 rounded-2xl text-xs tracking-wider uppercase shadow-lg shadow-emerald-600/10 transition-all active:scale-95"
                                            >
                                                {t('sim_cart_btn_checkout')}
                                            </button>

                                        </div>
                                    )}

                                    {/* 6. SİPARİŞ DURUMU / CANLI HARİTA TAKİBİ */}
                                    {simScreen === 'order_status' && (
                                        <div className="flex-1 overflow-y-auto flex flex-col p-4 space-y-4">

                                            {/* Sipariş Durum Timeline'ı */}
                                            <div className="bg-white p-4 rounded-2xl border border-slate-100 shadow-sm text-left space-y-4">
                                                <h5 className="text-xs font-bold text-slate-800 leading-none">{t('sim_status_title')}</h5>

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
                                                            <span className="text-[8px] mt-1 font-bold text-slate-600">{t('sim_status_step0')}</span>
                                                        </div>

                                                        {/* Hazırlanıyor */}
                                                        <div className="flex flex-col items-center">
                                                            <span className={`w-4 h-4 rounded-full flex items-center justify-center text-[8px] font-bold ${orderStep >= 1 ? 'bg-emerald-500 text-white' : 'bg-slate-200'}`}>
                                                                {orderStep >= 1 ? '✓' : '2'}
                                                            </span>
                                                            <span className="text-[8px] mt-1 font-bold text-slate-600">{t('sim_status_step1')}</span>
                                                        </div>

                                                        {/* Yolda */}
                                                        <div className="flex flex-col items-center">
                                                            <span className={`w-4 h-4 rounded-full flex items-center justify-center text-[8px] font-bold ${orderStep >= 2 ? 'bg-emerald-500 text-white' : 'bg-slate-200'}`}>
                                                                {orderStep >= 2 ? '✓' : '3'}
                                                            </span>
                                                            <span className="text-[8px] mt-1 font-bold text-slate-600">{t('sim_status_step2')}</span>
                                                        </div>

                                                        {/* Teslim Edildi */}
                                                        <div className="flex flex-col items-center">
                                                            <span className={`w-4 h-4 rounded-full flex items-center justify-center text-[8px] font-bold ${orderStep >= 3 ? 'bg-emerald-500 text-white' : 'bg-slate-200'}`}>
                                                                {orderStep >= 3 ? '✓' : '4'}
                                                            </span>
                                                            <span className="text-[8px] mt-1 font-bold text-slate-600">{t('sim_status_step3')}</span>
                                                        </div>
                                                    </div>
                                                </div>

                                                {/* Sipariş Tarihi / ID */}
                                                <div className="text-center pt-2 border-t border-slate-50 space-y-1">
                                                    <div className="text-[9px] text-slate-400">25 Jun 2026, 17:43</div>
                                                    <div className="text-[10px] font-bold text-slate-700">{t('sim_status_no')}: #FD6FE83B</div>
                                                </div>

                                                {/* Takip / Yol Tarifi Butonu */}
                                                {simDeliveryMethod === 'eve_teslim' ? (
                                                    <div className="bg-emerald-600 text-white p-3.5 rounded-xl text-center font-bold text-xs flex items-center justify-center space-x-2 relative overflow-hidden shadow-md shadow-emerald-600/10">
                                                        <span className="animate-bounce">🛵</span>
                                                        <span>{t('sim_status_track_btn')}</span>
                                                    </div>
                                                ) : (
                                                    <div className="bg-orange-500 text-white p-3.5 rounded-xl text-center font-bold text-xs flex items-center justify-center space-x-2 relative overflow-hidden shadow-md shadow-orange-500/10">
                                                        <span>📍</span>
                                                        <span>{t('sim_status_directions_btn')}</span>
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
                                                        {simDeliveryMethod === 'eve_teslim' ? t('sim_map_market') : t('sim_map_home')}
                                                    </span>
                                                </div>

                                                {/* Bitiş Noktası (Sağ) */}
                                                <div className="absolute bottom-8 right-10 bg-emerald-50 p-1.5 rounded-xl border border-emerald-300 shadow-sm z-10 text-center">
                                                    <span className="text-sm">{simDeliveryMethod === 'eve_teslim' ? '🏠' : '🏬'}</span>
                                                    <span className="text-[7px] block font-black text-emerald-700">
                                                        {simDeliveryMethod === 'eve_teslim' ? t('sim_map_home') : t('sim_map_pickup')}
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
                                                        orderStep === 3 ? t('sim_map_alert_delivery_done') : t('sim_map_alert_delivery_road')
                                                    ) : (
                                                        orderStep === 3 ? t('sim_map_alert_pickup_done') : t('sim_map_alert_pickup_prep')
                                                    )}
                                                </div>
                                            </div>

                                            {/* Sipariş İçeriği Özeti */}
                                            <div className="bg-white p-3.5 rounded-2xl border border-slate-100 shadow-sm text-left space-y-2">
                                                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block">{t('sim_status_items_lbl')}</span>
                                                <div className="space-y-2">
                                                    {simCart.map((item) => (
                                                        <div key={item.id} className="flex justify-between text-xs">
                                                            <span className="text-slate-600 font-medium">
                                                                <span className="text-orange-500 font-bold bg-orange-50 px-1.5 py-0.5 rounded mr-1.5 text-[9px]">{item.qty}x</span>
                                                                {getProductFieldName(item.id, 'name')}
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
                                                        <span className="text-[9px] text-yellow-800 font-bold uppercase block">{t('sim_status_note_lbl')}</span>
                                                        <p className="text-[10px] text-slate-600 italic">&quot;{simOrderNote}&quot;</p>
                                                    </div>
                                                )}

                                                <div className="flex justify-between items-center pt-2 border-t border-slate-100">
                                                    <span className="text-xs font-bold text-slate-500">{t('sim_status_paid')}</span>
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
                                                {t('sim_status_reset')}
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
            <section id="partners" className="py-24 bg-white scroll-animate">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">

                    <div className="text-center max-w-3xl mx-auto space-y-4 mb-16">
                        <h2 className="text-xs uppercase font-extrabold tracking-widest text-emerald-600">{t('partners_label')}</h2>
                        <p className="text-3xl sm:text-4xl font-extrabold text-slate-900">{t('partners_title')}</p>
                        <p className="text-slate-500">
                            {t('partners_desc')}
                        </p>
                    </div>

                    {/* Sekme Seçenekleri */}
                    <div className="flex justify-center mb-12">
                        <div className="bg-slate-100 p-1.5 rounded-2xl flex space-x-1">
                            <button
                                onClick={() => setActiveTab('user')}
                                className={`px-6 py-3 rounded-xl text-xs sm:text-sm font-bold transition-all ${activeTab === 'user' ? 'bg-emerald-600 text-white shadow' : 'text-slate-600 hover:text-slate-950'}`}
                            >
                                {t('partners_tab_merchant')}
                            </button>
                            <button
                                onClick={() => setActiveTab('partner')}
                                className={`px-6 py-3 rounded-xl text-xs sm:text-sm font-bold transition-all ${activeTab === 'partner' ? 'bg-emerald-600 text-white shadow' : 'text-slate-600 hover:text-slate-950'}`}
                            >
                                {t('partners_tab_courier')}
                            </button>
                        </div>
                    </div>

                    <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">

                        {/* Form ve Detaylar */}
                        {activeTab === 'user' ? (
                            <>
                                <div className="lg:col-span-6 space-y-6 text-left">
                                    <div className="bg-emerald-50 text-emerald-800 p-3 rounded-2xl inline-block font-bold text-xs">
                                        {t('partners_merchant_tag')}
                                    </div>
                                    <h3 className="text-2xl sm:text-3xl font-black text-slate-900 leading-tight">
                                        {t('partners_merchant_title')}
                                    </h3>
                                    <p className="text-slate-600">
                                        {t('partners_merchant_desc')}
                                    </p>

                                    <div className="space-y-3.5 pt-2">
                                        <div className="flex items-start space-x-3 text-sm text-slate-700">
                                            <span className="text-emerald-600 font-bold">✓</span>
                                            <span>{t('partners_merchant_bullet1')}</span>
                                        </div>
                                        <div className="flex items-start space-x-3 text-sm text-slate-700">
                                            <span className="text-emerald-600 font-bold">✓</span>
                                            <span>{t('partners_merchant_bullet2')}</span>
                                        </div>
                                        <div className="flex items-start space-x-3 text-sm text-slate-700">
                                            <span className="text-emerald-600 font-bold">✓</span>
                                            <span>{t('partners_merchant_bullet3')}</span>
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
                                                <h4 className="text-xl font-bold text-slate-800">{t('partners_merchant_success_title')}</h4>
                                                <p className="text-sm text-slate-500">
                                                    {t('partners_merchant_success_desc')}
                                                </p>
                                            </div>
                                        ) : (
                                            <form onSubmit={(e) => { e.preventDefault(); setPartnerSubmitted(true); }} className="space-y-4">
                                                <h4 className="font-extrabold text-lg text-slate-900 mb-2">{t('partners_merchant_form_title')}</h4>

                                                <div>
                                                    <label className="text-xs font-bold text-slate-500 mb-1.5 block">{t('partners_merchant_form_store')}</label>
                                                    <input required type="text" placeholder={t('partners_merchant_form_store_placeholder')} className="w-full bg-white border border-slate-200 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600" />
                                                </div>

                                                <div className="grid grid-cols-2 gap-4">
                                                    <div>
                                                        <label className="text-xs font-bold text-slate-500 mb-1.5 block">{t('partners_merchant_form_name')}</label>
                                                        <input required type="text" placeholder={t('partners_merchant_form_name_placeholder')} className="w-full bg-white border border-slate-200 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600" />
                                                    </div>
                                                    <div>
                                                        <label className="text-xs font-bold text-slate-500 mb-1.5 block">{t('partners_merchant_form_phone')}</label>
                                                        <input required type="tel" placeholder={t('partners_merchant_form_phone_placeholder')} className="w-full bg-white border border-slate-200 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600" />
                                                    </div>
                                                </div>

                                                <div>
                                                    <label className="text-xs font-bold text-slate-500 mb-1.5 block">{t('partners_merchant_form_cat')}</label>
                                                    <select className="w-full bg-white border border-slate-200 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600">
                                                        <option>{t('partners_merchant_form_cat1')}</option>
                                                        <option>{t('partners_merchant_form_cat2')}</option>
                                                        <option>{t('partners_merchant_form_cat3')}</option>
                                                        <option>{t('partners_merchant_form_cat4')}</option>
                                                        <option>{t('partners_merchant_form_cat5')}</option>
                                                    </select>
                                                </div>

                                                <button type="submit" className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-bold py-4 rounded-xl text-sm shadow-md transition-all">
                                                    {t('partners_merchant_form_btn')}
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
                                        {t('partners_courier_tag')}
                                    </div>
                                    <h3 className="text-2xl sm:text-3xl font-black text-slate-900 leading-tight">
                                        {t('partners_courier_title')}
                                    </h3>
                                    <p className="text-slate-600">
                                        {t('partners_courier_desc')}
                                    </p>

                                    <div className="space-y-3.5 pt-2">
                                        <div className="flex items-start space-x-3 text-sm text-slate-700">
                                            <span className="text-orange-500 font-bold">✓</span>
                                            <span>{t('partners_courier_bullet1')}</span>
                                        </div>
                                        <div className="flex items-start space-x-3 text-sm text-slate-700">
                                            <span className="text-orange-500 font-bold">✓</span>
                                            <span>{t('partners_courier_bullet2')}</span>
                                        </div>
                                        <div className="flex items-start space-x-3 text-sm text-slate-700">
                                            <span className="text-orange-500 font-bold">✓</span>
                                            <span>{t('partners_courier_bullet3')}</span>
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
                                                <h4 className="text-xl font-bold text-slate-800">{t('partners_courier_success_title')}</h4>
                                                <p className="text-sm text-slate-500">
                                                    {t('partners_courier_success_desc')}
                                                </p>
                                            </div>
                                        ) : (
                                            <form onSubmit={(e) => { e.preventDefault(); setCourierSubmitted(true); }} className="space-y-4">
                                                <h4 className="font-extrabold text-lg text-slate-900 mb-2">{t('partners_courier_form_title')}</h4>

                                                <div className="grid grid-cols-2 gap-4">
                                                    <div>
                                                        <label className="text-xs font-bold text-slate-500 mb-1.5 block">{t('partners_courier_form_name')}</label>
                                                        <input required type="text" placeholder={t('partners_courier_form_name_placeholder')} className="w-full bg-white border border-slate-200 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600" />
                                                    </div>
                                                    <div>
                                                        <label className="text-xs font-bold text-slate-500 mb-1.5 block">{t('partners_courier_form_phone')}</label>
                                                        <input required type="tel" placeholder={t('partners_courier_form_phone_placeholder')} className="w-full bg-white border border-slate-200 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600" />
                                                    </div>
                                                </div>

                                                <div>
                                                    <label className="text-xs font-bold text-slate-500 mb-1.5 block">{t('partners_courier_form_vehicle')}</label>
                                                    <select className="w-full bg-white border border-slate-200 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600">
                                                        <option>{t('partners_courier_form_vehicle1')}</option>
                                                        <option>{t('partners_courier_form_vehicle2')}</option>
                                                        <option>{t('partners_courier_form_vehicle3')}</option>
                                                    </select>
                                                </div>

                                                <div>
                                                    <label className="text-xs font-bold text-slate-500 mb-1.5 block">{t('partners_courier_form_license')}</label>
                                                    <select className="w-full bg-white border border-slate-200 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600">
                                                        <option>{t('partners_courier_form_license1')}</option>
                                                        <option>{t('partners_courier_form_license2')}</option>
                                                        <option>{t('partners_courier_form_license3')}</option>
                                                    </select>
                                                </div>

                                                <button type="submit" className="w-full bg-orange-500 hover:bg-orange-600 text-white font-bold py-4 rounded-xl text-sm shadow-md transition-all">
                                                    {t('partners_courier_form_btn')}
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
            <section id="contact" className="py-20 bg-slate-50 border-t border-slate-100 scroll-animate">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-12 items-center">

                        <div className="text-left space-y-6">
                            <h3 className="text-3xl font-extrabold text-slate-900">
                                {t('contact_title_1')} <br />
                                {t('contact_title_2')}
                            </h3>
                            <p className="text-slate-600 leading-relaxed">
                                {t('contact_desc')}
                            </p>

                            <div className="space-y-4 pt-2">
                                <div className="flex items-center space-x-4">
                                    <div className="w-12 h-12 rounded-xl bg-white border border-slate-200 flex items-center justify-center text-emerald-600">
                                        <Phone size={20} />
                                    </div>
                                    <div>
                                        <span className="text-xs text-slate-400 block font-semibold">{t('contact_phone_lbl')}</span>
                                        <a href="tel:05338765432" className="text-sm font-bold text-slate-800 hover:text-emerald-600">0533 876 54 32</a>
                                    </div>
                                </div>

                                <div className="flex items-center space-x-4">
                                    <div className="w-12 h-12 rounded-xl bg-white border border-slate-200 flex items-center justify-center text-emerald-600">
                                        <MapPin size={20} />
                                    </div>
                                    <div>
                                        <span className="text-xs text-slate-400 block font-semibold">{t('contact_office_lbl')}</span>
                                        <span className="text-sm font-bold text-slate-800">{t('contact_office_val')}</span>
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
                                    <h4 className="text-xl font-bold text-slate-800">{t('contact_success_title')}</h4>
                                    <p className="text-sm text-slate-500">
                                        {t('contact_success_desc')}
                                    </p>
                                </div>
                            ) : (
                                <form onSubmit={(e) => { e.preventDefault(); setContactSubmitted(true); }} className="space-y-4">
                                    <h4 className="font-extrabold text-lg text-slate-900 mb-2">{t('contact_form_title')}</h4>

                                    <div>
                                        <label className="text-xs font-bold text-slate-500 mb-1.5 block">{t('contact_form_name')}</label>
                                        <input required type="text" placeholder={t('contact_form_name_placeholder')} className="w-full bg-slate-50 border border-slate-100 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600" />
                                    </div>

                                    <div>
                                        <label className="text-xs font-bold text-slate-500 mb-1.5 block">{t('contact_form_email')}</label>
                                        <input required type="email" placeholder={t('contact_form_email_placeholder')} className="w-full bg-slate-50 border border-slate-100 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600" />
                                    </div>

                                    <div>
                                        <label className="text-xs font-bold text-slate-500 mb-1.5 block">{t('contact_form_msg')}</label>
                                        <textarea required rows={4} placeholder={t('contact_form_msg_placeholder')} className="w-full bg-slate-50 border border-slate-100 rounded-xl p-3 text-sm focus:outline-none focus:border-emerald-600"></textarea>
                                    </div>

                                    <button type="submit" className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-bold py-4 rounded-xl text-sm shadow-md transition-all">
                                        {t('contact_form_btn')}
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
                            <div className="flex items-center cursor-pointer" onClick={() => { setSimScreen('splash'); window.scrollTo({ top: 0, behavior: 'smooth' }); }}>
                                <img src="/logo-color.png" alt="Hoppa Logo" className="h-10 w-auto object-contain brightness-0 invert" />
                            </div>
                            <p className="text-xs text-slate-400 leading-relaxed">
                                {t('footer_desc')}
                            </p>
                        </div>

                        {/* Hızlı Linkler */}
                        <div className="text-left space-y-3">
                            <h4 className="text-xs font-extrabold uppercase tracking-widest text-slate-400">{t('footer_corporate')}</h4>
                            <ul className="space-y-2 text-xs text-slate-300">
                                <li><a href="#features" className="hover:text-emerald-400 transition-colors">{t('footer_link_who')}</a></li>
                                <li><a href="#partners" onClick={() => setActiveTab('user')} className="hover:text-emerald-400 transition-colors">{t('footer_link_merchant')}</a></li>
                                <li><a href="#partners" onClick={() => setActiveTab('partner')} className="hover:text-emerald-400 transition-colors">{t('footer_link_courier')}</a></li>
                                <li><a href="#contact" className="hover:text-emerald-400 transition-colors">{t('footer_link_terms')}</a></li>
                            </ul>
                        </div>

                        {/* İletişim Bilgileri */}
                        <div className="text-left space-y-3">
                            <h4 className="text-xs font-extrabold uppercase tracking-widest text-slate-400">{t('footer_contact')}</h4>
                            <ul className="space-y-2 text-xs text-slate-300">
                                <li>{t('footer_contact_support')}</li>
                                <li>{t('footer_contact_pr')}</li>
                                <li>{t('footer_contact_phone')}</li>
                                <li>{t('footer_contact_addr')}</li>
                            </ul>
                        </div>

                        {/* Mobil Mağazalar */}
                        <div className="text-left space-y-3">
                            <h4 className="text-xs font-extrabold uppercase tracking-widest text-slate-400">{t('footer_download')}</h4>
                            <div className="space-y-2">
                                <a
                                    href="#interactive-demo"
                                    className="bg-slate-800 hover:bg-slate-750 text-white text-[10px] px-4 py-2.5 rounded-xl font-bold flex items-center justify-center space-x-2 border border-slate-700"
                                >
                                    <span>{t('footer_download_ios')}</span>
                                </a>
                                <a
                                    href="#interactive-demo"
                                    className="bg-slate-800 hover:bg-slate-750 text-white text-[10px] px-4 py-2.5 rounded-xl font-bold flex items-center justify-center space-x-2 border border-slate-700"
                                >
                                    <span>{t('footer_download_android')}</span>
                                </a>
                            </div>
                        </div>

                    </div>

                    <div className="pt-8 flex flex-col sm:flex-row items-center justify-between text-xs text-slate-400 space-y-4 sm:space-y-0">
                        <span>{t('footer_rights')}</span>
                        <div className="flex space-x-4">
                            <a href="#privacy" className="hover:text-slate-200 transition-colors">{t('footer_link_privacy')}</a>
                            <a href="#data-protection" className="hover:text-slate-200 transition-colors">{t('footer_link_kvkk')}</a>
                            <a href="#cookie-policy" className="hover:text-slate-200 transition-colors">{t('footer_link_cookie')}</a>
                        </div>
                    </div>

                </div>
            </footer>

        </div>
    );
}
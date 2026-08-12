import React, { useEffect, useState } from 'react';
import Head from 'next/head';
import { useRouter } from 'next/router';
import { 
  Store, Package, ShoppingBag, BarChart3, Settings, LogOut, 
  ChevronRight, Power, Menu, X, Sun, Moon 
} from 'lucide-react';
import { getMerchantProfile, getMerchantToken, clearMerchantAuth, merchantApiFetch } from '../../utils/merchant-auth';
import { useMerchantTheme } from '../../context/MerchantThemeContext';

interface MerchantLayoutProps {
  children: React.ReactNode;
  title?: string;
  activeTab?: 'products' | 'orders' | 'dashboard' | 'settings';
}

export default function MerchantLayout({ children, title = 'Ürün Yönetimi', activeTab = 'products' }: MerchantLayoutProps) {
  const router = useRouter();
  const { theme, toggleTheme } = useMerchantTheme();
  const [profile, setProfile] = useState<any>(null);
  const [isShopActive, setIsShopActive] = useState<boolean>(true);
  const [isTogglingShop, setIsTogglingShop] = useState<boolean>(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState<boolean>(false);

  useEffect(() => {
    const token = getMerchantToken();
    const currentProfile = getMerchantProfile();

    if (!token || !currentProfile) {
      router.push('/merchant/login');
      return;
    }

    setProfile(currentProfile);
    fetchShopDetails();
  }, []);

  const fetchShopDetails = async () => {
    try {
      const res = await merchantApiFetch('/merchant/shop');
      if (res.data) {
        setIsShopActive(res.data.isActive ?? true);
      }
    } catch (err) {
      console.error('Dükkan detayları alınamadı:', err);
    }
  };

  const handleToggleShopStatus = async () => {
    setIsTogglingShop(true);
    try {
      const res = await merchantApiFetch('/merchant/shop/toggle-status', { method: 'POST' });
      if (res.data) {
        setIsShopActive(res.data.isActive);
      }
    } catch (err: any) {
      alert(err.message || 'Dükkan durumu değiştirilemedi.');
    } finally {
      setIsTogglingShop(false);
    }
  };

  const handleLogout = () => {
    clearMerchantAuth();
    router.push('/merchant/login');
  };

  const navItems = [
    { id: 'products', label: 'Ürün & Menü Portalı', icon: Package, href: '/merchant/products' },
    { id: 'orders', label: 'Canlı Siparişler', icon: ShoppingBag, href: '/merchant/orders' },
    { id: 'dashboard', label: 'Performans & Analiz', icon: BarChart3, href: '/merchant/dashboard' },
    { id: 'settings', label: 'Mağaza Ayarları', icon: Settings, href: '/merchant/settings' },
  ];

  const isDark = theme === 'dark';

  return (
    <>
      <Head>
        <title>{title} | Hoppa Satıcı Portalı</title>
      </Head>

      <div className={`min-h-screen flex flex-col md:flex-row font-sans transition-colors duration-300 ${
        isDark ? 'bg-slate-950 text-slate-100' : 'bg-slate-50 text-slate-900'
      }`}>
        {/* Mobile Header */}
        <div className={`md:hidden p-4 border-b flex items-center justify-between sticky top-0 z-40 transition-colors ${
          isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
        }`}>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-[#FF6B00] text-white font-bold flex items-center justify-center shadow-md shadow-[#FF6B00]/20">
              <Store className="w-6 h-6" />
            </div>
            <div>
              <h2 className="font-bold text-sm">{profile?.businessName || 'Hoppa Mağazası'}</h2>
              <span className="text-xs text-slate-400">Satıcı Yönetim Paneli</span>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button 
              onClick={toggleTheme}
              className="p-2 rounded-xl border text-xs font-bold"
            >
              {isDark ? <Sun className="w-5 h-5 text-amber-400" /> : <Moon className="w-5 h-5 text-slate-700" />}
            </button>
            <button 
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              className="p-2 rounded-xl bg-slate-100 dark:bg-slate-800"
            >
              {isMobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>
        </div>

        {/* Sidebar Navigation */}
        <aside className={`
          fixed md:static inset-y-0 left-0 z-50 w-72 border-r flex flex-col justify-between p-6 transform transition-all duration-300
          ${isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'}
          ${isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'}
        `}>
          <div>
            {/* Hoppa Branded Logo */}
            <div className="hidden md:flex items-center justify-between mb-8">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-2xl bg-[#FF6B00] text-white flex items-center justify-center font-black shadow-lg shadow-[#FF6B00]/30 ring-2 ring-[#FF6B00]/20">
                  <Store className="w-7 h-7 text-white" />
                </div>
                <div>
                  <h1 className="font-black text-xl tracking-tight">
                    Hoppa <span className="text-[#FF6B00]">Satıcı</span>
                  </h1>
                  <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider">Masaüstü Portal</span>
                </div>
              </div>

              {/* Header Theme Switch */}
              <button
                onClick={toggleTheme}
                className={`p-2 rounded-xl border transition-colors ${
                  isDark ? 'bg-slate-800 border-slate-700 text-amber-400' : 'bg-slate-100 border-slate-200 text-slate-600'
                }`}
                title={isDark ? 'Beyaz Temaya Geç' : 'Karanlık Temaya Geç'}
              >
                {isDark ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
              </button>
            </div>

            {/* Business Info & Live Status Toggle */}
            <div className={`border rounded-2xl p-4 mb-6 transition-colors ${
              isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
            }`}>
              <p className="text-[11px] font-extrabold text-slate-400 uppercase tracking-wider">Mağaza Adı</p>
              <h3 className="font-bold text-sm truncate mt-0.5">{profile?.businessName || 'Mağaza Yükleniyor...'}</h3>
              <div className="mt-3 pt-3 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
                <span className="text-xs font-bold text-slate-500">Sipariş Alımı:</span>
                <button
                  onClick={handleToggleShopStatus}
                  disabled={isTogglingShop}
                  className={`px-3 py-1 rounded-full text-xs font-bold flex items-center gap-1.5 transition-all ${
                    isShopActive 
                      ? 'bg-[#00A651]/15 text-[#00A651] border border-[#00A651]/30' 
                      : 'bg-rose-500/15 text-rose-500 border border-rose-500/30'
                  }`}
                >
                  <Power className={`w-3.5 h-3.5 ${isShopActive ? 'text-[#00A651]' : 'text-rose-500'}`} />
                  <span>{isShopActive ? 'AÇIK (Aktif)' : 'KAPALI'}</span>
                </button>
              </div>
            </div>

            {/* Navigation Links */}
            <nav className="space-y-1.5">
              {navItems.map((item) => {
                const Icon = item.icon;
                const isActive = activeTab === item.id;
                return (
                  <button
                    key={item.id}
                    onClick={() => router.push(item.href)}
                    className={`w-full flex items-center justify-between px-4 py-3.5 rounded-2xl text-sm font-bold transition-all ${
                      isActive 
                        ? 'bg-[#FF6B00] text-white shadow-lg shadow-[#FF6B00]/25' 
                        : isDark 
                          ? 'text-slate-400 hover:text-slate-100 hover:bg-slate-800' 
                          : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <Icon className={`w-5 h-5 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                      <span>{item.label}</span>
                    </div>
                    {isActive && <ChevronRight className="w-4 h-4 text-white" />}
                  </button>
                );
              })}
            </nav>
          </div>

          {/* Footer Info & Logout */}
          <div className="pt-6 border-t border-slate-200 dark:border-slate-800">
            <button
              onClick={handleLogout}
              className="w-full flex items-center gap-3 px-4 py-3 rounded-xl text-xs font-bold text-rose-500 hover:bg-rose-500/10 transition-colors"
            >
              <LogOut className="w-4 h-4" />
              <span>Güvenli Çıkış Yap</span>
            </button>
          </div>
        </aside>

        {/* Main Content Area */}
        <main className={`flex-1 min-w-0 overflow-y-auto p-4 md:p-8 transition-colors ${
          isDark ? 'bg-slate-950' : 'bg-slate-50'
        }`}>
          {children}
        </main>
      </div>
    </>
  );
}

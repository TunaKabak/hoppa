import React, { useEffect, useState } from 'react';
import Head from 'next/head';
import { useRouter } from 'next/router';
import { 
  Store, Package, ShoppingBag, BarChart3, Settings, LogOut, 
  ChevronRight, Power, Menu, X, Sun, Moon, Tag 
} from 'lucide-react';
import { 
  getMerchantProfile, getMerchantToken, clearMerchantAuth, merchantApiFetch, 
  getSelectedShopId, setSelectedShopId 
} from '../../utils/merchant-auth';
import { useMerchantTheme } from '../../context/MerchantThemeContext';

interface MerchantLayoutProps {
  children: React.ReactNode;
  title?: string;
  subtitle?: string;
  headerIcon?: React.ElementType;
  headerActions?: React.ReactNode;
  activeTab?: 'products' | 'orders' | 'dashboard' | 'campaigns' | 'settings';
}

export default function MerchantLayout({ 
  children, 
  title = 'Ürün Yönetimi', 
  subtitle,
  headerIcon: HeaderIcon,
  headerActions,
  activeTab = 'products' 
}: MerchantLayoutProps) {
  const router = useRouter();
  const { theme, toggleTheme } = useMerchantTheme();
  const [profile, setProfile] = useState<any>(null);
  const [isShopActive, setIsShopActive] = useState<boolean>(true);
  const [isTogglingShop, setIsTogglingShop] = useState<boolean>(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState<boolean>(false);
  const [pendingOrdersCount, setPendingOrdersCount] = useState<number>(0);
  const [allShops, setAllShops] = useState<any[]>([]);
  const [selectedShopIdState, setSelectedShopIdState] = useState<string>('');

  const isAdmin = profile?.role === 'super_admin' || profile?.role === 'admin';

  useEffect(() => {
    const token = getMerchantToken();
    const currentProfile = getMerchantProfile();

    if (!token || !currentProfile) {
      router.push('/merchant/login');
      return;
    }

    setProfile(currentProfile);
    setSelectedShopIdState(getSelectedShopId() || '');

    if (currentProfile.role === 'super_admin' || currentProfile.role === 'admin') {
      fetchAdminShops();
    }

    fetchShopDetails();
    fetchPendingOrders();
  }, []);

  const fetchAdminShops = async () => {
    try {
      const res = await merchantApiFetch('/consumer/shops');
      if (res.data && Array.isArray(res.data)) {
        setAllShops(res.data);
      }
    } catch (err) {
      console.error('Tüm dükkanlar alınamadı:', err);
    }
  };

  const handleShopChange = (shopId: string) => {
    setSelectedShopId(shopId || null);
    setSelectedShopIdState(shopId || '');
    router.reload();
  };

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

  const fetchPendingOrders = async () => {
    try {
      const res = await merchantApiFetch('/merchant/orders');
      if (res.data && Array.isArray(res.data)) {
        const pending = res.data.filter((o: any) => o.status === 'PENDING').length;
        setPendingOrdersCount(pending);
      }
    } catch (err) {
      console.error('Sipariş rozeti alınamadı:', err);
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
    { id: 'orders', label: 'Canlı Siparişler', icon: ShoppingBag, href: '/merchant/orders', badge: pendingOrdersCount },
    { id: 'dashboard', label: 'Performans & Analiz', icon: BarChart3, href: '/merchant/dashboard' },
    { id: 'campaigns', label: 'Kampanya & Reklam', icon: Tag, href: '/merchant/campaigns' },
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
            <div className="w-10 h-10 rounded-2xl bg-[#FF6B00] text-white font-bold flex items-center justify-center">
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
          fixed md:sticky md:top-0 md:h-screen inset-y-0 left-0 z-50 w-72 shrink-0 border-r flex flex-col justify-between p-6 overflow-y-auto transform transition-all duration-300
          ${isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'}
          ${isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'}
        `}>
          <div>
            {/* Hoppa Branded Logo */}
            <div className="hidden md:flex items-center justify-between mb-8">
              <div className="flex items-center gap-3">
                <img 
                  src="/logo-square-orange.png" 
                  alt="Hoppa Logo" 
                  className="w-11 h-11 rounded-2xl object-cover ring-2 ring-[#FF6B00]/20" 
                />
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

            {/* Super Admin Shop Context Selector */}
            {isAdmin && (
              <div className="mb-4">
                <label className="block text-[11px] font-black text-[#FF6B00] uppercase tracking-wider mb-1.5 flex items-center justify-between">
                  <span>Yönetici Mağaza Seçimi</span>
                  <span className="px-1.5 py-0.5 rounded text-[9px] bg-[#FF6B00]/15 text-[#FF6B00] font-bold">ADMIN</span>
                </label>
                <select
                  value={selectedShopIdState}
                  onChange={(e) => handleShopChange(e.target.value)}
                  className={`w-full border rounded-xl p-2.5 text-xs font-bold outline-none transition-colors ${
                    isDark 
                      ? 'bg-slate-950 border-slate-700 text-slate-100' 
                      : 'bg-white border-slate-300 text-slate-900 shadow-sm'
                  }`}
                >
                  <option value="">-- Kendi Mağazam / Varsayılan --</option>
                  {allShops.map((shop) => (
                    <option key={shop.id} value={shop.id}>
                      {shop.name} ({shop.type?.toUpperCase() || 'MAĞAZA'})
                    </option>
                  ))}
                </select>
              </div>
            )}

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
                        ? 'bg-[#FF6B00] text-white' 
                        : isDark 
                          ? 'text-slate-400 hover:text-slate-100 hover:bg-slate-800' 
                          : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <Icon className={`w-5 h-5 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                      <span>{item.label}</span>
                    </div>

                    <div className="flex items-center gap-2">
                      {item.badge && item.badge > 0 ? (
                        <span className="px-2 py-0.5 rounded-full text-xs font-black bg-amber-500 text-white animate-pulse">
                          {item.badge}
                        </span>
                      ) : null}
                      {isActive && <ChevronRight className="w-4 h-4 text-white" />}
                    </div>
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

        {/* Main Content Area with Hoppa Curved Header */}
        <div className="flex-1 min-w-0 flex flex-col h-screen overflow-y-auto">
          {/* Curved Hoppa Degrade Header */}
          <header className="relative bg-gradient-to-r from-[#E95D22] via-[#FF6B00] to-[#FF8C00] text-white pt-8 pb-14 px-6 md:px-10 shrink-0 overflow-hidden">
            {/* Ambient Background Glow Details */}
            <div className="absolute top-0 right-0 -mr-16 -mt-16 w-64 h-64 rounded-full bg-white/10 blur-2xl pointer-events-none" />
            <div className="absolute bottom-0 left-1/4 -mb-12 w-48 h-48 rounded-full bg-black/5 blur-xl pointer-events-none" />

            <div className="relative z-10 max-w-7xl mx-auto flex flex-col sm:flex-row sm:items-center justify-between gap-4">
              <div className="flex items-center gap-4">
                {HeaderIcon && (
                  <div className="w-12 h-12 rounded-2xl bg-white/15 backdrop-blur-md border border-white/20 text-white flex items-center justify-center font-bold shrink-0">
                    <HeaderIcon className="w-6 h-6" />
                  </div>
                )}
                <div>
                  <div className="flex items-center gap-2.5">
                    <h1 className="text-2xl md:text-3xl font-black tracking-tight text-white">{title}</h1>
                    {isShopActive ? (
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-emerald-500/20 text-emerald-100 border border-emerald-400/30 backdrop-blur-sm">
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                        Canlı Mağaza
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-rose-500/20 text-rose-100 border border-rose-400/30 backdrop-blur-sm">
                        <span className="w-1.5 h-1.5 rounded-full bg-rose-400" />
                        Kapalı
                      </span>
                    )}
                  </div>
                  {subtitle && (
                    <p className="text-xs md:text-sm font-medium text-white/85 mt-1 max-w-2xl">
                      {subtitle}
                    </p>
                  )}
                </div>
              </div>

              {headerActions && (
                <div className="flex items-center gap-2.5 shrink-0">
                  {headerActions}
                </div>
              )}
            </div>
          </header>

          {/* Curved Body Sheet */}
          <main className={`flex-1 -mt-8 relative z-20 rounded-t-[32px] md:rounded-t-[36px] transition-colors p-5 md:p-8 ${
            isDark ? 'bg-slate-950 border-t border-slate-800/80 shadow-2xl' : 'bg-slate-50 border-t border-white/60 shadow-2xl shadow-black/5'
          }`}>
            <div className="max-w-7xl mx-auto">
              {children}
            </div>
          </main>
        </div>
      </div>
    </>
  );
}

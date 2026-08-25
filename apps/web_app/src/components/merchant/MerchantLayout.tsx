import React, { useEffect, useState } from 'react';
import Head from 'next/head';
import { useRouter } from 'next/router';
import { 
  Store, Package, ShoppingBag, BarChart3, Settings, LogOut, 
  ChevronRight, ChevronLeft, Power, Menu, X, Sun, Moon, Tag, MapPin,
  Bell, Shield, PanelLeftClose, PanelLeftOpen, User, ChevronDown
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
  activeTab?: 'products' | 'orders' | 'dashboard' | 'campaigns' | 'settings' | 'service-zones';
  fullWidth?: boolean;
}

export default function MerchantLayout({ 
  children, 
  title = 'Yönetim Portalı', 
  subtitle,
  headerIcon: HeaderIcon,
  headerActions,
  activeTab = 'products',
  fullWidth = false,
}: MerchantLayoutProps) {
  const router = useRouter();
  const { theme, toggleTheme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [profile, setProfile] = useState<any>(null);
  const [isShopActive, setIsShopActive] = useState<boolean>(true);
  const [isTogglingShop, setIsTogglingShop] = useState<boolean>(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState<boolean>(false);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState<boolean>(false);
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

    // Restore saved sidebar collapsed state
    try {
      const savedCollapsed = localStorage.getItem('hoppa_merchant_sidebar_collapsed');
      if (savedCollapsed !== null) {
        setIsSidebarCollapsed(savedCollapsed === 'true');
      }
    } catch (_) {}

    if (currentProfile.role === 'super_admin' || currentProfile.role === 'admin') {
      fetchAdminShops();
    }

    fetchShopDetails();
    fetchPendingOrders();
  }, []);

  const toggleSidebarCollapse = () => {
    const next = !isSidebarCollapsed;
    setIsSidebarCollapsed(next);
    try {
      localStorage.setItem('hoppa_merchant_sidebar_collapsed', String(next));
    } catch (_) {}
  };

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
    { id: 'campaigns', label: 'Kampanya & Kupon', icon: Tag, href: '/merchant/campaigns' },
    { id: 'settings', label: 'Mağaza Ayarları', icon: Settings, href: '/merchant/settings' },
    ...(isAdmin ? [{
      id: 'service-zones',
      label: 'KKTC Hizmet Alanları',
      icon: MapPin,
      href: '/merchant/service-zones',
      adminOnly: true
    }] : []),
  ];

  return (
    <>
      <Head>
        <title>{title} | Hoppa Satıcı Portalı</title>
      </Head>

      <div className={`min-h-screen flex flex-col md:flex-row font-sans transition-colors duration-200 ${
        isDark ? 'bg-[#0B1120] text-slate-100' : 'bg-[#F8FAFC] text-slate-900'
      }`}>
        {/* Mobile Header Bar */}
        <div className={`md:hidden p-4 border-b flex items-center justify-between sticky top-0 z-40 transition-colors ${
          isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
        }`}>
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-[#E95D22] to-[#FF8C00] text-white font-bold flex items-center justify-center shadow-sm">
              <Store className="w-5 h-5" />
            </div>
            <div>
              <h2 className="font-extrabold text-sm truncate max-w-[180px]">
                {profile?.businessName || 'Hoppa Mağazası'}
              </h2>
              <span className="text-[10px] text-slate-400 block font-medium">Satıcı Portalı</span>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button 
              onClick={toggleTheme}
              className="p-2 rounded-xl border text-xs font-bold bg-slate-100 dark:bg-slate-800 dark:border-slate-700"
            >
              {isDark ? <Sun className="w-4 h-4 text-amber-400" /> : <Moon className="w-4 h-4 text-slate-700" />}
            </button>
            <button 
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              className="p-2 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-800 dark:text-white"
            >
              {isMobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
          </div>
        </div>

        {/* Mobile Sidebar Backdrop Overlay */}
        {isMobileMenuOpen && (
          <div 
            onClick={() => setIsMobileMenuOpen(false)}
            className="fixed inset-0 bg-slate-950/60 backdrop-blur-xs z-40 md:hidden"
          />
        )}

        {/* Desktop & Mobile Sidebar Navigation */}
        <aside className={`
          fixed md:sticky md:top-0 md:h-screen inset-y-0 left-0 z-40 shrink-0 border-r flex flex-col justify-between transition-all duration-300 ease-in-out select-none
          ${isSidebarCollapsed ? 'md:w-20 w-72 p-3.5' : 'w-72 p-5'}
          ${isDark ? 'bg-slate-900/95 border-slate-800' : 'bg-white border-slate-200/90 shadow-sm'}
          ${isMobileMenuOpen ? 'translate-x-0' : '-translate-x-full md:translate-x-0'}
        `}>
          <div className="space-y-4">
            {/* Logo & Collapse Header */}
            {isSidebarCollapsed ? (
              <div className="flex flex-col items-center gap-2 pb-3.5 border-b border-slate-100 dark:border-slate-800">
                <div className="p-0.5 rounded-xl bg-gradient-to-tr from-[#E95D22] to-[#FF8C00] shadow-sm shrink-0">
                  <img 
                    src="/logo-square-orange.png" 
                    alt="Hoppa" 
                    className="w-9 h-9 rounded-[10px] object-cover bg-white" 
                  />
                </div>
                <button
                  onClick={toggleSidebarCollapse}
                  className="hidden md:flex p-1.5 rounded-lg text-slate-400 hover:text-[#FF6B00] hover:bg-orange-500/10 dark:hover:bg-slate-800 transition-colors"
                  title="Menüyü Genişlet"
                >
                  <PanelLeftOpen className="w-4 h-4" />
                </button>
              </div>
            ) : (
              <div className="flex items-center justify-between pb-4 border-b border-slate-100 dark:border-slate-800">
                <div className="flex items-center gap-3 min-w-0">
                  <div className="p-0.5 rounded-xl bg-gradient-to-tr from-[#E95D22] to-[#FF8C00] shadow-sm shrink-0">
                    <img 
                      src="/logo-square-orange.png" 
                      alt="Hoppa" 
                      className="w-9 h-9 rounded-[10px] object-cover bg-white" 
                    />
                  </div>
                  <div className="min-w-0 transition-opacity duration-200">
                    <h1 className="font-black text-lg tracking-tight text-slate-900 dark:text-white leading-tight">
                      Hoppa <span className="text-[#FF6B00]">Satıcı</span>
                    </h1>
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider block truncate">
                      İşletme Portalı
                    </span>
                  </div>
                </div>

                <button
                  onClick={toggleSidebarCollapse}
                  className="hidden md:flex p-1.5 rounded-lg text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
                  title="Menüyü Daralt"
                >
                  <PanelLeftClose className="w-4 h-4" />
                </button>
              </div>
            )}

            {/* Admin Shop Context Selector */}
            {isAdmin && (
              !isSidebarCollapsed ? (
                <div className="p-3 rounded-2xl bg-orange-500/5 border border-[#FF6B00]/20">
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="text-[10px] font-black text-[#FF6B00] uppercase tracking-wider">
                      Yönetici Mağazası
                    </span>
                    <span className="px-1.5 py-0.2 rounded text-[8px] bg-[#FF6B00] text-white font-black">
                      ADMIN
                    </span>
                  </div>
                  <select
                    value={selectedShopIdState}
                    onChange={(e) => handleShopChange(e.target.value)}
                    className={`w-full border rounded-xl p-2 text-xs font-bold outline-none transition-colors ${
                      isDark 
                      ? 'bg-slate-950 border-slate-700 text-slate-100' 
                      : 'bg-white border-slate-200 text-slate-900 shadow-xs'
                    }`}
                  >
                    <option value="">-- Kendi Mağazam --</option>
                    {allShops.map((shop) => (
                      <option key={shop.id} value={shop.id}>
                        {shop.name} ({shop.type?.toUpperCase() || 'MAĞAZA'})
                      </option>
                    ))}
                  </select>
                </div>
              ) : (
                <div className="flex justify-center group relative">
                  <div className="p-2 rounded-xl bg-orange-500/10 text-[#FF6B00] cursor-pointer" title="Admin Mağaza Seçimi">
                    <Shield className="w-4 h-4" />
                  </div>
                  <div className="absolute left-full ml-2 px-2.5 py-1 bg-slate-900 text-white text-[11px] font-bold rounded-lg shadow-lg opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all whitespace-nowrap z-50">
                    Yönetici Modu
                  </div>
                </div>
              )
            )}

            {/* Live Store Status Card */}
            {!isSidebarCollapsed ? (
              <div className={`border rounded-2xl p-3.5 transition-all ${
                isDark ? 'bg-slate-950/60 border-slate-800' : 'bg-slate-50/80 border-slate-200/80 shadow-xs'
              }`}>
                <div className="flex items-center justify-between">
                  <span className="text-[10px] font-black text-slate-400 uppercase tracking-wider">
                    Sipariş Alımı
                  </span>
                  <button
                    onClick={handleToggleShopStatus}
                    disabled={isTogglingShop}
                    className={`px-2.5 py-0.5 rounded-full text-[11px] font-black flex items-center gap-1.5 transition-all ${
                      isShopActive 
                        ? 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 border border-emerald-500/30' 
                        : 'bg-rose-500/15 text-rose-500 border border-rose-500/30'
                    }`}
                  >
                    <span className={`w-2 h-2 rounded-full ${isShopActive ? 'bg-emerald-500 animate-pulse' : 'bg-rose-500'}`} />
                    <span>{isShopActive ? 'AÇIK' : 'KAPALI'}</span>
                  </button>
                </div>
                <h4 className="font-extrabold text-xs truncate mt-1.5 text-slate-800 dark:text-slate-200">
                  {profile?.businessName || 'Mağaza Yükleniyor...'}
                </h4>
              </div>
            ) : (
              <div className="flex justify-center group relative">
                <button
                  onClick={handleToggleShopStatus}
                  disabled={isTogglingShop}
                  className={`p-2.5 rounded-xl border transition-all ${
                    isShopActive
                      ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-500'
                      : 'bg-rose-500/10 border-rose-500/30 text-rose-500'
                  }`}
                  title={isShopActive ? 'Mağaza Canlı (Sipariş Alıyor)' : 'Mağaza Kapalı'}
                >
                  <Power className="w-4 h-4" />
                </button>
                <div className="absolute left-full ml-2 px-2.5 py-1 bg-slate-900 text-white text-[11px] font-bold rounded-lg shadow-lg opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all whitespace-nowrap z-50">
                  {isShopActive ? 'Mağaza: Açık' : 'Mağaza: Kapalı'}
                </div>
              </div>
            )}

            {/* Navigation Menu */}
            <nav className="space-y-1 pt-1">
              {navItems.map((item: any) => {
                const Icon = item.icon;
                const isActive = activeTab === item.id;
                return (
                  <button
                    key={item.id}
                    onClick={() => {
                      router.push(item.href);
                      setIsMobileMenuOpen(false);
                    }}
                    className={`w-full flex items-center rounded-xl text-xs font-black transition-all duration-150 group relative ${
                      isSidebarCollapsed ? 'justify-center p-3' : 'justify-between px-3.5 py-2.5'
                    } ${
                      isActive 
                        ? 'bg-[#FF6B00]/10 text-[#FF6B00] dark:bg-[#FF6B00]/15 dark:text-[#FF8C00] shadow-xs' 
                        : isDark 
                          ? 'text-slate-400 hover:text-slate-100 hover:bg-slate-800/70' 
                          : 'text-slate-600 hover:text-[#FF6B00] hover:bg-orange-50/70'
                    }`}
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <Icon className={`w-4 h-4 shrink-0 transition-colors ${
                        isActive ? 'text-[#FF6B00]' : 'text-slate-400 group-hover:text-current'
                      }`} />
                      {!isSidebarCollapsed && (
                        <span className="truncate">{item.label}</span>
                      )}
                    </div>

                    {!isSidebarCollapsed && (
                      <div className="flex items-center gap-1.5 shrink-0">
                        {item.adminOnly && (
                          <span className="px-1.5 py-0.2 rounded text-[8px] bg-[#FF6B00] text-white font-black">
                            ADMIN
                          </span>
                        )}
                        {item.badge && item.badge > 0 ? (
                          <span className="px-1.5 py-0.5 rounded-full text-[10px] font-black bg-amber-500 text-white animate-pulse">
                            {item.badge}
                          </span>
                        ) : null}
                        {isActive && <ChevronRight className="w-3.5 h-3.5 text-[#FF6B00]" />}
                      </div>
                    )}

                    {/* Collapsed Tooltip Hover Popover */}
                    {isSidebarCollapsed && (
                      <div className="absolute left-full ml-3 px-3 py-1.5 bg-slate-900 dark:bg-slate-800 text-white text-xs font-bold rounded-xl shadow-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all whitespace-nowrap z-50 flex items-center gap-2 pointer-events-none">
                        <span>{item.label}</span>
                        {item.adminOnly && (
                          <span className="px-1.5 py-0.2 rounded text-[8px] bg-[#FF6B00] text-white font-black">
                            ADMIN
                          </span>
                        )}
                      </div>
                    )}
                  </button>
                );
              })}
            </nav>
          </div>

          {/* Sidebar Footer */}
          <div className="pt-4 border-t border-slate-100 dark:border-slate-800 space-y-2">
            <button
              onClick={handleLogout}
              className={`w-full flex items-center rounded-xl text-xs font-black text-rose-500 hover:bg-rose-500/10 transition-colors group relative ${
                isSidebarCollapsed ? 'justify-center p-2.5' : 'gap-2.5 px-3 py-2.5'
              }`}
              title="Güvenli Çıkış Yap"
            >
              <LogOut className="w-4 h-4 shrink-0" />
              {!isSidebarCollapsed && <span>Güvenli Çıkış</span>}
              {isSidebarCollapsed && (
                <div className="absolute left-full ml-3 px-3 py-1.5 bg-slate-900 text-white text-xs font-bold rounded-xl shadow-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all whitespace-nowrap z-50 pointer-events-none">
                  Güvenli Çıkış
                </div>
              )}
            </button>
          </div>
        </aside>

        {/* Main Content Viewport */}
        <div className="flex-1 min-w-0 flex flex-col h-screen overflow-y-auto">
          {/* Top Corporate Navbar */}
          <header className={`sticky top-0 z-30 px-6 py-3 border-b flex items-center justify-between transition-colors backdrop-blur-md ${
            isDark 
              ? 'bg-slate-900/80 border-slate-800 text-white' 
              : 'bg-white/80 border-slate-200/80 text-slate-800 shadow-2xs'
          }`}>
            {/* Breadcrumb / Title Info */}
            <div className="flex items-center gap-3">
              <button
                onClick={toggleSidebarCollapse}
                className="hidden md:flex p-2 rounded-xl text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors shrink-0"
                title={isSidebarCollapsed ? "Sol Menüyü Genişlet" : "Sol Menüyü Daralt"}
              >
                {isSidebarCollapsed ? <PanelLeftOpen className="w-4 h-4 text-[#FF6B00]" /> : <PanelLeftClose className="w-4 h-4" />}
              </button>
              {HeaderIcon && (
                <div className="w-9 h-9 rounded-xl bg-orange-500/10 text-[#FF6B00] flex items-center justify-center font-bold shrink-0 border border-orange-500/20">
                  <HeaderIcon className="w-4 h-4" />
                </div>
              )}
              <div>
                <div className="flex items-center gap-2">
                  <span className="text-[11px] font-bold text-slate-400 uppercase tracking-wider hidden sm:inline">
                    Hoppa Portal /
                  </span>
                  <h1 className="text-base sm:text-lg font-black tracking-tight text-slate-900 dark:text-white">
                    {title}
                  </h1>
                </div>
                {subtitle && (
                  <p className="text-[11px] font-medium text-slate-500 dark:text-slate-400 truncate max-w-xl hidden md:block">
                    {subtitle}
                  </p>
                )}
              </div>
            </div>

            {/* Top Right Quick Actions */}
            <div className="flex items-center gap-2.5">
              {headerActions}

              {/* Theme Toggle */}
              <button
                onClick={toggleTheme}
                className={`p-2 rounded-xl border transition-colors ${
                  isDark ? 'bg-slate-800 border-slate-700 text-amber-400 hover:bg-slate-700' : 'bg-slate-100 border-slate-200 text-slate-600 hover:bg-slate-200'
                }`}
                title={isDark ? 'Aydınlık Temaya Geç' : 'Karanlık Temaya Geç'}
              >
                {isDark ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
              </button>

              {/* Merchant Profile Pill */}
              <div className={`hidden sm:flex items-center gap-2 pl-2 border-l ${
                isDark ? 'border-slate-800' : 'border-slate-200'
              }`}>
                <div className="w-7 h-7 rounded-lg bg-gradient-to-tr from-[#E95D22] to-[#FF8C00] text-white font-bold flex items-center justify-center text-xs">
                  {profile?.businessName ? profile.businessName.charAt(0).toUpperCase() : 'M'}
                </div>
                <div className="text-left hidden lg:block">
                  <span className="text-xs font-black text-slate-900 dark:text-white block truncate max-w-[120px]">
                    {profile?.businessName || 'Satıcı'}
                  </span>
                  <span className="text-[9px] font-bold text-slate-400 block uppercase">
                    {profile?.role === 'super_admin' ? 'Süper Admin' : profile?.role === 'admin' ? 'Yönetici' : 'Satıcı'}
                  </span>
                </div>
              </div>
            </div>
          </header>

          {/* Main Content Area (Full width or standard container) */}
          <main className="flex-1 p-4 sm:p-6 lg:p-8">
            <div className={fullWidth ? 'w-full' : 'max-w-7xl mx-auto'}>
              {children}
            </div>
          </main>
        </div>
      </div>
    </>
  );
}

import React, { useCallback, useEffect, useRef, useState } from 'react';
import Head from 'next/head';
import { useRouter } from 'next/router';
import { 
  Store, Package, ShoppingBag, BarChart3, Settings, LogOut, 
  ChevronRight, ChevronLeft, Power, Menu, X, Sun, Moon, Tag, MapPin,
  Bell, Shield, PanelLeftClose, PanelLeftOpen, User, ChevronDown,
  Building2, Truck, ShieldCheck, LayoutGrid, Star, Sparkles, AlertTriangle
} from 'lucide-react';
import { 
  getMerchantProfile, getMerchantToken, clearMerchantAuth, merchantApiFetch, 
  getSelectedShopId, setSelectedShopId, MerchantProfile 
} from '../../utils/merchant-auth';
import {
  createMerchantRealtimeClient,
  MerchantRealtimeClient,
  RealtimeConnectionState,
  RealtimeEventEnvelope,
} from '../../utils/realtime-client';
import { useMerchantTheme } from '../../context/MerchantThemeContext';
import HoppaSelect from './HoppaSelect';

export type MerchantNavTab =
  | 'products'
  | 'orders'
  | 'dashboard'
  | 'campaigns'
  | 'settings'
  | 'promotions'
  | 'reviews'
  | 'service-zones'
  | 'admin-merchants'
  | 'admin-couriers'
  | 'admin-moderation'
  | 'admin-categories';

interface NavItemConfig {
  id: MerchantNavTab;
  label: string;
  icon: React.ElementType;
  href: string;
  badge?: number;
  adminOnly?: boolean;
}

interface MerchantLayoutProps {
  children: React.ReactNode;
  title?: string;
  subtitle?: string;
  headerIcon?: React.ElementType;
  headerActions?: React.ReactNode;
  activeTab?: MerchantNavTab;
  fullWidth?: boolean;
}

type RealtimeToastTone = 'emerald' | 'rose' | 'amber' | 'orange';

interface RealtimeToast {
  id: string;
  type: RealtimeEventEnvelope['type'];
  title: string;
  message: string;
  tone: RealtimeToastTone;
  timeLabel: string;
}

const ORDER_STATUS_LABELS: Record<string, string> = {
  PENDING: 'Onay Bekliyor',
  PREPARING: 'Hazırlanıyor',
  READY_FOR_PICKUP: 'Teslimata Hazır',
  ON_THE_WAY: 'Kurye Yolda',
  DELIVERED: 'Teslim Edildi',
  CANCELLED: 'İptal Edildi',
};

const TOAST_TONE_STYLES: Record<
  RealtimeToastTone,
  {
    borderLight: string;
    borderDark: string;
    iconBgLight: string;
    iconBgDark: string;
    Icon: React.ElementType;
  }
> = {
  emerald: {
    borderLight: 'border-emerald-200',
    borderDark: 'border-emerald-500/40',
    iconBgLight: 'bg-emerald-50 text-emerald-600 border-emerald-200',
    iconBgDark: 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30',
    Icon: ShoppingBag,
  },
  rose: {
    borderLight: 'border-rose-200',
    borderDark: 'border-rose-500/40',
    iconBgLight: 'bg-rose-50 text-rose-600 border-rose-200',
    iconBgDark: 'bg-rose-500/15 text-rose-400 border-rose-500/30',
    Icon: AlertTriangle,
  },
  amber: {
    borderLight: 'border-amber-200',
    borderDark: 'border-amber-500/40',
    iconBgLight: 'bg-amber-50 text-amber-600 border-amber-200',
    iconBgDark: 'bg-amber-500/15 text-amber-400 border-amber-500/30',
    Icon: Bell,
  },
  orange: {
    borderLight: 'border-orange-200',
    borderDark: 'border-[#FF6B00]/40',
    iconBgLight: 'bg-orange-50 text-[#FF6B00] border-orange-200',
    iconBgDark: 'bg-[#FF6B00]/15 text-[#FF8C00] border-[#FF6B00]/30',
    Icon: Shield,
  },
};

function readPayloadText(payload: Record<string, unknown>, keys: string[]): string | null {
  for (const key of keys) {
    const value = payload[key];
    if (typeof value === 'string' && value.trim().length > 0) {
      return value.trim();
    }
    if (typeof value === 'number' && Number.isFinite(value)) {
      return String(value);
    }
  }
  return null;
}

function formatOrderRef(payload: Record<string, unknown>): string | null {
  const rawRef = readPayloadText(payload, ['orderNumber', 'orderCode', 'shortId', 'orderId', 'id']);
  if (!rawRef) {
    return null;
  }
  const cleanRef = rawRef.startsWith('#') ? rawRef.slice(1) : rawRef;
  return cleanRef.length > 12 ? `#${cleanRef.slice(0, 8).toUpperCase()}` : `#${cleanRef}`;
}

function formatToastTime(timestamp: string): string {
  const parsed = new Date(timestamp);
  if (Number.isNaN(parsed.getTime())) {
    return 'Şimdi';
  }
  return parsed.toLocaleTimeString('tr-TR', { hour: '2-digit', minute: '2-digit' });
}

function buildRealtimeToast(event: RealtimeEventEnvelope, isAdmin: boolean): RealtimeToast | null {
  const { type, payload, timestamp } = event;
  const orderRef = formatOrderRef(payload);
  const timeLabel = formatToastTime(timestamp);
  const toastId = `${event.id}-${Date.now()}`;

  switch (type) {
    case 'NEW_ORDER': {
      const customMessage = readPayloadText(payload, ['message']);
      const customerName = readPayloadText(payload, ['customerName', 'customer']);
      const amount = readPayloadText(payload, ['totalAmount', 'total']);
      const fallbackMessage = [
        orderRef ? `${orderRef} numaralı sipariş` : 'Yeni bir sipariş',
        customerName ? `(${customerName})` : null,
        amount ? `• ₺${amount}` : null,
        'onayınızı bekliyor.',
      ]
        .filter((part): part is string => Boolean(part))
        .join(' ');

      return {
        id: toastId,
        type,
        title: 'Yeni Sipariş Geldi',
        message: customMessage || fallbackMessage,
        tone: 'emerald',
        timeLabel,
      };
    }

    case 'ORDER_CANCELLED': {
      const reason = readPayloadText(payload, ['reason', 'cancelReason', 'message']);
      const baseText = orderRef
        ? `${orderRef} numaralı sipariş iptal edildi.`
        : 'Bir sipariş iptal edildi.';

      return {
        id: toastId,
        type,
        title: 'Sipariş İptal Edildi',
        message: reason ? `${baseText} (${reason})` : baseText,
        tone: 'rose',
        timeLabel,
      };
    }

    case 'ORDER_STATUS_UPDATED': {
      const customMessage = readPayloadText(payload, ['message']);
      const rawStatus = readPayloadText(payload, ['statusLabel', 'status']);
      const statusLabel = rawStatus ? ORDER_STATUS_LABELS[rawStatus] || rawStatus : null;
      const defaultMessage = orderRef
        ? `${orderRef} durumu güncellendi${statusLabel ? `: ${statusLabel}` : '.'}`
        : `Sipariş durumu güncellendi${statusLabel ? `: ${statusLabel}` : '.'}`;

      return {
        id: toastId,
        type,
        title: 'Sipariş Durumu Güncellendi',
        message: customMessage || defaultMessage,
        tone: 'amber',
        timeLabel,
      };
    }

    case 'ADMIN_ALERT': {
      if (!isAdmin) {
        return null;
      }
      return {
        id: toastId,
        type,
        title: readPayloadText(payload, ['title']) || 'Yönetici Bildirimi',
        message:
          readPayloadText(payload, ['message', 'description', 'summary']) ||
          'Yeni bir sistem bildirimi alındı.',
        tone: 'orange',
        timeLabel,
      };
    }

    default:
      return null;
  }
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

  const [profile, setProfile] = useState<MerchantProfile | null>(null);
  const [isAuthReady, setIsAuthReady] = useState<boolean>(false);
  const [isShopActive, setIsShopActive] = useState<boolean>(true);
  const [isTogglingShop, setIsTogglingShop] = useState<boolean>(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState<boolean>(false);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState<boolean>(false);
  const [pendingOrdersCount, setPendingOrdersCount] = useState<number>(0);
  const [allShops, setAllShops] = useState<any[]>([]);
  const [selectedShopIdState, setSelectedShopIdState] = useState<string>('');
  const [realtimeState, setRealtimeState] = useState<RealtimeConnectionState>('disconnected');
  const [realtimeToast, setRealtimeToast] = useState<RealtimeToast | null>(null);
  const realtimeClientRef = useRef<MerchantRealtimeClient | null>(null);

  const isAdmin = profile?.role === 'super_admin' || profile?.role === 'admin';

  const fetchPendingOrders = useCallback(async () => {
    try {
      const res = await merchantApiFetch('/merchant/orders');
      if (res.data && Array.isArray(res.data)) {
        const pending = (res.data as unknown[]).filter(
          (item) =>
            typeof item === 'object' &&
            item !== null &&
            (item as Record<string, unknown>).status === 'PENDING'
        ).length;
        setPendingOrdersCount(pending);
      }
    } catch (err) {
      console.error('Sipariş rozeti alınamadı:', err);
    }
  }, []);

  useEffect(() => {
    const token = getMerchantToken();
    const currentProfile = getMerchantProfile();

    if (!token || !currentProfile) {
      router.push('/merchant/login');
      return;
    }

    setProfile(currentProfile);
    setSelectedShopIdState(getSelectedShopId() || '');
    setIsAuthReady(true);

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
    void fetchPendingOrders();
  }, []);

  useEffect(() => {
    if (!isAuthReady) {
      return;
    }

    let isMounted = true;
    const client = createMerchantRealtimeClient({
      shopId: selectedShopIdState || null,
      onStateChange: (nextState) => {
        if (isMounted) {
          setRealtimeState(nextState);
        }
      },
      onEvent: (event) => {
        if (!isMounted) {
          return;
        }
        const toast = buildRealtimeToast(event, isAdmin);
        if (toast) {
          setRealtimeToast(toast);
          void fetchPendingOrders();
        }
      },
    });

    realtimeClientRef.current = client;
    client.connect();

    return () => {
      isMounted = false;
      client.disconnect();
      if (realtimeClientRef.current === client) {
        realtimeClientRef.current = null;
      }
    };
  }, [isAuthReady, selectedShopIdState, isAdmin, fetchPendingOrders]);

  useEffect(() => {
    if (!realtimeToast || typeof window === 'undefined') {
      return;
    }
    const timer = window.setTimeout(() => {
      setRealtimeToast(null);
    }, 6000);
    return () => {
      window.clearTimeout(timer);
    };
  }, [realtimeToast]);

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
    realtimeClientRef.current?.disconnect();
    clearMerchantAuth();
    router.push('/merchant/login');
  };

  const merchantNavItems: NavItemConfig[] = [
    { id: 'products', label: 'Ürün & Menü Portalı', icon: Package, href: '/merchant/products' },
    { id: 'orders', label: 'Canlı Siparişler', icon: ShoppingBag, href: '/merchant/orders', badge: pendingOrdersCount },
    { id: 'dashboard', label: 'Performans & Analiz', icon: BarChart3, href: '/merchant/dashboard' },
    { id: 'campaigns', label: 'Kampanya & Kupon', icon: Tag, href: '/merchant/campaigns' },
    { id: 'promotions', label: 'Sponsorlu Vitrin', icon: Sparkles, href: '/merchant/promotions' },
    { id: 'reviews', label: 'Müşteri Yorumları', icon: Star, href: '/merchant/reviews' },
    { id: 'settings', label: 'Mağaza Ayarları', icon: Settings, href: '/merchant/settings' },
  ];

  const adminNavItems: NavItemConfig[] = isAdmin
    ? [
        { id: 'admin-merchants', label: 'İşletme Başvuruları', icon: Building2, href: '/merchant/admin/merchants', adminOnly: true },
        { id: 'admin-couriers', label: 'Kurye & Filo AI', icon: Truck, href: '/merchant/admin/couriers', adminOnly: true },
        { id: 'admin-moderation', label: 'Moderasyon Merkezi', icon: ShieldCheck, href: '/merchant/admin/moderation', adminOnly: true },
        { id: 'admin-categories', label: 'İşletme Kategorileri', icon: LayoutGrid, href: '/merchant/admin/categories', adminOnly: true },
        { id: 'service-zones', label: 'KKTC Hizmet Alanları', icon: MapPin, href: '/merchant/service-zones', adminOnly: true },
      ]
    : [];

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
                  <HoppaSelect
                    value={selectedShopIdState}
                    onChange={(val) => handleShopChange(val)}
                    placeholder="-- Kendi Mağazam --"
                    options={[
                      { value: '', label: 'Kendi Mağazam', badge: 'VARSAYILAN' },
                      ...allShops.map((shop) => ({
                        value: shop.id,
                        label: shop.name,
                        badge: shop.type?.toUpperCase() || 'MAĞAZA',
                      })),
                    ]}
                    size="sm"
                    variant="contrast"
                    searchable={allShops.length > 5}
                    searchPlaceholder="Mağaza ara..."
                  />
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
              {merchantNavItems.map((item) => {
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
                        {item.badge && item.badge > 0 ? (
                          <span className="px-1.5 py-0.5 rounded-full text-[10px] font-black bg-amber-500 text-white animate-pulse tabular-nums">
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
                      </div>
                    )}
                  </button>
                );
              })}

              {adminNavItems.length > 0 && (
                <div className="pt-3 mt-3 border-t border-slate-100 dark:border-slate-800 space-y-1">
                  {!isSidebarCollapsed && (
                    <div className="px-3.5 pb-1 flex items-center justify-between">
                      <span className="text-[10px] font-black uppercase tracking-wider text-[#FF6B00]">
                        Süper Admin Merkezi
                      </span>
                      <Shield className="w-3 h-3 text-[#FF6B00]" />
                    </div>
                  )}
                  {adminNavItems.map((item) => {
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
                            <span className="px-1.5 py-0.2 rounded text-[8px] bg-[#FF6B00] text-white font-black">
                              ADMIN
                            </span>
                            {isActive && <ChevronRight className="w-3.5 h-3.5 text-[#FF6B00]" />}
                          </div>
                        )}

                        {isSidebarCollapsed && (
                          <div className="absolute left-full ml-3 px-3 py-1.5 bg-slate-900 dark:bg-slate-800 text-white text-xs font-bold rounded-xl shadow-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all whitespace-nowrap z-50 flex items-center gap-2 pointer-events-none">
                            <span>{item.label}</span>
                            <span className="px-1.5 py-0.2 rounded text-[8px] bg-[#FF6B00] text-white font-black">
                              ADMIN
                            </span>
                          </div>
                        )}
                      </button>
                    );
                  })}
                </div>
              )}
            </nav>
          </div>

          {/* Sidebar Footer */}
          <div className="pt-4 border-t border-slate-100 dark:border-slate-800 space-y-1.5">
            <button
              type="button"
              onClick={() => {
                router.push('/merchant/login?switch=1');
                setIsMobileMenuOpen(false);
              }}
              className={`w-full flex items-center rounded-xl text-xs font-black transition-colors group relative ${
                isSidebarCollapsed ? 'justify-center p-2.5' : 'gap-2.5 px-3 py-2.5'
              } ${
                isDark
                  ? 'text-slate-300 hover:bg-slate-800'
                  : 'text-slate-600 hover:bg-slate-100'
              }`}
              title="Hesap Değiştir"
            >
              <User className="w-4 h-4 shrink-0" />
              {!isSidebarCollapsed && <span>Hesap Değiştir</span>}
              {isSidebarCollapsed && (
                <div className="absolute left-full ml-3 px-3 py-1.5 bg-slate-900 text-white text-xs font-bold rounded-xl shadow-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all whitespace-nowrap z-50 pointer-events-none">
                  Hesap Değiştir
                </div>
              )}
            </button>

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
              {isAuthReady && realtimeState !== 'disconnected' && (
                <div
                  className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full border text-[11px] font-bold transition-colors shrink-0 ${
                    realtimeState === 'connected'
                      ? isDark
                        ? 'bg-emerald-500/15 border-emerald-500/30 text-emerald-400'
                        : 'bg-emerald-50 border-emerald-200 text-emerald-700'
                      : isDark
                        ? 'bg-amber-500/15 border-amber-500/30 text-amber-400'
                        : 'bg-amber-50 border-amber-200 text-amber-700'
                  }`}
                  title={
                    realtimeState === 'connected'
                      ? 'Gerçek zamanlı bağlantı aktif'
                      : 'Gerçek zamanlı bağlantı kuruluyor'
                  }
                  aria-live="polite"
                >
                  <span
                    className={`w-2 h-2 rounded-full shrink-0 ${
                      realtimeState === 'connected'
                        ? 'bg-emerald-500 animate-pulse'
                        : 'bg-amber-500 animate-pulse'
                    }`}
                  />
                  <span>
                    {realtimeState === 'connected' ? 'Canlı' : 'Bağlanıyor...'}
                  </span>
                </div>
              )}

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

        {/* Floating Realtime Notification Toast */}
        {realtimeToast && (() => {
          const toneStyle = TOAST_TONE_STYLES[realtimeToast.tone];
          const ToastIcon = toneStyle.Icon;
          return (
            <div
              role="status"
              aria-live="polite"
              className={`fixed bottom-5 right-5 z-50 w-[calc(100vw-2.5rem)] max-w-sm rounded-2xl border p-4 backdrop-blur-md transition-all print:hidden ${
                isDark
                  ? `bg-slate-900/95 text-slate-100 shadow-2xl ${toneStyle.borderDark}`
                  : `bg-white/95 text-slate-900 shadow-lg ${toneStyle.borderLight}`
              }`}
            >
              <div className="flex items-start gap-3">
                <div
                  className={`w-9 h-9 rounded-xl border flex items-center justify-center shrink-0 ${
                    isDark ? toneStyle.iconBgDark : toneStyle.iconBgLight
                  }`}
                >
                  <ToastIcon className="w-4 h-4" />
                </div>

                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between gap-2">
                    <p className="text-xs font-black tracking-tight truncate">
                      {realtimeToast.title}
                    </p>
                    <span className="text-[10px] font-bold text-slate-400 tabular-nums shrink-0">
                      {realtimeToast.timeLabel}
                    </span>
                  </div>
                  <p
                    className={`mt-1 text-xs font-medium leading-relaxed break-words ${
                      isDark ? 'text-slate-300' : 'text-slate-600'
                    }`}
                  >
                    {realtimeToast.message}
                  </p>
                </div>

                <button
                  type="button"
                  onClick={() => setRealtimeToast(null)}
                  className={`p-1 rounded-lg transition-colors shrink-0 ${
                    isDark
                      ? 'text-slate-400 hover:text-white hover:bg-slate-800'
                      : 'text-slate-400 hover:text-slate-700 hover:bg-slate-100'
                  }`}
                  aria-label="Bildirimi kapat"
                  title="Kapat"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            </div>
          );
        })()}
      </div>
    </>
  );
}

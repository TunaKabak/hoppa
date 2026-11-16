import React, { useCallback, useEffect, useRef, useState } from 'react';
import Head from 'next/head';
import { useRouter } from 'next/router';
import { 
  Package, ShoppingBag, BarChart3, Settings, LogOut, 
  ChevronRight, Power, Menu, X, Sun, Moon, Tag, MapPin,
  Bell, Shield, PanelLeftClose, PanelLeftOpen, User,
  Building2, Truck, ShieldCheck, LayoutGrid, Star, Megaphone, AlertTriangle, Wallet
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
import { useToast } from './ToastContext';

export type MerchantNavTab =
  | 'products'
  | 'orders'
  | 'dashboard'
  | 'finance'
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

interface AdminShopOption {
  id: string;
  name: string;
  type?: string;
}

const SHOP_TYPE_LABELS: Record<string, string> = {
  MARKET: 'Market',
  RESTAURANT: 'Restoran',
  FLOWER: 'Çiçek',
  WATER: 'Su',
  BUTCHER: 'Kasap',
  GREENGROCER: 'Manav',
  CAFE: 'Kafe',
  NUTS: 'Kuruyemiş',
};

function formatShopTypeLabel(type?: string): string {
  if (!type) {
    return 'Mağaza';
  }
  const normalized = type.trim().toUpperCase();
  return SHOP_TYPE_LABELS[normalized] || 'Mağaza';
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
  const toast = useToast();
  const isDark = theme === 'dark';

  const [profile, setProfile] = useState<MerchantProfile | null>(null);
  const [isAuthReady, setIsAuthReady] = useState<boolean>(false);
  const [isShopActive, setIsShopActive] = useState<boolean>(true);
  const [isTogglingShop, setIsTogglingShop] = useState<boolean>(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState<boolean>(false);
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState<boolean>(false);
  const [pendingOrdersCount, setPendingOrdersCount] = useState<number>(0);
  const [allShops, setAllShops] = useState<AdminShopOption[]>([]);
  const [selectedShopIdState, setSelectedShopIdState] = useState<string>('');
  const [realtimeState, setRealtimeState] = useState<RealtimeConnectionState>('disconnected');
  const [realtimeToast, setRealtimeToast] = useState<RealtimeToast | null>(null);
  const realtimeClientRef = useRef<MerchantRealtimeClient | null>(null);

  const isAdmin = profile?.role === 'super_admin' || profile?.role === 'admin';
  const isAdminPlatformPage =
    activeTab.startsWith('admin-') || activeTab === 'service-zones';
  const showShopToggle = !(isAdmin && isAdminPlatformPage && !selectedShopIdState);
  const selectedAdminShop = allShops.find((s) => s.id === selectedShopIdState);
  const activeShopDisplayName =
    selectedAdminShop?.name || profile?.businessName || 'Mağaza Yükleniyor...';
  const roleSubtitleLabel =
    profile?.role === 'super_admin'
      ? 'Hoppa Merkez'
      : profile?.role === 'admin'
        ? 'Operasyon'
        : 'Mağaza Hesabı';

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
        setAllShops(res.data as AdminShopOption[]);
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
        toast.success(
          res.data.isActive
            ? 'Mağaza sipariş alımına açıldı.'
            : 'Mağaza sipariş alımına kapatıldı.'
        );
      }
    } catch (err: any) {
      toast.error(err.message || 'Dükkan durumu değiştirilemedi.');
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
    { id: 'finance', label: 'Finans & Hakediş', icon: Wallet, href: '/merchant/finance' },
    { id: 'campaigns', label: 'Kampanya & Kupon', icon: Tag, href: '/merchant/campaigns' },
    { id: 'promotions', label: 'Sponsorlu Vitrin', icon: Megaphone, href: '/merchant/promotions' },
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

  if (!isAuthReady) {
    return (
      <>
        <Head>
          <title>{title} | Hoppa Satıcı Portalı</title>
        </Head>
        <div
          className={`min-h-screen flex items-center justify-center p-6 font-sans ${
            isDark ? 'bg-[#0B1120] text-slate-300' : 'bg-[#F8FAFC] text-slate-600'
          }`}
        >
          <div className="flex flex-col items-center gap-3">
            <img
              src="/logo-mark.svg"
              alt="Hoppa"
              className="w-10 h-10 rounded-xl shadow-xs ring-1 ring-black/5"
            />
            <div className="w-6 h-6 border-2 border-[#FF6B00] border-t-transparent rounded-full animate-spin" />
            <span className="text-xs font-bold text-slate-400">Oturum doğrulanıyor...</span>
          </div>
        </div>
      </>
    );
  }

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
            {isAdmin ? (
              <img
                src="/logo-mark.svg"
                alt="Hoppa"
                className="w-8 h-8 rounded-lg object-cover ring-1 ring-black/5 shrink-0"
              />
            ) : (
              <div className="w-8 h-8 rounded-lg bg-slate-900 text-white border border-slate-800 font-extrabold text-xs flex items-center justify-center shrink-0">
                {activeShopDisplayName.charAt(0).toUpperCase() || 'H'}
              </div>
            )}
            <div className="min-w-0">
              <h2 className="font-extrabold text-sm truncate max-w-[180px]">
                {activeShopDisplayName}
              </h2>
              <span className="text-[10px] text-slate-400 block font-medium">
                {roleSubtitleLabel}
              </span>
            </div>
          </div>
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={toggleTheme}
              aria-label={isDark ? 'Aydınlık temaya geç' : 'Karanlık temaya geç'}
              className="p-2 rounded-xl border text-xs font-bold bg-slate-100 dark:bg-slate-800 dark:border-slate-700"
            >
              {isDark ? <Sun className="w-4 h-4 text-amber-400" /> : <Moon className="w-4 h-4 text-slate-700" />}
            </button>
            <button
              type="button"
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              aria-label={isMobileMenuOpen ? 'Menüyü kapat' : 'Menüyü aç'}
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
                <img
                  src="/logo-mark.svg"
                  alt="Hoppa"
                  className="w-9 h-9 rounded-xl object-cover shadow-xs ring-1 ring-black/5 shrink-0"
                />
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
                  <img
                    src="/logo-mark.svg"
                    alt="Hoppa"
                    className="w-9 h-9 rounded-xl object-cover shadow-xs ring-1 ring-black/5 shrink-0"
                  />
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
                <div
                  className={`p-3 rounded-2xl border ${
                    isDark
                      ? 'bg-slate-950/60 border-slate-800'
                      : 'bg-slate-50/80 border-slate-200/80'
                  }`}
                >
                  <label className="text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-1.5 block">
                    Aktif Mağaza Bağlamı
                  </label>
                  <HoppaSelect
                    value={selectedShopIdState}
                    onChange={(val) => handleShopChange(val)}
                    placeholder="-- Kendi Mağazam --"
                    options={[
                      { value: '', label: 'Kendi Mağazam', badge: 'Varsayılan' },
                      ...allShops.map((shop) => ({
                        value: shop.id,
                        label: shop.name,
                        badge: formatShopTypeLabel(shop.type),
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
                  <div className="p-2 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 cursor-pointer" title="Aktif Mağaza Bağlamı">
                    <Shield className="w-4 h-4" />
                  </div>
                  <div className="absolute left-full ml-2 px-2.5 py-1 bg-slate-900 text-white text-[11px] font-bold rounded-lg shadow-lg opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all whitespace-nowrap z-50">
                    Hoppa Merkez Yönetimi
                  </div>
                </div>
              )
            )}

            {/* Live Store Status Card (Hidden on platform-level admin pages unless a specific shop is targeted) */}
            {showShopToggle ? (
              !isSidebarCollapsed ? (
                <div className={`border rounded-2xl p-3.5 transition-all ${
                  isDark ? 'bg-slate-950/60 border-slate-800' : 'bg-slate-50/80 border-slate-200/80 shadow-xs'
                }`}>
                  <div className="flex items-center justify-between gap-2">
                    <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">
                      Sipariş Alımı
                    </span>
                    <button
                      type="button"
                      role="switch"
                      aria-checked={isShopActive}
                      aria-label="Sipariş alım durumu"
                      onClick={handleToggleShopStatus}
                      disabled={isTogglingShop}
                      className={`relative inline-flex h-5 w-9 shrink-0 items-center rounded-full transition-colors disabled:opacity-50 ${
                        isShopActive
                          ? 'bg-[#00A651]'
                          : isDark
                            ? 'bg-slate-700'
                            : 'bg-slate-300'
                      }`}
                    >
                      <span
                        className={`inline-block h-3.5 w-3.5 rounded-full bg-white shadow-xs transition-transform ${
                          isShopActive ? 'translate-x-4' : 'translate-x-1'
                        }`}
                      />
                    </button>
                  </div>
                  <h4 className="font-extrabold text-xs truncate mt-2 text-slate-800 dark:text-slate-200">
                    {activeShopDisplayName}
                  </h4>
                  <p
                    className={`text-[11px] font-medium mt-0.5 ${
                      isShopActive ? 'text-[#00A651] dark:text-emerald-400' : 'text-slate-400'
                    }`}
                  >
                    {isShopActive ? 'Sipariş alımına açık' : 'Sipariş alımı duraklatıldı'}
                  </p>
                </div>
              ) : (
                <div className="flex justify-center group relative">
                  <button
                    type="button"
                    aria-label={isShopActive ? 'Mağaza açık, kapat' : 'Mağaza kapalı, aç'}
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
              )
            ) : !isSidebarCollapsed ? (
              <div className={`border rounded-2xl p-3 flex items-center gap-2.5 ${
                isDark ? 'bg-slate-950/60 border-slate-800 text-slate-300' : 'bg-orange-50/60 border-orange-200/70 text-slate-700'
              }`}>
                <Shield className="w-4 h-4 text-[#FF6B00] shrink-0" />
                <div className="min-w-0">
                  <span className="text-[11px] font-black block truncate">Platform Kontrol Modu</span>
                  <span className="text-[10px] text-slate-400 block truncate">Yönetici genel görünümü</span>
                </div>
              </div>
            ) : null}

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
                          <span className="px-1.5 py-0.5 rounded-md text-[11px] font-bold bg-[#FF6B00] text-white tabular-nums">
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
                      <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400">
                        Hoppa Merkez Yönetimi
                      </span>
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

                        {!isSidebarCollapsed && isActive && (
                          <ChevronRight className="w-3.5 h-3.5 text-[#FF6B00] shrink-0" />
                        )}

                        {isSidebarCollapsed && (
                          <div className="absolute left-full ml-3 px-3 py-1.5 bg-slate-900 dark:bg-slate-800 text-white text-xs font-bold rounded-xl shadow-xl opacity-0 invisible group-hover:opacity-100 group-hover:visible transition-all whitespace-nowrap z-50 flex items-center gap-2 pointer-events-none">
                            <span>{item.label}</span>
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
                  className={`hidden sm:inline-flex items-center gap-2 pr-3 mr-0.5 border-r text-xs font-semibold shrink-0 ${
                    isDark ? 'border-slate-800 text-slate-400' : 'border-slate-200 text-slate-500'
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
                        ? 'bg-[#00A651]'
                        : 'bg-amber-500 animate-pulse'
                    }`}
                  />
                  <span>{realtimeState === 'connected' ? 'Anlık Akış' : 'Bağlanıyor…'}</span>
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

              {/* Merchant Profile Lockup */}
              <div className={`hidden sm:flex items-center gap-2 pl-2 border-l ${
                isDark ? 'border-slate-800' : 'border-slate-200'
              }`}>
                {isAdmin ? (
                  <img
                    src="/logo-mark.svg"
                    alt="Hoppa"
                    className="w-8 h-8 rounded-lg object-cover ring-1 ring-black/5 shrink-0"
                  />
                ) : (
                  <div className="w-8 h-8 rounded-lg bg-slate-900 text-white border border-slate-800 font-extrabold flex items-center justify-center text-xs shrink-0">
                    {profile?.businessName ? profile.businessName.charAt(0).toUpperCase() : 'M'}
                  </div>
                )}
                <div className="text-left hidden lg:block">
                  <span className="text-xs font-black text-slate-900 dark:text-white block truncate max-w-[120px]">
                    {profile?.businessName || 'Satıcı'}
                  </span>
                  <span className="text-[10px] font-semibold text-slate-400 block">
                    {roleSubtitleLabel}
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

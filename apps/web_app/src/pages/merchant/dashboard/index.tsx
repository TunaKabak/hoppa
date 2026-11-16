import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { useRouter } from 'next/router';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import StoreReadinessWidget from '../../../components/merchant/StoreReadinessWidget';
import {
  TrendingUp,
  ShoppingBag,
  Clock,
  DollarSign,
  ShieldCheck,
  Star,
  Building2,
  ArrowRight,
  RefreshCw,
  CreditCard,
  BarChart3,
  AlertCircle,
} from 'lucide-react';
import { merchantApiFetch } from '../../../utils/merchant-auth';
import {
  isRealtimeEventEnvelope,
  REALTIME_WINDOW_EVENT,
} from '../../../utils/realtime-client';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';

interface TopProductStat {
  name: string;
  count: number;
  revenue: number;
}

interface WeeklyTrendPoint {
  date: string;
  label?: string;
  orderCount: number;
  revenue?: number;
}

interface LiveFunnelStats {
  pending: number;
  preparing: number;
  onTheWay: number;
  deliveredToday: number;
}

interface ShopBankSummary {
  iban: string;
  bankName: string;
  accountHolder: string;
}

interface DashboardStatsData {
  totalRevenue?: number;
  totalOrders?: number;
  todayOrderCount?: number;
  cancelRate?: number;
  acceptanceRate?: number | null;
  avgDeliveryTimeLabel?: string | null;
  activeCommissionRate?: number;
  liveFunnel?: LiveFunnelStats;
  weeklyTrend?: WeeklyTrendPoint[];
  topProducts?: TopProductStat[];
  bankInfo?: ShopBankSummary | null;
}

interface ShopSummaryInfo {
  name?: string;
  isActive?: boolean;
  address?: string;
  averageRating?: number;
  reviewCount?: number;
  deliveryTime?: string;
  activeCommissionRate?: number;
}

function maskIban(iban: string): string {
  const clean = iban.replace(/\s+/g, '');
  if (clean.length <= 10) return clean;
  return `${clean.slice(0, 4)} •••• •••• ${clean.slice(-4)}`;
}

export default function MerchantDashboardPage() {
  const router = useRouter();
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [timeRange, setTimeRange] = useState<'today' | 'week' | 'month'>('week');
  const [stats, setStats] = useState<DashboardStatsData | null>(null);
  const [shopInfo, setShopInfo] = useState<ShopSummaryInfo | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [hoveredDay, setHoveredDay] = useState<WeeklyTrendPoint | null>(null);

  const fetchStats = useCallback(async () => {
    setIsLoading(true);
    try {
      const [statsSettled, shopSettled] = await Promise.allSettled([
        merchantApiFetch(`/merchant/dashboard/stats?range=${timeRange}`),
        merchantApiFetch('/merchant/shop'),
      ]);

      if (statsSettled.status === 'fulfilled' && statsSettled.value.data) {
        setStats(statsSettled.value.data as DashboardStatsData);
      } else if (statsSettled.status === 'rejected') {
        console.error('İstatistikler alınamadı:', statsSettled.reason);
      }

      if (shopSettled.status === 'fulfilled' && shopSettled.value.data) {
        setShopInfo(shopSettled.value.data as ShopSummaryInfo);
      }
    } catch (err: unknown) {
      console.error('İstatistikler alınamadı:', err);
    } finally {
      setIsLoading(false);
    }
  }, [timeRange]);

  const fetchStatsRef = useRef(fetchStats);
  fetchStatsRef.current = fetchStats;

  useEffect(() => {
    void fetchStats();
  }, [fetchStats]);

  useEffect(() => {
    if (typeof window === 'undefined') return;

    const handleRealtimeEvent = (event: Event) => {
      if (!(event instanceof CustomEvent)) return;
      if (!isRealtimeEventEnvelope(event.detail)) return;
      if (
        event.detail.type === 'NEW_ORDER' ||
        event.detail.type === 'ORDER_CANCELLED' ||
        event.detail.type === 'ORDER_STATUS_UPDATED'
      ) {
        void fetchStatsRef.current();
      }
    };

    window.addEventListener(REALTIME_WINDOW_EVENT, handleRealtimeEvent);
    return () => {
      window.removeEventListener(REALTIME_WINDOW_EVENT, handleRealtimeEvent);
    };
  }, []);

  const totalRevenue = Number(stats?.totalRevenue ?? 0);
  const totalOrders = Number(stats?.totalOrders ?? 0);
  const avgBasket = totalOrders > 0 ? totalRevenue / totalOrders : 0;
  const acceptanceRateText =
    typeof stats?.acceptanceRate === 'number' ? `%${stats.acceptanceRate.toFixed(1)}` : '—';
  const deliveryTimeLabel =
    stats?.avgDeliveryTimeLabel || shopInfo?.deliveryTime || 'Tanımlanmadı';

  const funnel: LiveFunnelStats = stats?.liveFunnel || {
    pending: 0,
    preparing: 0,
    onTheWay: 0,
    deliveredToday: 0,
  };

  const topProducts: TopProductStat[] = Array.isArray(stats?.topProducts)
    ? stats.topProducts
    : [];
  const weeklyTrend: WeeklyTrendPoint[] = Array.isArray(stats?.weeklyTrend)
    ? stats.weeklyTrend
    : [];

  const shopDisplayName = shopInfo?.name?.trim() || 'Mağaza Operasyonu';
  const isShopOpen = shopInfo?.isActive ?? false;
  const shopAddress = shopInfo?.address?.trim();
  const reviewCount = typeof shopInfo?.reviewCount === 'number' ? shopInfo.reviewCount : 0;
  const ratingValue =
    reviewCount > 0 && typeof shopInfo?.averageRating === 'number'
      ? shopInfo.averageRating.toFixed(1)
      : '—';

  const hoppaCommissionRate =
    typeof stats?.activeCommissionRate === 'number'
      ? stats.activeCommissionRate
      : typeof shopInfo?.activeCommissionRate === 'number'
        ? shopInfo.activeCommissionRate
        : 0.05;
  const commissionPct = Math.round(hoppaCommissionRate * 100);
  const commissionFee = totalRevenue * hoppaCommissionRate;
  const netPayout = Math.max(0, totalRevenue - commissionFee);
  const bankInfo = stats?.bankInfo || null;

  const maxChartRevenue = useMemo(() => {
    const maxVal = weeklyTrend.reduce((acc, pt) => Math.max(acc, Number(pt.revenue || 0)), 0);
    return maxVal > 0 ? maxVal : 1;
  }, [weeklyTrend]);

  const maxChartOrders = useMemo(() => {
    const maxVal = weeklyTrend.reduce((acc, pt) => Math.max(acc, Number(pt.orderCount || 0)), 0);
    return maxVal > 0 ? maxVal : 1;
  }, [weeklyTrend]);

  const periodLabel =
    timeRange === 'today' ? 'Bugün' : timeRange === 'month' ? 'Son 30 Gün' : 'Son 7 Gün';

  const headerFilterActions = (
    <div className="flex items-center gap-2">
      <div
        className={`flex items-center rounded-xl border p-1 ${
          isDark ? 'bg-slate-800/90 border-slate-700' : 'bg-slate-100/90 border-slate-200/80'
        }`}
      >
        {(
          [
            { id: 'today', label: 'Bugün' },
            { id: 'week', label: 'Bu Hafta' },
            { id: 'month', label: 'Bu Ay' },
          ] as const
        ).map((tab) => {
          const active = timeRange === tab.id;
          return (
            <button
              key={tab.id}
              type="button"
              onClick={() => setTimeRange(tab.id)}
              className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                active
                  ? isDark
                    ? 'bg-slate-950 text-white shadow-2xs'
                    : 'bg-white text-slate-900 shadow-2xs'
                  : isDark
                    ? 'text-slate-400 hover:text-slate-200'
                    : 'text-slate-500 hover:text-slate-800'
              }`}
            >
              {tab.label}
            </button>
          );
        })}
      </div>

      <button
        type="button"
        onClick={() => void fetchStats()}
        disabled={isLoading}
        aria-label="Verileri Yenile"
        className={`p-2 rounded-xl border transition-colors ${
          isDark
            ? 'bg-slate-800 border-slate-700 text-slate-200 hover:bg-slate-700'
            : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'
        }`}
        title="Verileri Yenile"
      >
        <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
      </button>
    </div>
  );

  return (
    <MerchantLayout
      title="Kurumsal Yönetici Paneli"
      subtitle="Gerçek zamanlı ciro performansı, canlı sipariş akışı ve hakediş mutabakatı"
      headerIcon={Building2}
      headerActions={headerFilterActions}
      activeTab="dashboard"
    >
      <div className="space-y-6">
        {/* Executive Overview Banner */}
        <div
          className={`p-5 rounded-2xl border flex flex-col md:flex-row items-start md:items-center justify-between gap-4 transition-all ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/90 shadow-2xs'
          }`}
        >
          <div className="flex items-center gap-3.5 min-w-0">
            <span
              className={`w-1 h-10 rounded-full shrink-0 ${
                isShopOpen ? 'bg-[#00A651]' : 'bg-slate-400'
              }`}
              aria-hidden="true"
            />
            <div className="min-w-0">
              <h2 className="text-sm sm:text-base font-extrabold tracking-tight truncate">
                {shopDisplayName}
                <span className="text-slate-300 dark:text-slate-700 mx-1.5">·</span>
                <span
                  className={
                    isShopOpen ? 'text-[#00A651] dark:text-emerald-400' : 'text-slate-400'
                  }
                >
                  {isShopOpen ? 'Sipariş Alımı Açık' : 'Sipariş Alımı Kapalı'}
                </span>
              </h2>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5 font-medium truncate">
                {shopAddress ||
                  'KKTC teslimat ağı üzerinden canlı sipariş ve kurye operasyonu yürütülüyor.'}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-5 w-full md:w-auto tabular-nums">
            <div className="border-l border-slate-200 dark:border-slate-800 pl-5">
              <span className="text-[11px] font-bold tracking-wide text-slate-400 block">
                Mağaza Puanı
              </span>
              <span className="inline-flex items-center gap-1.5 text-sm font-black mt-0.5">
                <Star className="w-3.5 h-3.5 fill-amber-400 text-amber-400 shrink-0" />
                <span>{ratingValue}</span>
                <span className="text-[11px] text-slate-400 font-semibold">
                  ({reviewCount} değerlendirme)
                </span>
              </span>
            </div>
            <div className="border-l border-slate-200 dark:border-slate-800 pl-5">
              <span className="text-[11px] font-bold tracking-wide text-slate-400 block">
                Kabul Oranı
              </span>
              <span className="text-sm font-black text-[#00A651] dark:text-emerald-400 mt-0.5 block">
                {acceptanceRateText}
              </span>
            </div>
          </div>
        </div>

        {/* Store Readiness & Onboarding Hub */}
        <StoreReadinessWidget />

        {/* Core Metric Cards Grid */}
        {isLoading ? (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {[0, 1, 2, 3].map((idx) => (
              <div
                key={idx}
                className={`p-5 rounded-2xl border animate-pulse space-y-3 ${
                  isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/90'
                }`}
              >
                <div className="h-3 w-24 rounded bg-slate-200 dark:bg-slate-800" />
                <div className="h-7 w-32 rounded bg-slate-200 dark:bg-slate-800" />
                <div className="h-3 w-28 rounded bg-slate-200 dark:bg-slate-800" />
              </div>
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 tabular-nums">
            <div
              className={`p-5 rounded-2xl border transition-all ${
                isDark
                  ? 'bg-slate-900 border-slate-800'
                  : 'bg-white border-slate-200/90 shadow-2xs hover:border-[#FF6B00]/40'
              }`}
            >
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-extrabold tracking-wide text-slate-400">
                  Brüt Ciro ({periodLabel})
                </span>
                <div className="w-9 h-9 rounded-xl bg-[#FF6B00]/10 text-[#FF6B00] flex items-center justify-center font-bold">
                  <DollarSign className="w-5 h-5" />
                </div>
              </div>
              <p className="text-2xl font-black text-[#FF6B00]">
                ₺{totalRevenue.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
              </p>
              <p className="text-[11px] font-semibold text-slate-400 mt-2">
                Tamamlanan &amp; ödenen siparişler toplamı
              </p>
            </div>

            <div
              className={`p-5 rounded-2xl border transition-all ${
                isDark
                  ? 'bg-slate-900 border-slate-800'
                  : 'bg-white border-slate-200/90 shadow-2xs hover:border-indigo-500/40'
              }`}
            >
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-extrabold tracking-wide text-slate-400">
                  Sipariş Adedi ({periodLabel})
                </span>
                <div className="w-9 h-9 rounded-xl bg-indigo-500/10 text-indigo-500 flex items-center justify-center font-bold">
                  <ShoppingBag className="w-5 h-5" />
                </div>
              </div>
              <p className="text-2xl font-black">
                {totalOrders} <span className="text-xs text-slate-400 font-bold">Adet</span>
              </p>
              <p className="text-[11px] font-semibold text-slate-400 mt-2">
                İptal oranı: %{(stats?.cancelRate ?? 0).toFixed(1)}
              </p>
            </div>

            <div
              className={`p-5 rounded-2xl border transition-all ${
                isDark
                  ? 'bg-slate-900 border-slate-800'
                  : 'bg-white border-slate-200/90 shadow-2xs hover:border-amber-500/40'
              }`}
            >
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-extrabold tracking-wide text-slate-400">
                  Ortalama Sepet
                </span>
                <div className="w-9 h-9 rounded-xl bg-amber-500/10 text-amber-500 flex items-center justify-center font-bold">
                  <TrendingUp className="w-5 h-5" />
                </div>
              </div>
              <p className="text-2xl font-black">
                ₺{avgBasket.toLocaleString('tr-TR', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}
              </p>
              <p className="text-[11px] text-slate-400 mt-2 font-semibold">
                {totalOrders > 0 ? 'Sipariş başına gerçekleşen ortalama' : 'Henüz veri bulunmuyor'}
              </p>
            </div>

            <div
              className={`p-5 rounded-2xl border transition-all ${
                isDark
                  ? 'bg-slate-900 border-slate-800'
                  : 'bg-white border-slate-200/90 shadow-2xs hover:border-emerald-500/40'
              }`}
            >
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-extrabold tracking-wide text-slate-400">
                  Tahmini Teslimat Süresi
                </span>
                <div className="w-9 h-9 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center font-bold">
                  <Clock className="w-5 h-5" />
                </div>
              </div>
              <p className="text-2xl font-black text-emerald-600 dark:text-emerald-400">
                {deliveryTimeLabel}
              </p>
              <p className="text-[11px] text-slate-400 mt-2 font-semibold">
                Mağaza operasyon ayarına göre
              </p>
            </div>
          </div>
        )}

        {/* 7-Day SVG Trend Chart & Live Operational Funnel */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          {/* Weekly Revenue & Orders Chart (5 cols) */}
          <div
            className={`lg:col-span-5 p-6 rounded-2xl border flex flex-col justify-between transition-all ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/90 shadow-2xs'
            }`}
          >
            <div className="flex items-center justify-between mb-4">
              <div>
                <h3 className="font-extrabold text-sm flex items-center gap-2">
                  <BarChart3 className="w-4 h-4 text-[#FF6B00]" />
                  <span>7 Günlük Sipariş &amp; Ciro Trendi</span>
                </h3>
                <p className="text-[11px] text-slate-400 mt-0.5 font-medium tabular-nums">
                  {hoveredDay
                    ? `${hoveredDay.label || hoveredDay.date}: ${hoveredDay.orderCount} sipariş • ₺${Number(hoveredDay.revenue || 0).toLocaleString('tr-TR', { minimumFractionDigits: 2 })}`
                    : 'Detay görmek için çubukların üzerine gelin'}
                </p>
              </div>
            </div>

            {weeklyTrend.length === 0 ? (
              <div className="py-10 text-center text-xs text-slate-400 font-semibold">
                Trend grafiği için veri bekleniyor.
              </div>
            ) : (
              <div className="pt-2">
                <svg
                  viewBox="0 0 350 150"
                  className="w-full h-40 overflow-visible"
                  role="img"
                  aria-label="Son 7 gün sipariş ve ciro grafiği"
                >
                  {[0, 0.5, 1].map((ratio, idx) => {
                    const y = 115 - ratio * 90;
                    return (
                      <line
                        key={idx}
                        x1="8"
                        y1={y}
                        x2="342"
                        y2={y}
                        stroke={isDark ? '#1E293B' : '#E2E8F0'}
                        strokeDasharray="3 3"
                        strokeWidth="1"
                      />
                    );
                  })}

                  {weeklyTrend.map((point, idx) => {
                    const barSlotW = 336 / weeklyTrend.length;
                    const barW = Math.min(28, barSlotW * 0.54);
                    const x = 10 + idx * barSlotW + (barSlotW - barW) / 2;
                    const rev = Number(point.revenue || 0);
                    const metricRatio =
                      rev > 0
                        ? rev / maxChartRevenue
                        : (Number(point.orderCount || 0) / maxChartOrders) * 0.6;
                    const barH = Math.max(metricRatio > 0 ? 8 : 3, Math.round(metricRatio * 90));
                    const y = 115 - barH;
                    const isHovered = hoveredDay?.date === point.date;

                    return (
                      <g
                        key={point.date}
                        onMouseEnter={() => setHoveredDay(point)}
                        onMouseLeave={() => setHoveredDay(null)}
                        className="cursor-pointer"
                      >
                        <rect
                          x={x}
                          y={y}
                          width={barW}
                          height={barH}
                          rx="6"
                          fill={
                            rev > 0 || point.orderCount > 0
                              ? isHovered
                                ? '#E55A00'
                                : '#FF6B00'
                              : isDark
                                ? '#334155'
                                : '#CBD5E1'
                          }
                          opacity={isHovered ? 1 : 0.88}
                        />
                        {point.orderCount > 0 && (
                          <text
                            x={x + barW / 2}
                            y={y - 6}
                            textAnchor="middle"
                            fontSize="9"
                            fontWeight="700"
                            fill={isDark ? '#E2E8F0' : '#475569'}
                          >
                            {point.orderCount}
                          </text>
                        )}
                        <text
                          x={x + barW / 2}
                          y="134"
                          textAnchor="middle"
                          fontSize="10"
                          fontWeight="700"
                          fill={isDark ? '#94A3B8' : '#64748B'}
                        >
                          {point.label || point.date.slice(5)}
                        </text>
                      </g>
                    );
                  })}
                </svg>
              </div>
            )}
          </div>

          {/* Live Operational Order Funnel (7 cols) */}
          <div
            className={`lg:col-span-7 p-6 rounded-2xl border flex flex-col justify-between transition-all ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/90 shadow-2xs'
            }`}
          >
            <div className="flex items-center justify-between mb-5 gap-3">
              <div>
                <h3 className="font-extrabold text-sm">Canlı Sipariş Operasyon Akışı</h3>
                <p className="text-xs text-slate-500 dark:text-slate-400">
                  Mutfak ve kurye aşamasındaki anlık sipariş dağılımı
                </p>
              </div>
              <button
                type="button"
                onClick={() => void router.push('/merchant/orders')}
                className="inline-flex items-center gap-1.5 text-xs font-bold text-slate-600 dark:text-slate-300 hover:text-[#FF6B00] transition-colors shrink-0"
              >
                <span>Sipariş Panosuna Git</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 tabular-nums">
              <div
                className={`p-4 rounded-2xl border ${
                  isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                }`}
              >
                <div className="flex items-center justify-between text-xs text-slate-500 mb-1">
                  <span className="font-bold">Yeni Bekleyen</span>
                  <span className="w-2 h-2 rounded-full bg-amber-500" />
                </div>
                <p className="text-2xl font-black text-amber-500">{funnel.pending}</p>
                <span className="text-[11px] text-slate-400 font-semibold block mt-1">
                  Onay bekliyor
                </span>
              </div>

              <div
                className={`p-4 rounded-2xl border ${
                  isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                }`}
              >
                <div className="flex items-center justify-between text-xs text-slate-500 mb-1">
                  <span className="font-bold">Hazırlanıyor</span>
                  <span className="w-2 h-2 rounded-full bg-[#FF6B00]" />
                </div>
                <p className="text-2xl font-black text-[#FF6B00]">{funnel.preparing}</p>
                <span className="text-[11px] text-slate-400 font-semibold block mt-1">
                  Mutfakta işlemde
                </span>
              </div>

              <div
                className={`p-4 rounded-2xl border ${
                  isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                }`}
              >
                <div className="flex items-center justify-between text-xs text-slate-500 mb-1">
                  <span className="font-bold">Kuryede / Hazır</span>
                  <span className="w-2 h-2 rounded-full bg-indigo-500" />
                </div>
                <p className="text-2xl font-black text-indigo-500">{funnel.onTheWay}</p>
                <span className="text-[11px] text-slate-400 font-semibold block mt-1">
                  Teslimat aşamasında
                </span>
              </div>

              <div
                className={`p-4 rounded-2xl border ${
                  isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
                }`}
              >
                <div className="flex items-center justify-between text-xs text-slate-500 mb-1">
                  <span className="font-bold">Bugün Teslim</span>
                  <span className="w-2 h-2 rounded-full bg-[#00A651]" />
                </div>
                <p className="text-2xl font-black text-[#00A651] dark:text-emerald-400">
                  {funnel.deliveredToday}
                </p>
                <span className="text-[11px] text-slate-400 font-semibold block mt-1">
                  Bugün tamamlandı
                </span>
              </div>
            </div>
          </div>
        </div>

        {/* Two Column Section: Top Products + Financial Settlement Report */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Top Products Bestsellers */}
          <div
            className={`p-6 rounded-2xl border space-y-4 transition-all ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/90 shadow-2xs'
            }`}
          >
            <div className="flex items-center justify-between pb-3 border-b border-slate-200 dark:border-slate-800">
              <div className="flex items-center gap-2">
                <ShoppingBag className="w-4 h-4 text-[#FF6B00]" />
                <h3 className="font-extrabold text-sm">En Çok Satan 5 Ürün ({periodLabel})</h3>
              </div>
              <button
                type="button"
                onClick={() => void router.push('/merchant/products')}
                className="text-xs text-slate-400 hover:text-[#FF6B00] font-bold"
              >
                Menüye Git
              </button>
            </div>

            {topProducts.length === 0 ? (
              <div
                className={`p-8 rounded-2xl border text-center space-y-3 ${
                  isDark ? 'bg-slate-950/60 border-slate-800' : 'bg-slate-50 border-slate-200'
                }`}
              >
                <ShoppingBag className="w-8 h-8 text-slate-400 mx-auto opacity-70" />
                <div className="space-y-1">
                  <p className="text-xs font-bold text-slate-600 dark:text-slate-300">
                    Seçili dönemde henüz tamamlanan ürün satışı bulunmuyor.
                  </p>
                  <p className="text-[11px] text-slate-400">
                    Siparişler tamamlandıkça en çok tercih edilen ürünleriniz burada listelenir.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => void router.push('/merchant/products')}
                  className="px-4 py-2 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-bold inline-flex items-center gap-1.5"
                >
                  <span>Ürün &amp; Menü Portalına Git</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </button>
              </div>
            ) : (
              <div className="space-y-3">
                {topProducts.map((prod, idx) => (
                  <div
                    key={`${prod.name}-${idx}`}
                    className={`p-3.5 rounded-2xl border flex items-center justify-between transition-colors ${
                      isDark
                        ? 'bg-slate-950 border-slate-800'
                        : 'bg-slate-50 border-slate-200 hover:border-slate-300'
                    }`}
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <div className="w-8 h-8 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-200 flex items-center justify-center font-black text-xs tabular-nums shrink-0">
                        #{idx + 1}
                      </div>
                      <div className="min-w-0">
                        <h4 className="font-bold text-sm truncate">{prod.name}</h4>
                        <span className="text-xs text-slate-400 font-semibold tabular-nums">
                          {prod.count} adet satıldı
                        </span>
                      </div>
                    </div>

                    <span className="font-black text-sm text-[#FF6B00] tabular-nums shrink-0 ml-2">
                      ₺{Number(prod.revenue).toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Financial Settlement & Payout Report */}
          <div
            className={`p-6 rounded-2xl border space-y-4 transition-all ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/90 shadow-2xs'
            }`}
          >
            <div className="flex items-center justify-between pb-3 border-b border-slate-200 dark:border-slate-800 gap-2">
              <div className="flex items-center gap-2">
                <ShieldCheck className="w-4 h-4 text-emerald-600 dark:text-emerald-400" />
                <h3 className="font-extrabold text-sm">Hakediş &amp; Finans Özeti</h3>
              </div>
              <button
                type="button"
                onClick={() => void router.push('/merchant/finance')}
                className="inline-flex items-center gap-1 text-xs font-bold text-[#FF6B00] hover:underline shrink-0"
              >
                <span>Finans &amp; IBAN Merkezi</span>
                <ArrowRight className="w-3.5 h-3.5" />
              </button>
            </div>

            <div
              className={`p-4 rounded-2xl border space-y-3 tabular-nums ${
                isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
              }`}
            >
              <div className="flex justify-between text-xs font-bold">
                <span className="text-slate-500">Brüt Satış Cirosu ({periodLabel}):</span>
                <span>₺{totalRevenue.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}</span>
              </div>

              <div className="flex justify-between text-xs font-bold text-rose-500">
                <span>Aktif Hoppa Komisyon Oranı (%{commissionPct}):</span>
                <span>
                  -₺{commissionFee.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
                </span>
              </div>

              <div className="pt-3 border-t border-slate-200 dark:border-slate-800 flex justify-between items-center gap-2">
                <div>
                  <span className="text-xs text-slate-400 font-extrabold block">
                    Tahmini Net Hakediş Tutarı
                  </span>
                  <span className="text-xs text-slate-500 font-semibold">
                    Pazartesi 09:00 otomatik ödeme periyodu
                  </span>
                </div>
                <span className="text-xl font-black text-emerald-600 dark:text-emerald-400 shrink-0">
                  ₺{netPayout.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
                </span>
              </div>
            </div>

            {bankInfo ? (
              <div
                className={`p-3.5 rounded-2xl border flex items-center justify-between gap-3 ${
                  isDark ? 'bg-slate-950/60 border-slate-800' : 'bg-emerald-50/50 border-emerald-200/70'
                }`}
              >
                <div className="flex items-center gap-2.5 min-w-0">
                  <CreditCard className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0" />
                  <div className="min-w-0">
                    <p className="text-xs font-bold truncate">
                      {bankInfo.bankName} · {bankInfo.accountHolder}
                    </p>
                    <p className="text-[11px] font-mono text-slate-500 dark:text-slate-400">
                      {maskIban(bankInfo.iban)}
                    </p>
                  </div>
                </div>
                <button
                  type="button"
                  onClick={() => void router.push('/merchant/finance')}
                  className="px-3 py-1.5 rounded-xl bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-[11px] font-bold shrink-0 hover:border-[#FF6B00]"
                >
                  Düzenle
                </button>
              </div>
            ) : (
              <div className="p-3.5 rounded-2xl border border-amber-500/30 bg-amber-500/10 flex items-center justify-between gap-3">
                <div className="flex items-center gap-2.5 min-w-0">
                  <AlertCircle className="w-4 h-4 text-amber-500 shrink-0" />
                  <p className="text-xs font-bold text-amber-700 dark:text-amber-300">
                    Banka / IBAN bilgisi henüz tanımlanmadı. Hakediş aktarımı için tanımlayın.
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => void router.push('/merchant/finance')}
                  className="px-3 py-1.5 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-[11px] font-bold shrink-0"
                >
                  IBAN Ekle
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </MerchantLayout>
  );
}

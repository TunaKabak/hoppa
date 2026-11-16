import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Star, RefreshCw, AlertCircle, MessageSquare, Clock, Truck, ShieldCheck } from 'lucide-react';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import HoppaSelect from '../../../components/merchant/HoppaSelect';
import StatusIndicator, { StatusTone } from '../../../components/merchant/StatusIndicator';
import { merchantApiFetch } from '../../../utils/merchant-auth';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';

interface ShopRatingSummary {
  id: string;
  name: string;
  averageRating: number;
  reviewCount: number;
  avgServiceRating: number;
  avgSpeedRating: number;
  avgTasteRating: number;
}

interface MerchantReviewItem {
  id: string;
  rating: number;
  comment?: string | null;
  serviceRating?: number | null;
  speedRating?: number | null;
  tasteRating?: number | null;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  createdAt: string;
  user?: {
    name?: string | null;
    surname?: string | null;
  } | null;
  order?: {
    id: string;
    totalAmount: string | number;
    createdAt: string;
  } | null;
}

export default function MerchantReviewsPage() {
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [shopSummary, setShopSummary] = useState<ShopRatingSummary | null>(null);
  const [reviews, setReviews] = useState<MerchantReviewItem[]>([]);
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [ratingFilter, setRatingFilter] = useState<string>('ALL');
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const fetchReviews = useCallback(async () => {
    setIsLoading(true);
    setErrorMsg(null);
    try {
      const res = await merchantApiFetch('/merchant/reviews');
      const payload = res.data as
        | { shop?: ShopRatingSummary; reviews?: MerchantReviewItem[] }
        | undefined;
      if (payload?.shop) {
        setShopSummary(payload.shop);
      }
      setReviews(Array.isArray(payload?.reviews) ? payload.reviews : []);
    } catch (err: unknown) {
      setErrorMsg(err instanceof Error ? err.message : 'Müşteri yorumları yüklenemedi.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchReviews();
  }, [fetchReviews]);

  const filteredReviews = useMemo(() => {
    return reviews.filter((rev) => {
      if (statusFilter !== 'ALL' && rev.status !== statusFilter) {
        return false;
      }
      if (ratingFilter !== 'ALL' && rev.rating !== Number(ratingFilter)) {
        return false;
      }
      return true;
    });
  }, [reviews, statusFilter, ratingFilter]);

  const distribution = useMemo(() => {
    const counts: Record<number, number> = { 5: 0, 4: 0, 3: 0, 2: 0, 1: 0 };
    for (const r of reviews) {
      if (counts[r.rating] !== undefined) {
        counts[r.rating] += 1;
      }
    }
    return counts;
  }, [reviews]);

  return (
    <MerchantLayout
      title="Müşteri Değerlendirmeleri"
      subtitle="Mağaza puan kırılımlarını ve müşteri geri bildirimlerini inceleyin"
      headerIcon={Star}
      activeTab="reviews"
      headerActions={
        <button
          type="button"
          onClick={fetchReviews}
          disabled={isLoading}
          className={`px-3 py-2 rounded-xl border text-xs font-black flex items-center gap-1.5 ${
            isDark
              ? 'bg-slate-800 border-slate-700 text-slate-200 hover:bg-slate-700'
              : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50'
          }`}
        >
          <RefreshCw className={`w-3.5 h-3.5 ${isLoading ? 'animate-spin' : ''}`} />
          <span>Yenile</span>
        </button>
      }
    >
      <div className="space-y-6">
        {errorMsg && (
          <div className="p-4 rounded-2xl bg-rose-500/10 border border-rose-500/30 text-rose-500 text-xs font-bold flex items-center gap-2.5">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{errorMsg}</span>
          </div>
        )}

        {/* Rating KPIs */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {[
            {
              label: 'Genel Puan',
              value: (shopSummary?.averageRating ?? 5).toFixed(2),
              sub: `${shopSummary?.reviewCount ?? reviews.length} değerlendirme`,
              icon: Star,
              color: 'text-amber-500',
            },
            {
              label: 'Servis Puanı',
              value: (shopSummary?.avgServiceRating ?? 5).toFixed(2),
              sub: 'Paketleme & sunum',
              icon: ShieldCheck,
              color: 'text-[#FF6B00]',
            },
            {
              label: 'Teslimat Hızı',
              value: (shopSummary?.avgSpeedRating ?? 5).toFixed(2),
              sub: 'Hazırlık & varış',
              icon: Truck,
              color: 'text-emerald-500',
            },
            {
              label: 'Lezzet / Kalite',
              value: (shopSummary?.avgTasteRating ?? 5).toFixed(2),
              sub: 'Ürün memnuniyeti',
              icon: Clock,
              color: 'text-sky-500',
            },
          ].map((kpi) => {
            const Icon = kpi.icon;
            return (
              <div
                key={kpi.label}
                className={`p-4 rounded-2xl border ${
                  isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/80 shadow-2xs'
                }`}
              >
                <div className="flex items-center justify-between mb-2">
                  <span className="text-[11px] font-bold uppercase tracking-wider text-slate-400">
                    {kpi.label}
                  </span>
                  <Icon className={`w-4 h-4 ${kpi.color}`} />
                </div>
                <p className="text-2xl font-black tabular-nums">{kpi.value}</p>
                <p className="text-[11px] text-slate-400 mt-0.5 tabular-nums">{kpi.sub}</p>
              </div>
            );
          })}
        </div>

        {/* Distribution + Filter Bar */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
          <div
            className={`lg:col-span-2 p-5 rounded-2xl border space-y-2.5 ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/80 shadow-2xs'
            }`}
          >
            <h3 className="text-xs font-black uppercase tracking-wider text-slate-400 mb-3">
              Yıldız Dağılımı
            </h3>
            {[5, 4, 3, 2, 1].map((stars) => {
              const count = distribution[stars] || 0;
              const pct = reviews.length > 0 ? Math.round((count / reviews.length) * 100) : 0;
              return (
                <div key={stars} className="flex items-center gap-3 text-xs">
                  <span className="w-12 font-black tabular-nums flex items-center gap-1">
                    {stars} <Star className="w-3 h-3 text-amber-500 fill-amber-500" />
                  </span>
                  <div className="flex-1 h-2.5 rounded-full bg-slate-100 dark:bg-slate-800 overflow-hidden">
                    <div
                      className="h-full rounded-full bg-[#FF6B00] transition-all"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                  <span className="w-16 text-right font-bold text-slate-400 tabular-nums">
                    {count} (%{pct})
                  </span>
                </div>
              );
            })}
          </div>

          <div
            className={`p-5 rounded-2xl border space-y-3 ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/80 shadow-2xs'
            }`}
          >
            <HoppaSelect
              label="Yayın Durumu"
              value={statusFilter}
              onChange={setStatusFilter}
              options={[
                { value: 'ALL', label: 'Tüm Değerlendirmeler' },
                { value: 'APPROVED', label: 'Onaylı & Yayında' },
                { value: 'PENDING', label: 'Yönetici Onayı Bekleyen' },
                { value: 'REJECTED', label: 'Reddedilenler' },
              ]}
            />
            <HoppaSelect
              label="Puan Filtresi"
              value={ratingFilter}
              onChange={setRatingFilter}
              options={[
                { value: 'ALL', label: 'Tüm Puanlar' },
                { value: '5', label: '5 Yıldız' },
                { value: '4', label: '4 Yıldız' },
                { value: '3', label: '3 Yıldız' },
                { value: '2', label: '2 Yıldız' },
                { value: '1', label: '1 Yıldız' },
              ]}
            />
          </div>
        </div>

        {/* Reviews List */}
        {isLoading ? (
          <div className="py-16 flex flex-col items-center justify-center gap-3 text-slate-400">
            <div className="w-6 h-6 border-2 border-[#FF6B00] border-t-transparent rounded-full animate-spin" />
            <span className="text-xs font-bold">Müşteri değerlendirmeleri yükleniyor...</span>
          </div>
        ) : filteredReviews.length === 0 ? (
          <div
            className={`py-16 rounded-2xl border text-center space-y-2 text-slate-400 ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200'
            }`}
          >
            <MessageSquare className="w-10 h-10 mx-auto opacity-50" />
            <p className="text-sm font-bold">Seçili filtreye uygun değerlendirme bulunmuyor.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {filteredReviews.map((rev) => {
              const customerDisplay =
                `${rev.user?.name || 'Hoppa'} ${rev.user?.surname ? `${rev.user.surname.charAt(0)}.` : ''}`.trim();
              const reviewStatusMeta: Record<
                MerchantReviewItem['status'],
                { label: string; tone: StatusTone }
              > = {
                APPROVED: { label: 'Yayında', tone: 'emerald' },
                REJECTED: { label: 'Reddedildi', tone: 'rose' },
                PENDING: { label: 'Onay Bekliyor', tone: 'amber' },
              };
              const statusBadge = reviewStatusMeta[rev.status];

              return (
                <div
                  key={rev.id}
                  className={`p-5 rounded-2xl border space-y-3 ${
                    isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/80 shadow-2xs'
                  }`}
                >
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <h4 className="text-sm font-black">{customerDisplay}</h4>
                      <p className="text-[11px] text-slate-400 font-semibold tabular-nums">
                        {new Date(rev.createdAt).toLocaleString('tr-TR')}
                        {rev.order?.id ? ` • Sipariş #${rev.order.id.slice(0, 8).toUpperCase()}` : ''}
                      </p>
                    </div>

                    <StatusIndicator
                      label={statusBadge.label}
                      tone={statusBadge.tone}
                      isDark={isDark}
                    />
                  </div>

                  <div className="flex flex-wrap items-center gap-2 text-xs font-black tabular-nums">
                    <span className="px-2.5 py-1 rounded-lg bg-amber-500/10 text-amber-500 inline-flex items-center gap-1">
                      <Star className="w-3.5 h-3.5 fill-amber-500" />
                      {rev.rating}/5
                    </span>
                    {rev.serviceRating && (
                      <span className="px-2 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-300">
                        Servis: {rev.serviceRating}
                      </span>
                    )}
                    {rev.speedRating && (
                      <span className="px-2 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-300">
                        Hız: {rev.speedRating}
                      </span>
                    )}
                    {rev.tasteRating && (
                      <span className="px-2 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-300">
                        Lezzet: {rev.tasteRating}
                      </span>
                    )}
                  </div>

                  <p
                    className={`text-xs leading-relaxed p-3 rounded-xl ${
                      isDark ? 'bg-slate-950/60 text-slate-300' : 'bg-slate-50 text-slate-700'
                    }`}
                  >
                    {rev.comment || 'Yalnızca yıldız puanlaması yapıldı.'}
                  </p>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </MerchantLayout>
  );
}

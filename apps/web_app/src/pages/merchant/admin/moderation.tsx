import React, { useCallback, useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import {
  ShieldCheck,
  Star,
  Megaphone,
  CheckCircle2,
  XCircle,
  AlertCircle,
  RefreshCw,
  Layers,
} from 'lucide-react';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import HoppaSelect from '../../../components/merchant/HoppaSelect';
import StatusIndicator, { StatusTone } from '../../../components/merchant/StatusIndicator';
import { getMerchantProfile, merchantApiFetch } from '../../../utils/merchant-auth';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';

type ModerationTab = 'reviews' | 'campaigns';

const MODERATION_STATUS_MAP: Record<string, { label: string; tone: StatusTone }> = {
  APPROVED: { label: 'Onaylı', tone: 'emerald' },
  REJECTED: { label: 'Reddedildi', tone: 'rose' },
  PENDING: { label: 'Onay Bekliyor', tone: 'amber' },
};

function getModerationStatusMeta(status: string): { label: string; tone: StatusTone } {
  return MODERATION_STATUS_MAP[status] || { label: status || 'Onay Bekliyor', tone: 'slate' };
}

interface AdminReviewItem {
  id: string;
  rating: number;
  comment?: string | null;
  serviceRating?: number | null;
  speedRating?: number | null;
  tasteRating?: number | null;
  status: 'PENDING' | 'APPROVED' | 'REJECTED';
  createdAt: string;
  user: {
    id: string;
    name?: string | null;
    surname?: string | null;
    phone: string;
  };
  shop: {
    id: string;
    name: string;
    type: string;
  };
  order: {
    id: string;
    totalAmount: string | number;
    createdAt: string;
  };
}

interface AdminCampaignItem {
  id: string;
  title: string;
  description: string;
  imageUrl: string;
  targetArea: string;
  designService: boolean;
  status: string;
  type: string;
  createdAt: string;
  shop?: {
    id: string;
    name: string;
    type: string;
  } | null;
}

export default function AdminModerationPage() {
  const router = useRouter();
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [isAuthorized, setIsAuthorized] = useState(false);
  const [activeModTab, setActiveModTab] = useState<ModerationTab>('reviews');
  const [reviewFilter, setReviewFilter] = useState<string>('ALL');
  const [campaignFilter, setCampaignFilter] = useState<string>('ALL');

  const [reviews, setReviews] = useState<AdminReviewItem[]>([]);
  const [campaigns, setCampaigns] = useState<AdminCampaignItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const loadModerationData = useCallback(async (revStatus: string, campStatus: string) => {
    setIsLoading(true);
    setErrorMsg(null);
    try {
      const [revRes, campRes] = await Promise.all([
        merchantApiFetch(`/admin/reviews?status=${encodeURIComponent(revStatus)}`),
        merchantApiFetch(`/admin/campaigns?status=${encodeURIComponent(campStatus)}`),
      ]);
      setReviews(Array.isArray(revRes.data) ? (revRes.data as AdminReviewItem[]) : []);
      setCampaigns(Array.isArray(campRes.data) ? (campRes.data as AdminCampaignItem[]) : []);
    } catch (err: unknown) {
      setErrorMsg(err instanceof Error ? err.message : 'Moderasyon verileri yüklenemedi.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    const profile = getMerchantProfile();
    if (!profile) {
      router.replace('/merchant/login');
      return;
    }
    if (profile.role !== 'super_admin' && profile.role !== 'admin') {
      router.replace('/merchant/dashboard');
      return;
    }
    setIsAuthorized(true);
    loadModerationData('ALL', 'ALL');
  }, [router, loadModerationData]);

  const handleReviewAction = async (reviewId: string, action: 'approve' | 'reject') => {
    setErrorMsg(null);
    setSuccessMsg(null);
    try {
      const res = await merchantApiFetch(`/admin/reviews/${reviewId}/${action}`, {
        method: 'PUT',
      });
      const rewardInfo =
        action === 'approve' && res.rewardAmount !== undefined
          ? ` (+${res.rewardAmount} Hoppa Para tanımlandı)`
          : '';
      setSuccessMsg((res.message || 'Yorum güncellendi.') + rewardInfo);
      await loadModerationData(reviewFilter, campaignFilter);
    } catch (err: unknown) {
      setErrorMsg(err instanceof Error ? err.message : 'Yorum işlemi başarısız oldu.');
    }
  };

  const handleCampaignAction = async (campaignId: string, status: 'APPROVED' | 'REJECTED') => {
    setErrorMsg(null);
    setSuccessMsg(null);
    try {
      const res = await merchantApiFetch(`/admin/campaigns/${campaignId}/approve`, {
        method: 'PUT',
        body: JSON.stringify({ status }),
      });
      setSuccessMsg(res.message || 'Kampanya durumu güncellendi.');
      await loadModerationData(reviewFilter, campaignFilter);
    } catch (err: unknown) {
      setErrorMsg(err instanceof Error ? err.message : 'Kampanya işlemi başarısız oldu.');
    }
  };

  if (!isAuthorized) {
    return null;
  }

  return (
    <MerchantLayout
      title="Moderasyon Merkezi"
      subtitle="Müşteri değerlendirmelerini (Hoppa Para ödüllü) ve mağaza kampanya/slider taleplerini yönetin"
      headerIcon={ShieldCheck}
      activeTab="admin-moderation"
      headerActions={
        <button
          type="button"
          onClick={() => loadModerationData(reviewFilter, campaignFilter)}
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
        {/* Tabs & Filters */}
        <div
          className={`p-4 rounded-2xl border flex flex-col sm:flex-row sm:items-center justify-between gap-3 ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/80 shadow-2xs'
          }`}
        >
          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => setActiveModTab('reviews')}
              className={`px-4 py-2 rounded-xl text-xs font-black inline-flex items-center gap-2 transition-colors ${
                activeModTab === 'reviews'
                  ? 'bg-[#FF6B00] text-white'
                  : isDark
                    ? 'bg-slate-800 text-slate-300 hover:bg-slate-700'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              }`}
            >
              <Star className="w-3.5 h-3.5" />
              <span>Yorum Moderasyonu ({reviews.length})</span>
            </button>
            <button
              type="button"
              onClick={() => setActiveModTab('campaigns')}
              className={`px-4 py-2 rounded-xl text-xs font-black inline-flex items-center gap-2 transition-colors ${
                activeModTab === 'campaigns'
                  ? 'bg-[#FF6B00] text-white'
                  : isDark
                    ? 'bg-slate-800 text-slate-300 hover:bg-slate-700'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              }`}
            >
              <Megaphone className="w-3.5 h-3.5" />
              <span>Kampanya & Sliderlar ({campaigns.length})</span>
            </button>
          </div>

          <div className="w-full sm:w-56">
            {activeModTab === 'reviews' ? (
              <HoppaSelect
                value={reviewFilter}
                onChange={(val) => {
                  setReviewFilter(val);
                  loadModerationData(val, campaignFilter);
                }}
                options={[
                  { value: 'ALL', label: 'Tüm Yorumlar' },
                  { value: 'PENDING', label: 'Onay Bekleyenler' },
                  { value: 'APPROVED', label: 'Onaylananlar' },
                  { value: 'REJECTED', label: 'Reddedilenler' },
                ]}
              />
            ) : (
              <HoppaSelect
                value={campaignFilter}
                onChange={(val) => {
                  setCampaignFilter(val);
                  loadModerationData(reviewFilter, val);
                }}
                options={[
                  { value: 'ALL', label: 'Tüm Kampanyalar' },
                  { value: 'PENDING', label: 'Onay Bekleyenler' },
                  { value: 'APPROVED', label: 'Onaylananlar' },
                  { value: 'REJECTED', label: 'Reddedilenler' },
                ]}
              />
            )}
          </div>
        </div>

        {errorMsg && (
          <div className="p-4 rounded-2xl bg-rose-500/10 border border-rose-500/30 text-rose-500 text-xs font-bold flex items-center gap-2.5">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>{errorMsg}</span>
          </div>
        )}
        {successMsg && (
          <div className="p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-600 dark:text-emerald-400 text-xs font-bold flex items-center gap-2.5">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>{successMsg}</span>
          </div>
        )}

        {isLoading ? (
          <div className="py-16 flex flex-col items-center justify-center gap-3 text-slate-400">
            <div className="w-6 h-6 border-2 border-[#FF6B00] border-t-transparent rounded-full animate-spin" />
            <span className="text-xs font-bold">Moderasyon kuyruğu yükleniyor...</span>
          </div>
        ) : activeModTab === 'reviews' ? (
          reviews.length === 0 ? (
            <div
              className={`py-16 rounded-2xl border text-center space-y-2 text-slate-400 ${
                isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200'
              }`}
            >
              <Star className="w-10 h-10 mx-auto opacity-50" />
              <p className="text-sm font-bold">Seçili durumda yorum bulunmuyor.</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {reviews.map((rev) => {
                const customerName =
                  `${rev.user.name || ''} ${rev.user.surname || ''}`.trim() || rev.user.phone;
                const statusMeta = getModerationStatusMeta(rev.status);
                return (
                  <div
                    key={rev.id}
                    className={`p-5 rounded-2xl border space-y-3 ${
                      isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/80 shadow-2xs'
                    }`}
                  >
                    <div className="flex items-start justify-between gap-2">
                      <div>
                        <h4 className="text-sm font-black">{rev.shop.name}</h4>
                        <p className="text-xs text-slate-400 font-semibold">
                          Müşteri: {customerName} •{' '}
                          <span className="tabular-nums">
                            {new Date(rev.createdAt).toLocaleDateString('tr-TR')}
                          </span>
                        </p>
                      </div>
                      <StatusIndicator
                        label={statusMeta.label}
                        tone={statusMeta.tone}
                        isDark={isDark}
                      />
                    </div>

                    <div className="flex flex-wrap items-center gap-2 text-xs font-black tabular-nums">
                      <span className="px-2.5 py-1 rounded-lg bg-amber-500/10 text-amber-500 inline-flex items-center gap-1">
                        <Star className="w-3.5 h-3.5 fill-amber-500" />
                        Genel: {rev.rating}/5
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
                      {rev.comment || 'Müşteri yazılı yorum eklemeden yıldız değerlendirmesi yaptı.'}
                    </p>

                    {rev.status !== 'APPROVED' && (
                      <div className="flex items-center justify-end gap-2 pt-2">
                        {rev.status !== 'REJECTED' && (
                          <button
                            type="button"
                            onClick={() => handleReviewAction(rev.id, 'reject')}
                            className="px-3 py-1.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-black inline-flex items-center gap-1"
                          >
                            <XCircle className="w-3.5 h-3.5" />
                            <span>Reddet</span>
                          </button>
                        )}
                        <button
                          type="button"
                          onClick={() => handleReviewAction(rev.id, 'approve')}
                          className="px-3 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-black inline-flex items-center gap-1"
                        >
                          <CheckCircle2 className="w-3.5 h-3.5" />
                          <span>Onayla & Ödül Ver</span>
                        </button>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          )
        ) : campaigns.length === 0 ? (
          <div
            className={`py-16 rounded-2xl border text-center space-y-2 text-slate-400 ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200'
            }`}
          >
            <Megaphone className="w-10 h-10 mx-auto opacity-50" />
            <p className="text-sm font-bold">Seçili durumda kampanya/slider talebi bulunmuyor.</p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {campaigns.map((camp) => {
              const statusMeta = getModerationStatusMeta(camp.status);
              return (
                <div
                  key={camp.id}
                  className={`p-5 rounded-2xl border space-y-3 ${
                    isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/80 shadow-2xs'
                  }`}
                >
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <h4 className="text-sm font-black">{camp.title}</h4>
                      <p className="text-xs text-slate-400 font-semibold">
                        {camp.shop?.name || 'Platform Kampanyası'} • {camp.targetArea}
                      </p>
                    </div>
                    <StatusIndicator
                      label={statusMeta.label}
                      tone={statusMeta.tone}
                      isDark={isDark}
                    />
                  </div>

                  {camp.imageUrl && (
                    <div className="rounded-xl overflow-hidden border border-slate-200 dark:border-slate-800 h-32 bg-slate-100 dark:bg-slate-950">
                      <img
                        src={camp.imageUrl}
                        alt={camp.title}
                        className="w-full h-full object-cover"
                      />
                    </div>
                  )}

                  <p className="text-xs text-slate-500 dark:text-slate-300">{camp.description}</p>

                  {camp.designService && (
                    <span
                      className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md border text-[11px] font-semibold ${
                        isDark
                          ? 'bg-slate-950/80 border-slate-800 text-slate-300'
                          : 'bg-slate-50 border-slate-200 text-slate-700'
                      }`}
                    >
                      <Layers className="w-3.5 h-3.5 text-slate-500" />
                      <span>Hoppa Tasarım Desteği Talep Edildi</span>
                    </span>
                  )}

                  <div className="flex items-center justify-end gap-2 pt-2 border-t border-slate-100 dark:border-slate-800">
                    {camp.status !== 'REJECTED' && (
                      <button
                        type="button"
                        onClick={() => handleCampaignAction(camp.id, 'REJECTED')}
                        className="px-3 py-1.5 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-black inline-flex items-center gap-1"
                      >
                        <XCircle className="w-3.5 h-3.5" />
                        <span>Reddet</span>
                      </button>
                    )}
                    {camp.status !== 'APPROVED' && (
                      <button
                        type="button"
                        onClick={() => handleCampaignAction(camp.id, 'APPROVED')}
                        className="px-3 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-black inline-flex items-center gap-1"
                      >
                        <CheckCircle2 className="w-3.5 h-3.5" />
                        <span>Onayla (Slider Aktif Et)</span>
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </MerchantLayout>
  );
}

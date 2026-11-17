import React, { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/router';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import GuidedOnboardingWidget from '../../../components/merchant/GuidedOnboardingWidget';
import HoppaSelect from '../../../components/merchant/HoppaSelect';
import StatusIndicator from '../../../components/merchant/StatusIndicator';
import SlideOverDrawer from '../../../components/merchant/SlideOverDrawer';
import { useConfirm, useToast } from '../../../components/merchant/ToastContext';
import {
  Tag,
  Plus,
  Trash2,
  Zap,
  Calendar,
  ArrowRight,
  Users,
} from 'lucide-react';
import { merchantApiFetch } from '../../../utils/merchant-auth';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';

interface MerchantCouponItem {
  id: string;
  code: string;
  title: string;
  discountType: 'PERCENTAGE' | 'FIXED';
  discountValue: number;
  minOrderAmount: number;
  startDate: string;
  endDate: string;
  isActive: boolean;
  _count?: {
    usages?: number;
  };
}

function getDefaultExpiryDateInput(): string {
  const d = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
  return d.toISOString().split('T')[0];
}

export default function MerchantCampaignsPage() {
  const router = useRouter();
  const { theme } = useMerchantTheme();
  const toast = useToast();
  const { confirm } = useConfirm();
  const isDark = theme === 'dark';

  const [coupons, setCoupons] = useState<MerchantCouponItem[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // New Coupon Drawer State
  const [showCouponModal, setShowCouponModal] = useState(false);
  const [couponCode, setCouponCode] = useState('HOPPA20');
  const [discountType, setDiscountType] = useState<'PERCENTAGE' | 'FIXED'>('PERCENTAGE');
  const [discountValue, setDiscountValue] = useState<number>(20);
  const [minOrderAmount, setMinOrderAmount] = useState<number>(150);
  const [endDate, setEndDate] = useState<string>(getDefaultExpiryDateInput);
  const [isSaving, setIsSaving] = useState(false);

  const fetchData = useCallback(async () => {
    setIsLoading(true);
    try {
      const couponRes = await merchantApiFetch('/merchant/coupons');
      if (Array.isArray(couponRes.data)) {
        setCoupons(couponRes.data as MerchantCouponItem[]);
      } else {
        setCoupons([]);
      }
    } catch (err) {
      console.error('Kupon verileri alınamadı:', err);
      toast.error('Kupon verileri yüklenemedi.');
    } finally {
      setIsLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    void fetchData();
  }, [fetchData]);

  const handleCreateCoupon = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    try {
      const res = await merchantApiFetch('/merchant/coupons', {
        method: 'POST',
        body: JSON.stringify({
          code: couponCode.toUpperCase().trim(),
          discountType,
          discountValue: Number(discountValue),
          minOrderAmount: Number(minOrderAmount),
          endDate,
        }),
      });
      toast.success(res.message || 'İndirim kuponunuz yayınlandı.');
      setShowCouponModal(false);
      await fetchData();
    } catch (err: any) {
      toast.error(err.message || 'Kupon oluşturulamadı.');
    } finally {
      setIsSaving(false);
    }
  };

  const handleDeleteCoupon = async (coupon: MerchantCouponItem) => {
    const ok = await confirm({
      title: 'Kuponu Kaldır',
      message: `"${coupon.code}" indirim kuponunu kaldırmak istediğinize emin misiniz? Daha önce kullanılmış kuponlar arşivlenerek pasife alınır.`,
      confirmText: 'Kuponu Kaldır',
      tone: 'danger',
    });
    if (!ok) return;

    try {
      const res = await merchantApiFetch(`/merchant/coupons/${coupon.id}`, {
        method: 'DELETE',
      });
      toast.info(res.message || 'Kupon kaldırıldı.');
      await fetchData();
    } catch (err: any) {
      toast.error(err.message || 'Kupon kaldırılamadı.');
    }
  };

  const campaignHeaderActions = (
    <div className="flex flex-wrap items-center gap-2">
      <button
        type="button"
        onClick={() => void router.push('/merchant/promotions')}
        className={`px-3.5 py-2 rounded-xl border font-bold text-xs flex items-center gap-2 transition-colors ${
          isDark
            ? 'bg-slate-800 border-slate-700 text-slate-200 hover:bg-slate-700'
            : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50'
        }`}
      >
        <Zap className="w-3.5 h-3.5 text-[#FF6B00]" />
        <span>Mağazayı Öne Çıkar</span>
        <ArrowRight className="w-3.5 h-3.5 text-slate-400" />
      </button>

      <button
        type="button"
        onClick={() => setShowCouponModal(true)}
        className="px-4 py-2 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white font-black text-xs flex items-center gap-2 transition-colors shadow-2xs"
      >
        <Plus className="w-4 h-4" />
        <span>Yeni Kupon Oluştur</span>
      </button>
    </div>
  );

  return (
    <MerchantLayout
      title="Kampanya & Kupon Yönetimi"
      subtitle="Mağazanıza özel indirim kuponları tanımlayın ve kullanımları takip edin"
      headerIcon={Tag}
      headerActions={campaignHeaderActions}
      activeTab="campaigns"
    >
      <div className="space-y-6">
        <GuidedOnboardingWidget hasCampaigns={coupons.some((c) => c.isActive)} />

        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="font-extrabold text-base tracking-tight">Mağaza İndirim Kuponlarınız</h3>
            <span className="text-xs font-bold text-slate-400 tabular-nums">
              Toplam {coupons.length} kupon
            </span>
          </div>

          {isLoading ? (
            <div
              className={`text-center py-12 rounded-3xl border ${
                isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
              }`}
            >
              <div className="w-8 h-8 border-3 border-[#FF6B00] border-t-transparent rounded-full animate-spin mx-auto mb-2" />
              <p className="text-xs text-slate-400 font-semibold">Kuponlar yükleniyor...</p>
            </div>
          ) : coupons.length === 0 ? (
            <div
              className={`text-center py-16 px-4 rounded-3xl border space-y-3 ${
                isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
              }`}
            >
              <Tag className="w-12 h-12 text-slate-400 mx-auto" />
              <h4 className="font-bold text-slate-700 dark:text-slate-300">
                Henüz mağaza indirim kuponunuz bulunmuyor
              </h4>
              <p className="text-xs text-slate-500 max-w-sm mx-auto">
                Müşterilerinizi ilk siparişe veya yüksek sepete teşvik etmek için % indirim veya ₺ tutar bazlı kuponlar tanımlayın.
              </p>
              <button
                type="button"
                onClick={() => setShowCouponModal(true)}
                className="px-5 py-2.5 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white font-black text-xs inline-flex items-center gap-2 transition-colors"
              >
                <Plus className="w-4 h-4" />
                <span>İlk Kuponumu Oluştur</span>
              </button>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 tabular-nums">
              {coupons.map((camp) => {
                const isExpired = new Date(camp.endDate).getTime() < Date.now();
                const isLive = camp.isActive && !isExpired;
                const usageCount = camp._count?.usages ?? 0;

                return (
                  <div
                    key={camp.id}
                    className={`p-5 rounded-3xl border flex flex-col justify-between transition-all ${
                      isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
                    } ${!isLive ? 'opacity-75' : ''}`}
                  >
                    <div>
                      <div className="flex items-center justify-between mb-3">
                        <span
                          className={`px-2.5 py-1 rounded-lg text-xs font-mono font-bold border border-dashed ${
                            isDark
                              ? 'bg-slate-950 border-slate-700 text-slate-100'
                              : 'bg-slate-50 border-slate-300 text-slate-900'
                          }`}
                        >
                          {camp.code}
                        </span>
                        <StatusIndicator
                          tone={isLive ? 'emerald' : isExpired ? 'amber' : 'slate'}
                          label={isLive ? 'Aktif' : isExpired ? 'Süresi Doldu' : 'Pasif'}
                          isDark={isDark}
                        />
                      </div>

                      <h4 className="font-black text-lg">
                        {camp.discountType === 'PERCENTAGE'
                          ? `%${camp.discountValue} İndirim`
                          : `₺${camp.discountValue} İndirim`}
                      </h4>
                      <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
                        Min. Sepet Tutarı:{' '}
                        <span className="font-bold text-slate-700 dark:text-slate-300">
                          ₺{camp.minOrderAmount || 0}
                        </span>
                      </p>
                      <div className="mt-2.5 flex items-center gap-3 text-[11px] font-semibold text-slate-400">
                        <span className="inline-flex items-center gap-1">
                          <Calendar className="w-3.5 h-3.5" />
                          Bitiş: {new Date(camp.endDate).toLocaleDateString('tr-TR')}
                        </span>
                        <span className="inline-flex items-center gap-1">
                          <Users className="w-3.5 h-3.5" />
                          {usageCount} kullanım
                        </span>
                      </div>
                    </div>

                    <div className="mt-4 pt-3 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
                      <span className="text-[11px] font-semibold text-slate-400 truncate pr-2">
                        {camp.title}
                      </span>
                      <button
                        type="button"
                        onClick={() => void handleDeleteCoupon(camp)}
                        className="text-xs font-bold text-rose-500 hover:underline inline-flex items-center gap-1 shrink-0"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                        <span>Kuponu Kaldır</span>
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>

        {/* Create Coupon Slide-Over Drawer */}
        <SlideOverDrawer
          isOpen={showCouponModal}
          onClose={() => setShowCouponModal(false)}
          title="Yeni İndirim Kuponu Oluştur"
          subtitle="Müşterilerin ödeme ekranında kullanabileceği mağaza kuponu tanımlayın"
          icon={<Tag className="w-5 h-5" />}
          widthClass="max-w-md"
          footer={
            <div className="flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={() => setShowCouponModal(false)}
                className="px-4 py-2.5 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 text-xs font-bold"
              >
                Vazgeç
              </button>
              <button
                type="submit"
                form="create-coupon-form"
                disabled={isSaving}
                className="px-5 py-2.5 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-black shadow-sm disabled:opacity-50"
              >
                {isSaving ? 'Kaydediliyor...' : 'Kuponu Yayınla'}
              </button>
            </div>
          }
        >
          <form id="create-coupon-form" onSubmit={handleCreateCoupon} className="space-y-4">
            <div>
              <label className="block text-xs font-bold mb-1.5 text-slate-500 dark:text-slate-400">
                Kupon Kodu *
              </label>
              <input
                type="text"
                required
                value={couponCode}
                onChange={(e) => setCouponCode(e.target.value.toUpperCase().replace(/[^A-Z0-9_-]/g, ''))}
                placeholder="Örn: INDIRIM20"
                className={`w-full border rounded-xl p-3 text-sm font-mono font-bold outline-none focus:border-[#FF6B00] ${
                  isDark
                    ? 'bg-slate-950 border-slate-800 text-white'
                    : 'bg-slate-50 border-slate-200 text-slate-900'
                }`}
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div>
                <HoppaSelect
                  label="İndirim Tipi"
                  value={discountType}
                  onChange={(val) => setDiscountType(val as 'PERCENTAGE' | 'FIXED')}
                  options={[
                    { value: 'PERCENTAGE', label: 'Yüzde (%) İndirim' },
                    { value: 'FIXED', label: 'Sabit (₺) İndirim' },
                  ]}
                />
              </div>

              <div>
                <label className="block text-[11px] font-bold mb-1.5 text-slate-500 dark:text-slate-400">
                  İndirim Miktarı *
                </label>
                <input
                  type="number"
                  min="1"
                  max={discountType === 'PERCENTAGE' ? 90 : undefined}
                  required
                  value={discountValue}
                  onChange={(e) => setDiscountValue(Number(e.target.value))}
                  className={`w-full border border-[#FF6B00] rounded-xl p-2.5 text-sm font-bold text-[#FF6B00] outline-none ${
                    isDark ? 'bg-slate-950' : 'bg-white'
                  }`}
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold mb-1.5 text-slate-500 dark:text-slate-400">
                Minimum Sepet Tutarı (₺)
              </label>
              <input
                type="number"
                min="0"
                value={minOrderAmount}
                onChange={(e) => setMinOrderAmount(Number(e.target.value))}
                className={`w-full border rounded-xl p-3 text-sm font-bold outline-none focus:border-[#FF6B00] ${
                  isDark
                    ? 'bg-slate-950 border-slate-800 text-white'
                    : 'bg-slate-50 border-slate-200 text-slate-900'
                }`}
              />
            </div>

            <div>
              <label className="block text-xs font-bold mb-1.5 text-slate-500 dark:text-slate-400">
                Son Kullanma Tarihi *
              </label>
              <input
                type="date"
                required
                min={new Date().toISOString().split('T')[0]}
                value={endDate}
                onChange={(e) => setEndDate(e.target.value)}
                className={`w-full border rounded-xl p-3 text-sm font-bold outline-none focus:border-[#FF6B00] ${
                  isDark
                    ? 'bg-slate-950 border-slate-800 text-white'
                    : 'bg-slate-50 border-slate-200 text-slate-900'
                }`}
              />
            </div>
          </form>
        </SlideOverDrawer>
      </div>
    </MerchantLayout>
  );
}

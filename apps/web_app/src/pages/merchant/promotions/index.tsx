import React, { useCallback, useEffect, useState } from 'react';
import {
  Megaphone,
  TrendingUp,
  CheckCircle2,
  AlertCircle,
  Clock,
  RefreshCw,
  ArrowUpRight,
  XCircle,
  Layers,
} from 'lucide-react';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import StatusIndicator from '../../../components/merchant/StatusIndicator';
import { useConfirm, useToast } from '../../../components/merchant/ToastContext';
import { merchantApiFetch } from '../../../utils/merchant-auth';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';

type PromoType = 'MAIN_SCREEN' | 'CATEGORY';

interface ShopPromotionRecord {
  id: string;
  shopId: string;
  promoType: PromoType;
  startDate: string;
  endDate: string;
  isActive: boolean;
  createdAt: string;
}

interface ShopPromoOverview {
  id: string;
  name: string;
  activeCommissionRate?: number;
  activePromotions?: ShopPromotionRecord[];
}

function getRemainingDaysText(endDateIso: string): string {
  const diffMs = new Date(endDateIso).getTime() - Date.now();
  if (diffMs <= 0) return 'Süresi Doldu';
  const days = Math.floor(diffMs / (1000 * 60 * 60 * 24));
  const hours = Math.floor((diffMs % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
  return `${days} gün ${hours} saat kaldı`;
}

export default function MerchantPromotionsPage() {
  const { theme } = useMerchantTheme();
  const toast = useToast();
  const { confirm } = useConfirm();
  const isDark = theme === 'dark';

  const [shopOverview, setShopOverview] = useState<ShopPromoOverview | null>(null);
  const [promoHistory, setPromoHistory] = useState<ShopPromotionRecord[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isProcessing, setIsProcessing] = useState<boolean>(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const loadPromotionData = useCallback(async () => {
    setIsLoading(true);
    setErrorMsg(null);
    try {
      const [shopRes, promosRes] = await Promise.all([
        merchantApiFetch('/merchant/shop'),
        merchantApiFetch('/merchant/promotions'),
      ]);
      if (shopRes.data) {
        setShopOverview(shopRes.data as ShopPromoOverview);
      }
      setPromoHistory(
        Array.isArray(promosRes.data) ? (promosRes.data as ShopPromotionRecord[]) : []
      );
    } catch (err: unknown) {
      setErrorMsg(err instanceof Error ? err.message : 'Sponsorluk bilgileri yüklenemedi.');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    loadPromotionData();
  }, [loadPromotionData]);

  const activePromos = shopOverview?.activePromotions || [];
  const activeMain = activePromos.find((p) => p.promoType === 'MAIN_SCREEN') || null;
  const activeCategory = activePromos.find((p) => p.promoType === 'CATEGORY') || null;
  const currentCommissionPct = Math.round((shopOverview?.activeCommissionRate ?? 0.05) * 100);

  const handleActivate = async (promoType: PromoType) => {
    setIsProcessing(true);
    setErrorMsg(null);
    setSuccessMsg(null);
    try {
      const res = await merchantApiFetch('/merchant/promotions', {
        method: 'POST',
        body: JSON.stringify({ promoType }),
      });
      const msg = res.message || 'Sponsorluk paketi başarıyla aktif edildi.';
      setSuccessMsg(msg);
      toast.success(msg);
      await loadPromotionData();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Sponsorluk aktif edilemedi.';
      setErrorMsg(msg);
      toast.error(msg);
    } finally {
      setIsProcessing(false);
    }
  };

  const handleCancel = async (promoType: PromoType) => {
    const label = promoType === 'MAIN_SCREEN' ? 'Ana Sayfa Vitrin' : 'Kategori Vitrini';
    const ok = await confirm({
      title: `${label} Sponsorluğunu İptal Et`,
      message: `${label} sponsorluğunu sonlandırmak istediğinize emin misiniz? Komisyon oranınız standart %5 seviyesine dönecektir.`,
      confirmText: 'Sponsorluğu İptal Et',
      tone: 'danger',
    });
    if (!ok) return;

    setIsProcessing(true);
    setErrorMsg(null);
    setSuccessMsg(null);
    try {
      const res = await merchantApiFetch('/merchant/promotions/cancel', {
        method: 'POST',
        body: JSON.stringify({ promoType }),
      });
      const msg = res.message || 'Sponsorluk iptal edildi.';
      setSuccessMsg(msg);
      toast.info(msg);
      await loadPromotionData();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Sponsorluk iptal edilemedi.';
      setErrorMsg(msg);
      toast.error(msg);
    } finally {
      setIsProcessing(false);
    }
  };

  return (
    <MerchantLayout
      title="Sponsorlu Vitrin & Öne Çıkarma"
      subtitle="Mağazanızı ana ekran veya kategori vitrininde üst sıralara taşıyın"
      headerIcon={Megaphone}
      activeTab="promotions"
      headerActions={
        <button
          type="button"
          onClick={loadPromotionData}
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
        {successMsg && (
          <div className="p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-600 dark:text-emerald-400 text-xs font-bold flex items-center gap-2.5">
            <CheckCircle2 className="w-4 h-4 shrink-0" />
            <span>{successMsg}</span>
          </div>
        )}

        {/* Current Commission Banner */}
        <div
          className={`p-5 rounded-2xl border flex flex-col sm:flex-row sm:items-center justify-between gap-4 ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/80 shadow-2xs'
          }`}
        >
          <div className="flex items-center gap-3.5">
            <div className="w-11 h-11 rounded-2xl bg-[#FF6B00]/15 text-[#FF6B00] flex items-center justify-center shrink-0">
              <TrendingUp className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-sm font-black">
                Mevcut Komisyon Oranı: <span className="text-[#FF6B00] tabular-nums">%{currentCommissionPct}</span>
              </h3>
              <p className="text-xs text-slate-400 font-semibold mt-0.5">
                Standart komisyon oranı %5&apos;tir. Aktif vitrin sponsorluğunuz varsa sipariş başı oran
                otomatik güncellenir ve dilediğiniz an iptal edilebilir.
              </p>
            </div>
          </div>

          {(activeMain || activeCategory) && (
            <div className="px-3.5 py-2 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-600 dark:text-emerald-400 text-xs font-black flex items-center gap-1.5 shrink-0 tabular-nums">
              <Clock className="w-3.5 h-3.5" />
              <span>{getRemainingDaysText((activeMain || activeCategory)!.endDate)}</span>
            </div>
          )}
        </div>

        {/* Two Package Cards */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
          {/* CATEGORY PACKAGE */}
          <div
            className={`p-6 rounded-3xl border flex flex-col justify-between space-y-5 ${
              activeCategory
                ? 'border-emerald-500/60 ring-1 ring-emerald-500/20 '
                : 'border-slate-200 dark:border-slate-800 '
            }${isDark ? 'bg-slate-900' : 'bg-white shadow-2xs'}`}
          >
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="inline-flex items-center gap-2 text-[11px] font-extrabold uppercase tracking-[0.12em] text-sky-600 dark:text-sky-400">
                  <span className="w-2 h-2 rounded-[2px] bg-sky-500" aria-hidden="true" />
                  <span>Kategori Vitrini</span>
                </span>
                <span className="text-xl font-black text-[#FF6B00] tabular-nums">%10 Komisyon</span>
              </div>
              <h4 className="text-lg font-black">Kategori İçi Öne Çıkarma (7 Gün)</h4>
              <p className="text-xs text-slate-500 dark:text-slate-400 leading-relaxed">
                Kendi işletme kategorinizde tüketicilerin ilk gördüğü önerilen işletmeler arasında yer
                alın. Ön ödeme gerektirmez; 7 gün boyunca siparişler üzerinden toplam %10 komisyon
                uygulanır.
              </p>
            </div>

            {activeCategory ? (
              <div className="space-y-2.5">
                <div className="p-3 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 text-xs font-bold flex items-center justify-between tabular-nums">
                  <span>Paket Şu An Aktif</span>
                  <span>{getRemainingDaysText(activeCategory.endDate)}</span>
                </div>
                <button
                  type="button"
                  disabled={isProcessing}
                  onClick={() => handleCancel('CATEGORY')}
                  className="w-full py-2.5 px-4 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-black flex items-center justify-center gap-1.5 disabled:opacity-50"
                >
                  <XCircle className="w-4 h-4" />
                  <span>Kategori Sponsorluğunu İptal Et</span>
                </button>
              </div>
            ) : (
              <button
                type="button"
                disabled={isProcessing || Boolean(activeMain)}
                onClick={() => handleActivate('CATEGORY')}
                className="w-full py-3 px-4 rounded-xl bg-slate-900 dark:bg-slate-800 hover:bg-[#FF6B00] dark:hover:bg-[#FF6B00] text-white text-xs font-black flex items-center justify-center gap-1.5 transition-colors disabled:opacity-40"
              >
                <ArrowUpRight className="w-4 h-4" />
                <span>
                  {activeMain
                    ? 'Ana Sayfa Sponsorluğu Zaten Aktif'
                    : 'Kategori Vitrini Paketini Aktifleştir'}
                </span>
              </button>
            )}
          </div>

          {/* MAIN SCREEN PACKAGE */}
          <div
            className={`p-6 rounded-3xl border flex flex-col justify-between space-y-5 ${
              activeMain
                ? 'border-[#FF6B00] ring-1 ring-[#FF6B00]/25 '
                : 'border-[#FF6B00]/40 '
            }${isDark ? 'bg-slate-900' : 'bg-white shadow-2xs'}`}
          >
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="inline-flex items-center gap-2 text-[11px] font-extrabold uppercase tracking-[0.12em] text-[#FF6B00]">
                  <span className="w-2 h-2 rounded-[2px] bg-[#FF6B00]" aria-hidden="true" />
                  <span>Ana Ekran Tepe Vitrin</span>
                </span>
                <span className="text-xl font-black text-[#FF6B00] tabular-nums">%15 Komisyon</span>
              </div>
              <h4 className="text-lg font-black">Ana Sayfa Sponsorlu Vitrin (7 Gün)</h4>
              <p className="text-xs text-slate-500 dark:text-slate-400 leading-relaxed">
                Tüketici uygulaması ana sayfasında tüm kullanıcıların gördüğü en üst vitrinde yer alın.
                Aktif bir Kategori sponsorluğunuz varsa tek tıkla Ana Sayfa paketine yükseltebilirsiniz.
              </p>
            </div>

            {activeMain ? (
              <div className="space-y-2.5">
                <div className="p-3 rounded-xl bg-[#FF6B00]/10 text-[#FF6B00] text-xs font-bold flex items-center justify-between tabular-nums">
                  <span>Ana Ekran Vitrininde Yayında</span>
                  <span>{getRemainingDaysText(activeMain.endDate)}</span>
                </div>
                <button
                  type="button"
                  disabled={isProcessing}
                  onClick={() => handleCancel('MAIN_SCREEN')}
                  className="w-full py-2.5 px-4 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-xs font-black flex items-center justify-center gap-1.5 disabled:opacity-50"
                >
                  <XCircle className="w-4 h-4" />
                  <span>Ana Sayfa Sponsorluğunu İptal Et</span>
                </button>
              </div>
            ) : (
              <button
                type="button"
                disabled={isProcessing}
                onClick={() => handleActivate('MAIN_SCREEN')}
                className="w-full py-3 px-4 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-black flex items-center justify-center gap-1.5 transition-colors disabled:opacity-50"
              >
                <Megaphone className="w-4 h-4" />
                <span>
                  {activeCategory
                    ? 'Ana Sayfa Vitrinine Yükselt'
                    : 'Ana Sayfa Vitrinini Aktifleştir'}
                </span>
              </button>
            )}
          </div>
        </div>

        {/* History Table */}
        <div
          className={`rounded-2xl border overflow-hidden ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/80 shadow-2xs'
          }`}
        >
          <div className="p-4 border-b border-slate-100 dark:border-slate-800 flex items-center gap-2">
            <Layers className="w-4 h-4 text-[#FF6B00]" />
            <h3 className="text-sm font-black">Sponsorluk Geçmişi</h3>
          </div>
          {isLoading ? (
            <div className="py-12 text-center text-xs text-slate-400 font-bold">Yükleniyor...</div>
          ) : promoHistory.length === 0 ? (
            <div className="py-12 text-center text-xs text-slate-400 font-bold">
              Henüz oluşturulmuş bir vitrin sponsorluğu kaydı bulunmuyor.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse text-xs">
                <thead>
                  <tr
                    className={`border-b text-[11px] font-black uppercase text-slate-400 ${
                      isDark ? 'bg-slate-950/50 border-slate-800' : 'bg-slate-50 border-slate-200'
                    }`}
                  >
                    <th className="py-3 px-4">Paket Türü</th>
                    <th className="py-3 px-4">Başlangıç</th>
                    <th className="py-3 px-4">Bitiş</th>
                    <th className="py-3 px-4">Durum</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 dark:divide-slate-800 tabular-nums">
                  {promoHistory.map((item) => {
                    const isPromoActive =
                      item.isActive && new Date(item.endDate).getTime() > Date.now();
                    return (
                      <tr key={item.id}>
                        <td className="py-3 px-4 font-black">
                          {item.promoType === 'MAIN_SCREEN' ? 'Ana Sayfa Vitrin (%15)' : 'Kategori Vitrini (%10)'}
                        </td>
                        <td className="py-3 px-4 text-slate-400">
                          {new Date(item.startDate).toLocaleDateString('tr-TR')}
                        </td>
                        <td className="py-3 px-4 text-slate-400">
                          {new Date(item.endDate).toLocaleDateString('tr-TR')}
                        </td>
                        <td className="py-3 px-4">
                          <StatusIndicator
                            label={isPromoActive ? 'Aktif' : 'Tamamlandı'}
                            tone={isPromoActive ? 'emerald' : 'slate'}
                            isDark={isDark}
                          />
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>
    </MerchantLayout>
  );
}

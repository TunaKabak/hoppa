import React, { useState, useEffect } from 'react';
import Head from 'next/head';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import GuidedOnboardingWidget from '../../../components/merchant/GuidedOnboardingWidget';
import { 
  Tag, Plus, Sparkles, Check, Trash2, Zap, AlertCircle, Percent, DollarSign, Calendar 
} from 'lucide-react';
import { merchantApiFetch } from '../../../utils/merchant-auth';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';

export default function MerchantCampaignsPage() {
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [campaigns, setCampaigns] = useState<any[]>([]);
  const [promotions, setPromotions] = useState<any[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  // New Coupon Modal State
  const [showCouponModal, setShowCouponModal] = useState(false);
  const [couponCode, setCouponCode] = useState('HOPPA20');
  const [discountType, setDiscountType] = useState<'PERCENTAGE' | 'FIXED'>('PERCENTAGE');
  const [discountValue, setDiscountValue] = useState<number>(20);
  const [minOrderAmount, setMinOrderAmount] = useState<number>(150);
  const [isSaving, setIsSaving] = useState(false);

  // New Promotion Modal State
  const [showSponsorshipModal, setShowSponsorshipModal] = useState(false);

  useEffect(() => {
    fetchData();
  }, []);

  const fetchData = async () => {
    setIsLoading(true);
    try {
      const [campRes, promoRes] = await Promise.all([
        merchantApiFetch('/merchant/campaigns'),
        merchantApiFetch('/merchant/promotions'),
      ]);

      if (campRes.data) setCampaigns(campRes.data);
      if (promoRes.data) setPromotions(promoRes.data);
    } catch (err) {
      console.error('Kampanya verileri alınamadı:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleCreateCoupon = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSaving(true);
    try {
      await merchantApiFetch('/merchant/campaigns', {
        method: 'POST',
        body: JSON.stringify({
          code: couponCode.toUpperCase().trim(),
          discountType,
          discountValue: Number(discountValue),
          minOrderAmount: Number(minOrderAmount),
        }),
      });
      setShowCouponModal(false);
      fetchData();
    } catch (err: any) {
      alert(err.message || 'Kupon oluşturulamadı.');
    } finally {
      setIsSaving(false);
    }
  };

  const handleApplySponsorship = async () => {
    setIsSaving(true);
    try {
      await merchantApiFetch('/merchant/promotions', {
        method: 'POST',
        body: JSON.stringify({
          type: 'TOP_BANNER',
          durationDays: 7,
        }),
      });
      setShowSponsorshipModal(false);
      fetchData();
      alert('Sponsorlu Mağaza başvurunuz alındı! İnceleme sonrası öne çıkarılacaktır.');
    } catch (err: any) {
      alert(err.message || 'Başvuru alınamadı.');
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <MerchantLayout title="Kampanya & Sponsorluk Portalı" activeTab="settings">
      <div className="space-y-6">
        {/* Top Header */}
        <div className={`flex flex-col sm:flex-row sm:items-center justify-between gap-4 border rounded-3xl p-6 transition-colors ${
          isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
        }`}>
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-2xl bg-[#00A651] text-white flex items-center justify-center font-bold shadow-lg shadow-[#00A651]/25">
              <Tag className="w-6 h-6" />
            </div>
            <div>
              <h1 className="text-2xl font-black tracking-tight">Kampanya & Reklam Portalı</h1>
              <p className="text-xs font-semibold text-slate-500 dark:text-slate-400 mt-0.5">
                İndirim kuponları tanımlayın ve mağazanızı öne çıkarın
              </p>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-3">
            <button
              onClick={() => setShowSponsorshipModal(true)}
              className="px-4 py-3 rounded-2xl bg-amber-500/15 text-amber-500 border border-amber-500/40 font-bold text-xs flex items-center gap-2 transition-all"
            >
              <Zap className="w-4 h-4 text-amber-500" />
              <span>Mağazayı Öne Çıkar (Sponsorlu)</span>
            </button>

            <button
              onClick={() => setShowCouponModal(true)}
              className="px-5 py-3 rounded-2xl bg-[#FF6B00] hover:bg-[#E56000] text-white font-black text-xs shadow-lg shadow-[#FF6B00]/25 flex items-center gap-2 transition-all"
            >
              <Plus className="w-4 h-4" />
              <span>Yeni Kupon Oluştur</span>
            </button>
          </div>
        </div>

        {/* Guided Onboarding Bar */}
        <GuidedOnboardingWidget hasCampaigns={campaigns.length > 0} />

        {/* Campaigns Grid */}
        <div className="space-y-4">
          <h3 className="font-extrabold text-base tracking-tight">Aktif İndirim Kuponlarınız</h3>

          {isLoading ? (
            <div className={`text-center py-12 rounded-3xl border ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
            }`}>
              <div className="w-8 h-8 border-3 border-[#00A651] border-t-transparent rounded-full animate-spin mx-auto mb-2" />
              <p className="text-xs text-slate-400 font-semibold">Kampanyalar yükleniyor...</p>
            </div>
          ) : campaigns.length === 0 ? (
            <div className={`text-center py-16 rounded-3xl border ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
            }`}>
              <Tag className="w-12 h-12 text-slate-400 mx-auto mb-3" />
              <h4 className="font-bold text-slate-700 dark:text-slate-300">Henüz aktif kampanya bulunmuyor</h4>
              <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto">
                "Yeni Kupon Oluştur" butonuna basarak ilk %10 veya ₺20 indirim kuponunuzu anında yayınlayabilirsiniz.
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {campaigns.map((camp) => (
                <div
                  key={camp.id}
                  className={`p-5 rounded-3xl border flex flex-col justify-between transition-all ${
                    isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
                  }`}
                >
                  <div>
                    <div className="flex items-center justify-between mb-3">
                      <span className="px-3 py-1 rounded-full text-xs font-mono font-black bg-[#FF6B00]/15 text-[#FF6B00] border border-[#FF6B00]/30">
                        {camp.code || 'HOPPA10'}
                      </span>
                      <span className="text-[10px] font-bold text-[#00A651] bg-[#00A651]/15 px-2.5 py-0.5 rounded-full">
                        AKTİF
                      </span>
                    </div>

                    <h4 className="font-black text-lg">
                      {camp.discountType === 'PERCENTAGE' ? `%${camp.discountValue} İndirim` : `₺${camp.discountValue} İndirim`}
                    </h4>
                    <p className="text-xs text-slate-400 mt-1">
                      Min. Sepet Tutarı: <span className="font-bold text-slate-300">₺{camp.minOrderAmount || 0}</span>
                    </p>
                  </div>

                  <div className="mt-4 pt-3 border-t border-slate-200 dark:border-slate-800 flex items-center justify-between">
                    <span className="text-[11px] font-semibold text-slate-400">Sınırsız Kullanım</span>
                    <button className="text-xs font-bold text-rose-500 hover:underline">Kuponu Kaldır</button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Create Coupon Modal */}
        {showCouponModal && (
          <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-md flex items-center justify-center p-4">
            <div className={`border rounded-3xl p-6 w-full max-w-md space-y-4 ${
              isDark ? 'bg-slate-900 border-slate-800 text-white' : 'bg-white border-slate-200 text-slate-900 shadow-xl'
            }`}>
              <h3 className="font-bold text-base">Yeni İndirim Kuponu Oluştur</h3>

              <form onSubmit={handleCreateCoupon} className="space-y-4">
                <div>
                  <label className="block text-xs font-bold uppercase mb-1 text-slate-400">Kupon Kodu *</label>
                  <input
                    type="text"
                    required
                    value={couponCode}
                    onChange={(e) => setCouponCode(e.target.value.toUpperCase())}
                    placeholder="Örn: INDIRIM20"
                    className={`w-full border rounded-xl p-3 text-sm font-mono font-bold outline-none ${
                      isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                    }`}
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div>
                    <label className="block text-xs font-bold uppercase mb-1 text-slate-400">İndirim Tipi</label>
                    <select
                      value={discountType}
                      onChange={(e: any) => setDiscountType(e.target.value)}
                      className={`w-full border rounded-xl p-3 text-xs font-bold outline-none ${
                        isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                      }`}
                    >
                      <option value="PERCENTAGE">Yüzde (%) İndirim</option>
                      <option value="FIXED">Sabit (₺) İndirim</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-xs font-bold uppercase mb-1 text-slate-400">İndirim Miktarı</label>
                    <input
                      type="number"
                      min="1"
                      required
                      value={discountValue}
                      onChange={(e) => setDiscountValue(Number(e.target.value))}
                      className="w-full border border-[#FF6B00] rounded-xl p-3 text-sm font-bold text-[#FF6B00] outline-none bg-white dark:bg-slate-950"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold uppercase mb-1 text-slate-400">Minimum Sepet Tutarı (₺)</label>
                  <input
                    type="number"
                    min="0"
                    value={minOrderAmount}
                    onChange={(e) => setMinOrderAmount(Number(e.target.value))}
                    className={`w-full border rounded-xl p-3 text-sm font-bold outline-none ${
                      isDark ? 'bg-slate-950 border-slate-800 text-white' : 'bg-slate-50 border-slate-200 text-slate-900'
                    }`}
                  />
                </div>

                <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-200 dark:border-slate-800">
                  <button
                    type="button"
                    onClick={() => setShowCouponModal(false)}
                    className="px-4 py-2.5 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 text-xs font-bold"
                  >
                    Vazgeç
                  </button>
                  <button
                    type="submit"
                    disabled={isSaving}
                    className="px-5 py-2.5 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-bold shadow-md"
                  >
                    Kuponu Yayınla
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}

        {/* Sponsorship Modal */}
        {showSponsorshipModal && (
          <div className="fixed inset-0 z-50 bg-slate-950/70 backdrop-blur-md flex items-center justify-center p-4">
            <div className={`border rounded-3xl p-6 w-full max-w-md space-y-4 ${
              isDark ? 'bg-slate-900 border-slate-800 text-white' : 'bg-white border-slate-200 text-slate-900 shadow-xl'
            }`}>
              <h3 className="font-bold text-base text-amber-500">Mağazayı Öne Çıkar (Sponsorlu)</h3>
              <p className="text-xs text-slate-400">
                Mağazanızı kullanıcı ana sayfasının en üst sırasına taşıyarak satışlarınızı ortalama %60 artırın.
              </p>

              <div className="p-4 rounded-2xl bg-amber-500/10 border border-amber-500/30 text-xs space-y-2">
                <div className="flex justify-between font-bold text-amber-500">
                  <span>Haftalık Reklam Paketi:</span>
                  <span>7 Günlük Öne Çıkarma</span>
                </div>
                <p className="text-slate-400">Açılışta özel rozet ve ana banner alanında görünürlük.</p>
              </div>

              <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-200 dark:border-slate-800">
                <button
                  type="button"
                  onClick={() => setShowSponsorshipModal(false)}
                  className="px-4 py-2.5 rounded-xl bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 text-xs font-bold"
                >
                  Vazgeç
                </button>
                <button
                  type="button"
                  onClick={handleApplySponsorship}
                  disabled={isSaving}
                  className="px-5 py-2.5 rounded-xl bg-amber-500 hover:bg-amber-600 text-white text-xs font-bold shadow-md"
                >
                  Başvuruyu Gönder
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </MerchantLayout>
  );
}

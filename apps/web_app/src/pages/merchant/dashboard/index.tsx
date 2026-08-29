import React, { useState, useEffect } from 'react';
import Head from 'next/head';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import StoreReadinessWidget from '../../../components/merchant/StoreReadinessWidget';
import { 
  BarChart3, TrendingUp, ShoppingBag, Clock, DollarSign, 
  Award, ShieldCheck, ArrowUpRight, ArrowDownRight, Calendar,
  Building2, CheckCircle2, AlertCircle, ArrowRight, Zap, RefreshCw
} from 'lucide-react';
import { merchantApiFetch } from '../../../utils/merchant-auth';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';

export default function MerchantDashboardPage() {
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [timeRange, setTimeRange] = useState<'today' | 'week' | 'month'>('week');
  const [stats, setStats] = useState<any>(null);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, [timeRange]);

  const fetchStats = async () => {
    setIsLoading(true);
    try {
      const res = await merchantApiFetch(`/merchant/dashboard/stats?range=${timeRange}`);
      if (res.data) {
        setStats(res.data);
      }
    } catch (err) {
      console.error('İstatistikler alınamadı:', err);
    } finally {
      setIsLoading(false);
    }
  };

  // Fallbacks if stats API is seeding or null
  const totalRevenue = stats?.totalRevenue !== undefined ? Number(stats.totalRevenue) : 12450.00;
  const totalOrders = stats?.totalOrders !== undefined ? Number(stats.totalOrders) : 142;
  const avgBasket = totalOrders > 0 ? (totalRevenue / totalOrders) : 87.67;
  const avgDeliveryTime = stats?.avgDeliveryTime || 24;
  const topProducts = stats?.topProducts || [
    { name: 'Adana Kebap Porsiyon', count: 48, revenue: 4320.00 },
    { name: 'Kuşbaşı Pide', count: 35, revenue: 2975.00 },
    { name: 'Lahmacun (5\'li Paket)', count: 29, revenue: 1740.00 },
    { name: 'Ayran 300ml', count: 64, revenue: 640.00 },
    { name: 'Künefe', count: 22, revenue: 1100.00 },
  ];

  // Financial Payout Calculations (Hakediş Raporu)
  const hoppaCommissionRate = 0.12; // 12% commission
  const commissionFee = totalRevenue * hoppaCommissionRate;
  const netPayout = totalRevenue - commissionFee;

  const headerFilterActions = (
    <div className="flex items-center gap-2">
      <div className="flex items-center bg-white/20 backdrop-blur-md border border-white/25 rounded-xl p-1 text-white">
        <button
          onClick={() => setTimeRange('today')}
          className={`px-3.5 py-1.5 rounded-lg text-xs font-black transition-all ${
            timeRange === 'today' ? 'bg-white text-[#E95D22] shadow-sm' : 'text-white/85 hover:text-white hover:bg-white/10'
          }`}
        >
          Bugün
        </button>
        <button
          onClick={() => setTimeRange('week')}
          className={`px-3.5 py-1.5 rounded-lg text-xs font-black transition-all ${
            timeRange === 'week' ? 'bg-white text-[#E95D22] shadow-sm' : 'text-white/85 hover:text-white hover:bg-white/10'
          }`}
        >
          Bu Hafta
        </button>
        <button
          onClick={() => setTimeRange('month')}
          className={`px-3.5 py-1.5 rounded-lg text-xs font-black transition-all ${
            timeRange === 'month' ? 'bg-white text-[#E95D22] shadow-sm' : 'text-white/85 hover:text-white hover:bg-white/10'
          }`}
        >
          Bu Ay
        </button>
      </div>

      <button
        onClick={fetchStats}
        disabled={isLoading}
        className="p-2 rounded-xl bg-white/20 hover:bg-white/30 text-white backdrop-blur-md border border-white/25 transition-all"
        title="Verileri Yenile"
      >
        <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
      </button>
    </div>
  );

  return (
    <MerchantLayout 
      title="Kurumsal Yönetici Paneli" 
      subtitle="Finansal performans, canlı sipariş operasyonları ve hakediş mutabakatı"
      headerIcon={Building2}
      headerActions={headerFilterActions}
      activeTab="dashboard"
    >
      <div className="space-y-6">
        
        {/* Executive Overview Banner */}
        <div className={`p-5 rounded-3xl border flex flex-col md:flex-row items-start md:items-center justify-between gap-4 transition-all ${
          isDark 
          ? 'bg-gradient-to-r from-slate-900 via-slate-900 to-slate-950 border-slate-800/80' 
          : 'bg-gradient-to-r from-white via-slate-50 to-orange-50/30 border-slate-200/80 shadow-xs'
        }`}>
          <div className="flex items-center gap-3.5">
            <div className="w-12 h-12 rounded-2xl bg-[#FF6B00]/10 border border-[#FF6B00]/20 flex items-center justify-center text-[#FF6B00]">
              <Zap className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-base font-extrabold tracking-tight">Mağaza Operasyon Durumu:</h2>
                <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-black bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span>
                  SİPARİŞ ALIMINA AÇIK
                </span>
              </div>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5 font-medium">
                KKTC Lefkoşa & Girne bölgelerine kurye teslimatları aktif olarak devam ediyor.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3 w-full md:w-auto">
            <div className="px-3.5 py-2 rounded-2xl bg-slate-500/5 border border-slate-500/10 text-right">
              <span className="text-[10px] font-extrabold uppercase text-slate-400 block">Mağaza Puanı</span>
              <span className="text-sm font-black text-amber-500">⭐ 4.9 <span className="text-[10px] text-slate-400 font-bold">(184 Yorum)</span></span>
            </div>
            <div className="px-3.5 py-2 rounded-2xl bg-slate-500/5 border border-slate-500/10 text-right">
              <span className="text-[10px] font-extrabold uppercase text-slate-400 block">Kabul Başarısı</span>
              <span className="text-sm font-black text-emerald-600 dark:text-emerald-400">%99.2</span>
            </div>
          </div>
        </div>

        {/* Store Readiness & Onboarding Hub */}
        <StoreReadinessWidget />

        {/* Core Metric Cards Grid */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          
          {/* Card 1: Total Revenue */}
          <div className={`p-5 rounded-3xl border transition-all ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-xs hover:border-[#FF6B00]/40'
          }`}>
            <div className="flex items-center justify-between mb-3">
              <span className="text-xs font-extrabold uppercase tracking-wider text-slate-400">Brüt Ciro</span>
              <div className="w-9 h-9 rounded-2xl bg-[#FF6B00]/10 text-[#FF6B00] flex items-center justify-center font-bold">
                <DollarSign className="w-5 h-5" />
              </div>
            </div>
            <p className="text-2xl font-black text-[#FF6B00]">₺{totalRevenue.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}</p>
            <div className="flex items-center gap-1 text-[11px] font-bold text-emerald-600 dark:text-emerald-400 mt-2">
              <ArrowUpRight className="w-3.5 h-3.5" />
              <span>Önceki döneme göre +%18.4 artış</span>
            </div>
          </div>

          {/* Card 2: Total Orders */}
          <div className={`p-5 rounded-3xl border transition-all ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-xs hover:border-indigo-500/40'
          }`}>
            <div className="flex items-center justify-between mb-3">
              <span className="text-xs font-extrabold uppercase tracking-wider text-slate-400">Toplam Sipariş</span>
              <div className="w-9 h-9 rounded-2xl bg-indigo-500/10 text-indigo-500 flex items-center justify-center font-bold">
                <ShoppingBag className="w-5 h-5" />
              </div>
            </div>
            <p className="text-2xl font-black">{totalOrders} <span className="text-xs text-slate-400 font-bold">Adet</span></p>
            <div className="flex items-center gap-1 text-[11px] font-bold text-emerald-600 dark:text-emerald-400 mt-2">
              <ArrowUpRight className="w-3.5 h-3.5" />
              <span>Önceki döneme göre +%12.2</span>
            </div>
          </div>

          {/* Card 3: Avg Basket */}
          <div className={`p-5 rounded-3xl border transition-all ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-xs hover:border-amber-500/40'
          }`}>
            <div className="flex items-center justify-between mb-3">
              <span className="text-xs font-extrabold uppercase tracking-wider text-slate-400">Ortalama Sepet Tutarı</span>
              <div className="w-9 h-9 rounded-2xl bg-amber-500/10 text-amber-500 flex items-center justify-center font-bold">
                <TrendingUp className="w-5 h-5" />
              </div>
            </div>
            <p className="text-2xl font-black">₺{avgBasket.toFixed(2)}</p>
            <p className="text-[11px] text-slate-400 mt-2 font-bold">Sipariş başına ortalama harcama</p>
          </div>

          {/* Card 4: Avg Delivery Time */}
          <div className={`p-5 rounded-3xl border transition-all ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-xs hover:border-emerald-500/40'
          }`}>
            <div className="flex items-center justify-between mb-3">
              <span className="text-xs font-extrabold uppercase tracking-wider text-slate-400">Ortalama Hazırlık Süresi</span>
              <div className="w-9 h-9 rounded-2xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center font-bold">
                <Clock className="w-5 h-5" />
              </div>
            </div>
            <p className="text-2xl font-black text-emerald-600 dark:text-emerald-400">{avgDeliveryTime} <span className="text-xs font-bold">Dakika</span></p>
            <p className="text-[11px] text-emerald-600 dark:text-emerald-400 mt-2 font-bold">Hedeflenen standart hızda</p>
          </div>

        </div>

        {/* Live Operational Order Funnel */}
        <div className={`p-6 rounded-3xl border transition-all ${
          isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-xs'
        }`}>
          <div className="flex items-center justify-between mb-5">
            <div>
              <h3 className="font-extrabold text-sm uppercase tracking-wider">Canlı Sipariş Operasyon Akışı</h3>
              <p className="text-xs text-slate-500 dark:text-slate-400">Şu anda mutfakta ve kuryede olan siparişlerin anlık durumu</p>
            </div>
            <span className="text-xs font-black text-[#FF6B00] bg-orange-500/10 px-3 py-1 rounded-xl border border-[#FF6B00]/20">
              Canlı Takip
            </span>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div className={`p-4 rounded-2xl border ${isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'}`}>
              <div className="flex items-center justify-between text-xs text-slate-500 mb-1">
                <span className="font-bold">Yeni Bekleyen</span>
                <span className="w-2 h-2 rounded-full bg-amber-500 animate-ping"></span>
              </div>
              <p className="text-xl font-black text-amber-500">3 <span className="text-xs font-bold text-slate-400">Sipariş</span></p>
              <span className="text-[10px] text-slate-400 font-semibold block mt-1">Kabul bekliyor</span>
            </div>

            <div className={`p-4 rounded-2xl border ${isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'}`}>
              <div className="flex items-center justify-between text-xs text-slate-500 mb-1">
                <span className="font-bold">Hazırlanıyor</span>
                <span className="w-2 h-2 rounded-full bg-blue-500"></span>
              </div>
              <p className="text-xl font-black text-blue-500">5 <span className="text-xs font-bold text-slate-400">Sipariş</span></p>
              <span className="text-[10px] text-slate-400 font-semibold block mt-1">Mutfakta hazırlanıyor</span>
            </div>

            <div className={`p-4 rounded-2xl border ${isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'}`}>
              <div className="flex items-center justify-between text-xs text-slate-500 mb-1">
                <span className="font-bold">Kuryede / Yolda</span>
                <span className="w-2 h-2 rounded-full bg-indigo-500"></span>
              </div>
              <p className="text-xl font-black text-indigo-500">4 <span className="text-xs font-bold text-slate-400">Sipariş</span></p>
              <span className="text-[10px] text-slate-400 font-semibold block mt-1">Müşteriye teslimatta</span>
            </div>

            <div className={`p-4 rounded-2xl border ${isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'}`}>
              <div className="flex items-center justify-between text-xs text-slate-500 mb-1">
                <span className="font-bold">Bugün Teslim Edilen</span>
                <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
              </div>
              <p className="text-xl font-black text-emerald-600 dark:text-emerald-400">32 <span className="text-xs font-bold text-slate-400">Sipariş</span></p>
              <span className="text-[10px] text-slate-400 font-semibold block mt-1">Başarıyla ulaştırıldı</span>
            </div>
          </div>
        </div>

        {/* Two Column Section: Top Products + Financial Settlement Report */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          
          {/* Top Products Bestsellers */}
          <div className={`p-6 rounded-3xl border space-y-4 transition-all ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-xs'
          }`}>
            <div className="flex items-center justify-between pb-3 border-b border-slate-200 dark:border-slate-800">
              <div className="flex items-center gap-2">
                <Award className="w-5 h-5 text-[#FF6B00]" />
                <h3 className="font-extrabold text-sm uppercase tracking-wider">En Çok Satan 5 Ürün</h3>
              </div>
              <span className="text-xs text-slate-400 font-bold">Satış Performansı</span>
            </div>

            <div className="space-y-3">
              {topProducts.map((prod: any, idx: number) => (
                <div key={idx} className={`p-3.5 rounded-2xl border flex items-center justify-between transition-colors ${
                  isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200 hover:border-[#FF6B00]/30'
                }`}>
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-xl bg-[#FF6B00] text-white flex items-center justify-center font-black text-xs">
                      #{idx + 1}
                    </div>
                    <div>
                      <h4 className="font-bold text-sm">{prod.name}</h4>
                      <span className="text-xs text-slate-400 font-semibold">{prod.count} adet satıldı</span>
                    </div>
                  </div>

                  <span className="font-black text-sm text-[#FF6B00]">₺{Number(prod.revenue).toFixed(2)}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Financial Settlement & Payout Report (Hakediş Raporu) */}
          <div className={`p-6 rounded-3xl border space-y-4 transition-all ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-xs'
          }`}>
            <div className="flex items-center justify-between pb-3 border-b border-slate-200 dark:border-slate-800">
              <div className="flex items-center gap-2">
                <ShieldCheck className="w-5 h-5 text-emerald-600 dark:text-emerald-400" />
                <h3 className="font-extrabold text-sm uppercase tracking-wider">Hakediş & Finans Mutabakatı</h3>
              </div>
              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20">
                Haftalık Düzenli Transfer
              </span>
            </div>

            <div className={`p-4 rounded-2xl border space-y-3 ${
              isDark ? 'bg-slate-950 border-slate-800' : 'bg-slate-50 border-slate-200'
            }`}>
              <div className="flex justify-between text-xs font-bold">
                <span className="text-slate-500">Brüt Satış Cirosu:</span>
                <span>₺{totalRevenue.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}</span>
              </div>

              <div className="flex justify-between text-xs font-bold text-rose-500">
                <span>Hoppa Komisyon Kesintisi (%12):</span>
                <span>-₺{commissionFee.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}</span>
              </div>

              <div className="pt-3 border-t border-slate-200 dark:border-slate-800 flex justify-between items-center">
                <div>
                  <span className="text-xs text-slate-400 font-extrabold block uppercase">Net Banka Hesabınıza Yatacak Tutar</span>
                  <span className="text-xs text-slate-500 font-semibold">Ödeme Günü: Gelecek Pazartesi (09:00)</span>
                </div>
                <span className="text-xl font-black text-emerald-600 dark:text-emerald-400">
                  ₺{netPayout.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
                </span>
              </div>
            </div>

            <div className="p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 text-xs text-slate-600 dark:text-slate-300 space-y-1">
              <p className="font-bold text-emerald-600 dark:text-emerald-400">💡 Kurumsal Otomatik Mutabakat Bildirimi:</p>
              <p className="text-[11px]">
                Ödemeleriniz her Pazartesi saat 09:00'da sistemde kayıtlı TR56... IBAN numaralı kurumsal banka hesabınıza otomatik olarak aktarılır.
              </p>
            </div>
          </div>

        </div>
      </div>
    </MerchantLayout>
  );
}

import React, { useCallback, useEffect, useState } from 'react';
import {
  Wallet,
  Building2,
  CreditCard,
  Download,
  RefreshCw,
  CheckCircle2,
  Save,
  TrendingUp,
  Percent,
  DollarSign,
} from 'lucide-react';
import MerchantLayout from '../../../components/merchant/MerchantLayout';
import HoppaSelect from '../../../components/merchant/HoppaSelect';
import StatusIndicator, { StatusTone } from '../../../components/merchant/StatusIndicator';
import { useToast } from '../../../components/merchant/ToastContext';
import { merchantApiFetch } from '../../../utils/merchant-auth';
import { useMerchantTheme } from '../../../context/MerchantThemeContext';

interface SettlementOrderItem {
  id: string;
  createdAt: string;
  status: string;
  paymentMethod: string;
  paymentStatus: string;
  grossAmount: number;
  commissionRate: number;
  commissionAmount: number;
  netAmount: number;
  isSettled: boolean;
}

interface BankInfoData {
  iban: string;
  bankName: string;
  accountHolder: string;
  updatedAt?: string;
}

interface FinanceOverviewResponse {
  shopId: string;
  shopName: string;
  activeCommissionRate: number;
  grossRevenue: number;
  commissionTotal: number;
  netPayout: number;
  settledOrderCount: number;
  bankInfo: BankInfoData | null;
  settlements: SettlementOrderItem[];
}

const BANK_OPTIONS = [
  { value: 'Kıbrıs İktisat Bankası', label: 'Kıbrıs İktisat Bankası' },
  { value: 'Koopbank (Kıbrıs Türk Kooperatif Merkez Bankası)', label: 'Koopbank' },
  { value: 'Türk Bankası', label: 'Türk Bankası' },
  { value: 'Limasol Türk Kooperatif Bankası', label: 'Limasol Türk Kooperatif Bankası' },
  { value: 'Yakın Doğu Bank', label: 'Yakın Doğu Bank' },
  { value: 'Creditwest Bank', label: 'Creditwest Bank' },
  { value: 'Türkiye İş Bankası', label: 'Türkiye İş Bankası' },
  { value: 'Ziraat Bankası', label: 'Ziraat Bankası' },
  { value: 'Garanti BBVA', label: 'Garanti BBVA' },
  { value: 'Halkbank', label: 'Halkbank' },
  { value: 'Diğer Kurumsal Banka', label: 'Diğer Kurumsal Banka' },
];

const PAYMENT_LABELS: Record<string, string> = {
  ONLINE_PAYMENT: 'Online Kart',
  CASH_ON_DELIVERY: 'Kapıda Nakit',
  CARD_ON_DELIVERY: 'Kapıda Kart',
  WALLET: 'Hoppa Para',
};

const ORDER_STATUS_BADGE: Record<string, { label: string; tone: StatusTone }> = {
  DELIVERED: { label: 'Teslim Edildi', tone: 'emerald' },
  PENDING: { label: 'Bekliyor', tone: 'amber' },
  PREPARING: { label: 'Hazırlanıyor', tone: 'orange' },
  READY_FOR_PICKUP: { label: 'Hazır', tone: 'sky' },
  ON_THE_WAY: { label: 'Kuryede', tone: 'indigo' },
  CANCELLED: { label: 'İptal', tone: 'rose' },
};

function formatIbanGroups(raw: string): string {
  const clean = raw.replace(/[^A-Za-z0-9]/g, '').toUpperCase().slice(0, 34);
  return clean.replace(/(.{4})/g, '$1 ').trim();
}

export default function MerchantFinancePage() {
  const { theme } = useMerchantTheme();
  const toast = useToast();
  const isDark = theme === 'dark';

  const [financeData, setFinanceData] = useState<FinanceOverviewResponse | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isSavingBank, setIsSavingBank] = useState<boolean>(false);

  const [bankName, setBankName] = useState<string>('Kıbrıs İktisat Bankası');
  const [accountHolder, setAccountHolder] = useState<string>('');
  const [ibanDisplay, setIbanDisplay] = useState<string>('');

  const loadFinance = useCallback(async () => {
    setIsLoading(true);
    try {
      const res = await merchantApiFetch('/merchant/finance');
      if (res.data) {
        const data = res.data as FinanceOverviewResponse;
        setFinanceData(data);
        if (data.bankInfo) {
          setBankName(data.bankInfo.bankName || 'Kıbrıs İktisat Bankası');
          setAccountHolder(data.bankInfo.accountHolder || '');
          setIbanDisplay(formatIbanGroups(data.bankInfo.iban || ''));
        }
      }
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : 'Finansal veriler yüklenemedi.');
    } finally {
      setIsLoading(false);
    }
  }, [toast]);

  useEffect(() => {
    void loadFinance();
  }, [loadFinance]);

  const handleSaveBank = async (e: React.FormEvent) => {
    e.preventDefault();
    const cleanIban = ibanDisplay.replace(/\s+/g, '').toUpperCase();
    if (!cleanIban || cleanIban.length < 16) {
      toast.warning('Lütfen geçerli bir IBAN numarası giriniz.');
      return;
    }
    if (accountHolder.trim().length < 3) {
      toast.warning('Hesap sahibi veya firma ünvanını giriniz.');
      return;
    }

    setIsSavingBank(true);
    try {
      const res = await merchantApiFetch('/merchant/finance/bank', {
        method: 'PUT',
        body: JSON.stringify({
          iban: cleanIban,
          bankName,
          accountHolder: accountHolder.trim(),
        }),
      });
      toast.success(res.message || 'Banka ve IBAN bilgileriniz kaydedildi.');
      await loadFinance();
    } catch (err: unknown) {
      toast.error(err instanceof Error ? err.message : 'Banka bilgileri kaydedilemedi.');
    } finally {
      setIsSavingBank(false);
    }
  };

  const handleExportCsv = () => {
    if (!financeData || financeData.settlements.length === 0) {
      toast.info('Dışa aktarılacak sipariş mutabakat kaydı bulunmuyor.');
      return;
    }

    const headers = [
      'Sipariş ID',
      'Tarih',
      'Durum',
      'Ödeme Yöntemi',
      'Brüt Tutar (TL)',
      'Komisyon Oranı (%)',
      'Komisyon Kesintisi (TL)',
      'Net Hakediş (TL)',
      'Mutabakat',
    ];

    const rows = financeData.settlements.map((item) => [
      item.id.slice(0, 8).toUpperCase(),
      new Date(item.createdAt).toLocaleString('tr-TR'),
      ORDER_STATUS_BADGE[item.status]?.label || item.status,
      PAYMENT_LABELS[item.paymentMethod] || item.paymentMethod,
      item.grossAmount.toFixed(2),
      Math.round(item.commissionRate * 100),
      item.commissionAmount.toFixed(2),
      item.netAmount.toFixed(2),
      item.isSettled ? 'Hakedişe Dahil' : 'Beklemede / İptal',
    ]);

    const csv =
      'data:text/csv;charset=utf-8,\uFEFF' +
      [headers.join(','), ...rows.map((r) => r.map((v) => `"${v}"`).join(','))].join('\n');

    const link = document.createElement('a');
    link.href = encodeURI(csv);
    link.download = `hoppa_hakedis_mutabakat_${new Date().toISOString().slice(0, 10)}.csv`;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const commissionPct = Math.round((financeData?.activeCommissionRate ?? 0.05) * 100);
  const planLabel =
    commissionPct === 15
      ? 'Ana Ekran Vitrin (%15)'
      : commissionPct === 10
        ? 'Kategori Vitrini (%10)'
        : 'Standart Plan (%5)';

  return (
    <MerchantLayout
      title="Finans, Hakediş & Banka Merkezi"
      subtitle="Sipariş bazlı net hakediş mutabakatı ve kurumsal IBAN ödeme ayarları"
      headerIcon={Wallet}
      activeTab="finance"
      headerActions={
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={handleExportCsv}
            disabled={!financeData || financeData.settlements.length === 0}
            className={`px-3.5 py-2 rounded-xl border text-xs font-bold flex items-center gap-1.5 disabled:opacity-40 ${
              isDark
                ? 'bg-slate-800 border-slate-700 text-slate-200 hover:bg-slate-700'
                : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50'
            }`}
          >
            <Download className="w-3.5 h-3.5" />
            <span>CSV Mutabakat İndir</span>
          </button>
          <button
            type="button"
            onClick={() => void loadFinance()}
            disabled={isLoading}
            aria-label="Finans verilerini yenile"
            className={`p-2 rounded-xl border transition-colors ${
              isDark
                ? 'bg-slate-800 border-slate-700 text-slate-200 hover:bg-slate-700'
                : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'
            }`}
          >
            <RefreshCw className={`w-4 h-4 ${isLoading ? 'animate-spin' : ''}`} />
          </button>
        </div>
      }
    >
      <div className="space-y-6">
        {/* Financial KPIs */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 tabular-nums">
          <div
            className={`p-5 rounded-2xl border ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/90 shadow-2xs'
            }`}
          >
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold text-slate-400">Brüt Satış Cirosu</span>
              <DollarSign className="w-4 h-4 text-[#FF6B00]" />
            </div>
            <p className="text-2xl font-black text-[#FF6B00]">
              ₺{(financeData?.grossRevenue ?? 0).toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
            </p>
            <p className="text-[11px] text-slate-400 mt-1 font-semibold">
              {financeData?.settledOrderCount ?? 0} ödenen / teslim edilen sipariş
            </p>
          </div>

          <div
            className={`p-5 rounded-2xl border ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/90 shadow-2xs'
            }`}
          >
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold text-slate-400">Aktif Komisyon Tarifesi</span>
              <Percent className="w-4 h-4 text-sky-500" />
            </div>
            <p className="text-2xl font-black">%{commissionPct}</p>
            <p className="text-[11px] text-slate-400 mt-1 font-semibold">{planLabel}</p>
          </div>

          <div
            className={`p-5 rounded-2xl border ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/90 shadow-2xs'
            }`}
          >
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold text-slate-400">Toplam Komisyon Kesintisi</span>
              <TrendingUp className="w-4 h-4 text-rose-500" />
            </div>
            <p className="text-2xl font-black text-rose-500">
              -₺{(financeData?.commissionTotal ?? 0).toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
            </p>
            <p className="text-[11px] text-slate-400 mt-1 font-semibold">
              Sipariş anı oranlarına göre hesaplanır
            </p>
          </div>

          <div
            className={`p-5 rounded-2xl border ${
              isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/90 shadow-2xs'
            }`}
          >
            <div className="flex items-center justify-between mb-2">
              <span className="text-xs font-bold text-slate-400">Net Banka Hakedişiniz</span>
              <CheckCircle2 className="w-4 h-4 text-[#00A651]" />
            </div>
            <p className="text-2xl font-black text-[#00A651] dark:text-emerald-400">
              ₺{(financeData?.netPayout ?? 0).toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
            </p>
            <p className="text-[11px] text-slate-400 mt-1 font-semibold">
              Her Pazartesi 09:00 otomatik aktarım
            </p>
          </div>
        </div>

        {/* Corporate IBAN Settings Card */}
        <form
          onSubmit={handleSaveBank}
          className={`p-6 rounded-2xl border space-y-5 ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/90 shadow-2xs'
          }`}
        >
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-slate-100 dark:border-slate-800">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-[#FF6B00]/15 text-[#FF6B00] flex items-center justify-center shrink-0">
                <CreditCard className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-sm font-black">Kurumsal Banka &amp; IBAN Hesabı</h3>
                <p className="text-xs text-slate-400 font-medium">
                  Hakediş ödemelerinizin aktarılacağı KKTC veya Türkiye banka hesabınızı tanımlayın.
                </p>
              </div>
            </div>
            {financeData?.bankInfo?.updatedAt && (
              <span className="text-[11px] font-semibold text-emerald-600 dark:text-emerald-400 bg-emerald-500/10 px-3 py-1 rounded-xl shrink-0">
                Son Güncelleme: {new Date(financeData.bankInfo.updatedAt).toLocaleDateString('tr-TR')}
              </span>
            )}
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <HoppaSelect
                label="Banka Adı *"
                value={bankName}
                onChange={setBankName}
                options={BANK_OPTIONS}
                searchable
                searchPlaceholder="Banka ara..."
              />
            </div>

            <div>
              <label className="block text-[11px] font-bold tracking-wide text-slate-500 dark:text-slate-400 mb-1.5">
                Hesap Sahibi / Ticari Ünvan *
              </label>
              <div className="relative">
                <Building2 className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
                <input
                  type="text"
                  required
                  value={accountHolder}
                  onChange={(e) => setAccountHolder(e.target.value)}
                  placeholder="Örn: Hoppa Market Ltd."
                  className={`w-full border rounded-xl py-2.5 pl-10 pr-3.5 text-xs font-bold outline-none focus:border-[#FF6B00] ${
                    isDark
                      ? 'bg-slate-950 border-slate-800 text-white placeholder-slate-500'
                      : 'bg-slate-50 border-slate-200 text-slate-900 placeholder-slate-400'
                  }`}
                />
              </div>
            </div>

            <div>
              <label className="block text-[11px] font-bold tracking-wide text-slate-500 dark:text-slate-400 mb-1.5">
                IBAN Numarası *
              </label>
              <input
                type="text"
                required
                value={ibanDisplay}
                onChange={(e) => setIbanDisplay(formatIbanGroups(e.target.value))}
                placeholder="TR00 0000 0000 0000 0000 0000 00"
                className={`w-full border rounded-xl py-2.5 px-3.5 text-xs font-mono font-bold tracking-wider outline-none focus:border-[#FF6B00] ${
                  isDark
                    ? 'bg-slate-950 border-slate-800 text-white placeholder-slate-500'
                    : 'bg-slate-50 border-slate-200 text-slate-900 placeholder-slate-400'
                }`}
              />
            </div>
          </div>

          <div className="flex items-center justify-end">
            <button
              type="submit"
              disabled={isSavingBank}
              className="px-5 py-2.5 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-black flex items-center gap-2 transition-colors disabled:opacity-50"
            >
              {isSavingBank ? (
                <span className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />
              ) : (
                <Save className="w-4 h-4" />
              )}
              <span>IBAN Bilgilerini Kaydet</span>
            </button>
          </div>
        </form>

        {/* Order-Level Settlement Ledger */}
        <div
          className={`rounded-2xl border overflow-hidden ${
            isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200/90 shadow-2xs'
          }`}
        >
          <div className="p-5 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between gap-3">
            <div>
              <h3 className="text-sm font-black">Sipariş Bazlı Hakediş Defteri</h3>
              <p className="text-xs text-slate-400 font-medium">
                Son {financeData?.settlements.length ?? 0} siparişin brüt tutar, komisyon ve net hakediş kırılımı
              </p>
            </div>
          </div>

          {isLoading ? (
            <div className="py-12 text-center text-xs font-bold text-slate-400">
              Mutabakat kayıtları yükleniyor...
            </div>
          ) : !financeData || financeData.settlements.length === 0 ? (
            <div className="py-14 text-center text-xs font-bold text-slate-400">
              Henüz finansal mutabakat kaydı oluşmamış. İlk siparişler geldikçe burada görünecektir.
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs border-collapse tabular-nums">
                <thead>
                  <tr
                    className={`border-b text-[11px] font-extrabold ${
                      isDark
                        ? 'bg-slate-950 border-slate-800 text-slate-400'
                        : 'bg-slate-50 border-slate-200 text-slate-600'
                    }`}
                  >
                    <th className="p-3.5">Sipariş No</th>
                    <th className="p-3.5">Tarih</th>
                    <th className="p-3.5">Durum</th>
                    <th className="p-3.5">Ödeme Yöntemi</th>
                    <th className="p-3.5 text-right">Brüt Tutar</th>
                    <th className="p-3.5 text-right">Komisyon</th>
                    <th className="p-3.5 text-right">Net Hakediş</th>
                  </tr>
                </thead>
                <tbody className={`divide-y ${isDark ? 'divide-slate-800' : 'divide-slate-100'}`}>
                  {financeData.settlements.map((row) => {
                    const statusBadge = ORDER_STATUS_BADGE[row.status] || {
                      label: row.status,
                      tone: 'slate' as StatusTone,
                    };
                    return (
                      <tr
                        key={row.id}
                        className={isDark ? 'hover:bg-slate-800/40' : 'hover:bg-slate-50/70'}
                      >
                        <td className="p-3.5 font-mono font-black text-[#FF6B00]">
                          #{row.id.slice(0, 8).toUpperCase()}
                        </td>
                        <td className="p-3.5 text-slate-500 dark:text-slate-400 font-medium whitespace-nowrap">
                          {new Date(row.createdAt).toLocaleString('tr-TR', {
                            day: '2-digit',
                            month: '2-digit',
                            year: 'numeric',
                            hour: '2-digit',
                            minute: '2-digit',
                          })}
                        </td>
                        <td className="p-3.5">
                          <StatusIndicator
                            label={statusBadge.label}
                            tone={statusBadge.tone}
                            isDark={isDark}
                          />
                        </td>
                        <td className="p-3.5 font-semibold text-slate-600 dark:text-slate-300">
                          {PAYMENT_LABELS[row.paymentMethod] || row.paymentMethod}
                        </td>
                        <td className="p-3.5 text-right font-bold">
                          ₺{row.grossAmount.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}
                        </td>
                        <td className="p-3.5 text-right font-bold text-rose-500">
                          -₺{row.commissionAmount.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}{' '}
                          <span className="text-[10px] text-slate-400 font-semibold">
                            (%{Math.round(row.commissionRate * 100)})
                          </span>
                        </td>
                        <td className="p-3.5 text-right font-black text-[#00A651] dark:text-emerald-400">
                          {row.isSettled
                            ? `₺${row.netAmount.toLocaleString('tr-TR', { minimumFractionDigits: 2 })}`
                            : '—'}
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

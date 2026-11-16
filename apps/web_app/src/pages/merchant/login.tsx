import React, { useEffect, useState } from 'react';
import Head from 'next/head';
import { useRouter } from 'next/router';
import {
  AlertCircle,
  TrendingUp,
  Clock,
  Users,
  CheckCircle2,
  ChevronRight,
  Sun,
  Moon,
} from 'lucide-react';
import {
  clearMerchantAuth,
  getMerchantProfile,
  getMerchantToken,
  merchantApiFetch,
  MerchantProfile,
  setMerchantAuth,
} from '../../utils/merchant-auth';
import {
  getSavedMerchantAccounts,
  removeSavedMerchantAccount,
  upsertSavedMerchantAccount,
} from '../../utils/saved-accounts';
import { LoginViewMode, SavedMerchantAccount } from '../../types/auth.types';
import AccountChooser from '../../components/merchant/AccountChooser';
import MerchantLoginForm from '../../components/merchant/MerchantLoginForm';
import { useMerchantTheme } from '../../context/MerchantThemeContext';

interface LoginResponseMerchant extends MerchantProfile {
  ownerFirstName?: string;
  ownerLastName?: string;
}

export default function MerchantLoginPage() {
  const router = useRouter();
  const { theme, toggleTheme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [savedAccounts, setSavedAccounts] = useState<SavedMerchantAccount[]>([]);
  const [view, setView] = useState<LoginViewMode>('login');
  const [selectedAccount, setSelectedAccount] = useState<SavedMerchantAccount | null>(null);
  const [activeAccountId, setActiveAccountId] = useState<string | null>(null);
  const [verifyingAccountId, setVerifyingAccountId] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  useEffect(() => {
    const accounts = getSavedMerchantAccounts();
    const currentProfile = getMerchantProfile();
    const currentToken = getMerchantToken();

    setSavedAccounts(accounts);
    setActiveAccountId(currentProfile && currentToken ? currentProfile.id : null);

    if (accounts.length > 0) {
      setView('chooser');
    } else {
      setView('login');
    }
  }, [router.query.switch]);

  const handleSelectSavedAccount = async (account: SavedMerchantAccount) => {
    setErrorMsg(null);
    const currentProfile = getMerchantProfile();
    const currentToken = getMerchantToken();

    // Seçilen hesap halihazırda cihazdaki aktif oturumla eşleşiyorsa oturum geçerliliğini doğrula
    if (currentProfile?.id === account.id && currentToken) {
      setVerifyingAccountId(account.id);
      try {
        const isAdminRole =
          account.role === 'super_admin' || account.role === 'admin';
        await merchantApiFetch(isAdminRole ? '/admin/service-zones' : '/merchant/shop');
        upsertSavedMerchantAccount({
          ...account,
          lastLoginAt: new Date().toISOString(),
        });
        await router.push('/merchant/dashboard');
        return;
      } catch {
        // Oturum geçersizse yalnızca şifre soracak moda düş
        clearMerchantAuth();
        setActiveAccountId(null);
      } finally {
        setVerifyingAccountId(null);
      }
    } else if (currentToken) {
      // Farklı bir hesaba geçişte önceki aktif token bağlamını temizle
      clearMerchantAuth();
      setActiveAccountId(null);
    }

    setSelectedAccount(account);
    setView('password_only');
  };

  const handleRemoveSavedAccount = (accountId: string) => {
    const remaining = removeSavedMerchantAccount(accountId);
    setSavedAccounts(remaining);

    if (activeAccountId === accountId) {
      clearMerchantAuth();
      setActiveAccountId(null);
    }

    if (remaining.length === 0) {
      setSelectedAccount(null);
      setView('login');
    }
  };

  const handleLoginSubmit = async ({
    email,
    password,
    rememberOnDevice,
  }: {
    email: string;
    password: string;
    rememberOnDevice: boolean;
  }) => {
    setIsLoading(true);
    setErrorMsg(null);

    try {
      const res = await merchantApiFetch('/merchant/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      });

      const responseData = res.data as
        | {
            token?: string;
            refreshToken?: string;
            merchant?: LoginResponseMerchant;
          }
        | undefined;

      if (responseData?.token && responseData.merchant) {
        const merchant = responseData.merchant;
        setMerchantAuth(responseData.token, merchant, responseData.refreshToken);

        if (rememberOnDevice) {
          const fullOwnerName = `${merchant.ownerFirstName || ''} ${merchant.ownerLastName || ''}`.trim();
          const updated = upsertSavedMerchantAccount({
            id: merchant.id,
            email: merchant.email,
            merchantName: fullOwnerName || merchant.businessName,
            businessName: merchant.businessName,
            role: merchant.role,
            lastLoginAt: new Date().toISOString(),
          });
          setSavedAccounts(updated);
        }

        await router.push('/merchant/dashboard');
      } else {
        setErrorMsg('Giriş başarısız. Lütfen bilgilerinizi kontrol ediniz.');
      }
    } catch (err: unknown) {
      setErrorMsg(err instanceof Error ? err.message : 'Giriş yapılırken bir sunucu hatası oluştu.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <>
      <Head>
        <title>Hoppa İş Ortaklığı &amp; Satıcı Giriş Portalı</title>
        <meta
          name="description"
          content="Hoppa İş Ortakları için Çoklu Hesap Destekli Ürün, Menü ve Sipariş Yönetim Portalı"
        />
      </Head>

      <div
        className={`min-h-screen font-sans flex flex-col justify-between transition-colors duration-300 ${
          isDark ? 'bg-slate-950 text-slate-100' : 'bg-slate-50 text-slate-900'
        }`}
      >
        {/* Top Navbar */}
        <header
          className={`border-b px-6 py-4 flex items-center justify-between sticky top-0 z-40 transition-colors ${
            isDark ? 'bg-slate-900/90 border-slate-800' : 'bg-white/90 border-slate-200 shadow-sm'
          }`}
        >
          <div className="flex items-center gap-3">
            <img
              src="/logo-mark.svg"
              alt="Hoppa"
              className="w-9 h-9 rounded-xl object-cover shadow-xs ring-1 ring-black/5 shrink-0"
            />
            <div className="flex items-center">
              <span className="font-black text-lg tracking-tight">
                Hoppa <span className="text-[#FF6B00]">İş Ortağı</span>
              </span>
              <span
                className={`hidden sm:inline-block ml-3 pl-3 border-l text-xs font-semibold ${
                  isDark ? 'border-slate-800 text-slate-400' : 'border-slate-200 text-slate-500'
                }`}
              >
                Satıcı &amp; Şube Yönetim Portalı
              </span>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={toggleTheme}
              className={`p-2.5 rounded-xl border text-xs font-bold flex items-center gap-2 transition-all ${
                isDark
                  ? 'bg-slate-800 border-slate-700 text-amber-400 hover:bg-slate-700'
                  : 'bg-slate-100 border-slate-300 text-slate-700 hover:bg-slate-200'
              }`}
              title="Tema Değiştir (Beyaz / Karanlık)"
            >
              {isDark ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
              <span className="hidden md:inline">{isDark ? 'Açık Tema' : 'Karanlık Tema'}</span>
            </button>

            <a
              href="/merchant-onboard"
              className="px-4 py-2.5 rounded-xl bg-[#00A651] hover:bg-[#008C44] text-white font-bold text-xs shadow-sm transition-all"
            >
              İş Ortaklığı Başvurusu
            </a>
          </div>
        </header>

        {/* Main Split Layout */}
        <div className="flex-1 max-w-7xl w-full mx-auto p-4 md:p-8 lg:p-12 flex flex-col lg:flex-row items-center gap-8 lg:gap-16">
          {/* Left Promotional Showcase */}
          <div className="flex-1 space-y-8 text-left">
            <div>
              <div className="flex flex-wrap items-center gap-x-3 gap-y-1.5 mb-5">
                <span className="inline-flex items-center gap-2 text-xs font-extrabold uppercase tracking-[0.14em] text-[#FF6B00]">
                  <span className="w-2 h-2 rounded-[2px] bg-[#FF6B00]" aria-hidden="true" />
                  <span>Hoppa Ticari Ağ · KKTC</span>
                </span>
                <span
                  className={`hidden sm:inline-block h-3.5 w-px ${
                    isDark ? 'bg-slate-800' : 'bg-slate-300'
                  }`}
                  aria-hidden="true"
                />
                <span
                  className={`text-xs font-semibold ${
                    isDark ? 'text-slate-400' : 'text-slate-500'
                  }`}
                >
                  Lefkoşa · Girne · Gazimağusa · İskele · Güzelyurt
                </span>
              </div>

              <h1 className="text-3xl md:text-5xl font-black tracking-tight leading-tight">
                İşletmenizi Dijitale Taşıyın, <br className="hidden sm:inline" />
                <span className="text-[#FF6B00]">Satışlarınızı Katlayın</span>
              </h1>

              <p
                className={`mt-4 text-sm md:text-base leading-relaxed max-w-xl ${
                  isDark ? 'text-slate-400' : 'text-slate-600'
                }`}
              >
                Süpermarket, restoran, manav, kasap veya su bayisi olmanız fark etmez. Hoppa
                Satıcı Portalı ile tüm şube ve mağaza hesaplarınızı tek cihazdan güvenle yönetin.
              </p>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
              <div
                className={`p-4 rounded-2xl border transition-all ${
                  isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
                }`}
              >
                <div className="flex items-center gap-2 text-[#FF6B00] mb-1">
                  <Users className="w-5 h-5" />
                  <span className="text-xs font-extrabold">Aktif Müşteri</span>
                </div>
                <p className="text-2xl font-black tabular-nums">100.000+</p>
                <p className="text-[11px] text-slate-400 mt-0.5">KKTC Geneli Kullanıcı</p>
              </div>

              <div
                className={`p-4 rounded-2xl border transition-all ${
                  isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
                }`}
              >
                <div className="flex items-center gap-2 text-[#00A651] mb-1">
                  <Clock className="w-5 h-5" />
                  <span className="text-xs font-extrabold">Ort. Teslimat</span>
                </div>
                <p className="text-2xl font-black tabular-nums">28 Dk</p>
                <p className="text-[11px] text-slate-400 mt-0.5">Hoppa Kurye Ağı</p>
              </div>

              <div
                className={`col-span-2 sm:col-span-1 p-4 rounded-2xl border transition-all ${
                  isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
                }`}
              >
                <div className="flex items-center gap-2 text-amber-500 mb-1">
                  <TrendingUp className="w-5 h-5" />
                  <span className="text-xs font-extrabold">Ciro Artışı</span>
                </div>
                <p className="text-2xl font-black tabular-nums">%45+</p>
                <p className="text-[11px] text-slate-400 mt-0.5">Ortalama Satıcı Büyümesi</p>
              </div>
            </div>

            <div className="space-y-3.5">
              {[
                'Düşük komisyon oranları ve haftalık düzenli ödeme garantisi',
                'Kendi kuryenizle veya Hoppa profesyonel kurye ağıyla teslimat seçeneği',
                'Masaüstü kolaylığında toplu stok/fiyat güncelleme ve Master Katalog aktarımı',
                'Aynı cihazdan çoklu şube & işletme profili hızlı geçiş desteği',
              ].map((text) => (
                <div key={text} className="flex items-center gap-3">
                  <div className="w-6 h-6 rounded-full bg-[#00A651]/15 text-[#00A651] flex items-center justify-center shrink-0">
                    <CheckCircle2 className="w-4 h-4" />
                  </div>
                  <span className={`text-xs md:text-sm font-semibold ${isDark ? 'text-slate-300' : 'text-slate-700'}`}>
                    {text}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Right Auth Card (Account Chooser + Form State Machine) */}
          <div className="w-full max-w-md shrink-0">
            <div
              className={`rounded-3xl border p-8 shadow-xl transition-colors ${
                isDark
                  ? 'bg-slate-900 border-slate-800 shadow-black/80'
                  : 'bg-white border-slate-200 shadow-slate-200/50'
              }`}
            >
              <div className="mb-6 text-center">
                <h2 className="text-2xl font-black tracking-tight">
                  {view === 'chooser'
                    ? 'Bir Hesap Seçin'
                    : view === 'password_only'
                      ? 'Tekrar Hoş Geldiniz'
                      : 'Satıcı Paneli Girişi'}
                </h2>
                <p className={`text-xs mt-1 font-semibold ${isDark ? 'text-slate-400' : 'text-slate-500'}`}>
                  {view === 'chooser'
                    ? 'Devam etmek için kayıtlı mağaza profillerinizden birini seçin'
                    : view === 'password_only'
                      ? 'Güvenliğiniz için lütfen seçili hesabın şifresini girin'
                      : 'Hesabınıza giriş yaparak envanter ve siparişlerinizi yönetin'}
                </p>
              </div>

              {errorMsg && (
                <div className="mb-5 p-4 rounded-2xl bg-rose-500/10 border border-rose-500/30 text-rose-500 text-xs font-bold flex items-start gap-3">
                  <AlertCircle className="w-5 h-5 text-rose-500 shrink-0 mt-0.5" />
                  <span>{errorMsg}</span>
                </div>
              )}

              {view === 'chooser' && savedAccounts.length > 0 ? (
                <AccountChooser
                  accounts={savedAccounts}
                  activeAccountId={activeAccountId}
                  verifyingAccountId={verifyingAccountId}
                  isDark={isDark}
                  onSelectAccount={handleSelectSavedAccount}
                  onRemoveAccount={handleRemoveSavedAccount}
                  onUseAnotherAccount={() => {
                    setErrorMsg(null);
                    setSelectedAccount(null);
                    setView('login');
                  }}
                />
              ) : (
                <MerchantLoginForm
                  mode={view === 'password_only' ? 'password_only' : 'login'}
                  selectedAccount={selectedAccount}
                  hasSavedAccounts={savedAccounts.length > 0}
                  isLoading={isLoading}
                  isDark={isDark}
                  onSubmit={handleLoginSubmit}
                  onBackToChooser={() => {
                    setErrorMsg(null);
                    setSelectedAccount(null);
                    setView('chooser');
                  }}
                />
              )}

              <div className="mt-7 pt-6 border-t border-slate-200 dark:border-slate-800 text-center">
                <p className="text-xs font-semibold text-slate-500">
                  Henüz Hoppa satıcı hesabınız yok mu?
                </p>
                <a
                  href="/merchant-onboard"
                  className="mt-2 w-full py-3 px-4 rounded-xl border border-[#00A651] text-[#00A651] hover:bg-[#00A651]/10 font-bold text-xs inline-flex items-center justify-center gap-2 transition-all"
                >
                  <span>Anında İş Ortaklığı Başvurusu Yapın</span>
                  <ChevronRight className="w-4 h-4" />
                </a>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <footer
          className={`border-t px-6 py-4 text-center text-xs font-semibold ${
            isDark ? 'border-slate-800 text-slate-500' : 'border-slate-200 text-slate-400'
          }`}
        >
          <p>© 2026 Hoppa Delivery &amp; Marketplace. Tüm Hakları Saklıdır.</p>
        </footer>
      </div>
    </>
  );
}

import React, { useState } from 'react';
import Head from 'next/head';
import { useRouter } from 'next/router';
import { 
  Store, Lock, Mail, ArrowRight, ShieldCheck, AlertCircle, 
  TrendingUp, Clock, Users, Zap, CheckCircle2, Award, ChevronRight, Sun, Moon 
} from 'lucide-react';
import { merchantApiFetch, setMerchantAuth } from '../../utils/merchant-auth';
import { useMerchantTheme } from '../../context/MerchantThemeContext';

export default function MerchantLoginPage() {
  const router = useRouter();
  const { theme, toggleTheme } = useMerchantTheme();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email || !password) {
      setErrorMsg('Lütfen e-posta adresi ve şifrenizi giriniz.');
      return;
    }

    setIsLoading(true);
    setErrorMsg(null);

    try {
      const res = await merchantApiFetch('/merchant/auth/login', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      });

      if (res.data && res.data.token && res.data.merchant) {
        setMerchantAuth(res.data.token, res.data.merchant, res.data.refreshToken);
        router.push('/merchant/products');
      } else {
        setErrorMsg('Giriş başarısız. Lütfen bilgilerinizi kontrol ediniz.');
      }
    } catch (err: any) {
      setErrorMsg(err.message || 'Giriş yapılırken bir sunucu hatası oluştu.');
    } finally {
      setIsLoading(false);
    }
  };

  const isDark = theme === 'dark';

  return (
    <>
      <Head>
        <title>Hoppa İş Ortaklığı & Satıcı Giriş Portalı</title>
        <meta name="description" content="Hoppa İş Ortakları için Trendyol Partner tarzı Ürün, Menü ve Sipariş Yönetim Portalı" />
      </Head>

      <div className={`min-h-screen font-sans flex flex-col justify-between transition-colors duration-300 ${
        isDark ? 'bg-slate-950 text-slate-100' : 'bg-slate-50 text-slate-900'
      }`}>
        {/* Top Navbar */}
        <header className={`border-b px-6 py-4 flex items-center justify-between sticky top-0 z-40 transition-colors ${
          isDark ? 'bg-slate-900/90 border-slate-800' : 'bg-white/90 border-slate-200 shadow-sm'
        }`}>
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-[#FF6B00] text-white flex items-center justify-center font-black shadow-md shadow-[#FF6B00]/20">
              <Store className="w-6 h-6" />
            </div>
            <div>
              <span className="font-black text-xl tracking-tight">
                Hoppa <span className="text-[#FF6B00]">Satıcı</span>
              </span>
              <span className="hidden sm:inline-block ml-3 text-xs font-semibold text-slate-400 border-l border-slate-300 dark:border-slate-700 pl-3">
                İş Ortaklığı & Ürün Suite
              </span>
            </div>
          </div>

          <div className="flex items-center gap-3">
            {/* Theme Toggle Switch */}
            <button
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
              className="px-4 py-2.5 rounded-xl bg-[#00A651] hover:bg-[#008C44] text-white font-bold text-xs shadow-md shadow-[#00A651]/20 transition-all"
            >
              İş Ortaklığı Başvurusu
            </a>
          </div>
        </header>

        {/* Main Split Layout: Left Promotional Showcase + Right Login Card */}
        <div className="flex-1 max-w-7xl w-full mx-auto p-4 md:p-8 lg:p-12 flex flex-col lg:flex-row items-center gap-8 lg:gap-16">
          
          {/* Left Side: Trendyol / Getir Partner Style Promotional Showcase */}
          <div className="flex-1 space-y-8 text-left">
            <div>
              <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full text-xs font-extrabold uppercase tracking-wider bg-[#FF6B00]/10 text-[#FF6B00] border border-[#FF6B00]/20 mb-4">
                <Award className="w-4 h-4 text-[#FF6B00]" />
                <span>Kuzey Kıbrıs'ın Lider Yerel Pazar Yeri</span>
              </span>

              <h1 className="text-3xl md:text-5xl font-black tracking-tight leading-tight">
                İşletmenizi Dijitale Taşıyın, <br className="hidden sm:inline" />
                <span className="text-[#FF6B00]">Satışlarınızı Katlayın</span>
              </h1>

              <p className={`mt-4 text-sm md:text-base leading-relaxed max-w-xl ${
                isDark ? 'text-slate-400' : 'text-slate-600'
              }`}>
                Süpermarket, restoran, manav, kasap veya su bayisi olmanız fark etmez. 
                Hoppa Satıcı Portalı ile menülerinizi, stoklarınızı ve siparişlerinizi masaüstünüzden saniyeler içinde yönetin.
              </p>
            </div>

            {/* Live Stats Row */}
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-4">
              <div className={`p-4 rounded-2xl border transition-all ${
                isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
              }`}>
                <div className="flex items-center gap-2 text-[#FF6B00] mb-1">
                  <Users className="w-5 h-5" />
                  <span className="text-xs font-extrabold">Aktif Müşteri</span>
                </div>
                <p className="text-2xl font-black">100.000+</p>
                <p className="text-[11px] text-slate-400 mt-0.5">KKTC Geneli Kullanıcı</p>
              </div>

              <div className={`p-4 rounded-2xl border transition-all ${
                isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
              }`}>
                <div className="flex items-center gap-2 text-[#00A651] mb-1">
                  <Clock className="w-5 h-5" />
                  <span className="text-xs font-extrabold">Ort. Teslimat</span>
                </div>
                <p className="text-2xl font-black">28 Dk</p>
                <p className="text-[11px] text-slate-400 mt-0.5">Hoppa Kurye Ağı</p>
              </div>

              <div className={`col-span-2 sm:col-span-1 p-4 rounded-2xl border transition-all ${
                isDark ? 'bg-slate-900 border-slate-800' : 'bg-white border-slate-200 shadow-sm'
              }`}>
                <div className="flex items-center gap-2 text-amber-500 mb-1">
                  <TrendingUp className="w-5 h-5" />
                  <span className="text-xs font-extrabold">Ciro Artışı</span>
                </div>
                <p className="text-2xl font-black">%45+</p>
                <p className="text-[11px] text-slate-400 mt-0.5">Ortalama Satıcı Büyümesi</p>
              </div>
            </div>

            {/* Feature Bullets List (Trendyol Partner Style) */}
            <div className="space-y-3.5">
              {[
                'Düşük komisyon oranları ve haftalık düzenli ödeme garantisi',
                'Kendi kuryenizle veya Hoppa profesyonel kurye ağıyla teslimat seçeneği',
                'Masaüstü kolaylığında toplu stok/fiyat güncelleme ve Master Katalog aktarımı',
                'Sıfır başlangıç ve cihaz maliyeti — Anında dijitalleşme',
              ].map((text, idx) => (
                <div key={idx} className="flex items-center gap-3">
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

          {/* Right Side: Clean Login Card */}
          <div className="w-full max-w-md shrink-0">
            <div className={`rounded-3xl border p-8 shadow-xl transition-colors ${
              isDark 
                ? 'bg-slate-900 border-slate-800 shadow-black/80' 
                : 'bg-white border-slate-200 shadow-slate-200/50'
            }`}>
              <div className="mb-6 text-center">
                <h2 className="text-2xl font-black tracking-tight">Satıcı Paneli Girişi</h2>
                <p className={`text-xs mt-1 font-semibold ${isDark ? 'text-slate-400' : 'text-slate-500'}`}>
                  Hesabınıza giriş yaparak envanter ve siparişlerinizi yönetin
                </p>
              </div>

              {errorMsg && (
                <div className="mb-6 p-4 rounded-2xl bg-rose-500/10 border border-rose-500/30 text-rose-500 text-xs font-bold flex items-start gap-3">
                  <AlertCircle className="w-5 h-5 text-rose-500 shrink-0 mt-0.5" />
                  <span>{errorMsg}</span>
                </div>
              )}

              <form onSubmit={handleSubmit} className="space-y-5">
                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider mb-2 text-slate-400">
                    E-Posta Adresi
                  </label>
                  <div className="relative">
                    <Mail className="absolute left-4 top-3.5 w-5 h-5 text-slate-400" />
                    <input
                      type="email"
                      required
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="isletme@hoppa.app"
                      className={`w-full border rounded-2xl py-3.5 pl-12 pr-4 text-sm font-semibold outline-none transition-all ${
                        isDark 
                          ? 'bg-slate-950 border-slate-800 focus:border-[#FF6B00] text-white placeholder-slate-600' 
                          : 'bg-slate-50 border-slate-200 focus:border-[#FF6B00] text-slate-900 placeholder-slate-400'
                      }`}
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold uppercase tracking-wider mb-2 text-slate-400">
                    Şifre
                  </label>
                  <div className="relative">
                    <Lock className="absolute left-4 top-3.5 w-5 h-5 text-slate-400" />
                    <input
                      type="password"
                      required
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      placeholder="••••••••"
                      className={`w-full border rounded-2xl py-3.5 pl-12 pr-4 text-sm font-semibold outline-none transition-all ${
                        isDark 
                          ? 'bg-slate-950 border-slate-800 focus:border-[#FF6B00] text-white placeholder-slate-600' 
                          : 'bg-slate-50 border-slate-200 focus:border-[#FF6B00] text-slate-900 placeholder-slate-400'
                      }`}
                    />
                  </div>
                </div>

                <div className="flex items-center justify-between text-xs font-semibold py-1">
                  <label className="flex items-center gap-2 cursor-pointer select-none">
                    <input type="checkbox" defaultChecked className="rounded border-slate-300 text-[#FF6B00] focus:ring-0" />
                    <span>Beni Hatırla</span>
                  </label>
                  <a href="#forgot" className="text-[#FF6B00] hover:underline font-bold">
                    Şifremi Unuttum?
                  </a>
                </div>

                <button
                  type="submit"
                  disabled={isLoading}
                  className="w-full py-4 px-6 rounded-2xl bg-[#FF6B00] hover:bg-[#E56000] text-white font-black text-sm shadow-xl shadow-[#FF6B00]/25 flex items-center justify-center gap-2 transform active:scale-95 transition-all disabled:opacity-50"
                >
                  {isLoading ? (
                    <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  ) : (
                    <>
                      <span>Satıcı Paneline Giriş Yap</span>
                      <ArrowRight className="w-4 h-4" />
                    </>
                  )}
                </button>
              </form>

              {/* Partner Application Prompt */}
              <div className="mt-8 pt-6 border-t border-slate-200 dark:border-slate-800 text-center">
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
        <footer className={`border-t px-6 py-4 text-center text-xs font-semibold ${
          isDark ? 'border-slate-800 text-slate-500' : 'border-slate-200 text-slate-400'
        }`}>
          <p>© 2026 Hoppa Delivery & Marketplace. Tüm Hakları Saklıdır.</p>
        </footer>
      </div>
    </>
  );
}

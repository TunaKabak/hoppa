import React, { useEffect, useRef, useState } from 'react';
import { ArrowLeft, ArrowRight, Lock, Mail, Eye, EyeOff } from 'lucide-react';
import { LoginFormErrors, SavedMerchantAccount } from '../../types/auth.types';
import { sanitizeAccountText } from '../../utils/saved-accounts';

interface MerchantLoginFormProps {
  mode: 'login' | 'password_only';
  selectedAccount: SavedMerchantAccount | null;
  hasSavedAccounts: boolean;
  isLoading: boolean;
  isDark: boolean;
  onSubmit: (payload: { email: string; password: string; rememberOnDevice: boolean }) => Promise<void>;
  onBackToChooser: () => void;
}

const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export default function MerchantLoginForm({
  mode,
  selectedAccount,
  hasSavedAccounts,
  isLoading,
  isDark,
  onSubmit,
  onBackToChooser,
}: MerchantLoginFormProps) {
  const isPasswordOnly = mode === 'password_only' && selectedAccount !== null;

  const [email, setEmail] = useState<string>(selectedAccount?.email || '');
  const [password, setPassword] = useState<string>('');
  const [showPassword, setShowPassword] = useState<boolean>(false);
  const [rememberOnDevice, setRememberOnDevice] = useState<boolean>(true);
  const [showForgotHelp, setShowForgotHelp] = useState<boolean>(false);
  const [fieldErrors, setFieldErrors] = useState<LoginFormErrors>({});

  const passwordInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (isPasswordOnly && selectedAccount) {
      setEmail(selectedAccount.email);
      setPassword('');
      setFieldErrors({});
      const timer = setTimeout(() => {
        passwordInputRef.current?.focus();
      }, 60);
      return () => clearTimeout(timer);
    } else if (mode === 'login') {
      setFieldErrors({});
    }
  }, [isPasswordOnly, mode, selectedAccount]);

  const validate = (): boolean => {
    const errors: LoginFormErrors = {};
    const normalizedEmail = email.trim().toLowerCase();

    if (!isPasswordOnly) {
      if (!normalizedEmail) {
        errors.email = 'E-posta adresi zorunludur.';
      } else if (!EMAIL_PATTERN.test(normalizedEmail)) {
        errors.email = 'Geçerli bir e-posta adresi giriniz.';
      }
    }

    if (!password || password.length === 0) {
      errors.password = 'Şifre alanı zorunludur.';
    }

    setFieldErrors(errors);
    return Object.keys(errors).length === 0;
  };

  const handleFormSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) {
      return;
    }

    await onSubmit({
      email: (isPasswordOnly && selectedAccount ? selectedAccount.email : email).trim().toLowerCase(),
      password,
      rememberOnDevice,
    });
  };

  const safeBusinessName = selectedAccount
    ? sanitizeAccountText(selectedAccount.businessName, 'Hoppa Mağazası')
    : '';
  const isAdminRole =
    selectedAccount?.role === 'super_admin' || selectedAccount?.role === 'admin';

  return (
    <form onSubmit={handleFormSubmit} noValidate className="space-y-4">
      {hasSavedAccounts && (
        <button
          type="button"
          onClick={onBackToChooser}
          className="inline-flex items-center gap-1.5 text-xs font-black text-slate-400 hover:text-[#FF6B00] transition-colors"
        >
          <ArrowLeft className="w-3.5 h-3.5" />
          <span>Kayıtlı Hesaplara Dön</span>
        </button>
      )}

      {isPasswordOnly && selectedAccount && (
        <div
          className={`flex items-center gap-3 p-3.5 rounded-2xl border ${
            isDark
              ? 'bg-slate-950/70 border-slate-800'
              : 'bg-slate-50 border-slate-200/90'
          }`}
        >
          {selectedAccount.avatarUrl ? (
            <img
              src={selectedAccount.avatarUrl}
              alt={safeBusinessName}
              className="w-10 h-10 rounded-xl object-cover border border-slate-200 dark:border-slate-700 shrink-0"
            />
          ) : isAdminRole ? (
            <img
              src="/logo-mark.svg"
              alt="Hoppa"
              className="w-10 h-10 rounded-xl object-cover shadow-2xs ring-1 ring-black/5 shrink-0"
            />
          ) : (
            <div
              className={`w-10 h-10 rounded-xl font-extrabold text-sm flex items-center justify-center border shrink-0 ${
                isDark
                  ? 'bg-slate-900 border-slate-700 text-slate-100'
                  : 'bg-slate-900 border-slate-800 text-white'
              }`}
            >
              {safeBusinessName.charAt(0).toUpperCase() || 'H'}
            </div>
          )}
          <div className="min-w-0 flex-1">
            <p className="text-sm font-extrabold tracking-tight truncate">{safeBusinessName}</p>
            <p
              className={`text-xs font-medium truncate ${
                isDark ? 'text-slate-400' : 'text-slate-500'
              }`}
            >
              {sanitizeAccountText(selectedAccount.email)}
            </p>
          </div>
        </div>
      )}

      <div>
        <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
          E-Posta Adresi
        </label>
        <div className="relative">
          <Mail className="absolute left-4 top-3.5 w-4 h-4 text-slate-400" />
          <input
            type="email"
            value={email}
            disabled={isPasswordOnly}
            readOnly={isPasswordOnly}
            onChange={(e) => {
              setEmail(e.target.value);
              if (fieldErrors.email) {
                setFieldErrors((prev) => ({ ...prev, email: undefined }));
              }
            }}
            placeholder="isletme@hoppa.app"
            autoComplete="username"
            className={`w-full border rounded-2xl py-3 pl-11 pr-4 text-sm font-semibold outline-none transition-all ${
              isPasswordOnly ? 'opacity-70 cursor-not-allowed ' : ''
            }${
              isDark
                ? 'bg-slate-950 border-slate-800 focus:border-[#FF6B00] text-white placeholder-slate-600'
                : 'bg-slate-50 border-slate-200 focus:border-[#FF6B00] text-slate-900 placeholder-slate-400'
            }`}
          />
        </div>
        {fieldErrors.email && (
          <p className="mt-1 text-[11px] font-bold text-rose-500">{fieldErrors.email}</p>
        )}
      </div>

      <div>
        <label className="block text-xs font-bold uppercase tracking-wider mb-1.5 text-slate-400">
          Şifre
        </label>
        <div className="relative">
          <Lock className="absolute left-4 top-3.5 w-4 h-4 text-slate-400" />
          <input
            ref={passwordInputRef}
            type={showPassword ? 'text' : 'password'}
            value={password}
            onChange={(e) => {
              setPassword(e.target.value);
              if (fieldErrors.password) {
                setFieldErrors((prev) => ({ ...prev, password: undefined }));
              }
            }}
            placeholder="••••••••"
            autoComplete="current-password"
            className={`w-full border rounded-2xl py-3 pl-11 pr-11 text-sm font-semibold outline-none transition-all ${
              isDark
                ? 'bg-slate-950 border-slate-800 focus:border-[#FF6B00] text-white placeholder-slate-600'
                : 'bg-slate-50 border-slate-200 focus:border-[#FF6B00] text-slate-900 placeholder-slate-400'
            }`}
          />
          <button
            type="button"
            onClick={() => setShowPassword((prev) => !prev)}
            className="absolute right-3.5 top-3 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200"
            aria-label={showPassword ? 'Şifreyi gizle' : 'Şifreyi göster'}
          >
            {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
          </button>
        </div>
        {fieldErrors.password && (
          <p className="mt-1 text-[11px] font-bold text-rose-500">{fieldErrors.password}</p>
        )}
      </div>

      <div className="flex flex-wrap items-center justify-between gap-2 text-xs font-semibold py-1">
        <label className="flex items-center gap-2 cursor-pointer select-none">
          <input
            type="checkbox"
            checked={rememberOnDevice}
            onChange={(e) => setRememberOnDevice(e.target.checked)}
            className="rounded border-slate-300 text-[#FF6B00] focus:ring-0"
          />
          <span>Profili bu cihazda hatırla</span>
        </label>
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => setShowForgotHelp((prev) => !prev)}
            className={`font-bold transition-colors ${
              isDark ? 'text-slate-300 hover:text-white' : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Şifremi Unuttum
          </button>
          <a href="/merchant-onboard" className="text-[#FF6B00] hover:underline font-bold">
            Başvuru Durumu
          </a>
        </div>
      </div>

      {showForgotHelp && (
        <div
          className={`p-3.5 rounded-xl border text-xs space-y-1.5 ${
            isDark
              ? 'bg-slate-800/70 border-slate-700 text-slate-200'
              : 'bg-orange-50/70 border-orange-200 text-slate-700'
          }`}
        >
          <div className="font-black text-[#FF6B00]">Kurumsal Şifre Sıfırlama Desteği</div>
          <p className="leading-relaxed">
            Mağaza hesabı güvenliği nedeniyle şifre yenileme işlemleri Hoppa Kurumsal Destek tarafından
            doğrulanarak yapılır:
          </p>
          <div className="flex flex-wrap items-center gap-x-4 gap-y-1 font-bold tabular-nums pt-0.5">
            <a href="mailto:support@hoppanow.com" className="inline-flex items-center gap-1 hover:underline">
              <Mail className="w-3.5 h-3.5 text-[#FF6B00]" />
              <span>support@hoppanow.com</span>
            </a>
            <a href="tel:+905338765432" className="hover:underline">
              +90 533 876 54 32
            </a>
            <a href="/#contact" className="text-[#FF6B00] hover:underline">
              Hoppa Destek Merkezi
            </a>
          </div>
        </div>
      )}

      <button
        type="submit"
        disabled={isLoading}
        className="w-full py-3.5 px-6 rounded-2xl bg-[#FF6B00] hover:bg-[#E56000] text-white font-black text-sm flex items-center justify-center gap-2 transition-colors disabled:opacity-50"
      >
        {isLoading ? (
          <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
        ) : (
          <>
            <span>{isPasswordOnly ? 'Doğrula ve Devam Et' : 'Satıcı Paneline Giriş Yap'}</span>
            <ArrowRight className="w-4 h-4" />
          </>
        )}
      </button>
    </form>
  );
}

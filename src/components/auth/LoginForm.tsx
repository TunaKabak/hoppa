import React, { useEffect, useRef } from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { LoginCredentials } from '../../types/auth.types';
import { Mail, Lock, Eye, EyeOff, ArrowLeft } from 'lucide-react';

interface LoginFormProps {
  selectedEmail?: string;
  selectedMerchantName?: string;
  selectedAvatarUrl?: string;
  isLoading: boolean;
  onCancel: () => void;
  onSubmit: (credentials: LoginCredentials) => void;
  showBackButton: boolean;
}

// Zod Validation Schema
const createLoginSchema = (isPasswordOnly: boolean) => {
  return z.object({
    email: isPasswordOnly
      ? z.string().optional()
      : z
          .string()
          .min(1, 'E-posta alanı zorunludur.')
          .email('Lütfen geçerli bir e-posta adresi giriniz.'),
    password: z
      .string()
      .min(4, 'Şifre en az 4 karakter olmalıdır.'),
  });
};

export const LoginForm: React.FC<LoginFormProps> = ({
  selectedEmail,
  selectedMerchantName,
  selectedAvatarUrl,
  isLoading,
  onCancel,
  onSubmit,
  showBackButton,
}) => {
  const isPasswordOnly = !!selectedEmail;
  const passwordInputRef = useRef<HTMLInputElement | null>(null);
  const [showPassword, setShowPassword] = React.useState(false);

  // Dynamic schema based on authentication mode
  const loginSchema = createLoginSchema(isPasswordOnly);
  type LoginFormData = z.infer<typeof loginSchema>;

  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: selectedEmail || '',
      password: '',
    },
  });

  // Automatically register and set values for selectedEmail
  useEffect(() => {
    if (selectedEmail) {
      setValue('email', selectedEmail);
      // Auto focus password input
      if (passwordInputRef.current) {
        passwordInputRef.current.focus();
      }
    }
  }, [selectedEmail, setValue]);

  const handleFormSubmit = (data: LoginFormData) => {
    onSubmit({
      email: selectedEmail || data.email || '',
      password: data.password,
    });
  };

  const getInitials = (name: string) => {
    return name
      .split(' ')
      .slice(0, 2)
      .map(part => part[0])
      .join('')
      .toUpperCase();
  };

  return (
    <div className="w-full space-y-6">
      {/* Header and selected account card */}
      <div className="space-y-4 text-center">
        {showBackButton && (
          <button
            type="button"
            onClick={onCancel}
            className="inline-flex items-center space-x-1.5 text-xs font-semibold text-slate-500 hover:text-slate-800 dark:text-slate-400 dark:hover:text-white transition-colors"
          >
            <ArrowLeft className="w-3.5 h-3.5" />
            <span>Hesap Seçimine Dön</span>
          </button>
        )}

        {isPasswordOnly && selectedMerchantName ? (
          <div className="flex flex-col items-center space-y-3">
            <div className="relative">
              {selectedAvatarUrl ? (
                <img
                  src={selectedAvatarUrl}
                  alt={selectedMerchantName}
                  className="w-16 h-16 rounded-2xl object-cover shadow-md border border-slate-100 dark:border-slate-700"
                />
              ) : (
                <div className="w-16 h-16 bg-gradient-to-tr from-emerald-400 to-teal-600 rounded-2xl flex items-center justify-center text-white font-bold text-xl shadow-md border border-emerald-500/20">
                  {getInitials(selectedMerchantName)}
                </div>
              )}
            </div>
            <div>
              <h2 className="text-xl font-bold text-slate-900 dark:text-white tracking-tight">
                Hoş Geldiniz, {selectedMerchantName}
              </h2>
              <p className="text-sm text-slate-500 dark:text-slate-400 mt-0.5">
                {selectedEmail}
              </p>
            </div>
          </div>
        ) : (
          <div className="space-y-2">
            <h2 className="text-2xl font-bold tracking-tight text-slate-900 dark:text-white">
              Giriş Yap
            </h2>
            <p className="text-sm text-slate-500 dark:text-slate-400">
              Devam etmek için Hoppa iş ortağı bilgilerinizi giriniz.
            </p>
          </div>
        )}
      </div>

      {/* Main Login Form */}
      <form onSubmit={handleSubmit(handleFormSubmit)} className="space-y-4">
        {/* Email Input Field (Only visible/editable if not in password-only flow) */}
        {!isPasswordOnly && (
          <div className="space-y-1">
            <label className="text-xs font-semibold text-slate-600 dark:text-slate-300">
              E-posta Adresi
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-slate-400">
                <Mail className="w-5 h-5" />
              </div>
              <input
                type="email"
                {...register('email')}
                placeholder="ornek@firma.com"
                className={`w-full pl-11 pr-4 py-3.5 bg-slate-50/50 hover:bg-slate-100/30 focus:bg-white dark:bg-slate-800/50 dark:hover:bg-slate-800/80 dark:focus:bg-slate-900 rounded-2xl border ${
                  errors.email
                    ? 'border-red-500/60 focus:border-red-500 focus:ring-red-500/10'
                    : 'border-slate-200/80 dark:border-slate-700/80 focus:border-emerald-500 focus:ring-emerald-500/10'
                } focus:ring-4 outline-none transition-all duration-200 font-medium text-sm text-slate-800 dark:text-slate-100 placeholder-slate-400 dark:placeholder-slate-500`}
              />
            </div>
            {errors.email && (
              <p className="text-xs font-medium text-red-500 mt-1 pl-1">
                {errors.email.message}
              </p>
            )}
          </div>
        )}

        {/* Password Input Field */}
        <div className="space-y-1">
          <div className="flex justify-between items-center px-1">
            <label className="text-xs font-semibold text-slate-600 dark:text-slate-300">
              Şifre
            </label>
            <a
              href="#forgot-password"
              className="text-xs text-emerald-600 hover:text-emerald-700 dark:text-emerald-400 dark:hover:text-emerald-300 font-semibold transition-colors"
            >
              Şifremi Unuttum
            </a>
          </div>
          <div className="relative">
            <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-slate-400">
              <Lock className="w-5 h-5" />
            </div>
            <input
              type={showPassword ? 'text' : 'password'}
              {...register('password')}
              placeholder="••••••••"
              ref={(e) => {
                // Connect both react-hook-form and local ref
                register('password').ref(e);
                passwordInputRef.current = e;
              }}
              className={`w-full pl-11 pr-12 py-3.5 bg-slate-50/50 hover:bg-slate-100/30 focus:bg-white dark:bg-slate-800/50 dark:hover:bg-slate-800/80 dark:focus:bg-slate-900 rounded-2xl border ${
                errors.password
                  ? 'border-red-500/60 focus:border-red-500 focus:ring-red-500/10'
                  : 'border-slate-200/80 dark:border-slate-700/80 focus:border-emerald-500 focus:ring-emerald-500/10'
              } focus:ring-4 outline-none transition-all duration-200 font-medium text-sm text-slate-800 dark:text-slate-100 placeholder-slate-400 dark:placeholder-slate-500`}
            />
            {/* Show/Hide Password Toggle */}
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute inset-y-0 right-0 pr-4 flex items-center text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 transition-colors"
            >
              {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
            </button>
          </div>
          {errors.password && (
            <p className="text-xs font-medium text-red-500 mt-1 pl-1">
              {errors.password.message}
            </p>
          )}
        </div>

        {/* Submit Button */}
        <button
          type="submit"
          disabled={isLoading}
          className="relative w-full flex items-center justify-center py-3.5 px-4 bg-emerald-600 hover:bg-emerald-700 active:bg-emerald-800 text-white font-semibold rounded-2xl shadow-lg shadow-emerald-600/10 hover:shadow-xl hover:shadow-emerald-600/20 active:translate-y-0.5 outline-none focus:ring-4 focus:ring-emerald-500/20 transition-all duration-200 disabled:opacity-70 disabled:pointer-events-none text-sm tracking-wide mt-2"
        >
          {isLoading ? (
            <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
          ) : (
            <span>Devam Et</span>
          )}
        </button>
      </form>
    </div>
  );
};

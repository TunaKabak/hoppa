import React, {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useRef,
  useState,
} from 'react';
import {
  AlertTriangle,
  CheckCircle2,
  Info,
  X,
  XCircle,
} from 'lucide-react';
import { useMerchantTheme } from '../../context/MerchantThemeContext';

export type ToastTone = 'success' | 'error' | 'info' | 'warning';

interface ToastItem {
  id: string;
  tone: ToastTone;
  title?: string;
  message: string;
}

export interface ConfirmOptions {
  title: string;
  message: string;
  confirmText?: string;
  cancelText?: string;
  tone?: 'danger' | 'primary' | 'warning';
}

export interface ConfirmReasonOptions extends ConfirmOptions {
  reasonLabel: string;
  reasonPlaceholder?: string;
  initialReason?: string;
  reasonRequired?: boolean;
}

interface PendingConfirmState {
  options: ConfirmOptions & {
    withReason: boolean;
    reasonLabel?: string;
    reasonPlaceholder?: string;
    reasonRequired?: boolean;
  };
  reason: string;
  error: string | null;
  resolveBoolean?: (confirmed: boolean) => void;
  resolveReason?: (result: { confirmed: boolean; reason: string }) => void;
}

interface ToastContextValue {
  toast: {
    show: (message: string, tone?: ToastTone, title?: string) => void;
    success: (message: string, title?: string) => void;
    error: (message: string, title?: string) => void;
    info: (message: string, title?: string) => void;
    warning: (message: string, title?: string) => void;
  };
  confirm: (options: ConfirmOptions) => Promise<boolean>;
  confirmWithReason: (
    options: ConfirmReasonOptions
  ) => Promise<{ confirmed: boolean; reason: string }>;
}

const ToastContext = createContext<ToastContextValue | undefined>(undefined);

const TONE_META: Record<
  ToastTone,
  {
    Icon: React.ElementType;
    defaultTitle: string;
    lightBox: string;
    darkBox: string;
    iconBox: string;
  }
> = {
  success: {
    Icon: CheckCircle2,
    defaultTitle: 'Başarılı',
    lightBox: 'bg-white/95 border-emerald-200 text-slate-900',
    darkBox: 'bg-slate-900/95 border-emerald-500/40 text-slate-100',
    iconBox: 'bg-emerald-500/15 text-emerald-500',
  },
  error: {
    Icon: XCircle,
    defaultTitle: 'İşlem Hatası',
    lightBox: 'bg-white/95 border-rose-200 text-slate-900',
    darkBox: 'bg-slate-900/95 border-rose-500/40 text-slate-100',
    iconBox: 'bg-rose-500/15 text-rose-500',
  },
  warning: {
    Icon: AlertTriangle,
    defaultTitle: 'Uyarı',
    lightBox: 'bg-white/95 border-amber-200 text-slate-900',
    darkBox: 'bg-slate-900/95 border-amber-500/40 text-slate-100',
    iconBox: 'bg-amber-500/15 text-amber-500',
  },
  info: {
    Icon: Info,
    defaultTitle: 'Bilgi',
    lightBox: 'bg-white/95 border-sky-200 text-slate-900',
    darkBox: 'bg-slate-900/95 border-sky-500/40 text-slate-100',
    iconBox: 'bg-sky-500/15 text-sky-500',
  },
};

export const ToastProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const [toasts, setToasts] = useState<ToastItem[]>([]);
  const [pendingConfirm, setPendingConfirm] =
    useState<PendingConfirmState | null>(null);
  const timersRef = useRef<Map<string, number>>(new Map());
  const confirmButtonRef = useRef<HTMLButtonElement | null>(null);
  const reasonInputRef = useRef<HTMLTextAreaElement | null>(null);

  const dismissToast = useCallback((id: string) => {
    const timer = timersRef.current.get(id);
    if (timer !== undefined) {
      window.clearTimeout(timer);
      timersRef.current.delete(id);
    }
    setToasts((prev) => prev.filter((item) => item.id !== id));
  }, []);

  const showToast = useCallback(
    (message: string, tone: ToastTone = 'info', title?: string) => {
      const id = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
      setToasts((prev) => [...prev.slice(-3), { id, tone, title, message }]);
      if (typeof window !== 'undefined') {
        const timer = window.setTimeout(() => {
          dismissToast(id);
        }, 4500);
        timersRef.current.set(id, timer);
      }
    },
    [dismissToast]
  );

  useEffect(() => {
    return () => {
      timersRef.current.forEach((timer) => window.clearTimeout(timer));
      timersRef.current.clear();
    };
  }, []);

  const closeConfirm = useCallback(
    (confirmed: boolean) => {
      setPendingConfirm((current) => {
        if (!current) return null;
        if (confirmed && current.options.withReason && current.options.reasonRequired) {
          if (current.reason.trim().length < 3) {
            return {
              ...current,
              error: 'Lütfen en az 3 karakterlik bir gerekçe giriniz.',
            };
          }
        }
        if (current.resolveBoolean) {
          current.resolveBoolean(confirmed);
        }
        if (current.resolveReason) {
          current.resolveReason({
            confirmed,
            reason: confirmed ? current.reason.trim() : '',
          });
        }
        return null;
      });
    },
    []
  );

  useEffect(() => {
    if (!pendingConfirm) return;
    const focusTimer = window.setTimeout(() => {
      if (pendingConfirm.options.withReason) {
        reasonInputRef.current?.focus();
      } else {
        confirmButtonRef.current?.focus();
      }
    }, 30);

    const onKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        closeConfirm(false);
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => {
      window.clearTimeout(focusTimer);
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [pendingConfirm, closeConfirm]);

  const confirm = useCallback((options: ConfirmOptions) => {
    return new Promise<boolean>((resolve) => {
      setPendingConfirm({
        options: { ...options, withReason: false },
        reason: '',
        error: null,
        resolveBoolean: resolve,
      });
    });
  }, []);

  const confirmWithReason = useCallback((options: ConfirmReasonOptions) => {
    return new Promise<{ confirmed: boolean; reason: string }>((resolve) => {
      setPendingConfirm({
        options: {
          ...options,
          withReason: true,
          reasonRequired: options.reasonRequired ?? true,
        },
        reason: options.initialReason || '',
        error: null,
        resolveReason: resolve,
      });
    });
  }, []);

  const contextValue: ToastContextValue = {
    toast: {
      show: showToast,
      success: (msg, title) => showToast(msg, 'success', title),
      error: (msg, title) => showToast(msg, 'error', title),
      info: (msg, title) => showToast(msg, 'info', title),
      warning: (msg, title) => showToast(msg, 'warning', title),
    },
    confirm,
    confirmWithReason,
  };

  return (
    <ToastContext.Provider value={contextValue}>
      {children}

      {/* Global Toast Stack */}
      {toasts.length > 0 && (
        <div
          aria-live="polite"
          className="fixed top-5 right-5 z-[90] flex flex-col gap-2.5 w-[calc(100vw-2rem)] max-w-sm pointer-events-none print:hidden"
        >
          {toasts.map((item) => {
            const meta = TONE_META[item.tone];
            const Icon = meta.Icon;
            return (
              <div
                key={item.id}
                role="status"
                className={`pointer-events-auto rounded-2xl border p-3.5 backdrop-blur-md shadow-xl flex items-start gap-3 transition-all ${
                  isDark ? meta.darkBox : meta.lightBox
                }`}
              >
                <div
                  className={`w-8 h-8 rounded-xl flex items-center justify-center shrink-0 ${meta.iconBox}`}
                >
                  <Icon className="w-4 h-4" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-xs font-extrabold tracking-tight">
                    {item.title || meta.defaultTitle}
                  </p>
                  <p
                    className={`text-xs font-medium mt-0.5 leading-snug break-words ${
                      isDark ? 'text-slate-300' : 'text-slate-600'
                    }`}
                  >
                    {item.message}
                  </p>
                </div>
                <button
                  type="button"
                  onClick={() => dismissToast(item.id)}
                  aria-label="Bildirimi kapat"
                  className="p-1 rounded-lg text-slate-400 hover:text-slate-700 dark:hover:text-white transition-colors shrink-0"
                >
                  <X className="w-3.5 h-3.5" />
                </button>
              </div>
            );
          })}
        </div>
      )}

      {/* Accessible Confirmation Dialog */}
      {pendingConfirm && (
        <div
          className="fixed inset-0 z-[100] bg-slate-950/70 backdrop-blur-xs flex items-center justify-center p-4 print:hidden"
          onClick={() => closeConfirm(false)}
        >
          <div
            role="alertdialog"
            aria-modal="true"
            aria-labelledby="hoppa-confirm-title"
            aria-describedby="hoppa-confirm-desc"
            onClick={(e) => e.stopPropagation()}
            className={`w-full max-w-md rounded-3xl border p-6 shadow-2xl space-y-4 ${
              isDark
                ? 'bg-slate-900 border-slate-800 text-white'
                : 'bg-white border-slate-200 text-slate-900'
            }`}
          >
            <div className="flex items-start gap-3">
              <div
                className={`w-10 h-10 rounded-2xl flex items-center justify-center shrink-0 ${
                  pendingConfirm.options.tone === 'danger'
                    ? 'bg-rose-500/15 text-rose-500'
                    : pendingConfirm.options.tone === 'warning'
                      ? 'bg-amber-500/15 text-amber-500'
                      : 'bg-[#FF6B00]/15 text-[#FF6B00]'
                }`}
              >
                <AlertTriangle className="w-5 h-5" />
              </div>
              <div className="flex-1 min-w-0">
                <h3
                  id="hoppa-confirm-title"
                  className="text-base font-black tracking-tight"
                >
                  {pendingConfirm.options.title}
                </h3>
                <p
                  id="hoppa-confirm-desc"
                  className={`text-xs font-medium mt-1 leading-relaxed ${
                    isDark ? 'text-slate-300' : 'text-slate-600'
                  }`}
                >
                  {pendingConfirm.options.message}
                </p>
              </div>
            </div>

            {pendingConfirm.options.withReason && (
              <div className="space-y-1.5">
                <label className="block text-xs font-bold text-slate-500 dark:text-slate-400">
                  {pendingConfirm.options.reasonLabel}
                </label>
                <textarea
                  ref={reasonInputRef}
                  rows={3}
                  value={pendingConfirm.reason}
                  onChange={(e) =>
                    setPendingConfirm((prev) =>
                      prev
                        ? { ...prev, reason: e.target.value, error: null }
                        : null
                    )
                  }
                  placeholder={
                    pendingConfirm.options.reasonPlaceholder ||
                    'Açıklama veya gerekçe giriniz...'
                  }
                  className={`w-full border rounded-xl p-3 text-xs font-semibold outline-none focus:border-[#FF6B00] ${
                    isDark
                      ? 'bg-slate-950 border-slate-800 text-white placeholder-slate-500'
                      : 'bg-slate-50 border-slate-200 text-slate-900 placeholder-slate-400'
                  }`}
                />
                {pendingConfirm.error && (
                  <p className="text-[11px] font-bold text-rose-500">
                    {pendingConfirm.error}
                  </p>
                )}
              </div>
            )}

            <div className="flex items-center justify-end gap-2.5 pt-2 border-t border-slate-100 dark:border-slate-800">
              <button
                type="button"
                onClick={() => closeConfirm(false)}
                className={`px-4 py-2.5 rounded-xl text-xs font-bold transition-colors ${
                  isDark
                    ? 'bg-slate-800 hover:bg-slate-700 text-slate-200'
                    : 'bg-slate-100 hover:bg-slate-200 text-slate-700'
                }`}
              >
                {pendingConfirm.options.cancelText || 'Vazgeç'}
              </button>
              <button
                ref={confirmButtonRef}
                type="button"
                onClick={() => closeConfirm(true)}
                className={`px-4 py-2.5 rounded-xl text-xs font-black text-white shadow-sm transition-colors ${
                  pendingConfirm.options.tone === 'danger'
                    ? 'bg-rose-600 hover:bg-rose-700'
                    : pendingConfirm.options.tone === 'warning'
                      ? 'bg-amber-600 hover:bg-amber-700'
                      : 'bg-[#FF6B00] hover:bg-[#E56000]'
                }`}
              >
                {pendingConfirm.options.confirmText || 'Onayla'}
              </button>
            </div>
          </div>
        </div>
      )}
    </ToastContext.Provider>
  );
};

export function useToast() {
  const ctx = useContext(ToastContext);
  if (!ctx) {
    throw new Error('useToast must be used within a ToastProvider');
  }
  return ctx.toast;
}

export function useConfirm() {
  const ctx = useContext(ToastContext);
  if (!ctx) {
    throw new Error('useConfirm must be used within a ToastProvider');
  }
  return {
    confirm: ctx.confirm,
    confirmWithReason: ctx.confirmWithReason,
  };
}

import React, { useEffect } from 'react';
import { X } from 'lucide-react';
import { useMerchantTheme } from '../../context/MerchantThemeContext';

interface SlideOverDrawerProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  subtitle?: string;
  icon?: React.ReactNode;
  widthClass?: string;
  footer?: React.ReactNode;
  children: React.ReactNode;
}

export default function SlideOverDrawer({
  isOpen,
  onClose,
  title,
  subtitle,
  icon,
  widthClass = 'max-w-2xl',
  footer,
  children,
}: SlideOverDrawerProps) {
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  useEffect(() => {
    if (!isOpen) return;
    const prevOverflow = document.body.style.overflow;
    document.body.style.overflow = 'hidden';

    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        e.preventDefault();
        onClose();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => {
      document.body.style.overflow = prevOverflow;
      window.removeEventListener('keydown', handleKeyDown);
    };
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex justify-end bg-slate-950/60 backdrop-blur-xs font-sans print:hidden"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-label={title}
        onClick={(e) => e.stopPropagation()}
        className={`relative w-full ${widthClass} h-full flex flex-col border-l shadow-2xl transition-colors ${
          isDark
            ? 'bg-slate-900 border-slate-800 text-white'
            : 'bg-white border-slate-200 text-slate-900'
        }`}
      >
        {/* Header */}
        <div
          className={`px-6 py-4 border-b flex items-center justify-between gap-3 shrink-0 ${
            isDark
              ? 'bg-slate-950/90 border-slate-800'
              : 'bg-slate-50/90 border-slate-200'
          }`}
        >
          <div className="flex items-center gap-3 min-w-0">
            {icon && (
              <div className="w-10 h-10 rounded-2xl bg-[#FF6B00]/15 text-[#FF6B00] border border-[#FF6B00]/20 flex items-center justify-center shrink-0">
                {icon}
              </div>
            )}
            <div className="min-w-0">
              <h2 className="text-base sm:text-lg font-black tracking-tight truncate">
                {title}
              </h2>
              {subtitle && (
                <p className="text-xs font-medium text-slate-500 dark:text-slate-400 truncate">
                  {subtitle}
                </p>
              )}
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            aria-label="Paneli kapat"
            className={`p-2 rounded-xl transition-colors shrink-0 ${
              isDark
                ? 'text-slate-400 hover:text-white hover:bg-slate-800'
                : 'text-slate-400 hover:text-slate-800 hover:bg-slate-200/70'
            }`}
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Body */}
        <div className="flex-1 overflow-y-auto p-6 space-y-5">{children}</div>

        {/* Footer */}
        {footer && (
          <div
            className={`px-6 py-4 border-t shrink-0 ${
              isDark
                ? 'bg-slate-950/90 border-slate-800'
                : 'bg-slate-50/90 border-slate-200'
            }`}
          >
            {footer}
          </div>
        )}
      </div>
    </div>
  );
}

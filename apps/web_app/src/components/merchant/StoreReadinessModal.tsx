import React from 'react';
import { useRouter } from 'next/router';
import { 
  X, ArrowRight, ShieldCheck, 
  MapPin, Clock, CreditCard, Package, Building2, Store 
} from 'lucide-react';
import { useMerchantTheme } from '../../context/MerchantThemeContext';
import StatusIndicator from './StatusIndicator';

export interface StoreReadinessStep {
  id: string;
  title: string;
  description: string;
  category: string;
  isCompleted: boolean;
  weight: number;
  actionText: string;
  actionUrl: string;
}

export interface StoreReadinessData {
  score: number;
  isReadyToOpen: boolean;
  totalSteps: number;
  completedStepsCount: number;
  steps: StoreReadinessStep[];
  missingSteps: StoreReadinessStep[];
  activeProductCount: number;
}

interface StoreReadinessModalProps {
  isOpen: boolean;
  onClose: () => void;
  readinessData: StoreReadinessData | null;
}

export default function StoreReadinessModal({
  isOpen,
  onClose,
  readinessData,
}: StoreReadinessModalProps) {
  const router = useRouter();
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  if (!isOpen || !readinessData) return null;

  const score = readinessData.score;
  const isReady = readinessData.isReadyToOpen;

  const getStepIcon = (id: string) => {
    switch (id) {
      case 'identity': return Store;
      case 'location': return MapPin;
      case 'hours': return Clock;
      case 'payment': return CreditCard;
      case 'products': return Package;
      case 'legal': return Building2;
      default: return ShieldCheck;
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-md animate-fade-in">
      <div 
        className={`w-full max-w-2xl rounded-3xl overflow-hidden shadow-2xl border transition-all ${
          isDark ? 'bg-slate-900 border-slate-800 text-white' : 'bg-white border-slate-100 text-slate-900'
        }`}
      >
        {/* Modal Header */}
        <div
          className={`px-6 py-5 border-b flex items-center justify-between ${
            isDark ? 'bg-slate-900 border-slate-800 text-white' : 'bg-white border-slate-200 text-slate-900'
          }`}
        >
          <div className="flex items-center gap-3">
            <div
              className={`w-10 h-10 rounded-xl border flex items-center justify-center shrink-0 ${
                isDark
                  ? 'bg-slate-950 border-slate-800 text-[#FF6B00]'
                  : 'bg-slate-50 border-slate-200 text-[#FF6B00]'
              }`}
            >
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-lg font-black tracking-tight">Hoppa Mağaza Hazırlık Kontrol Listesi</h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 font-medium">
                Canlıya alınma ve sipariş kabul etme gereksinimleri
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="w-9 h-9 rounded-xl bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 flex items-center justify-center transition-colors text-slate-500 dark:text-slate-300"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        {/* Modal Content */}
        <div className="p-6 space-y-6 max-h-[75vh] overflow-y-auto">
          {/* Progress Header Box */}
          <div
            className={`p-5 rounded-2xl border ${
              isDark ? 'bg-slate-950/60 border-slate-800' : 'bg-slate-50 border-slate-200/80'
            }`}
          >
            <div className="flex items-center justify-between gap-4 mb-3">
              <div>
                <span className="text-xs font-bold text-slate-400 uppercase tracking-wider">
                  Profil Doluluk Oranı
                </span>
                <div className="flex items-center gap-3 mt-1">
                  <span className="text-2xl font-black tabular-nums">%{score}</span>
                  <StatusIndicator
                    label={isReady ? 'Sipariş Alımına Hazır' : 'Hazırlık Devam Ediyor'}
                    tone={isReady ? 'emerald' : 'orange'}
                    isDark={isDark}
                  />
                </div>
              </div>
              <div className="text-right tabular-nums">
                <span className="text-xs font-bold text-slate-400 block">Tamamlanan Adım</span>
                <span className="text-base font-black">
                  {readinessData.completedStepsCount} / {readinessData.totalSteps}
                </span>
              </div>
            </div>

            {/* Progress Bar */}
            <div className="w-full h-2 bg-slate-200 dark:bg-slate-800 rounded-full overflow-hidden">
              <div
                className={`h-full transition-all duration-500 rounded-full ${
                  isReady ? 'bg-[#00A651]' : 'bg-[#FF6B00]'
                }`}
                style={{ width: `${score}%` }}
              />
            </div>
          </div>

          {/* 6 Steps List */}
          <div className="space-y-3">
            <h4 className="text-xs font-extrabold text-slate-400 uppercase tracking-wider">
              Kontrol Adımları
            </h4>

            {readinessData.steps.map((step) => {
              const Icon = getStepIcon(step.id);
              return (
                <div
                  key={step.id}
                  className={`p-4 rounded-2xl border flex items-center justify-between gap-4 transition-all ${
                    step.isCompleted
                      ? isDark
                        ? 'bg-slate-900/60 border-slate-800'
                        : 'bg-slate-50/70 border-slate-200/70'
                      : isDark
                        ? 'bg-slate-900 border-slate-700'
                        : 'bg-white border-slate-200 shadow-2xs'
                  }`}
                >
                  <div className="flex items-center gap-3.5 min-w-0">
                    <div
                      className={`w-10 h-10 rounded-xl border flex items-center justify-center shrink-0 ${
                        step.isCompleted
                          ? isDark
                            ? 'bg-slate-950 border-slate-800 text-[#00A651]'
                            : 'bg-white border-slate-200 text-[#00A651]'
                          : isDark
                            ? 'bg-slate-950 border-slate-800 text-[#FF6B00]'
                            : 'bg-slate-50 border-slate-200 text-[#FF6B00]'
                      }`}
                    >
                      <Icon className="w-5 h-5" />
                    </div>
                    <div className="min-w-0">
                      <div className="flex flex-wrap items-center gap-2">
                        <h5 className="text-sm font-extrabold truncate">{step.title}</h5>
                        <StatusIndicator
                          label={step.isCompleted ? 'Tamamlandı' : 'Eksik'}
                          tone={step.isCompleted ? 'emerald' : 'orange'}
                          isDark={isDark}
                        />
                        <span className="text-[11px] font-semibold text-slate-400 tabular-nums">
                          Etki: %{step.weight}
                        </span>
                      </div>
                      <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5 truncate">
                        {step.description}
                      </p>
                    </div>
                  </div>

                  {!step.isCompleted && (
                    <button
                      type="button"
                      onClick={() => {
                        onClose();
                        router.push(step.actionUrl);
                      }}
                      className="px-3.5 py-2 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-black flex items-center gap-1.5 shrink-0 transition-colors"
                    >
                      <span>{step.actionText}</span>
                      <ArrowRight className="w-3.5 h-3.5" />
                    </button>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* Modal Footer */}
        <div className={`px-6 py-4 border-t flex items-center justify-between ${
          isDark ? 'bg-slate-900/80 border-slate-800' : 'bg-slate-50 border-slate-100'
        }`}>
          <p className="text-xs text-slate-400 font-medium">
            * Tüm zorunlu adımlar tamamlandığında dükkanınız sipariş alımına açılabilir.
          </p>
          <button
            onClick={onClose}
            className="px-5 py-2.5 rounded-xl bg-slate-200 dark:bg-slate-800 text-slate-700 dark:text-slate-200 text-xs font-black hover:bg-slate-300 transition-colors"
          >
            Kapat
          </button>
        </div>
      </div>
    </div>
  );
}

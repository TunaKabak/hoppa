import React from 'react';
import { useRouter } from 'next/router';
import { 
  X, CheckCircle2, AlertTriangle, ArrowRight, ShieldCheck, 
  MapPin, Clock, CreditCard, Package, Building2, Store 
} from 'lucide-react';
import { useMerchantTheme } from '../../context/MerchantThemeContext';

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
        <div className="bg-gradient-to-r from-[#E95D22] via-[#FF6B00] to-[#FF8C00] px-6 py-5 text-white flex items-center justify-between relative overflow-hidden">
          <div className="relative z-10 flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-white/20 backdrop-blur-md flex items-center justify-center">
              <ShieldCheck className="w-6 h-6 text-white" />
            </div>
            <div>
              <h3 className="text-lg font-black tracking-tight">Hoppa Mağaza Hazırlık Prosedürü</h3>
              <p className="text-xs text-white/80 font-medium">Canlıya alınma ve sipariş kabul etme kontrol listesi</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="w-9 h-9 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center transition-colors relative z-10"
          >
            <X className="w-5 h-5 text-white" />
          </button>
        </div>

        {/* Modal Content */}
        <div className="p-6 space-y-6 max-h-[75vh] overflow-y-auto">
          {/* Progress Header Box */}
          <div className={`p-5 rounded-2xl border ${
            isReady 
              ? 'bg-emerald-500/10 border-emerald-500/30' 
              : (isDark ? 'bg-slate-800/60 border-slate-700' : 'bg-orange-50/50 border-orange-100')
          }`}>
            <div className="flex items-center justify-between gap-4 mb-3">
              <div>
                <span className="text-xs font-bold text-slate-400 uppercase tracking-wider">Profil Doluluk Oranı</span>
                <div className="flex items-center gap-3 mt-1">
                  <span className="text-2xl font-black">{score}%</span>
                  <span className={`px-3 py-1 rounded-full text-xs font-black uppercase ${
                    isReady 
                      ? 'bg-emerald-500 text-white' 
                      : 'bg-[#FF6B00] text-white'
                  }`}>
                    {isReady ? 'Sipariş Alımına Hazır 🎉' : 'Hazırlık Devam Ediyor'}
                  </span>
                </div>
              </div>
              <div className="text-right">
                <span className="text-xs font-bold text-slate-400 block">Tamamlanan Adım</span>
                <span className="text-base font-black">{readinessData.completedStepsCount} / {readinessData.totalSteps}</span>
              </div>
            </div>

            {/* Progress Bar */}
            <div className="w-full h-3 bg-slate-200 dark:bg-slate-700 rounded-full overflow-hidden">
              <div 
                className={`h-full transition-all duration-500 ${
                  isReady ? 'bg-emerald-500' : 'bg-gradient-to-r from-[#E95D22] to-[#FF6B00]'
                }`}
                style={{ width: `${score}%` }}
              />
            </div>
          </div>

          {/* 6 Steps List */}
          <div className="space-y-3">
            <h4 className="text-sm font-extrabold text-slate-400 uppercase tracking-wider">Prosedör Adımları</h4>
            
            {readinessData.steps.map((step) => {
              const Icon = getStepIcon(step.id);
              return (
                <div
                  key={step.id}
                  className={`p-4 rounded-2xl border flex items-center justify-between gap-4 transition-all ${
                    step.isCompleted
                      ? (isDark ? 'bg-slate-800/40 border-slate-800' : 'bg-slate-50 border-slate-100')
                      : (isDark ? 'bg-slate-900 border-orange-500/30' : 'bg-white border-orange-200 shadow-sm')
                  }`}
                >
                  <div className="flex items-center gap-3.5 min-w-0">
                    <div className={`w-10 h-10 rounded-2xl flex items-center justify-center shrink-0 ${
                      step.isCompleted
                        ? 'bg-emerald-500/15 text-emerald-600 dark:text-emerald-400'
                        : 'bg-[#FF6B00]/15 text-[#FF6B00]'
                    }`}>
                      <Icon className="w-5 h-5" />
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center gap-2">
                        <h5 className="text-sm font-extrabold truncate">{step.title}</h5>
                        {step.isCompleted ? (
                          <span className="inline-flex items-center gap-1 text-[10px] font-black text-emerald-600 dark:text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-md">
                            <CheckCircle2 className="w-3 h-3" />
                            <span>Tamamlandı (+%{step.weight})</span>
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-[10px] font-black text-[#FF6B00] bg-[#FF6B00]/10 px-2 py-0.5 rounded-md">
                            <AlertTriangle className="w-3 h-3" />
                            <span>Eksik (+%{step.weight})</span>
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5 truncate">{step.description}</p>
                    </div>
                  </div>

                  {!step.isCompleted && (
                    <button
                      onClick={() => {
                        onClose();
                        router.push(step.actionUrl);
                      }}
                      className="px-3.5 py-2 rounded-xl bg-[#FF6B00] hover:bg-[#E56000] text-white text-xs font-black flex items-center gap-1.5 shrink-0 transition-all active:scale-95"
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

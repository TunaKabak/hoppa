import React from 'react';

export type StatusTone =
  | 'emerald'
  | 'amber'
  | 'orange'
  | 'sky'
  | 'indigo'
  | 'rose'
  | 'slate';

interface StatusIndicatorProps {
  label: string;
  tone: StatusTone;
  isDark: boolean;
  className?: string;
}

const DOT_TONE_CLASSES: Record<StatusTone, string> = {
  emerald: 'bg-[#00A651]',
  amber: 'bg-amber-500',
  orange: 'bg-[#FF6B00]',
  sky: 'bg-sky-500',
  indigo: 'bg-indigo-500',
  rose: 'bg-rose-500',
  slate: 'bg-slate-400',
};

/**
 * Hoppa kurumsal portal standartlarına uygun, nokta göstergeli nötr durum etiketi.
 */
export default function StatusIndicator({
  label,
  tone,
  isDark,
  className = '',
}: StatusIndicatorProps) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md border text-[11px] font-semibold leading-none whitespace-nowrap ${
        isDark
          ? 'bg-slate-950/80 border-slate-800 text-slate-200'
          : 'bg-slate-50/90 border-slate-200/90 text-slate-700'
      } ${className}`}
    >
      <span
        className={`w-1.5 h-1.5 rounded-full shrink-0 ${DOT_TONE_CLASSES[tone]}`}
        aria-hidden="true"
      />
      <span>{label}</span>
    </span>
  );
}

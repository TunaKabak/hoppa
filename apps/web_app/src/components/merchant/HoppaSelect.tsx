import React, { useState, useRef, useEffect, useId } from 'react';
import { ChevronDown, Check, Search, X } from 'lucide-react';
import { useMerchantTheme } from '../../context/MerchantThemeContext';

export interface HoppaSelectOption {
  value: string;
  label: string;
  icon?: React.ReactNode;
  badge?: string;
  badgeColor?: string;
  description?: string;
  disabled?: boolean;
}

interface HoppaSelectProps {
  options: (HoppaSelectOption | string)[];
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  label?: string;
  disabled?: boolean;
  searchable?: boolean;
  searchPlaceholder?: string;
  className?: string;
  size?: 'sm' | 'md' | 'lg';
  variant?: 'default' | 'subtle' | 'ghost' | 'contrast';
  prefixIcon?: React.ReactNode;
  zIndex?: number;
}

export default function HoppaSelect({
  options,
  value,
  onChange,
  placeholder = 'Seçiniz...',
  label,
  disabled = false,
  searchable = false,
  searchPlaceholder = 'Ara...',
  className = '',
  size = 'md',
  variant = 'default',
  prefixIcon,
  zIndex = 50,
}: HoppaSelectProps) {
  const { theme } = useMerchantTheme();
  const isDark = theme === 'dark';

  const reactId = useId();
  const triggerId = `hoppa-select-trigger-${reactId}`;
  const listboxId = `hoppa-select-listbox-${reactId}`;

  const [isOpen, setIsOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [highlightedIndex, setHighlightedIndex] = useState<number>(-1);
  const containerRef = useRef<HTMLDivElement>(null);
  const searchInputRef = useRef<HTMLInputElement>(null);

  const normalizedOptions: HoppaSelectOption[] = options.map((opt) =>
    typeof opt === 'string' ? { value: opt, label: opt } : opt
  );

  const selectedOption = normalizedOptions.find((opt) => opt.value === value);

  const filteredOptions = normalizedOptions.filter(
    (opt) =>
      opt.label.toLocaleLowerCase('tr-TR').includes(searchQuery.toLocaleLowerCase('tr-TR')) ||
      (opt.description &&
        opt.description.toLocaleLowerCase('tr-TR').includes(searchQuery.toLocaleLowerCase('tr-TR')))
  );

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
        setSearchQuery('');
      }
    };

    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen]);

  useEffect(() => {
    if (isOpen) {
      const currentIdx = filteredOptions.findIndex((o) => o.value === value && !o.disabled);
      setHighlightedIndex(currentIdx >= 0 ? currentIdx : 0);
      if (searchable && searchInputRef.current) {
        setTimeout(() => {
          searchInputRef.current?.focus();
        }, 40);
      }
    } else {
      setHighlightedIndex(-1);
    }
  }, [isOpen, searchable]);

  const handleSelectOption = (option: HoppaSelectOption) => {
    if (option.disabled) return;
    onChange(option.value);
    setIsOpen(false);
    setSearchQuery('');
  };

  const moveHighlight = (delta: 1 | -1) => {
    if (filteredOptions.length === 0) return;
    let next = highlightedIndex;
    for (let step = 0; step < filteredOptions.length; step++) {
      next = (next + delta + filteredOptions.length) % filteredOptions.length;
      if (!filteredOptions[next]?.disabled) {
        setHighlightedIndex(next);
        return;
      }
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (disabled) return;
    if (e.key === 'Escape') {
      if (isOpen) {
        e.preventDefault();
        setIsOpen(false);
        setSearchQuery('');
      }
      return;
    }
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      if (!isOpen) {
        setIsOpen(true);
      } else {
        moveHighlight(1);
      }
      return;
    }
    if (e.key === 'ArrowUp') {
      e.preventDefault();
      if (!isOpen) {
        setIsOpen(true);
      } else {
        moveHighlight(-1);
      }
      return;
    }
    if (e.key === 'Enter') {
      if (isOpen && highlightedIndex >= 0 && filteredOptions[highlightedIndex]) {
        e.preventDefault();
        handleSelectOption(filteredOptions[highlightedIndex]);
      }
    }
  };

  const sizeClasses = {
    sm: 'px-3 py-1.5 text-xs rounded-xl',
    md: 'px-3.5 py-2.5 text-xs rounded-xl font-semibold',
    lg: 'px-4 py-3 text-sm rounded-2xl font-semibold',
  };

  const getTriggerBg = () => {
    if (disabled) {
      return isDark
        ? 'bg-slate-900/40 text-slate-500 border-slate-800 cursor-not-allowed'
        : 'bg-slate-100 text-slate-400 border-slate-200 cursor-not-allowed';
    }

    switch (variant) {
      case 'subtle':
        return isDark
          ? 'bg-slate-900/80 hover:bg-slate-800/90 text-slate-200 border-slate-800/80 hover:border-orange-500/50'
          : 'bg-slate-50 hover:bg-slate-100/90 text-slate-700 border-slate-200/80 hover:border-orange-500/50';
      case 'contrast':
        return isDark
          ? 'bg-slate-950 text-white border-slate-800 hover:border-[#FF6B00]'
          : 'bg-white text-slate-900 border-slate-200 hover:border-[#FF6B00] shadow-xs';
      case 'ghost':
        return 'bg-transparent text-slate-700 dark:text-slate-200 border-transparent hover:bg-slate-100 dark:hover:bg-slate-800';
      case 'default':
      default:
        return isDark
          ? 'bg-slate-900/90 hover:bg-slate-800 text-slate-100 border-slate-800 hover:border-orange-500/40'
          : 'bg-white hover:bg-orange-50/20 text-slate-800 border-slate-200 hover:border-orange-500/40 shadow-xs';
    }
  };

  return (
    <div
      className={`relative inline-block w-full text-left font-sans ${className}`}
      ref={containerRef}
      onKeyDown={handleKeyDown}
    >
      {label && (
        <label
          htmlFor={triggerId}
          className="block text-[11px] font-bold tracking-wide text-slate-500 dark:text-slate-400 mb-1.5"
        >
          {label}
        </label>
      )}

      <button
        id={triggerId}
        type="button"
        disabled={disabled}
        role="combobox"
        aria-haspopup="listbox"
        aria-expanded={isOpen}
        aria-controls={listboxId}
        onClick={() => setIsOpen(!isOpen)}
        className={`w-full flex items-center justify-between gap-2 border transition-all duration-200 outline-none focus-visible:ring-2 focus-visible:ring-[#FF6B00]/40 select-none cursor-pointer group ${sizeClasses[size]} ${getTriggerBg()} ${
          isOpen ? 'ring-2 ring-[#FF6B00]/30 border-[#FF6B00] shadow-sm' : ''
        }`}
      >
        <div className="flex items-center gap-2 min-w-0 truncate">
          {prefixIcon && (
            <span className="shrink-0 text-slate-400 group-hover:text-[#FF6B00] transition-colors">
              {prefixIcon}
            </span>
          )}
          {selectedOption?.icon && <span className="shrink-0">{selectedOption.icon}</span>}
          <span className={`truncate ${!selectedOption ? 'text-slate-400 font-normal' : 'font-bold'}`}>
            {selectedOption ? selectedOption.label : placeholder}
          </span>
          {selectedOption?.badge && (
            <span
              className={`px-1.5 py-0.5 rounded text-[10px] font-semibold shrink-0 ${
                selectedOption.badgeColor
                  ? ''
                  : 'bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400'
              }`}
              style={
                selectedOption.badgeColor
                  ? {
                      backgroundColor: `${selectedOption.badgeColor}20`,
                      color: selectedOption.badgeColor,
                    }
                  : undefined
              }
            >
              {selectedOption.badge}
            </span>
          )}
        </div>

        <ChevronDown
          className={`w-4 h-4 shrink-0 transition-transform duration-200 text-slate-400 group-hover:text-[#FF6B00] ${
            isOpen ? 'rotate-180 text-[#FF6B00]' : ''
          }`}
        />
      </button>

      {isOpen && (
        <div
          id={listboxId}
          role="listbox"
          className="absolute left-0 right-0 mt-1.5 rounded-2xl border backdrop-blur-2xl shadow-2xl overflow-hidden transition-all duration-200 origin-top"
          style={{
            zIndex,
            backgroundColor: isDark ? 'rgba(15, 23, 42, 0.96)' : 'rgba(255, 255, 255, 0.98)',
            borderColor: isDark ? 'rgba(51, 65, 85, 0.8)' : 'rgba(226, 232, 240, 0.9)',
          }}
        >
          {searchable && (
            <div className="p-2 border-b border-slate-100 dark:border-slate-800/80 bg-slate-50/50 dark:bg-slate-950/40">
              <div className="relative flex items-center">
                <Search className="absolute left-2.5 w-3.5 h-3.5 text-slate-400" />
                <input
                  ref={searchInputRef}
                  type="text"
                  value={searchQuery}
                  onChange={(e) => {
                    setSearchQuery(e.target.value);
                    setHighlightedIndex(0);
                  }}
                  placeholder={searchPlaceholder}
                  className="w-full pl-8 pr-7 py-1.5 text-xs font-semibold rounded-lg bg-transparent border-0 outline-none placeholder-slate-400 text-slate-800 dark:text-slate-100"
                />
                {searchQuery && (
                  <button
                    type="button"
                    aria-label="Aramayı temizle"
                    onClick={() => setSearchQuery('')}
                    className="absolute right-2 p-0.5 text-slate-400 hover:text-slate-600 dark:hover:text-white"
                  >
                    <X className="w-3 h-3" />
                  </button>
                )}
              </div>
            </div>
          )}

          <div className="max-h-60 overflow-y-auto p-1.5 space-y-0.5 scrollbar-thin scrollbar-thumb-slate-300 dark:scrollbar-thumb-slate-700">
            {filteredOptions.length === 0 ? (
              <div className="py-4 text-center text-xs text-slate-400 font-medium">
                Sonuç bulunamadı
              </div>
            ) : (
              filteredOptions.map((option, idx) => {
                const isSelected = option.value === value;
                const isHighlighted = idx === highlightedIndex;
                return (
                  <button
                    key={option.value}
                    type="button"
                    role="option"
                    aria-selected={isSelected}
                    disabled={option.disabled}
                    onMouseEnter={() => setHighlightedIndex(idx)}
                    onClick={() => handleSelectOption(option)}
                    className={`w-full text-left px-3 py-2 rounded-xl text-xs flex items-center justify-between gap-2 transition-all group ${
                      option.disabled
                        ? 'opacity-40 cursor-not-allowed'
                        : isSelected
                          ? 'bg-gradient-to-r from-[#FF6B00] to-[#FF8533] text-white font-bold shadow-xs'
                          : isHighlighted
                            ? isDark
                              ? 'bg-slate-800 text-white font-semibold'
                              : 'bg-orange-50 text-[#FF6B00] font-semibold'
                            : isDark
                              ? 'text-slate-300 hover:bg-slate-800/80 hover:text-white font-semibold'
                              : 'text-slate-700 hover:bg-orange-50/70 hover:text-[#FF6B00] font-semibold'
                    }`}
                  >
                    <div className="flex items-center gap-2 min-w-0 truncate">
                      {option.icon && (
                        <span
                          className={`shrink-0 ${
                            isSelected ? 'text-white' : 'text-slate-400 group-hover:text-[#FF6B00]'
                          }`}
                        >
                          {option.icon}
                        </span>
                      )}
                      <div className="min-w-0 truncate">
                        <span className="truncate block">{option.label}</span>
                        {option.description && (
                          <span
                            className={`text-[10px] block truncate font-medium ${
                              isSelected ? 'text-white/80' : 'text-slate-400'
                            }`}
                          >
                            {option.description}
                          </span>
                        )}
                      </div>
                    </div>

                    <div className="flex items-center gap-1.5 shrink-0">
                      {option.badge && (
                        <span
                          className={`px-1.5 py-0.5 rounded text-[10px] font-semibold ${
                            isSelected
                              ? 'bg-white/20 text-white'
                              : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400'
                          }`}
                        >
                          {option.badge}
                        </span>
                      )}
                      {isSelected && <Check className="w-3.5 h-3.5 text-white shrink-0 stroke-[3]" />}
                    </div>
                  </button>
                );
              })
            )}
          </div>
        </div>
      )}
    </div>
  );
}

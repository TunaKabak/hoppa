import React, { useState, useRef, useEffect } from 'react';
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

  const [isOpen, setIsOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const containerRef = useRef<HTMLDivElement>(null);
  const searchInputRef = useRef<HTMLInputElement>(null);

  // Normalize options array
  const normalizedOptions: HoppaSelectOption[] = options.map((opt) => {
    if (typeof opt === 'string') {
      return { value: opt, label: opt };
    }
    return opt;
  });

  // Selected Option Object
  const selectedOption = normalizedOptions.find((opt) => opt.value === value);

  // Filtered Options when searchable
  const filteredOptions = normalizedOptions.filter((opt) =>
    opt.label.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (opt.description && opt.description.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  // Click outside to close
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

  // Focus search on open
  useEffect(() => {
    if (isOpen && searchable && searchInputRef.current) {
      setTimeout(() => {
        searchInputRef.current?.focus();
      }, 50);
    }
  }, [isOpen, searchable]);

  // Size styling maps
  const sizeClasses = {
    sm: 'px-3 py-1.5 text-xs rounded-xl',
    md: 'px-3.5 py-2.5 text-xs rounded-xl font-bold',
    lg: 'px-4 py-3 text-sm rounded-2xl font-bold',
  };

  // Base Trigger Button Styling
  const getTriggerBg = () => {
    if (disabled) return isDark ? 'bg-slate-900/40 text-slate-500 border-slate-800' : 'bg-slate-100 text-slate-400 border-slate-200';
    
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
    <div className={`relative inline-block w-full text-left font-sans ${className}`} ref={containerRef}>
      {label && (
        <label className="block text-[11px] font-black uppercase tracking-wider text-slate-400 mb-1.5">
          {label}
        </label>
      )}

      {/* Select Trigger Box */}
      <button
        type="button"
        disabled={disabled}
        onClick={() => setIsOpen(!isOpen)}
        className={`w-full flex items-center justify-between gap-2 border transition-all duration-200 outline-none select-none cursor-pointer group ${sizeClasses[size]} ${getTriggerBg()} ${
          isOpen ? 'ring-2 ring-[#FF6B00]/30 border-[#FF6B00] shadow-sm' : ''
        }`}
      >
        <div className="flex items-center gap-2 min-w-0 truncate">
          {prefixIcon && <span className="shrink-0 text-slate-400 group-hover:text-[#FF6B00] transition-colors">{prefixIcon}</span>}
          {selectedOption?.icon && <span className="shrink-0">{selectedOption.icon}</span>}
          <span className={`truncate ${!selectedOption ? 'text-slate-400 font-normal' : 'font-extrabold'}`}>
            {selectedOption ? selectedOption.label : placeholder}
          </span>
          {selectedOption?.badge && (
            <span
              className="px-1.5 py-0.5 rounded text-[9px] font-black shrink-0"
              style={{
                backgroundColor: selectedOption.badgeColor ? `${selectedOption.badgeColor}20` : 'rgba(255, 107, 0, 0.15)',
                color: selectedOption.badgeColor || '#FF6B00',
              }}
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

      {/* Dropdown Menu Popup */}
      {isOpen && (
        <div
          className={`absolute left-0 right-0 mt-1.5 rounded-2xl border backdrop-blur-2xl shadow-2xl overflow-hidden transition-all duration-200 origin-top`}
          style={{
            zIndex,
            backgroundColor: isDark ? 'rgba(15, 23, 42, 0.96)' : 'rgba(255, 255, 255, 0.98)',
            borderColor: isDark ? 'rgba(51, 65, 85, 0.8)' : 'rgba(226, 232, 240, 0.9)',
          }}
        >
          {/* Search Box */}
          {searchable && (
            <div className="p-2 border-b border-slate-100 dark:border-slate-800/80 bg-slate-50/50 dark:bg-slate-950/40">
              <div className="relative flex items-center">
                <Search className="absolute left-2.5 w-3.5 h-3.5 text-slate-400" />
                <input
                  ref={searchInputRef}
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder={searchPlaceholder}
                  className="w-full pl-8 pr-7 py-1.5 text-xs font-semibold rounded-lg bg-transparent border-0 outline-none placeholder-slate-400 text-slate-800 dark:text-slate-100"
                />
                {searchQuery && (
                  <button
                    type="button"
                    onClick={() => setSearchQuery('')}
                    className="absolute right-2 p-0.5 text-slate-400 hover:text-slate-600 dark:hover:text-white"
                  >
                    <X className="w-3 h-3" />
                  </button>
                )}
              </div>
            </div>
          )}

          {/* Options List */}
          <div className="max-h-60 overflow-y-auto p-1.5 space-y-0.5 scrollbar-thin scrollbar-thumb-slate-300 dark:scrollbar-thumb-slate-700">
            {filteredOptions.length === 0 ? (
              <div className="py-4 text-center text-xs text-slate-400 font-medium">
                Sonuç bulunamadı
              </div>
            ) : (
              filteredOptions.map((option) => {
                const isSelected = option.value === value;
                return (
                  <button
                    key={option.value}
                    type="button"
                    disabled={option.disabled}
                    onClick={() => {
                      if (!option.disabled) {
                        onChange(option.value);
                        setIsOpen(false);
                        setSearchQuery('');
                      }
                    }}
                    className={`w-full text-left px-3 py-2 rounded-xl text-xs flex items-center justify-between gap-2 transition-all group ${
                      option.disabled
                        ? 'opacity-40 cursor-not-allowed'
                        : isSelected
                        ? 'bg-gradient-to-r from-[#FF6B00] to-[#FF8533] text-white font-black shadow-xs'
                        : isDark
                        ? 'text-slate-300 hover:bg-slate-800/80 hover:text-white font-bold'
                        : 'text-slate-700 hover:bg-orange-50/70 hover:text-[#FF6B00] font-bold'
                    }`}
                  >
                    <div className="flex items-center gap-2 min-w-0 truncate">
                      {option.icon && (
                        <span className={`shrink-0 ${isSelected ? 'text-white' : 'text-slate-400 group-hover:text-[#FF6B00]'}`}>
                          {option.icon}
                        </span>
                      )}
                      <div className="min-w-0 truncate">
                        <span className="truncate block">{option.label}</span>
                        {option.description && (
                          <span className={`text-[10px] block truncate font-medium ${
                            isSelected ? 'text-white/80' : 'text-slate-400'
                          }`}>
                            {option.description}
                          </span>
                        )}
                      </div>
                    </div>

                    <div className="flex items-center gap-1.5 shrink-0">
                      {option.badge && (
                        <span
                          className={`px-1.5 py-0.5 rounded text-[9px] font-black ${
                            isSelected
                              ? 'bg-white/20 text-white'
                              : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400'
                          }`}
                        >
                          {option.badge}
                        </span>
                      )}
                      {isSelected && (
                        <Check className="w-3.5 h-3.5 text-white shrink-0 stroke-[3]" />
                      )}
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

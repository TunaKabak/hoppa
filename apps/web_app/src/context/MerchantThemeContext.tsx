import React, { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { useRouter } from 'next/router';

type Theme = 'light' | 'dark';

interface MerchantThemeContextType {
  theme: Theme;
  toggleTheme: () => void;
  setTheme: (theme: Theme) => void;
}

const MerchantThemeContext = createContext<MerchantThemeContextType | undefined>(undefined);

export const MerchantThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const router = useRouter();
  const [theme, setThemeState] = useState<Theme>('light');

  const applyThemeForRoute = useCallback((targetTheme: Theme, pathname: string) => {
    if (typeof document === 'undefined') return;
    const root = document.documentElement;
    const isMerchantRoute = pathname.startsWith('/merchant');
    if (isMerchantRoute && targetTheme === 'dark') {
      root.classList.add('dark');
    } else {
      root.classList.remove('dark');
    }
  }, []);

  useEffect(() => {
    const savedTheme = localStorage.getItem('hoppa_merchant_theme') as Theme | null;
    const resolvedTheme: Theme = savedTheme === 'dark' ? 'dark' : 'light';
    setThemeState(resolvedTheme);
    applyThemeForRoute(resolvedTheme, router.pathname);
  }, [router.pathname, applyThemeForRoute]);

  const setTheme = (newTheme: Theme) => {
    setThemeState(newTheme);
    localStorage.setItem('hoppa_merchant_theme', newTheme);
    applyThemeForRoute(newTheme, router.pathname);
  };

  const toggleTheme = () => {
    const next = theme === 'light' ? 'dark' : 'light';
    setTheme(next);
  };

  return (
    <MerchantThemeContext.Provider value={{ theme, toggleTheme, setTheme }}>
      {children}
    </MerchantThemeContext.Provider>
  );
};

export const useMerchantTheme = () => {
  const context = useContext(MerchantThemeContext);
  if (!context) {
    throw new Error('useMerchantTheme must be used within a MerchantThemeProvider');
  }
  return context;
};

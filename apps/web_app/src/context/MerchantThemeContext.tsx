import React, { createContext, useContext, useEffect, useState } from 'react';

type Theme = 'light' | 'dark';

interface MerchantThemeContextType {
  theme: Theme;
  toggleTheme: () => void;
  setTheme: (theme: Theme) => void;
}

const MerchantThemeContext = createContext<MerchantThemeContextType | undefined>(undefined);

export const MerchantThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [theme, setThemeState] = useState<Theme>('light');

  useEffect(() => {
    const savedTheme = localStorage.getItem('hoppa_merchant_theme') as Theme | null;
    if (savedTheme === 'dark' || savedTheme === 'light') {
      setThemeState(savedTheme);
      applyTheme(savedTheme);
    } else {
      setThemeState('light');
      applyTheme('light');
    }
  }, []);

  const applyTheme = (newTheme: Theme) => {
    const root = document.documentElement;
    if (newTheme === 'dark') {
      root.classList.add('dark');
    } else {
      root.classList.remove('dark');
    }
  };

  const setTheme = (newTheme: Theme) => {
    setThemeState(newTheme);
    localStorage.setItem('hoppa_merchant_theme', newTheme);
    applyTheme(newTheme);
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

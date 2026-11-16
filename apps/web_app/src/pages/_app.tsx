import type { AppProps } from 'next/app';
import '../styles/globals.css';
import { MerchantThemeProvider } from '../context/MerchantThemeContext';
import { ToastProvider } from '../components/merchant/ToastContext';

export default function MyApp({ Component, pageProps }: AppProps) {
  return (
    <MerchantThemeProvider>
      <ToastProvider>
        <Component {...pageProps} />
      </ToastProvider>
    </MerchantThemeProvider>
  );
}

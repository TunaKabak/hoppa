import type { AppProps } from 'next/app';
import '../styles/globals.css';
import { MerchantThemeProvider } from '../context/MerchantThemeContext';

export default function MyApp({ Component, pageProps }: AppProps) {
  return (
    <MerchantThemeProvider>
      <Component {...pageProps} />
    </MerchantThemeProvider>
  );
}

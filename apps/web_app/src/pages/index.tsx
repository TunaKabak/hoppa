import Head from 'next/head';
import App from '../app';

export default function Home() {
  return (
    <>
      <Head>
        <title>Hoppa - Kuzey Kıbrıs'ın Yerel Teslimat ve Market Uygulaması</title>
        <meta name="description" content="Hoppa ile KKTC'deki en sevdiğiniz restoranlardan yemek siparişi verin, market alışverişinizi dakikalar içinde kapınıza getirin." />
      </Head>
      <App initialTab="user" />
    </>
  );
}

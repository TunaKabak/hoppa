import Head from 'next/head';
import App from '../app';

export default function MerchantOnboardPage() {
  return (
    <>
      <Head>
        <title>İşletme İş Ortaklığı Başvurusu — Hoppa</title>
        <meta
          name="description"
          content="Restoran, market, kasap, manav veya su bayiniz için Hoppa iş ortağı başvurusu yapın ve KKTC genelinde dijital müşterilere ulaşın."
        />
      </Head>
      <App initialTab="user" autoScrollToPartners />
    </>
  );
}

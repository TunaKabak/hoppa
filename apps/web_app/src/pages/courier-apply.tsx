import Head from 'next/head';
import App from '../app';

export default function CourierApplyPage() {
  return (
    <>
      <Head>
        <title>Kurye Başvurusu — Hoppa</title>
        <meta
          name="description"
          content="Hoppa kurye ağına katılın; kendi aracınızla veya şirket aracıyla esnek saatlerde yüksek kazanç elde edin."
        />
      </Head>
      <App initialTab="partner" autoScrollToPartners />
    </>
  );
}

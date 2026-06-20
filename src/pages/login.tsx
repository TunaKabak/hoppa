import React, { useState } from 'react';
import Head from 'next/head';
import { AuthContainer } from '../components/auth/AuthContainer';
import { User } from '../types/auth.types';
import { LogOut, LayoutDashboard, Globe, MessageSquareCode } from 'lucide-react';

export default function LoginPage() {
  const [currentUser, setCurrentUser] = useState<User | null>(null);

  const handleLoginSuccess = (user: User) => {
    setCurrentUser(user);
  };

  const handleLogout = () => {
    setCurrentUser(null);
    // Refresh page state simulated
    if (typeof window !== 'undefined') {
      sessionStorage.removeItem('hoppa_active_session_email');
    }
  };

  return (
    <>
      <Head>
        <title>Hoppa İş Ortağı Girişi - Merchant Login Portal</title>
        <meta name="description" content="Hoppa iş ortağı portalı çoklu hesap seçici giriş ekranı. Güvenli, hızlı ve esnek." />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className="min-h-screen bg-slate-50 dark:bg-slate-950 flex flex-col items-center justify-center p-4 relative overflow-hidden transition-colors duration-300">
        
        {/* Radial Ambient Background Lights */}
        <div className="absolute top-[-10%] left-[-10%] w-[600px] h-[600px] rounded-full bg-emerald-500/10 dark:bg-emerald-500/5 blur-[120px] pointer-events-none" />
        <div className="absolute bottom-[-10%] right-[-10%] w-[600px] h-[600px] rounded-full bg-teal-500/10 dark:bg-teal-500/5 blur-[120px] pointer-events-none" />

        {/* Dynamic mesh-grid pattern backdrop */}
        <div className="absolute inset-0 bg-[linear-gradient(to_right,#8080800a_1px,transparent_1px),linear-gradient(to_bottom,#8080800a_1px,transparent_1px)] bg-[size:14px_24px] [mask-image:radial-gradient(ellipse_60%_50%_at_50%_0%,#000_70%,transparent_100%)] pointer-events-none" />

        {currentUser ? (
          /* Logged In Success Dashboard Screen Mockup */
          <div className="w-full max-w-[500px] bg-white/80 dark:bg-slate-900/80 backdrop-blur-md rounded-3xl border border-slate-100 dark:border-slate-800 shadow-2xl p-6 sm:p-8 space-y-6 animate-fade-in text-center">
            <div className="w-20 h-20 mx-auto rounded-3xl overflow-hidden shadow-md ring-4 ring-emerald-500/20 dark:ring-emerald-500/10">
              {currentUser.avatarUrl ? (
                <img
                  src={currentUser.avatarUrl}
                  alt={currentUser.merchantName}
                  className="w-full h-full object-cover"
                />
              ) : (
                <div className="w-full h-full bg-gradient-to-tr from-emerald-400 to-teal-500 flex items-center justify-center text-white font-extrabold text-2xl">
                  {currentUser.merchantName.substring(0, 2).toUpperCase()}
                </div>
              )}
            </div>

            <div className="space-y-1">
              <h2 className="text-2xl font-bold text-slate-800 dark:text-white">
                Hoş Geldiniz, {currentUser.merchantName}!
              </h2>
              <p className="text-sm text-slate-500 dark:text-slate-400 font-medium">
                {currentUser.email}
              </p>
              <div className="inline-flex items-center space-x-1.5 px-3 py-1 bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-100 dark:border-emerald-900/30 rounded-full text-xs font-bold text-emerald-600 dark:text-emerald-400 mt-2 capitalize shadow-sm">
                <span>{currentUser.role === 'super_admin' ? 'Sistem Yöneticisi' : 'Mağaza Sahibi'}</span>
              </div>
            </div>

            <div className="h-px bg-slate-100 dark:bg-slate-800/80 my-4" />

            <div className="grid grid-cols-2 gap-3">
              <button
                type="button"
                onClick={() => alert('Panel yükleniyor...')}
                className="flex items-center justify-center space-x-2 py-3 px-4 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-2xl transition-all duration-200 shadow-lg shadow-emerald-500/10 hover:shadow-emerald-500/25 active:translate-y-0.5 text-sm"
              >
                <LayoutDashboard className="w-4 h-4" />
                <span>Panele Git</span>
              </button>

              <button
                type="button"
                onClick={handleLogout}
                className="flex items-center justify-center space-x-2 py-3 px-4 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 font-bold rounded-2xl transition-all duration-200 active:translate-y-0.5 text-sm"
              >
                <LogOut className="w-4 h-4" />
                <span>Çıkış Yap</span>
              </button>
            </div>
          </div>
        ) : (
          /* Render Active Auth Container */
          <div className="w-full">
            <AuthContainer onLoginSuccess={handleLoginSuccess} />
          </div>
        )}

        {/* Global Footer */}
        <footer className="mt-8 text-center space-y-2 select-none pointer-events-none">
          <div className="flex justify-center items-center space-x-4 text-xs font-semibold text-slate-400 dark:text-slate-600">
            <span className="flex items-center space-x-1">
              <Globe className="w-3.5 h-3.5" />
              <span>Hoppa Global TR</span>
            </span>
            <span>•</span>
            <span className="flex items-center space-x-1">
              <MessageSquareCode className="w-3.5 h-3.5" />
              <span>Destek Portalı</span>
            </span>
          </div>
          <p className="text-[10px] text-slate-400 dark:text-slate-600 font-medium">
            © {new Date().getFullYear()} Hoppa Inc. Tüm Hakları Saklıdır.
          </p>
        </footer>
      </main>
    </>
  );
}

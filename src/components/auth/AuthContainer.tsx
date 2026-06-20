import React, { useState, useEffect } from 'react';
import { SavedProfile, LoginCredentials, User, AuthView } from '../../types/auth.types';
import { StorageUtils } from '../../utils/storage.utils';
import { AuthService } from '../../services/auth.service';
import { AccountChooser } from './AccountChooser';
import { LoginForm } from './LoginForm';
import { ShieldCheck, AlertCircle, Sparkles } from 'lucide-react';

interface AuthContainerProps {
  onLoginSuccess: (user: User) => void;
}

export const AuthContainer: React.FC<AuthContainerProps> = ({ onLoginSuccess }) => {
  const [activeView, setActiveView] = useState<AuthView>('login');
  const [profiles, setProfiles] = useState<SavedProfile[]>([]);
  const [selectedProfile, setSelectedProfile] = useState<SavedProfile | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [fastLoginMessage, setFastLoginMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successUser, setSuccessUser] = useState<User | null>(null);

  // Load profiles on mount and decide the initial view
  useEffect(() => {
    const saved = StorageUtils.getSavedProfiles();
    setProfiles(saved);
    if (saved.length > 0) {
      setActiveView('chooser');
    } else {
      setActiveView('login');
    }
  }, []);

  /**
   * Triggers when user selects a profile from the Account Chooser.
   * Checks if an active session exists (simulating backend HttpOnly cookies).
   */
  const handleSelectProfile = async (profile: SavedProfile) => {
    setSelectedProfile(profile);
    setIsLoading(true);
    setErrorMessage(null);
    setFastLoginMessage('Aktif oturum kontrol ediliyor...');

    try {
      // Check session simulation
      const res = await AuthService.checkSession(profile.email);

      if (res.success && res.user) {
        setFastLoginMessage('Aktif oturum bulundu! Hızlı giriş yapılıyor...');
        await AuthService.delay(800); // UI breathing room
        
        // Refresh profiles state
        const refreshed = StorageUtils.getSavedProfiles();
        setProfiles(refreshed);

        setSuccessUser(res.user);
        setTimeout(() => {
          onLoginSuccess(res.user!);
        }, 1500);
      } else {
        // No active session, prompt for password
        setFastLoginMessage(null);
        setActiveView('password_only');
      }
    } catch (err) {
      console.error('[AuthContainer.handleSelectProfile] Session check failed:', err);
      setFastLoginMessage(null);
      setActiveView('password_only');
    } finally {
      setIsLoading(false);
    }
  };

  /**
   * Handles credential submission (both standard and password-only)
   */
  const handleLoginSubmit = async (credentials: LoginCredentials) => {
    setIsLoading(true);
    setErrorMessage(null);

    try {
      const res = await AuthService.login(credentials);

      if (res.success && res.user) {
        // Refresh profiles lists
        const saved = StorageUtils.getSavedProfiles();
        setProfiles(saved);

        setSuccessUser(res.user);
        setTimeout(() => {
          onLoginSuccess(res.user!);
        }, 1500);
      } else {
        setErrorMessage(res.message || 'Giriş işlemi başarısız.');
      }
    } catch (err) {
      setErrorMessage('Beklenmeyen bir sunucu hatası oluştu. Lütfen tekrar deneyiniz.');
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  };

  /**
   * Removes saved profile from the client device.
   */
  const handleRemoveProfile = (id: string, e: React.MouseEvent) => {
    e.stopPropagation(); // Prevent card select click
    
    // UI confirmation optional, but let's implement safe removal
    StorageUtils.removeProfile(id);
    const updated = StorageUtils.getSavedProfiles();
    setProfiles(updated);

    // If no profiles left, switch directly to standard login
    if (updated.length === 0) {
      setSelectedProfile(null);
      setActiveView('login');
    } else if (selectedProfile?.id === id) {
      setSelectedProfile(null);
      setActiveView('chooser');
    }
  };

  const handleCancelForm = () => {
    setErrorMessage(null);
    setSelectedProfile(null);
    if (profiles.length > 0) {
      setActiveView('chooser');
    } else {
      setActiveView('login');
    }
  };

  return (
    <div className="relative w-full max-w-[460px] mx-auto transition-all duration-300">
      {/* Dynamic Success overlay */}
      {successUser && (
        <div className="absolute inset-0 bg-white/95 dark:bg-slate-900/95 backdrop-blur-md rounded-3xl z-50 flex flex-col items-center justify-center p-8 text-center space-y-4 animate-fade-in">
          <div className="w-16 h-16 bg-emerald-50 dark:bg-emerald-950/40 rounded-2xl flex items-center justify-center text-emerald-500 shadow-inner border border-emerald-100 dark:border-emerald-900/30 animate-bounce">
            <ShieldCheck className="w-9 h-9" />
          </div>
          <div className="space-y-1">
            <h3 className="text-xl font-bold text-slate-800 dark:text-white">
              Giriş Başarılı!
            </h3>
            <p className="text-sm text-slate-500 dark:text-slate-400">
              {successUser.merchantName} paneline yönlendiriliyorsunuz...
            </p>
          </div>
          {/* Custom smooth progress slider */}
          <div className="w-32 h-1.5 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
            <div className="h-full bg-gradient-to-r from-emerald-500 to-teal-500 rounded-full animate-progress" />
          </div>
        </div>
      )}

      {/* Fast login status overlay */}
      {fastLoginMessage && (
        <div className="absolute inset-0 bg-white/80 dark:bg-slate-900/80 backdrop-blur-sm rounded-3xl z-40 flex flex-col items-center justify-center p-8 text-center space-y-4">
          <div className="w-10 h-10 border-3 border-emerald-500/20 border-t-emerald-500 rounded-full animate-spin" />
          <p className="text-sm font-semibold text-slate-700 dark:text-slate-300 animate-pulse">
            {fastLoginMessage}
          </p>
        </div>
      )}

      {/* Glassmorphism card container */}
      <div className="bg-white/70 dark:bg-slate-900/70 backdrop-blur-xl rounded-3xl border border-white/40 dark:border-slate-800/40 shadow-2xl p-6 sm:p-8 space-y-6">
        
        {/* Safe Badge Header */}
        <div className="flex justify-between items-center border-b border-slate-100 dark:border-slate-800/80 pb-4">
          <div className="flex items-center space-x-2">
            <div className="w-8 h-8 rounded-lg bg-emerald-600 flex items-center justify-center text-white font-black text-sm shadow-md">
              H
            </div>
            <span className="text-sm font-bold text-slate-800 dark:text-white tracking-wider">
              HOPPA<span className="text-emerald-600 font-extrabold text-xs ml-1 bg-emerald-50 dark:bg-emerald-950/60 px-1.5 py-0.5 rounded">MERCHANT</span>
            </span>
          </div>

          <div className="flex items-center space-x-1 bg-emerald-50 dark:bg-emerald-950/30 border border-emerald-100/50 dark:border-emerald-900/20 px-2.5 py-1 rounded-full text-[10px] text-emerald-700 dark:text-emerald-400 font-semibold shadow-sm">
            <Sparkles className="w-3 h-3 text-emerald-500 animate-pulse mr-0.5" />
            <span>Güvenli Oturum</span>
          </div>
        </div>

        {/* Global error dialog */}
        {errorMessage && (
          <div className="flex items-start space-x-2.5 p-3.5 bg-red-50 dark:bg-red-950/20 border border-red-100 dark:border-red-900/30 rounded-2xl text-xs text-red-600 dark:text-red-400 animate-shake">
            <AlertCircle className="w-4 h-4 flex-shrink-0 mt-0.5" />
            <div className="font-medium">{errorMessage}</div>
          </div>
        )}

        {/* View Switcher logic */}
        {activeView === 'chooser' && (
          <AccountChooser
            profiles={profiles}
            onSelectProfile={handleSelectProfile}
            onRemoveProfile={handleRemoveProfile}
            onAddAccount={() => {
              setErrorMessage(null);
              setActiveView('login');
            }}
          />
        )}

        {(activeView === 'login' || activeView === 'password_only') && (
          <LoginForm
            selectedEmail={selectedProfile?.email}
            selectedMerchantName={selectedProfile?.merchantName}
            selectedAvatarUrl={selectedProfile?.avatarUrl}
            isLoading={isLoading}
            onCancel={handleCancelForm}
            onSubmit={handleLoginSubmit}
            showBackButton={profiles.length > 0}
          />
        )}
      </div>

      {/* Embedded CSS for custom keyframe animations */}
      <style>{`
        @keyframes fadeIn {
          from { opacity: 0; transform: scale(0.96); }
          to { opacity: 1; transform: scale(1); }
        }
        @keyframes progress {
          0% { width: 0%; }
          100% { width: 100%; }
        }
        @keyframes shake {
          0%, 100% { transform: translateX(0); }
          25% { transform: translateX(-4px); }
          75% { transform: translateX(4px); }
        }
        .animate-fade-in {
          animation: fadeIn 0.3s cubic-bezier(0.16, 1, 0.3, 1) forwards;
        }
        .animate-progress {
          animation: progress 1.5s cubic-bezier(0.22, 1, 0.36, 1) forwards;
        }
        .animate-shake {
          animation: shake 0.25s ease-in-out;
        }
      `}</style>
    </div>
  );
};

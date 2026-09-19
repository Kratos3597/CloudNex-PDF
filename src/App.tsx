import React, { useState, useEffect } from 'react';
import { 
  Home, 
  Folder, 
  Activity, 
  User, 
  Moon, 
  Sun, 
  FileText
} from 'lucide-react';
import { TabType, DocumentRecord } from './types';
import { StorageService } from './services/storage';
import { StatusCapsule } from './components/StatusCapsule';
import { DashboardScreen } from './components/DashboardScreen';
import { LibraryScreen } from './components/LibraryScreen';
import { AnalyticsScreen } from './components/AnalyticsScreen';
import { SignatureVaultScreen } from './components/SignatureVaultScreen';
import { EditorScreen } from './components/EditorScreen';
import { useDeviceLayout } from './hooks/useDeviceLayout';

export const App: React.FC = () => {
  const layout = useDeviceLayout();
  const [activeTab, setActiveTab] = useState<TabType>('home');
  const [documents, setDocuments] = useState<DocumentRecord[]>([]);
  const [activeDocument, setActiveDocument] = useState<DocumentRecord | null>(null);
  const [isDarkMode, setIsDarkMode] = useState(false);
  const [syncStatus, setSyncStatus] = useState<'SYNCED' | 'SYNCING_CLOUDNEX...'>('SYNCED');
  const [isSyncLoading, setIsSyncLoading] = useState(false);

  // Initialize documents & storage
  const loadDocuments = async () => {
    const docs = await StorageService.initializeDefaults();
    setDocuments(docs);
  };

  useEffect(() => {
    loadDocuments();

    // Simulated background cloud synchronization every 3 minutes or on load
    const triggerSync = () => {
      setIsSyncLoading(true);
      setSyncStatus('SYNCING_CLOUDNEX...');
      setTimeout(() => {
        setIsSyncLoading(false);
        setSyncStatus('SYNCED');
      }, 2000);
    };

    triggerSync();
    const interval = setInterval(triggerSync, 180000);
    return () => clearInterval(interval);
  }, []);

  const handleOpenDocument = (doc: DocumentRecord) => {
    setActiveDocument(doc);
    StorageService.logAction('OPEN_DOCUMENT', doc.fileName);
  };

  const handleBackToDashboard = () => {
    setActiveDocument(null);
    loadDocuments();
  };

  // If a document is active, display the full EditorScreen
  if (activeDocument) {
    return (
      <div className={isDarkMode ? 'dark bg-slate-950 text-slate-100' : 'bg-slate-50 text-slate-900'}>
        <StatusCapsule status={syncStatus} isLoading={isSyncLoading} />
        <EditorScreen
          document={activeDocument}
          layout={layout}
          onBack={handleBackToDashboard}
          onRefreshDocs={loadDocuments}
          onOpenVault={() => {
            setActiveDocument(null);
            setActiveTab('profile');
          }}
        />
      </div>
    );
  }

  return (
    <div className={`min-h-screen flex flex-col font-sans ${isDarkMode ? 'dark bg-slate-950 text-slate-100' : 'bg-slate-50/70 text-slate-900'}`}>
      {/* Top Dynamic Status Capsule */}
      <StatusCapsule status={syncStatus} isLoading={isSyncLoading} />

      {/* Main Modern Studio Header */}
      <header className={`h-16 border-b px-4 sm:px-6 flex items-center justify-between sticky top-0 z-30 backdrop-blur-md transition-colors ${
        isDarkMode 
          ? 'bg-slate-900/85 border-slate-800 shadow-sm' 
          : 'bg-white/85 border-slate-200/80 shadow-xs'
      }`}>
        {/* Brand & Logo */}
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-blue-600 to-indigo-700 flex items-center justify-center text-white shadow-md shadow-blue-600/20 shrink-0">
            <FileText className="w-5 h-5" />
          </div>
          <div className="min-w-0">
            <div className="flex items-center gap-2">
              <span className="font-extrabold text-base tracking-tight text-slate-900 dark:text-white">
                CloudNex
              </span>
              <span className="bg-gradient-to-r from-blue-600 to-indigo-600 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-md tracking-wider uppercase shadow-2xs">
                PRO
              </span>
              <span className="hidden sm:inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 text-[11px] font-medium border border-slate-200/60 dark:border-slate-700">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                {documents.length} Docs
              </span>
            </div>
            <p className="text-[11px] text-slate-500 dark:text-slate-400 font-normal truncate hidden sm:block">
              Professional PDF Studio
            </p>
          </div>
        </div>

        {/* Navigation Tabs (Desktop) */}
        <nav aria-label="Main navigation" className="hidden lg:flex items-center gap-1 bg-slate-100/90 dark:bg-slate-850 p-1 rounded-xl border border-slate-200/60 dark:border-slate-800">
          <button
            id="nav-tab-home"
            onClick={() => setActiveTab('home')}
            className={`px-4 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-all cursor-pointer ${
              activeTab === 'home'
                ? 'bg-white dark:bg-slate-800 text-blue-600 dark:text-blue-400 shadow-2xs border border-slate-200/50 dark:border-slate-700'
                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            <Home className="w-3.5 h-3.5" />
            <span>Studio</span>
          </button>

          <button
            id="nav-tab-files"
            onClick={() => setActiveTab('files')}
            className={`px-4 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-all cursor-pointer ${
              activeTab === 'files'
                ? 'bg-white dark:bg-slate-800 text-blue-600 dark:text-blue-400 shadow-2xs border border-slate-200/50 dark:border-slate-700'
                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            <Folder className="w-3.5 h-3.5" />
            <span>Library</span>
          </button>

          <button
            id="nav-tab-activity"
            onClick={() => setActiveTab('activity')}
            className={`px-4 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-all cursor-pointer ${
              activeTab === 'activity'
                ? 'bg-white dark:bg-slate-800 text-blue-600 dark:text-blue-400 shadow-2xs border border-slate-200/50 dark:border-slate-700'
                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            <Activity className="w-3.5 h-3.5" />
            <span>Activity</span>
          </button>

          <button
            id="nav-tab-profile"
            onClick={() => setActiveTab('profile')}
            className={`px-4 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-all cursor-pointer ${
              activeTab === 'profile'
                ? 'bg-white dark:bg-slate-800 text-blue-600 dark:text-blue-400 shadow-2xs border border-slate-200/50 dark:border-slate-700'
                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white'
            }`}
          >
            <User className="w-3.5 h-3.5" />
            <span>Vault</span>
          </button>
        </nav>

        {/* Right Actions: Dark Mode Toggle */}
        <div className="flex items-center gap-2">
          <button
            onClick={() => setIsDarkMode(d => !d)}
            className="p-2 rounded-xl border border-slate-200 dark:border-slate-800 hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-300 transition-colors cursor-pointer"
            title={isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode'}
          >
            {isDarkMode ? <Sun className="w-4 h-4 text-amber-400" /> : <Moon className="w-4 h-4 text-slate-700" />}
          </button>
        </div>
      </header>

      {/* Main Tab View */}
      <main className="flex-1 pb-20 md:pb-8">
        {activeTab === 'home' && (
          <DashboardScreen
            documents={documents}
            onOpenDocument={handleOpenDocument}
            onRefreshDocs={loadDocuments}
            onNavigateTab={setActiveTab}
          />
        )}

        {activeTab === 'files' && (
          <LibraryScreen
            documents={documents}
            onOpenDocument={handleOpenDocument}
            onRefreshDocs={loadDocuments}
          />
        )}

        {activeTab === 'activity' && (
          <AnalyticsScreen />
        )}

        {activeTab === 'profile' && (
          <SignatureVaultScreen />
        )}
      </main>

      {/* Mobile Bottom Navigation Bar */}
      <nav aria-label="Mobile navigation" className="md:hidden fixed bottom-0 left-0 right-0 h-16 bg-white/95 dark:bg-slate-900/95 backdrop-blur-md border-t border-slate-200/80 dark:border-slate-800 flex items-center justify-around z-30 shadow-lg">
        <button
          id="mobile-tab-home"
          onClick={() => setActiveTab('home')}
          className={`flex flex-col items-center gap-1 min-h-[44px] justify-center px-3 cursor-pointer transition-colors ${
            activeTab === 'home' ? 'text-blue-600 dark:text-blue-400 font-bold' : 'text-slate-500 hover:text-slate-800 dark:text-slate-400'
          }`}
        >
          <Home className="w-4 h-4" />
          <span className="text-[10px]">Studio</span>
        </button>

        <button
          id="mobile-tab-files"
          onClick={() => setActiveTab('files')}
          className={`flex flex-col items-center gap-1 min-h-[44px] justify-center px-3 cursor-pointer transition-colors ${
            activeTab === 'files' ? 'text-blue-600 dark:text-blue-400 font-bold' : 'text-slate-500 hover:text-slate-800 dark:text-slate-400'
          }`}
        >
          <Folder className="w-4 h-4" />
          <span className="text-[10px]">Library</span>
        </button>

        <button
          id="mobile-tab-activity"
          onClick={() => setActiveTab('activity')}
          className={`flex flex-col items-center gap-1 min-h-[44px] justify-center px-3 cursor-pointer transition-colors ${
            activeTab === 'activity' ? 'text-blue-600 dark:text-blue-400 font-bold' : 'text-slate-500 hover:text-slate-800 dark:text-slate-400'
          }`}
        >
          <Activity className="w-4 h-4" />
          <span className="text-[10px]">Activity</span>
        </button>

        <button
          id="mobile-tab-profile"
          onClick={() => setActiveTab('profile')}
          className={`flex flex-col items-center gap-1 min-h-[44px] justify-center px-3 cursor-pointer transition-colors ${
            activeTab === 'profile' ? 'text-blue-600 dark:text-blue-400 font-bold' : 'text-slate-500 hover:text-slate-800 dark:text-slate-400'
          }`}
        >
          <User className="w-4 h-4" />
          <span className="text-[10px]">Vault</span>
        </button>
      </nav>
    </div>
  );
};

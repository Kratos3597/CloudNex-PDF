import React, { useState, useEffect } from 'react';
import { 
  Home, 
  Folder, 
  Activity, 
  User, 
  Moon, 
  Sun, 
  FileText,
  Smartphone
} from 'lucide-react';
import { TabType, DocumentRecord } from './types';
import { StorageService } from './services/storage';
import { StatusCapsule } from './components/StatusCapsule';
import { DashboardScreen } from './components/DashboardScreen';
import { LibraryScreen } from './components/LibraryScreen';
import { AnalyticsScreen } from './components/AnalyticsScreen';
import { SignatureVaultScreen } from './components/SignatureVaultScreen';
import { EditorScreen } from './components/EditorScreen';
import { SyncfusionAndroidModal } from './components/SyncfusionAndroidModal';
import { useDeviceLayout } from './hooks/useDeviceLayout';
import { DeviceScaleControl } from './components/DeviceScaleControl';

export const App: React.FC = () => {
  const layout = useDeviceLayout();
  const [activeTab, setActiveTab] = useState<TabType>('home');
  const [documents, setDocuments] = useState<DocumentRecord[]>([]);
  const [activeDocument, setActiveDocument] = useState<DocumentRecord | null>(null);
  const [isDarkMode, setIsDarkMode] = useState(false);
  const [syncStatus, setSyncStatus] = useState<'SYNCED' | 'SYNCING_CLOUDNEX...'>('SYNCED');
  const [isSyncLoading, setIsSyncLoading] = useState(false);
  const [isSyncfusionModalOpen, setIsSyncfusionModalOpen] = useState(false);

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
      <div className={isDarkMode ? 'dark bg-zinc-950 text-zinc-100' : 'bg-[#F4F5F7] text-[#172B4D]'}>
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
    <div className={`min-h-screen flex flex-col ${isDarkMode ? 'dark bg-zinc-950 text-zinc-100' : 'bg-[#F4F5F7] text-[#172B4D]'}`}>
      {/* Top Punch-hole / Dynamic Status Capsule */}
      <StatusCapsule status={syncStatus} isLoading={isSyncLoading} />

      {/* Main Corporate Header */}
      <header className={`h-16 border-b px-4 sm:px-6 flex items-center justify-between sticky top-0 z-30 shadow-xs backdrop-blur-md ${
        isDarkMode ? 'bg-zinc-900/90 border-zinc-800' : 'bg-white/90 border-gray-200'
      }`}>
        {/* Brand & Logo */}
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-[#0052CC] flex items-center justify-center text-white shadow-md shadow-[#0052CC]/25 shrink-0">
            <FileText className="w-5 h-5" />
          </div>
          <div className="min-w-0">
            <div className="flex items-center gap-1.5">
              <span className="font-extrabold text-base tracking-tight text-[#172B4D] dark:text-white">
                CloudNex
              </span>
              <span className="bg-[#0052CC] text-white text-[10px] font-extrabold px-1.5 py-0.5 rounded">
                PRO
              </span>
            </div>
            <p className="text-[10px] text-[#6B778C] dark:text-zinc-400 -mt-0.5 font-medium truncate hidden sm:block">
              Enterprise Document Management & Signatures
            </p>
          </div>
        </div>

        {/* Navigation Tabs (Desktop) */}
        <nav aria-label="Main navigation" className="hidden lg:flex items-center gap-1 bg-gray-100 dark:bg-zinc-800 p-1 rounded-xl">
          <button
            id="nav-tab-home"
            onClick={() => setActiveTab('home')}
            className={`px-4 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1.5 transition-all cursor-pointer ${
              activeTab === 'home'
                ? 'bg-white dark:bg-zinc-700 text-[#0052CC] dark:text-white shadow-xs'
                : 'text-gray-600 dark:text-zinc-400 hover:text-gray-900'
            }`}
          >
            <Home className="w-3.5 h-3.5" />
            <span>Home</span>
          </button>

          <button
            id="nav-tab-files"
            onClick={() => setActiveTab('files')}
            className={`px-4 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1.5 transition-all cursor-pointer ${
              activeTab === 'files'
                ? 'bg-white dark:bg-zinc-700 text-[#0052CC] dark:text-white shadow-xs'
                : 'text-gray-600 dark:text-zinc-400 hover:text-gray-900'
            }`}
          >
            <Folder className="w-3.5 h-3.5" />
            <span>Files</span>
          </button>

          <button
            id="nav-tab-activity"
            onClick={() => setActiveTab('activity')}
            className={`px-4 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1.5 transition-all cursor-pointer ${
              activeTab === 'activity'
                ? 'bg-white dark:bg-zinc-700 text-[#0052CC] dark:text-white shadow-xs'
                : 'text-gray-600 dark:text-zinc-400 hover:text-gray-900'
            }`}
          >
            <Activity className="w-3.5 h-3.5" />
            <span>Activity</span>
          </button>

          <button
            id="nav-tab-profile"
            onClick={() => setActiveTab('profile')}
            className={`px-4 py-1.5 rounded-lg text-xs font-bold flex items-center gap-1.5 transition-all cursor-pointer ${
              activeTab === 'profile'
                ? 'bg-white dark:bg-zinc-700 text-[#0052CC] dark:text-white shadow-xs'
                : 'text-gray-600 dark:text-zinc-400 hover:text-gray-900'
            }`}
          >
            <User className="w-3.5 h-3.5" />
            <span>Signature Vault</span>
          </button>
        </nav>

        {/* Right Actions: Device Scale Controller, Syncfusion & Dark Mode */}
        <div className="flex items-center gap-2">
          {/* Device Orientation & Scaling Controller */}
          <DeviceScaleControl layout={layout} />

          <button
            onClick={() => setIsSyncfusionModalOpen(true)}
            className="px-2.5 py-1.5 rounded-xl border border-blue-200 dark:border-blue-900/40 bg-blue-50/80 dark:bg-blue-950/40 text-[#0052CC] dark:text-blue-400 text-xs font-bold flex items-center gap-1.5 hover:bg-blue-100 dark:hover:bg-blue-900/60 transition-colors cursor-pointer"
            title="Configure Syncfusion License, Stress Test PDFs & Android Studio Suite"
          >
            <Smartphone className="w-3.5 h-3.5" />
            <span className="hidden xl:inline">Syncfusion & Android</span>
          </button>

          <button
            onClick={() => setIsDarkMode(d => !d)}
            className="p-2 rounded-xl border border-gray-200 dark:border-zinc-700 hover:bg-gray-100 dark:hover:bg-zinc-800 text-gray-600 dark:text-zinc-300 transition-colors cursor-pointer"
            title={isDarkMode ? 'Switch to Light Mode' : 'Switch to Dark Mode'}
          >
            {isDarkMode ? <Sun className="w-4 h-4" /> : <Moon className="w-4 h-4" />}
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
            onOpenSyncfusion={() => setIsSyncfusionModalOpen(true)}
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
      <nav aria-label="Mobile navigation" className="md:hidden fixed bottom-0 left-0 right-0 h-16 bg-white dark:bg-zinc-900 border-t border-gray-200 dark:border-zinc-800 flex items-center justify-around z-30 shadow-lg">
        <button
          id="mobile-tab-home"
          onClick={() => setActiveTab('home')}
          className={`flex flex-col items-center gap-1 cursor-pointer ${
            activeTab === 'home' ? 'text-[#0052CC]' : 'text-gray-500'
          }`}
        >
          <Home className="w-4 h-4" />
          <span className="text-[10px] font-bold">Home</span>
        </button>

        <button
          id="mobile-tab-files"
          onClick={() => setActiveTab('files')}
          className={`flex flex-col items-center gap-1 cursor-pointer ${
            activeTab === 'files' ? 'text-[#0052CC]' : 'text-gray-500'
          }`}
        >
          <Folder className="w-4 h-4" />
          <span className="text-[10px] font-bold">Files</span>
        </button>

        <button
          id="mobile-tab-activity"
          onClick={() => setActiveTab('activity')}
          className={`flex flex-col items-center gap-1 cursor-pointer ${
            activeTab === 'activity' ? 'text-[#0052CC]' : 'text-gray-500'
          }`}
        >
          <Activity className="w-4 h-4" />
          <span className="text-[10px] font-bold">Activity</span>
        </button>

        <button
          id="mobile-tab-profile"
          onClick={() => setActiveTab('profile')}
          className={`flex flex-col items-center gap-1 cursor-pointer ${
            activeTab === 'profile' ? 'text-[#0052CC]' : 'text-gray-500'
          }`}
        >
          <User className="w-4 h-4" />
          <span className="text-[10px] font-bold">Vault</span>
        </button>
      </nav>

      {/* Syncfusion & Android Suite Modal */}
      <SyncfusionAndroidModal
        isOpen={isSyncfusionModalOpen}
        onClose={() => setIsSyncfusionModalOpen(false)}
        onDocumentCreated={(newDoc) => {
          loadDocuments();
          handleOpenDocument(newDoc);
        }}
      />
    </div>
  );
};

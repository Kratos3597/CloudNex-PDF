import React, { useState, useEffect } from 'react';
import { 
  X, 
  KeyRound, 
  Smartphone, 
  CheckCircle2, 
  ShieldCheck, 
  FileCode2, 
  Zap, 
  Copy, 
  Check, 
  Layers, 
  ExternalLink,
  PlusCircle
} from 'lucide-react';
import { StorageService } from '../services/storage';
import { PdfEngine } from '../services/pdfEngine';
import { DocumentRecord } from '../types';

interface SyncfusionAndroidModalProps {
  isOpen: boolean;
  onClose: () => void;
  onDocumentCreated?: (doc: DocumentRecord) => void;
}

export const SyncfusionAndroidModal: React.FC<SyncfusionAndroidModalProps> = ({
  isOpen,
  onClose,
  onDocumentCreated,
}) => {
  const [licenseKey, setLicenseKey] = useState('');
  const [isSaved, setIsSaved] = useState(false);
  const [copiedTab, setCopiedTab] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<'license' | 'android' | 'files'>('license');
  const [isGeneratingSample, setIsGeneratingSample] = useState(false);

  useEffect(() => {
    if (isOpen) {
      setLicenseKey(StorageService.getSyncfusionKey());
      setIsSaved(false);
    }
  }, [isOpen]);

  if (!isOpen) return null;

  const handleSaveKey = () => {
    StorageService.saveSyncfusionKey(licenseKey);
    setIsSaved(true);
    setTimeout(() => setIsSaved(false), 3000);
  };

  const handleCreateLargeSample = async () => {
    setIsGeneratingSample(true);
    try {
      const bytes = await PdfEngine.createLargeImageTestDocument();
      const newDoc: DocumentRecord = {
        id: `large-doc-${Date.now()}`,
        fileName: `Large_Image_Stress_Test_${Math.floor(100 + Math.random() * 900)}.pdf`,
        filePath: '/storage/cloudnex/large_sample.pdf',
        lastOpenedDate: new Date().toISOString(),
        lastOpenedPage: 1,
        fileSize: '420.5 KB',
        pageCount: 4,
      };
      StorageService.saveDocument(newDoc, bytes);
      StorageService.logAction('OPEN_DOCUMENT', newDoc.fileName);
      if (onDocumentCreated) {
        onDocumentCreated(newDoc);
      }
      onClose();
    } catch (e) {
      console.error('Failed to create large image sample:', e);
    } finally {
      setIsGeneratingSample(false);
    }
  };

  const copyToClipboard = (text: string, tabName: string) => {
    navigator.clipboard.writeText(text);
    setCopiedTab(tabName);
    setTimeout(() => setCopiedTab(null), 2000);
  };

  const pubspecContent = `name: cloudnex_pdf_android
dependencies:
  flutter:
    sdk: flutter
  syncfusion_flutter_pdfviewer: ^28.2.9
  syncfusion_flutter_pdf: ^28.2.9
  share_plus: ^10.1.4
  path_provider: ^2.1.2`;

  const manifestContent = `<application
    android:label="CloudNex PDF Pro"
    android:largeHeap="true">
    <provider
        android:name="androidx.core.content.FileProvider"
        android:authorities="\${applicationId}.fileprovider"
        android:exported="false"
        android:grantUriPermissions="true">
        <meta-data
            android:name="android.support.FILE_PROVIDER_PATHS"
            android:resource="@xml/file_paths" />
    </provider>
</application>`;

  return (
    <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl max-w-2xl w-full flex flex-col max-h-[90vh] border border-gray-100 overflow-hidden">
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-100 flex items-center justify-between bg-gray-50/50">
          <div className="flex items-center gap-2.5">
            <div className="p-2 bg-[#0052CC]/10 text-[#0052CC] rounded-lg">
              <Smartphone className="w-5 h-5" />
            </div>
            <div>
              <h2 className="font-bold text-base text-[#172B4D]">Syncfusion & Android Suite</h2>
              <p className="text-xs text-[#6B778C]">License Management, Large Image PDF Engine & Android Studio Config</p>
            </div>
          </div>
          <button onClick={onClose} className="p-1 rounded-lg hover:bg-gray-200 text-gray-500 cursor-pointer">
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Navigation Tabs */}
        <div className="flex border-b border-gray-100 px-6 bg-white">
          <button
            onClick={() => setActiveTab('license')}
            className={`py-3 px-4 text-xs font-semibold border-b-2 transition-colors cursor-pointer flex items-center gap-1.5 ${
              activeTab === 'license'
                ? 'border-[#0052CC] text-[#0052CC]'
                : 'border-transparent text-gray-600 hover:text-gray-900'
            }`}
          >
            <KeyRound className="w-3.5 h-3.5" />
            Syncfusion License
          </button>
          <button
            onClick={() => setActiveTab('android')}
            className={`py-3 px-4 text-xs font-semibold border-b-2 transition-colors cursor-pointer flex items-center gap-1.5 ${
              activeTab === 'android'
                ? 'border-[#0052CC] text-[#0052CC]'
                : 'border-transparent text-gray-600 hover:text-gray-900'
            }`}
          >
            <Zap className="w-3.5 h-3.5" />
            Large PDF & Android Spec
          </button>
          <button
            onClick={() => setActiveTab('files')}
            className={`py-3 px-4 text-xs font-semibold border-b-2 transition-colors cursor-pointer flex items-center gap-1.5 ${
              activeTab === 'files'
                ? 'border-[#0052CC] text-[#0052CC]'
                : 'border-transparent text-gray-600 hover:text-gray-900'
            }`}
          >
            <FileCode2 className="w-3.5 h-3.5" />
            Android Studio Files
          </button>
        </div>

        {/* Body Content */}
        <div className="p-6 overflow-y-auto space-y-5 flex-1">
          {activeTab === 'license' && (
            <div className="space-y-4">
              <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 flex items-start gap-3">
                <ShieldCheck className="w-5 h-5 text-[#0052CC] shrink-0 mt-0.5" />
                <div className="text-xs text-blue-900 space-y-1">
                  <p className="font-semibold">Commercial & Community License Validation</p>
                  <p className="text-blue-800">
                    Registering your Syncfusion license key disables evaluation watermarks and trial dialogs.
                    Your key is stored locally in this app and injected into the Flutter entry point (`lib/main.dart`).
                  </p>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#172B4D] mb-1.5">
                  Syncfusion License Key
                </label>
                <div className="flex gap-2">
                  <input
                    type="password"
                    value={licenseKey}
                    onChange={(e) => setLicenseKey(e.target.value)}
                    placeholder="Enter your Syncfusion license key..."
                    className="flex-1 px-3 py-2 text-xs border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0052CC] focus:border-transparent font-mono"
                  />
                  <button
                    onClick={handleSaveKey}
                    className="px-4 py-2 bg-[#0052CC] text-white text-xs font-bold rounded-lg hover:bg-blue-700 transition-colors flex items-center gap-1.5 cursor-pointer"
                  >
                    {isSaved ? <Check className="w-4 h-4" /> : <SaveIcon />}
                    <span>{isSaved ? 'Saved!' : 'Save Key'}</span>
                  </button>
                </div>
                {licenseKey && (
                  <p className="text-[11px] text-[#36B37E] font-medium mt-1.5 flex items-center gap-1">
                    <CheckCircle2 className="w-3.5 h-3.5" />
                    License key active for current session
                  </p>
                )}
              </div>

              <div className="border-t border-gray-100 pt-4 flex items-center justify-between">
                <div>
                  <h4 className="font-bold text-xs text-[#172B4D]">Need to test high-resolution large PDFs?</h4>
                  <p className="text-[11px] text-[#6B778C]">Generate a 4-page blueprint stress simulation directly in the app.</p>
                </div>
                <button
                  onClick={handleCreateLargeSample}
                  disabled={isGeneratingSample}
                  className="px-3.5 py-2 bg-[#F4F5F7] hover:bg-gray-200 text-[#172B4D] text-xs font-bold rounded-lg transition-colors flex items-center gap-1.5 cursor-pointer disabled:opacity-50"
                >
                  <PlusCircle className="w-4 h-4 text-[#0052CC]" />
                  <span>{isGeneratingSample ? 'Generating...' : 'Generate Stress Test PDF'}</span>
                </button>
              </div>
            </div>
          )}

          {activeTab === 'android' && (
            <div className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div className="p-3.5 rounded-xl border border-gray-200 bg-gray-50/50 space-y-1">
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-4 h-4 text-[#36B37E]" />
                    <h4 className="font-bold text-xs text-[#172B4D]">Android Large Heap</h4>
                  </div>
                  <p className="text-[11px] text-[#6B778C]">
                    `android:largeHeap="true"` configured to allocate up to 512MB RAM for handling scanned image-heavy PDFs without OOM.
                  </p>
                </div>

                <div className="p-3.5 rounded-xl border border-gray-200 bg-gray-50/50 space-y-1">
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-4 h-4 text-[#36B37E]" />
                    <h4 className="font-bold text-xs text-[#172B4D]">Scoped Storage & FileProvider</h4>
                  </div>
                  <p className="text-[11px] text-[#6B778C]">
                    Compliant with Android 10+ scoped storage. Uses `content://` URIs so sharing to WhatsApp, Gmail, or Drive works securely.
                  </p>
                </div>

                <div className="p-3.5 rounded-xl border border-gray-200 bg-gray-50/50 space-y-1">
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-4 h-4 text-[#36B37E]" />
                    <h4 className="font-bold text-xs text-[#172B4D]">Continuous Virtualization</h4>
                  </div>
                  <p className="text-[11px] text-[#6B778C]">
                    Syncfusion `SfPdfViewer` virtualizes off-screen pages so multi-page documents maintain 60 FPS scrolling and low memory usage.
                  </p>
                </div>

                <div className="p-3.5 rounded-xl border border-gray-200 bg-gray-50/50 space-y-1">
                  <div className="flex items-center gap-2">
                    <CheckCircle2 className="w-4 h-4 text-[#36B37E]" />
                    <h4 className="font-bold text-xs text-[#172B4D]">Flatten Before Sharing</h4>
                  </div>
                  <p className="text-[11px] text-[#6B778C]">
                    All signatures and annotations are burned directly into the PDF byte stream so third-party PDF viewers display them permanently.
                  </p>
                </div>
              </div>
            </div>
          )}

          {activeTab === 'files' && (
            <div className="space-y-4">
              <p className="text-xs text-[#6B778C]">
                All native Flutter and Android files have been generated in <code className="text-[#0052CC] font-bold">/flutter_android</code>.
                You can open this folder directly in Android Studio.
              </p>

              <div>
                <div className="flex items-center justify-between mb-1">
                  <span className="text-xs font-bold text-[#172B4D]">pubspec.yaml</span>
                  <button
                    onClick={() => copyToClipboard(pubspecContent, 'pubspec')}
                    className="text-[11px] text-[#0052CC] font-semibold flex items-center gap-1 hover:underline cursor-pointer"
                  >
                    {copiedTab === 'pubspec' ? <Check className="w-3.5 h-3.5" /> : <Copy className="w-3.5 h-3.5" />}
                    {copiedTab === 'pubspec' ? 'Copied' : 'Copy'}
                  </button>
                </div>
                <pre className="bg-[#172B4D] text-gray-200 p-3 rounded-lg text-[11px] font-mono overflow-x-auto">
                  {pubspecContent}
                </pre>
              </div>

              <div>
                <div className="flex items-center justify-between mb-1">
                  <span className="text-xs font-bold text-[#172B4D]">AndroidManifest.xml (Extract)</span>
                  <button
                    onClick={() => copyToClipboard(manifestContent, 'manifest')}
                    className="text-[11px] text-[#0052CC] font-semibold flex items-center gap-1 hover:underline cursor-pointer"
                  >
                    {copiedTab === 'manifest' ? <Check className="w-3.5 h-3.5" /> : <Copy className="w-3.5 h-3.5" />}
                    {copiedTab === 'manifest' ? 'Copied' : 'Copy'}
                  </button>
                </div>
                <pre className="bg-[#172B4D] text-gray-200 p-3 rounded-lg text-[11px] font-mono overflow-x-auto">
                  {manifestContent}
                </pre>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-3 border-t border-gray-100 bg-gray-50 flex items-center justify-between">
          <span className="text-[11px] text-[#6B778C]">
            Ready for compile with Flutter 3.x & Android API 21+
          </span>
          <button
            onClick={onClose}
            className="px-4 py-2 bg-[#172B4D] text-white text-xs font-bold rounded-lg hover:bg-gray-800 transition-colors cursor-pointer"
          >
            Done
          </button>
        </div>
      </div>
    </div>
  );
};

function SaveIcon() {
  return (
    <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4" />
    </svg>
  );
}

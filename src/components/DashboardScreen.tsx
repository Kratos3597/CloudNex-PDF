import React, { useRef } from 'react';
import { 
  Upload, 
  GitMerge, 
  Activity, 
  FileText, 
  MoreVertical, 
  Plus, 
  Clock, 
  Trash2,
  FolderOpen,
  Smartphone,
  Share2
} from 'lucide-react';
import { DocumentRecord, TabType } from '../types';
import { StorageService } from '../services/storage';
import { PdfEngine } from '../services/pdfEngine';

interface DashboardScreenProps {
  documents: DocumentRecord[];
  onOpenDocument: (doc: DocumentRecord) => void;
  onRefreshDocs: () => void;
  onNavigateTab: (tab: TabType) => void;
  onOpenSyncfusion?: () => void;
}

export const DashboardScreen: React.FC<DashboardScreenProps> = ({
  documents,
  onOpenDocument,
  onRefreshDocs,
  onNavigateTab,
  onOpenSyncfusion,
}) => {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const mergeInputRef = useRef<HTMLInputElement>(null);

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const arrayBuffer = await file.arrayBuffer();
    const bytes = new Uint8Array(arrayBuffer);
    const report = await PdfEngine.analyzeDocument(bytes);

    const newDoc: DocumentRecord = {
      id: `doc-${Date.now()}`,
      fileName: file.name,
      filePath: `/local/storage/${file.name}`,
      lastOpenedDate: new Date().toISOString(),
      lastOpenedPage: 1,
      fileSize: `${(file.size / 1024).toFixed(1)} KB`,
      pageCount: report.totalPages || 1,
    };

    StorageService.saveDocument(newDoc, bytes);
    StorageService.logAction('OPEN_DOCUMENT', newDoc.fileName);
    onRefreshDocs();
    onOpenDocument(newDoc);
    e.target.value = '';
  };

  const handleMergeFiles = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = e.target.files;
    if (!files || files.length < 2) {
      alert('Please select at least 2 PDF documents to merge.');
      return;
    }

    try {
      const byteArrays: Uint8Array[] = [];
      for (let i = 0; i < files.length; i++) {
        const buffer = await files[i].arrayBuffer();
        byteArrays.push(new Uint8Array(buffer));
      }

      const mergedBytes = await PdfEngine.mergeDocuments(byteArrays);
      const report = await PdfEngine.analyzeDocument(mergedBytes);
      const mergedName = `Merged_${Date.now().toString().slice(-4)}.pdf`;

      const newDoc: DocumentRecord = {
        id: `doc-${Date.now()}`,
        fileName: mergedName,
        filePath: `/local/storage/${mergedName}`,
        lastOpenedDate: new Date().toISOString(),
        lastOpenedPage: 1,
        fileSize: `${(mergedBytes.byteLength / 1024).toFixed(1)} KB`,
        pageCount: report.totalPages || byteArrays.length,
      };

      StorageService.saveDocument(newDoc, mergedBytes);
      StorageService.logAction('MERGE_DOCUMENTS', mergedName);
      onRefreshDocs();
      onOpenDocument(newDoc);
    } catch (err) {
      console.error('Merge error:', err);
      alert('Failed to merge documents.');
    }
    e.target.value = '';
  };

  const handleDeleteDoc = (e: React.MouseEvent, docId: string) => {
    e.stopPropagation();
    if (confirm('Remove document from library?')) {
      StorageService.deleteDocument(docId);
      onRefreshDocs();
    }
  };

  const handleQuickShare = async (e: React.MouseEvent, doc: DocumentRecord) => {
    e.stopPropagation();
    const bytes = await StorageService.getDocumentBytes(doc.id);
    if (!bytes) {
      alert('Document file data not found.');
      return;
    }

    const fileName = doc.fileName.endsWith('.pdf') ? doc.fileName : `${doc.fileName}.pdf`;
    const pdfBlob = new Blob([bytes.buffer as ArrayBuffer], { type: 'application/pdf' });
    const pdfFile = new File([pdfBlob], fileName, { type: 'application/pdf' });

    if (navigator.canShare && navigator.canShare({ files: [pdfFile] })) {
      try {
        await navigator.share({
          files: [pdfFile],
          title: doc.fileName,
          text: `PDF document: ${doc.fileName}`,
        });
        StorageService.logAction('EXPORT_DOCUMENT', `Shared ${doc.fileName}`);
      } catch (err: any) {
        if (err.name !== 'AbortError') {
          PdfEngine.downloadFile(bytes, fileName, 'application/pdf');
        }
      }
    } else {
      PdfEngine.downloadFile(bytes, fileName, 'application/pdf');
    }
  };

  return (
    <div id="dashboard-screen" className="max-w-6xl mx-auto px-4 py-8 space-y-8">
      {/* Hidden File Inputs */}
      <input
        type="file"
        ref={fileInputRef}
        onChange={handleFileUpload}
        accept="application/pdf"
        className="hidden"
      />
      <input
        type="file"
        ref={mergeInputRef}
        onChange={handleMergeFiles}
        accept="application/pdf"
        multiple
        className="hidden"
      />

      {/* Greeting Banner */}
      <div className="bg-gradient-to-r from-[#0052CC] to-[#172B4D] rounded-2xl p-7 text-white shadow-lg relative overflow-hidden">
        <div className="relative z-10 max-w-xl">
          <span className="text-xs font-bold uppercase tracking-wider text-[#4C9AFF] bg-white/10 px-2.5 py-1 rounded-full inline-block mb-3">
            CLOUDNEX PDF PRO ENTERPRISE
          </span>
          <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight mb-2">
            Welcome back,
          </h1>
          <p className="text-sm text-blue-100/90 leading-relaxed">
            What would you like to do today? Select an existing document, merge files, generate image-heavy PDFs, or open the Android Suite.
          </p>
        </div>
        {/* Subtle decorative background graphic */}
        <div className="absolute right-0 top-0 bottom-0 w-1/3 opacity-10 flex items-center justify-center pointer-events-none">
          <FileText className="w-64 h-64" />
        </div>
      </div>

      {/* Quick Actions Grid */}
      <div>
        <h2 className="text-sm font-bold uppercase tracking-wider text-[#6B778C] mb-4">
          Quick Actions
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          {/* Upload Card */}
          <button
            id="quick-action-upload"
            onClick={() => fileInputRef.current?.click()}
            className="bg-white p-5 rounded-xl border border-gray-200 shadow-sm hover:border-[#0052CC] hover:shadow-md transition-all text-left flex items-start gap-4 group cursor-pointer"
          >
            <div className="p-3 rounded-lg bg-[#0052CC]/10 text-[#0052CC] group-hover:bg-[#0052CC] group-hover:text-white transition-colors shrink-0">
              <Upload className="w-6 h-6" />
            </div>
            <div>
              <h3 className="font-bold text-[#172B4D] text-sm group-hover:text-[#0052CC] transition-colors">
                Upload Document
              </h3>
              <p className="text-xs text-[#6B778C] mt-1">
                Open and analyze PDF files from your device
              </p>
            </div>
          </button>

          {/* Merge Card */}
          <button
            id="quick-action-merge"
            onClick={() => mergeInputRef.current?.click()}
            className="bg-white p-5 rounded-xl border border-gray-200 shadow-sm hover:border-[#0052CC] hover:shadow-md transition-all text-left flex items-start gap-4 group cursor-pointer"
          >
            <div className="p-3 rounded-lg bg-[#36B37E]/10 text-[#36B37E] group-hover:bg-[#36B37E] group-hover:text-white transition-colors shrink-0">
              <GitMerge className="w-6 h-6" />
            </div>
            <div>
              <h3 className="font-bold text-[#172B4D] text-sm group-hover:text-[#36B37E] transition-colors">
                Merge PDFs
              </h3>
              <p className="text-xs text-[#6B778C] mt-1">
                Combine multiple PDF documents into one
              </p>
            </div>
          </button>

          {/* Syncfusion & Android Card */}
          <button
            id="quick-action-syncfusion"
            onClick={onOpenSyncfusion}
            className="bg-white p-5 rounded-xl border border-blue-200 shadow-sm hover:border-[#0052CC] hover:shadow-md transition-all text-left flex items-start gap-4 group cursor-pointer"
          >
            <div className="p-3 rounded-lg bg-blue-50 text-[#0052CC] group-hover:bg-[#0052CC] group-hover:text-white transition-colors shrink-0">
              <Smartphone className="w-6 h-6" />
            </div>
            <div>
              <h3 className="font-bold text-[#172B4D] text-sm group-hover:text-[#0052CC] transition-colors flex items-center gap-1.5">
                Syncfusion Suite
              </h3>
              <p className="text-xs text-[#6B778C] mt-1">
                License key, stress tests & Android setup
              </p>
            </div>
          </button>

          {/* Activity Insights Card */}
          <button
            id="quick-action-activity"
            onClick={() => onNavigateTab('activity')}
            className="bg-white p-5 rounded-xl border border-gray-200 shadow-sm hover:border-[#0052CC] hover:shadow-md transition-all text-left flex items-start gap-4 group cursor-pointer"
          >
            <div className="p-3 rounded-lg bg-[#FFAB00]/10 text-[#FFAB00] group-hover:bg-[#FFAB00] group-hover:text-white transition-colors shrink-0">
              <Activity className="w-6 h-6" />
            </div>
            <div>
              <h3 className="font-bold text-[#172B4D] text-sm group-hover:text-[#FFAB00] transition-colors">
                Activity Insights
              </h3>
              <p className="text-xs text-[#6B778C] mt-1">
                View audit trails and document metrics
              </p>
            </div>
          </button>
        </div>
      </div>

      {/* Recent Documents Section */}
      <div>
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-sm font-bold uppercase tracking-wider text-[#6B778C]">
            Recent Documents ({documents.length})
          </h2>
          <button
            onClick={() => onNavigateTab('files')}
            className="text-xs font-bold text-[#0052CC] hover:underline flex items-center gap-1 cursor-pointer"
          >
            <FolderOpen className="w-3.5 h-3.5" />
            <span>View All Files</span>
          </button>
        </div>

        {documents.length === 0 ? (
          <div className="bg-white rounded-xl border border-dashed border-gray-300 p-12 text-center">
            <FileText className="w-12 h-12 text-gray-400 mx-auto mb-3" />
            <p className="text-sm font-bold text-gray-700">No documents yet</p>
            <p className="text-xs text-gray-500 mt-1 mb-4">
              Upload a PDF to get started with reading and editing.
            </p>
            <button
              onClick={() => fileInputRef.current?.click()}
              className="px-4 py-2 bg-[#0052CC] text-white text-xs font-bold rounded-lg hover:bg-[#0040A0] shadow cursor-pointer"
            >
              Upload PDF
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {documents.slice(0, 4).map((doc) => (
              <div
                key={doc.id}
                id={`recent-doc-card-${doc.id}`}
                onClick={() => onOpenDocument(doc)}
                className="bg-white p-4 rounded-xl border border-gray-200 shadow-sm hover:border-[#0052CC] hover:shadow-md transition-all flex items-center justify-between group cursor-pointer"
              >
                <div className="flex items-center gap-3 min-w-0">
                  <div className="p-3 bg-[#0052CC]/10 text-[#0052CC] rounded-lg group-hover:bg-[#0052CC] group-hover:text-white transition-colors shrink-0">
                    <FileText className="w-5 h-5" />
                  </div>
                  <div className="min-w-0">
                    <h4 className="font-bold text-sm text-[#172B4D] truncate group-hover:text-[#0052CC] transition-colors">
                      {doc.fileName}
                    </h4>
                    <div className="flex items-center gap-3 text-xs text-[#6B778C] mt-1">
                      <span className="flex items-center gap-1">
                        <Clock className="w-3 h-3" />
                        {new Date(doc.lastOpenedDate).toLocaleDateString()}
                      </span>
                      <span>{doc.pageCount || 1} Pages</span>
                      {doc.fileSize && <span>{doc.fileSize}</span>}
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-1 shrink-0 ml-2">
                  <button
                    onClick={(e) => handleQuickShare(e, doc)}
                    className="p-2 text-gray-400 hover:text-[#0052CC] rounded-lg hover:bg-blue-50 transition-colors cursor-pointer"
                    title="Share PDF via Android Share Sheet"
                  >
                    <Share2 className="w-4 h-4" />
                  </button>
                  <button
                    onClick={(e) => handleDeleteDoc(e, doc.id)}
                    className="p-2 text-gray-400 hover:text-[#DE350B] rounded-lg hover:bg-red-50 transition-colors cursor-pointer"
                    title="Delete document"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Floating Action Button */}
      <button
        id="dashboard-fab-upload"
        onClick={() => fileInputRef.current?.click()}
        className="fixed bottom-20 right-6 md:bottom-8 md:right-8 bg-[#0052CC] hover:bg-[#0040A0] text-white p-4 rounded-full shadow-2xl flex items-center gap-2 font-bold text-sm transition-all hover:scale-105 cursor-pointer z-30"
      >
        <Plus className="w-5 h-5" />
        <span className="hidden sm:inline">Open PDF</span>
      </button>
    </div>
  );
};

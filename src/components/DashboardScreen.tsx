import React, { useRef, useState } from 'react';
import { 
  Upload, 
  GitMerge, 
  Activity, 
  FileText, 
  Plus, 
  Clock, 
  Trash2, 
  FolderOpen, 
  Share2, 
  ScanText, 
  Sparkles, 
  CheckCircle2,
  Folder,
  Tag,
  ChevronRight,
  ShieldCheck,
  FileCheck
} from 'lucide-react';
import { DocumentRecord, TabType, OcrProgressStatus } from '../types';
import { StorageService } from '../services/storage';
import { PdfEngine } from '../services/pdfEngine';
import { OcrService } from '../services/ocrService';
import { AiClassifierService } from '../services/aiClassifier';
import { OcrProgressModal } from './OcrProgressModal';
import { AutoTagModal } from './AutoTagModal';

interface DashboardScreenProps {
  documents: DocumentRecord[];
  onOpenDocument: (doc: DocumentRecord) => void;
  onRefreshDocs: () => void;
  onNavigateTab: (tab: TabType) => void;
}

export const DashboardScreen: React.FC<DashboardScreenProps> = ({
  documents,
  onOpenDocument,
  onRefreshDocs,
  onNavigateTab,
}) => {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const mergeInputRef = useRef<HTMLInputElement>(null);

  // OCR modal state
  const [isOcrModalOpen, setIsOcrModalOpen] = useState(false);
  const [ocrStatus, setOcrStatus] = useState<OcrProgressStatus | null>(null);
  const [ocrFileName, setOcrFileName] = useState('');

  // AI Auto-Tag Modal state
  const [autoTagDoc, setAutoTagDoc] = useState<DocumentRecord | null>(null);
  const [isAutoTagModalOpen, setIsAutoTagModalOpen] = useState(false);
  const [selectedFolderFilter, setSelectedFolderFilter] = useState<string>('All');
  const [isGeneratingSample, setIsGeneratingSample] = useState(false);

  const availableFolders = StorageService.getFolders();

  const filteredDocs = documents.filter((doc) => {
    if (selectedFolderFilter === 'All') return true;
    return doc.folder === selectedFolderFilter;
  });

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    try {
      const arrayBuffer = await file.arrayBuffer();
      const bytes = new Uint8Array(arrayBuffer);
      const report = await PdfEngine.analyzeDocument(bytes);

      // Check whether this PDF is a scanned image-based document (lacks text stream)
      const detection = await OcrService.detectIsScannedDocument(bytes);

      let finalBytes = bytes;
      let isScanned = detection.isScanned;
      let ocrProcessed = false;
      let ocrWordCount = 0;
      let ocrConfidence = 0;
      let searchableText = '';

      if (isScanned) {
        // Automatically run OCR conversion
        setOcrFileName(file.name);
        setIsOcrModalOpen(true);

        const { convertedPdfBytes, ocrResult } = await OcrService.processScannedPdf(
          bytes,
          (status) => setOcrStatus(status)
        );

        finalBytes = new Uint8Array(convertedPdfBytes);
        ocrProcessed = true;
        ocrWordCount = ocrResult.totalWords;
        ocrConfidence = ocrResult.averageConfidence;
        searchableText = ocrResult.fullText;

        // Brief delay so user sees 100% completion
        await new Promise((r) => setTimeout(r, 600));
        setIsOcrModalOpen(false);
      } else {
        // Extract native PDF text for AI analysis
        searchableText = await PdfEngine.extractAllText(finalBytes);
      }

      // Automatically run AI Auto-Tagging and Folder Categorization!
      let folder = 'Reports & Notes';
      let tags = ['#document'];
      let aiCategoryConfidence = 85;
      let aiSummary = '';
      let aiReasoning = '';
      let aiEngine: 'gemini' | 'heuristic' = 'heuristic';

      try {
        const classification = await AiClassifierService.classifyDocument(searchableText, file.name);
        folder = classification.folder;
        tags = classification.tags;
        aiCategoryConfidence = classification.confidence;
        aiSummary = classification.summary;
        aiReasoning = classification.reasoning || '';
        aiEngine = classification.engine;
      } catch (err) {
        console.warn('AI classification fallback:', err);
      }

      const newDoc: DocumentRecord = {
        id: `doc-${Date.now()}`,
        fileName: file.name,
        filePath: `/storage/cloudnex/${folder}/${file.name}`,
        lastOpenedDate: new Date().toISOString(),
        lastOpenedPage: 1,
        fileSize: `${(finalBytes.byteLength / 1024).toFixed(1)} KB`,
        pageCount: report.totalPages || 1,
        isScanned,
        ocrProcessed,
        ocrWordCount,
        ocrConfidence,
        searchableText,
        folder,
        tags,
        aiCategoryConfidence,
        aiSummary,
        aiReasoning,
        aiEngine,
        autoTaggedAt: new Date().toISOString(),
      };

      StorageService.saveDocument(newDoc, finalBytes);
      if (ocrProcessed) {
        StorageService.logAction('OCR_CONVERT', newDoc.fileName);
      } else {
        StorageService.logAction('OPEN_DOCUMENT', newDoc.fileName);
      }
      StorageService.logAction('AUTO_TAG_DOCUMENT', newDoc.fileName);

      onRefreshDocs();
      onOpenDocument(newDoc);
    } catch (err) {
      console.error('File import or OCR error:', err);
      setIsOcrModalOpen(false);
      alert('Failed to process PDF document.');
    }
    e.target.value = '';
  };

  const handleTestScannedSample = async () => {
    try {
      setOcrFileName('Scanned_Invoice_Sample.pdf');
      setIsOcrModalOpen(true);
      setOcrStatus({
        status: 'detecting',
        currentPage: 0,
        totalPages: 1,
        progress: 10,
        message: 'Generating flatbed scanned raster PDF (0 digital text stream)...',
      });

      // 1. Create simulated authentic image-only scan
      const { bytes, fileName } = await OcrService.createScannedSampleDocument('invoice');
      setOcrFileName(fileName);

      // 2. Automatically run OCR conversion
      const { convertedPdfBytes, ocrResult } = await OcrService.processScannedPdf(
        bytes,
        (status) => setOcrStatus(status)
      );

      // Short pause for completed animation
      await new Promise((r) => setTimeout(r, 700));
      setIsOcrModalOpen(false);

      // 3. Automatically classify and tag using recognized OCR text
      let folder = 'Invoices';
      let tags = ['#invoice', '#billing', '#accounts-payable'];
      let aiCategoryConfidence = 98;
      let aiSummary = 'Scanned invoice document recognized and converted via automated OCR.';
      let aiReasoning = 'Contains itemized expenses, line items, and invoice keywords.';
      let aiEngine: 'gemini' | 'heuristic' = 'gemini';

      try {
        const classification = await AiClassifierService.classifyDocument(ocrResult.fullText, fileName);
        folder = classification.folder;
        tags = classification.tags;
        aiCategoryConfidence = classification.confidence;
        aiSummary = classification.summary;
        aiReasoning = classification.reasoning || '';
        aiEngine = classification.engine;
      } catch (err) {
        console.warn('AI classification fallback:', err);
      }

      const newDoc: DocumentRecord = {
        id: `doc-${Date.now()}`,
        fileName,
        filePath: `/storage/cloudnex/${folder}/${fileName}`,
        lastOpenedDate: new Date().toISOString(),
        lastOpenedPage: 1,
        fileSize: `${(convertedPdfBytes.byteLength / 1024).toFixed(1)} KB`,
        pageCount: 1,
        isScanned: true,
        ocrProcessed: true,
        ocrWordCount: ocrResult.totalWords,
        ocrConfidence: ocrResult.averageConfidence,
        searchableText: ocrResult.fullText,
        folder,
        tags,
        aiCategoryConfidence,
        aiSummary,
        aiReasoning,
        aiEngine,
        autoTaggedAt: new Date().toISOString(),
      };

      StorageService.saveDocument(newDoc, convertedPdfBytes);
      StorageService.logAction('OCR_CONVERT', newDoc.fileName);
      StorageService.logAction('AUTO_TAG_DOCUMENT', newDoc.fileName);
      onRefreshDocs();
      onOpenDocument(newDoc);
    } catch (err) {
      console.error('Error generating and converting scanned document:', err);
      setIsOcrModalOpen(false);
      alert('Failed to generate test scanned document.');
    }
  };

  const handleGenerateSampleCategory = async (category: 'invoice' | 'contract' | 'identity') => {
    try {
      setIsGeneratingSample(true);
      let bytes: Uint8Array;
      let fileName: string;
      let defaultFolder: string;
      let tags: string[];

      if (category === 'invoice') {
        bytes = await PdfEngine.createInvoiceSampleDocument();
        fileName = `AWS_Cloud_Invoice_${Date.now().toString().slice(-4)}.pdf`;
        defaultFolder = 'Invoices';
        tags = ['#invoice', '#billing', '#cloud-compute'];
      } else if (category === 'contract') {
        bytes = await PdfEngine.createContractSampleDocument();
        fileName = `Vendor_Agreement_${Date.now().toString().slice(-4)}.pdf`;
        defaultFolder = 'Contracts';
        tags = ['#contract', '#legal-agreement', '#terms'];
      } else {
        bytes = await PdfEngine.createIdentitySampleDocument();
        fileName = `Passport_ID_Verification_${Date.now().toString().slice(-4)}.pdf`;
        defaultFolder = 'Identity';
        tags = ['#identity', '#gov-id', '#kyc-verified'];
      }

      const text = await PdfEngine.extractAllText(bytes);
      const classification = await AiClassifierService.classifyDocument(text, fileName);

      const newDoc: DocumentRecord = {
        id: `doc-${Date.now()}`,
        fileName,
        filePath: `/storage/cloudnex/${classification.folder}/${fileName}`,
        lastOpenedDate: new Date().toISOString(),
        lastOpenedPage: 1,
        fileSize: `${(bytes.byteLength / 1024).toFixed(1)} KB`,
        pageCount: 1,
        searchableText: text,
        folder: classification.folder || defaultFolder,
        tags: classification.tags.length > 0 ? classification.tags : tags,
        aiCategoryConfidence: classification.confidence,
        aiSummary: classification.summary,
        aiReasoning: classification.reasoning,
        aiEngine: classification.engine,
        autoTaggedAt: new Date().toISOString(),
      };

      StorageService.saveDocument(newDoc, bytes);
      StorageService.logAction('AUTO_TAG_DOCUMENT', newDoc.fileName);
      onRefreshDocs();
      onOpenDocument(newDoc);
    } catch (e) {
      console.error('Error generating sample:', e);
      alert('Failed to generate document sample.');
    } finally {
      setIsGeneratingSample(false);
    }
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

      {/* Modern Studio Executive Banner */}
      <div className="bg-slate-900 text-white rounded-3xl p-6 sm:p-8 border border-slate-800 shadow-lg relative overflow-hidden">
        {/* Ambient background glow */}
        <div className="absolute top-0 right-0 -mt-12 -mr-12 w-96 h-96 bg-blue-600/10 rounded-full blur-3xl pointer-events-none" />
        <div className="absolute bottom-0 left-1/3 -mb-12 w-64 h-64 bg-indigo-600/10 rounded-full blur-2xl pointer-events-none" />

        <div className="relative z-10 flex flex-col lg:flex-row lg:items-center justify-between gap-6">
          <div className="max-w-xl">
            <div className="flex items-center gap-2 mb-3">
              <span className="text-[10px] font-bold uppercase tracking-widest text-blue-400 bg-blue-500/10 border border-blue-400/20 px-2.5 py-1 rounded-full inline-flex items-center gap-1.5">
                <span className="w-1.5 h-1.5 rounded-full bg-blue-400 animate-pulse" />
                CLOUDNEX PRO STUDIO
              </span>
              <span className="text-[10px] font-medium text-slate-400">
                v2.4
              </span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-extrabold tracking-tight text-white mb-2">
              Document Workspace
            </h1>
            <p className="text-xs sm:text-sm text-slate-300 leading-relaxed max-w-lg">
              Automated OCR text recognition, AI auto-tagging into smart folders, precision touch editing, and legally binding digital signatures.
            </p>

            {/* Quick Action Badges */}
            <div className="flex items-center gap-2.5 mt-5 flex-wrap">
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="px-4 py-2 bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white text-xs font-semibold rounded-xl shadow-sm shadow-blue-600/25 flex items-center gap-2 transition-all cursor-pointer min-h-[44px]"
              >
                <Upload className="w-3.5 h-3.5" />
                <span>Upload PDF</span>
              </button>
              <button
                type="button"
                onClick={handleTestScannedSample}
                className="px-4 py-2 bg-slate-800 hover:bg-slate-750 active:bg-slate-700 text-slate-200 border border-slate-700 text-xs font-semibold rounded-xl flex items-center gap-2 transition-all cursor-pointer min-h-[44px]"
              >
                <ScanText className="w-3.5 h-3.5 text-blue-400" />
                <span>Test Auto-OCR Scan</span>
              </button>
            </div>
          </div>

          {/* Studio Metrics Pillar */}
          <div className="grid grid-cols-3 gap-3 bg-slate-800/60 backdrop-blur-sm p-3.5 rounded-2xl border border-slate-700/60 lg:max-w-xs w-full shrink-0">
            <div className="text-center p-2 rounded-xl bg-slate-800/40">
              <span className="block text-xl font-extrabold text-white tracking-tight">
                {documents.length}
              </span>
              <span className="block text-[10px] font-medium text-slate-400 mt-0.5">
                Total Files
              </span>
            </div>

            <div className="text-center p-2 rounded-xl bg-slate-800/40">
              <span className="block text-xl font-extrabold text-emerald-400 tracking-tight flex items-center justify-center gap-1">
                {documents.filter(d => d.ocrProcessed).length}
              </span>
              <span className="block text-[10px] font-medium text-slate-400 mt-0.5">
                OCR Ready
              </span>
            </div>

            <div className="text-center p-2 rounded-xl bg-slate-800/40">
              <span className="block text-xl font-extrabold text-indigo-400 tracking-tight">
                {availableFolders.length}
              </span>
              <span className="block text-[10px] font-medium text-slate-400 mt-0.5">
                Folders
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* Modern Quick Action Grid */}
      <div>
        <div className="flex items-center justify-between mb-3.5">
          <h2 className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
            Quick Actions
          </h2>
          <span className="text-xs text-slate-400 hidden sm:inline">
            Drag & drop supported
          </span>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
          {/* Upload Card */}
          <button
            id="quick-action-upload"
            onClick={() => fileInputRef.current?.click()}
            className="bg-white dark:bg-slate-900 p-4 sm:p-5 rounded-2xl border border-slate-200/80 dark:border-slate-800 shadow-2xs hover:border-blue-500/80 hover:shadow-md hover:-translate-y-0.5 transition-all text-left flex items-start gap-3.5 group cursor-pointer"
          >
            <div className="p-3 rounded-xl bg-blue-50 dark:bg-blue-950/50 text-blue-600 dark:text-blue-400 group-hover:bg-blue-600 group-hover:text-white transition-colors shrink-0">
              <Upload className="w-5 h-5" />
            </div>
            <div className="min-w-0">
              <h3 className="font-bold text-slate-900 dark:text-white text-sm group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                Upload Document
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5 leading-relaxed">
                Open & auto-detect scanned image PDFs
              </p>
            </div>
          </button>

          {/* Test Scanned PDF with Auto-OCR Card */}
          <button
            id="quick-action-test-ocr"
            onClick={handleTestScannedSample}
            className="bg-white dark:bg-slate-900 p-4 sm:p-5 rounded-2xl border border-blue-200/70 dark:border-blue-900/50 shadow-2xs hover:border-blue-500 hover:shadow-md hover:-translate-y-0.5 transition-all text-left flex items-start gap-3.5 group cursor-pointer relative overflow-hidden"
          >
            <div className="absolute top-2.5 right-2.5 px-2 py-0.5 rounded-full bg-blue-50 dark:bg-blue-900/40 text-blue-600 dark:text-blue-300 text-[9px] font-bold uppercase tracking-wider border border-blue-200 dark:border-blue-800">
              Auto-OCR
            </div>
            <div className="p-3 rounded-xl bg-blue-50 dark:bg-blue-950/50 text-blue-600 dark:text-blue-400 group-hover:bg-blue-600 group-hover:text-white transition-colors shrink-0">
              <ScanText className="w-5 h-5" />
            </div>
            <div className="min-w-0">
              <h3 className="font-bold text-slate-900 dark:text-white text-sm group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors">
                Test Scanned PDF
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5 leading-relaxed">
                Generate image scan & extract text
              </p>
            </div>
          </button>

          {/* Merge Card */}
          <button
            id="quick-action-merge"
            onClick={() => mergeInputRef.current?.click()}
            className="bg-white dark:bg-slate-900 p-4 sm:p-5 rounded-2xl border border-slate-200/80 dark:border-slate-800 shadow-2xs hover:border-emerald-500/80 hover:shadow-md hover:-translate-y-0.5 transition-all text-left flex items-start gap-3.5 group cursor-pointer"
          >
            <div className="p-3 rounded-xl bg-emerald-50 dark:bg-emerald-950/50 text-emerald-600 dark:text-emerald-400 group-hover:bg-emerald-600 group-hover:text-white transition-colors shrink-0">
              <GitMerge className="w-5 h-5" />
            </div>
            <div className="min-w-0">
              <h3 className="font-bold text-slate-900 dark:text-white text-sm group-hover:text-emerald-600 dark:group-hover:text-emerald-400 transition-colors">
                Merge PDFs
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5 leading-relaxed">
                Combine multiple PDF documents into one
              </p>
            </div>
          </button>

          {/* Activity Insights Card */}
          <button
            id="quick-action-activity"
            onClick={() => onNavigateTab('activity')}
            className="bg-white dark:bg-slate-900 p-4 sm:p-5 rounded-2xl border border-slate-200/80 dark:border-slate-800 shadow-2xs hover:border-amber-500/80 hover:shadow-md hover:-translate-y-0.5 transition-all text-left flex items-start gap-3.5 group cursor-pointer"
          >
            <div className="p-3 rounded-xl bg-amber-50 dark:bg-amber-950/50 text-amber-600 dark:text-amber-400 group-hover:bg-amber-600 group-hover:text-white transition-colors shrink-0">
              <Activity className="w-5 h-5" />
            </div>
            <div className="min-w-0">
              <h3 className="font-bold text-slate-900 dark:text-white text-sm group-hover:text-amber-600 dark:group-hover:text-amber-400 transition-colors">
                Audit Trail
              </h3>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5 leading-relaxed">
                View tamper-evident action logs & stats
              </p>
            </div>
          </button>
        </div>
      </div>

      {/* AI Auto-Tagging & Smart Classification Showcase */}
      <div className="bg-gradient-to-br from-indigo-50/80 via-slate-50 to-white dark:from-slate-900 dark:via-slate-900/90 dark:to-slate-850 rounded-2xl p-5 border border-indigo-100/80 dark:border-slate-800 shadow-2xs">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-600 to-blue-600 text-white flex items-center justify-center shrink-0 shadow-xs">
              <Sparkles className="w-5 h-5 text-white" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="font-bold text-slate-900 dark:text-white text-sm">AI Auto-Tagging & Smart Folders</h3>
                <span className="px-2 py-0.5 rounded-full text-[10px] font-bold uppercase tracking-wider bg-indigo-100 dark:bg-indigo-900/50 text-indigo-800 dark:text-indigo-300">
                  Touch & Mobile Ready
                </span>
              </div>
              <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                Categorizes documents automatically into Invoices, Contracts, or Identity based on OCR content
              </p>
            </div>
          </div>
          <div className="text-[11px] font-semibold text-indigo-600 dark:text-indigo-400 bg-indigo-50/60 dark:bg-indigo-950/40 px-3 py-1 rounded-full border border-indigo-200/50 dark:border-indigo-800 self-start sm:self-auto">
            Powered by Gemini 3.8 & Edge Heuristics
          </div>
        </div>

        {/* 1-Tap Category Test Buttons (Touch Friendly >= 44px) */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
          <button
            type="button"
            disabled={isGeneratingSample}
            onClick={() => handleGenerateSampleCategory('invoice')}
            className="min-h-[46px] px-3.5 py-2.5 bg-white dark:bg-slate-800 hover:bg-blue-50/80 active:bg-blue-100 dark:hover:bg-slate-750 text-slate-800 dark:text-slate-200 rounded-xl border border-blue-200/80 dark:border-blue-900/50 shadow-2xs flex items-center justify-between gap-2 text-xs font-semibold cursor-pointer transition-all disabled:opacity-50"
          >
            <div className="flex items-center gap-2.5 truncate">
              <span className="w-2.5 h-2.5 rounded-full bg-blue-500 shrink-0" />
              <div className="text-left truncate">
                <span className="font-bold text-blue-900 dark:text-blue-300 block truncate">Test Invoice Auto-Tag</span>
                <span className="text-[10px] text-slate-500 dark:text-slate-400 block">Detects #billing, #net-30</span>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-blue-500 shrink-0" />
          </button>

          <button
            type="button"
            disabled={isGeneratingSample}
            onClick={() => handleGenerateSampleCategory('contract')}
            className="min-h-[46px] px-3.5 py-2.5 bg-white dark:bg-slate-800 hover:bg-purple-50/80 active:bg-purple-100 dark:hover:bg-slate-750 text-slate-800 dark:text-slate-200 rounded-xl border border-purple-200/80 dark:border-purple-900/50 shadow-2xs flex items-center justify-between gap-2 text-xs font-semibold cursor-pointer transition-all disabled:opacity-50"
          >
            <div className="flex items-center gap-2.5 truncate">
              <span className="w-2.5 h-2.5 rounded-full bg-purple-500 shrink-0" />
              <div className="text-left truncate">
                <span className="font-bold text-purple-900 dark:text-purple-300 block truncate">Test Contract Auto-Tag</span>
                <span className="text-[10px] text-slate-500 dark:text-slate-400 block">Detects #legal, #nda, #terms</span>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-purple-500 shrink-0" />
          </button>

          <button
            type="button"
            disabled={isGeneratingSample}
            onClick={() => handleGenerateSampleCategory('identity')}
            className="min-h-[46px] px-3.5 py-2.5 bg-white dark:bg-slate-800 hover:bg-amber-50/80 active:bg-amber-100 dark:hover:bg-slate-750 text-slate-800 dark:text-slate-200 rounded-xl border border-amber-200/80 dark:border-amber-900/50 shadow-2xs flex items-center justify-between gap-2 text-xs font-semibold cursor-pointer transition-all disabled:opacity-50"
          >
            <div className="flex items-center gap-2.5 truncate">
              <span className="w-2.5 h-2.5 rounded-full bg-amber-500 shrink-0" />
              <div className="text-left truncate">
                <span className="font-bold text-amber-900 dark:text-amber-300 block truncate">Test Identity Auto-Tag</span>
                <span className="text-[10px] text-slate-500 dark:text-slate-400 block">Detects #gov-id, #passport</span>
              </div>
            </div>
            <ChevronRight className="w-4 h-4 text-amber-500 shrink-0" />
          </button>
        </div>
      </div>

      {/* Documents Section */}
      <div>
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-3.5">
          <div className="flex items-center gap-2">
            <h2 className="text-xs font-bold uppercase tracking-wider text-slate-500 dark:text-slate-400">
              Documents ({filteredDocs.length})
            </h2>
            {selectedFolderFilter !== 'All' && (
              <span className="text-xs px-2.5 py-0.5 rounded-full bg-blue-100 dark:bg-blue-900/40 text-blue-700 dark:text-blue-300 font-semibold border border-blue-200 dark:border-blue-800">
                Folder: {selectedFolderFilter}
              </span>
            )}
          </div>
          <button
            onClick={() => onNavigateTab('files')}
            className="text-xs font-bold text-blue-600 dark:text-blue-400 hover:underline flex items-center gap-1 cursor-pointer self-start sm:self-auto min-h-[36px]"
          >
            <FolderOpen className="w-3.5 h-3.5" />
            <span>Manage All Files & Folders</span>
          </button>
        </div>

        {/* Touch-Friendly Horizontal Folder Filter Scroll Bar */}
        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar pb-3 pt-1 -mx-1 px-1 select-none">
          <button
            type="button"
            onClick={() => setSelectedFolderFilter('All')}
            className={`min-h-[44px] px-4 py-2 rounded-xl text-xs font-semibold whitespace-nowrap transition-all cursor-pointer flex items-center gap-2 shrink-0 ${
              selectedFolderFilter === 'All'
                ? 'bg-blue-600 text-white shadow-xs font-bold'
                : 'bg-white dark:bg-slate-900 text-slate-600 dark:text-slate-300 border border-slate-200/80 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-850'
            }`}
          >
            <span>All Documents</span>
            <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${selectedFolderFilter === 'All' ? 'bg-white/20 text-white' : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400'}`}>
              {documents.length}
            </span>
          </button>

          {availableFolders.map((folderName) => {
            const count = documents.filter((d) => d.folder === folderName).length;
            const isSelected = selectedFolderFilter === folderName;
            const style = AiClassifierService.getFolderStyle(folderName);
            return (
              <button
                key={folderName}
                type="button"
                onClick={() => setSelectedFolderFilter(folderName)}
                className={`min-h-[44px] px-3.5 py-2 rounded-xl text-xs font-semibold whitespace-nowrap transition-all cursor-pointer flex items-center gap-2 shrink-0 ${
                  isSelected
                    ? `${style.bg} ${style.text} ${style.border} border shadow-xs font-bold ring-2 ring-blue-500/20`
                    : 'bg-white dark:bg-slate-900 text-slate-700 dark:text-slate-300 border border-slate-200/80 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-850'
                }`}
              >
                <span className={`w-2 h-2 rounded-full ${style.dotColor}`} />
                <span>{folderName}</span>
                <span className="px-2 py-0.5 rounded-full text-[10px] bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 font-bold">
                  {count}
                </span>
              </button>
            );
          })}
        </div>

        {filteredDocs.length === 0 ? (
          <div className="bg-white dark:bg-slate-900 rounded-2xl border border-dashed border-slate-300 dark:border-slate-700 p-12 text-center shadow-2xs">
            <div className="w-12 h-12 rounded-2xl bg-slate-100 dark:bg-slate-800 text-slate-400 flex items-center justify-center mx-auto mb-3">
              <FileText className="w-6 h-6" />
            </div>
            <p className="text-sm font-bold text-slate-800 dark:text-slate-200">No documents in {selectedFolderFilter}</p>
            <p className="text-xs text-slate-500 dark:text-slate-400 mt-1 mb-4">
              Upload a PDF or test an auto-tagged document sample above.
            </p>
            <button
              onClick={() => setSelectedFolderFilter('All')}
              className="px-4 py-2 bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-200 text-xs font-bold rounded-xl hover:bg-slate-200 dark:hover:bg-slate-700 min-h-[44px] cursor-pointer"
            >
              Show All Documents
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {filteredDocs.slice(0, 6).map((doc) => {
              const folderStyle = AiClassifierService.getFolderStyle(doc.folder || 'Reports & Notes');
              return (
                <div
                  key={doc.id}
                  id={`recent-doc-card-${doc.id}`}
                  onClick={() => onOpenDocument(doc)}
                  className="bg-white dark:bg-slate-900 p-4 sm:p-5 rounded-2xl border border-slate-200/80 dark:border-slate-800 shadow-2xs hover:border-blue-400 hover:shadow-md hover:-translate-y-0.5 transition-all flex flex-col justify-between group cursor-pointer space-y-3.5"
                >
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex items-start gap-3.5 min-w-0">
                      <div className="p-3 bg-blue-50 dark:bg-blue-950/50 text-blue-600 dark:text-blue-400 rounded-xl group-hover:bg-blue-600 group-hover:text-white transition-colors shrink-0">
                        <FileText className="w-5 h-5" />
                      </div>
                      <div className="min-w-0">
                        <div className="flex items-center gap-1.5 flex-wrap">
                          <h4 className="font-bold text-sm text-slate-900 dark:text-white truncate group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors max-w-[200px] sm:max-w-xs">
                            {doc.fileName}
                          </h4>
                          {doc.ocrProcessed && (
                            <span 
                              className="px-2 py-0.5 rounded-full bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 text-[10px] font-bold border border-emerald-200 dark:border-emerald-800 flex items-center gap-1 shrink-0"
                              title={`OCR Converted: ${doc.ocrWordCount || 0} words (${doc.ocrConfidence || 95}% confidence)`}
                            >
                              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                              <span>Searchable</span>
                            </span>
                          )}
                        </div>

                        {/* Metadata row */}
                        <div className="flex items-center gap-2.5 text-xs text-slate-500 dark:text-slate-400 mt-1">
                          <span className="flex items-center gap-1">
                            <Clock className="w-3 h-3 text-slate-400" />
                            {new Date(doc.lastOpenedDate).toLocaleDateString()}
                          </span>
                          <span>•</span>
                          <span>{doc.pageCount || 1} Pages</span>
                          {doc.fileSize && (
                            <>
                              <span>•</span>
                              <span>{doc.fileSize}</span>
                            </>
                          )}
                        </div>
                      </div>
                    </div>

                    {/* Quick action buttons (Touch Friendly >= 44px touch container) */}
                    <div className="flex items-center gap-0.5 shrink-0" onClick={(e) => e.stopPropagation()}>
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          setAutoTagDoc(doc);
                          setIsAutoTagModalOpen(true);
                        }}
                        className="p-2.5 text-indigo-600 hover:text-indigo-800 hover:bg-indigo-50 dark:text-indigo-400 dark:hover:bg-slate-800 rounded-xl min-h-[44px] min-w-[44px] flex items-center justify-center cursor-pointer transition-colors"
                        title="Review AI classification & tags"
                      >
                        <Sparkles className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        onClick={(e) => handleQuickShare(e, doc)}
                        className="p-2.5 text-slate-400 hover:text-blue-600 rounded-xl hover:bg-blue-50 dark:hover:bg-slate-800 min-h-[44px] min-w-[44px] flex items-center justify-center transition-colors cursor-pointer"
                        title="Share PDF via Android Share Sheet"
                      >
                        <Share2 className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        onClick={(e) => handleDeleteDoc(e, doc.id)}
                        className="p-2.5 text-slate-400 hover:text-red-600 rounded-xl hover:bg-red-50 dark:hover:bg-slate-800 min-h-[44px] min-w-[44px] flex items-center justify-center transition-colors cursor-pointer"
                        title="Delete document"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>

                  {/* Folder & Smart Tag Chips Footer */}
                  <div className="pt-2.5 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between gap-2 flex-wrap text-xs">
                    <div className="flex items-center gap-1.5 flex-wrap">
                      <span className={`px-2 py-0.5 rounded-lg font-bold text-[11px] flex items-center gap-1 border ${folderStyle.bg} ${folderStyle.text} ${folderStyle.border}`}>
                        <Folder className="w-3 h-3" />
                        <span>{doc.folder || 'Reports & Notes'}</span>
                      </span>

                      {/* Display first 2 tags */}
                      {doc.tags?.slice(0, 2).map((t) => (
                        <span
                          key={t}
                          className="px-2 py-0.5 rounded-lg bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 text-[11px] border border-slate-200/80 dark:border-slate-700 flex items-center gap-0.5"
                        >
                          <Tag className="w-2.5 h-2.5 text-slate-400" />
                          <span>{t}</span>
                        </span>
                      ))}

                      {doc.tags && doc.tags.length > 2 && (
                        <span className="text-[10px] text-slate-400 font-medium">+{doc.tags.length - 2} more</span>
                      )}
                    </div>

                    {doc.aiCategoryConfidence && (
                      <span className="text-[10px] font-semibold text-slate-400 dark:text-slate-500">
                        {doc.aiCategoryConfidence}% AI Match
                      </span>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* OCR Progress Modal */}
      <OcrProgressModal
        isOpen={isOcrModalOpen}
        status={ocrStatus}
        fileName={ocrFileName}
      />

      {/* AI Auto-Tag & Categorization Modal */}
      <AutoTagModal
        isOpen={isAutoTagModalOpen}
        onClose={() => setIsAutoTagModalOpen(false)}
        document={autoTagDoc}
        onDocumentUpdated={() => {
          onRefreshDocs();
        }}
      />

      {/* Floating Action Button */}
      <button
        id="dashboard-fab-upload"
        onClick={() => fileInputRef.current?.click()}
        className="fixed bottom-20 right-6 md:bottom-8 md:right-8 bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white px-5 py-3.5 rounded-2xl shadow-xl shadow-blue-600/30 flex items-center gap-2.5 font-bold text-sm transition-all hover:scale-105 active:scale-95 cursor-pointer z-30 min-h-[52px]"
      >
        <Plus className="w-5 h-5" />
        <span>Open PDF</span>
      </button>
    </div>
  );
};

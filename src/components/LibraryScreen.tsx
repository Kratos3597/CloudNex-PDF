import React, { useState, useRef } from 'react';
import { 
  Search, 
  FileText, 
  Trash2, 
  Clock, 
  ExternalLink,
  Plus,
  Share2,
  ScanText,
  CheckCircle2,
  Sparkles,
  Folder,
  Tag,
  X,
  ChevronRight
} from 'lucide-react';
import { DocumentRecord, OcrProgressStatus } from '../types';
import { StorageService } from '../services/storage';
import { PdfEngine } from '../services/pdfEngine';
import { OcrService } from '../services/ocrService';
import { AiClassifierService } from '../services/aiClassifier';
import { OcrProgressModal } from './OcrProgressModal';
import { AutoTagModal } from './AutoTagModal';

interface LibraryScreenProps {
  documents: DocumentRecord[];
  onOpenDocument: (doc: DocumentRecord) => void;
  onRefreshDocs: () => void;
}

export const LibraryScreen: React.FC<LibraryScreenProps> = ({
  documents,
  onOpenDocument,
  onRefreshDocs,
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedFolder, setSelectedFolder] = useState<string>('All');
  const [selectedTag, setSelectedTag] = useState<string | null>(null);
  const [autoTagDoc, setAutoTagDoc] = useState<DocumentRecord | null>(null);
  const [isAutoTagModalOpen, setIsAutoTagModalOpen] = useState(false);
  const [isGeneratingSample, setIsGeneratingSample] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // OCR modal state
  const [isOcrModalOpen, setIsOcrModalOpen] = useState(false);
  const [ocrStatus, setOcrStatus] = useState<OcrProgressStatus | null>(null);
  const [ocrFileName, setOcrFileName] = useState('');

  const availableFolders = StorageService.getFolders();

  // Search by file name OR by OCR recognized text, plus folder & tag filtering
  const filteredDocs = documents.filter((doc) => {
    // 1. Folder filter
    if (selectedFolder !== 'All' && doc.folder !== selectedFolder) {
      return false;
    }

    // 2. Tag filter
    if (selectedTag && (!doc.tags || !doc.tags.includes(selectedTag))) {
      return false;
    }

    // 3. Search query
    const q = searchQuery.toLowerCase().trim();
    if (!q) return true;
    const nameMatch = doc.fileName.toLowerCase().includes(q);
    const textMatch = doc.searchableText ? doc.searchableText.toLowerCase().includes(q) : false;
    const folderMatch = doc.folder ? doc.folder.toLowerCase().includes(q) : false;
    const tagMatch = doc.tags ? doc.tags.some((t) => t.toLowerCase().includes(q)) : false;
    return nameMatch || textMatch || folderMatch || tagMatch;
  });

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    try {
      const arrayBuffer = await file.arrayBuffer();
      const bytes = new Uint8Array(arrayBuffer);
      const report = await PdfEngine.analyzeDocument(bytes);

      // Check whether this PDF is a scanned image-based document
      const detection = await OcrService.detectIsScannedDocument(bytes);

      let finalBytes = bytes;
      let isScanned = detection.isScanned;
      let ocrProcessed = false;
      let ocrWordCount = 0;
      let ocrConfidence = 0;
      let searchableText = '';

      if (isScanned) {
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

        await new Promise((r) => setTimeout(r, 600));
        setIsOcrModalOpen(false);
      } else {
        searchableText = await PdfEngine.extractAllText(finalBytes);
      }

      // Automatically run AI Auto-Tagging
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

      const { bytes, fileName } = await OcrService.createScannedSampleDocument('invoice');
      setOcrFileName(fileName);

      const { convertedPdfBytes, ocrResult } = await OcrService.processScannedPdf(
        bytes,
        (status) => setOcrStatus(status)
      );

      await new Promise((r) => setTimeout(r, 700));
      setIsOcrModalOpen(false);

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
      console.error('Error in test scan & classify:', err);
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

  const handleDelete = (e: React.MouseEvent, docId: string) => {
    e.stopPropagation();
    if (confirm('Are you sure you want to delete this document?')) {
      StorageService.deleteDocument(docId);
      onRefreshDocs();
    }
  };

  const handleShare = async (e: React.MouseEvent, doc: DocumentRecord) => {
    e.stopPropagation();
    const bytes = await StorageService.getDocumentBytes(doc.id);
    if (!bytes) {
      alert('Document data could not be retrieved for sharing.');
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
    <div id="library-screen" className="max-w-6xl mx-auto px-4 py-8 space-y-6">
      <input
        type="file"
        ref={fileInputRef}
        onChange={handleFileUpload}
        accept="application/pdf"
        className="hidden"
      />

      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-extrabold text-slate-900 dark:text-white tracking-tight">
              Document Library
            </h1>
            <span className="px-2 py-0.5 rounded-full bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 text-xs font-semibold border border-slate-200/80 dark:border-slate-700">
              {documents.length} Files
            </span>
          </div>
          <p className="text-xs text-slate-500 dark:text-slate-400 mt-1">
            AI-powered document categorization, smart auto-tagging, and post-OCR full-text search
          </p>
        </div>

        <div className="flex items-center gap-2 self-start sm:self-auto flex-wrap">
          <button
            onClick={handleTestScannedSample}
            className="px-3.5 py-2.5 bg-blue-50 dark:bg-blue-950/40 hover:bg-blue-100 dark:hover:bg-blue-900/50 text-blue-600 dark:text-blue-400 border border-blue-200/80 dark:border-blue-800 text-xs font-semibold rounded-xl shadow-2xs flex items-center gap-1.5 transition-all cursor-pointer min-h-[44px]"
            title="Generate a realistic image-only scan, OCR it, and auto-tag into Invoices"
          >
            <ScanText className="w-4 h-4" />
            <span>Test Scanned Invoice</span>
          </button>

          <button
            onClick={() => fileInputRef.current?.click()}
            className="px-4 py-2.5 bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white text-xs font-semibold rounded-xl shadow-sm shadow-blue-600/20 flex items-center gap-1.5 transition-all cursor-pointer min-h-[44px]"
          >
            <Plus className="w-4 h-4" />
            <span>Upload PDF</span>
          </button>
        </div>
      </div>

      {/* Fast 1-Tap Category Test Showcase */}
      <div className="bg-gradient-to-r from-blue-50/70 via-indigo-50/70 to-purple-50/70 dark:from-slate-900 dark:via-slate-850 dark:to-slate-900 rounded-2xl p-4 border border-blue-100/80 dark:border-slate-800 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs shadow-2xs">
        <div className="flex items-center gap-2.5">
          <div className="w-7 h-7 rounded-lg bg-indigo-600 text-white flex items-center justify-center shrink-0 shadow-xs">
            <Sparkles className="w-4 h-4" />
          </div>
          <div>
            <span className="font-bold text-slate-800 dark:text-slate-200 block">
              Quick Test AI Categorization into Folders
            </span>
            <span className="text-[11px] text-slate-500 dark:text-slate-400">
              Injects realistic OCR text and triggers Gemini smart auto-tagging
            </span>
          </div>
        </div>
        <div className="flex items-center gap-2 flex-wrap">
          <button
            type="button"
            disabled={isGeneratingSample}
            onClick={() => handleGenerateSampleCategory('invoice')}
            className="px-3.5 py-1.5 bg-white dark:bg-slate-800 hover:bg-blue-50 dark:hover:bg-slate-750 border border-blue-200 dark:border-blue-900/50 text-blue-700 dark:text-blue-300 rounded-xl font-bold min-h-[38px] flex items-center gap-1.5 cursor-pointer transition-all shadow-2xs disabled:opacity-50"
          >
            <span className="w-2 h-2 rounded-full bg-blue-500" />
            + Invoice
          </button>
          <button
            type="button"
            disabled={isGeneratingSample}
            onClick={() => handleGenerateSampleCategory('contract')}
            className="px-3.5 py-1.5 bg-white dark:bg-slate-800 hover:bg-purple-50 dark:hover:bg-slate-750 border border-purple-200 dark:border-purple-900/50 text-purple-700 dark:text-purple-300 rounded-xl font-bold min-h-[38px] flex items-center gap-1.5 cursor-pointer transition-all shadow-2xs disabled:opacity-50"
          >
            <span className="w-2 h-2 rounded-full bg-purple-500" />
            + Contract
          </button>
          <button
            type="button"
            disabled={isGeneratingSample}
            onClick={() => handleGenerateSampleCategory('identity')}
            className="px-3.5 py-1.5 bg-white dark:bg-slate-800 hover:bg-amber-50 dark:hover:bg-slate-750 border border-amber-200 dark:border-amber-900/50 text-amber-700 dark:text-amber-300 rounded-xl font-bold min-h-[38px] flex items-center gap-1.5 cursor-pointer transition-all shadow-2xs disabled:opacity-50"
          >
            <span className="w-2 h-2 rounded-full bg-amber-500" />
            + Identity
          </button>
        </div>
      </div>

      {/* Touch-Friendly Horizontal Folder Filter Bar */}
      <div className="space-y-2.5">
        <div className="flex items-center justify-between">
          <span className="text-xs font-bold text-slate-500 dark:text-slate-400 uppercase tracking-wider flex items-center gap-1.5">
            <Folder className="w-3.5 h-3.5" />
            Category Folders
          </span>
          {selectedTag && (
            <div className="flex items-center gap-1 bg-blue-50 dark:bg-blue-900/40 text-blue-700 dark:text-blue-300 px-3 py-1 rounded-full text-xs font-semibold border border-blue-200 dark:border-blue-800">
              <Tag className="w-3 h-3" />
              <span>Tag: {selectedTag}</span>
              <button
                type="button"
                onClick={() => setSelectedTag(null)}
                className="hover:text-red-500 p-0.5 ml-1 cursor-pointer"
                title="Clear tag filter"
              >
                <X className="w-3 h-3" />
              </button>
            </div>
          )}
        </div>

        <div className="flex items-center gap-2 overflow-x-auto no-scrollbar pb-1 select-none">
          <button
            type="button"
            onClick={() => setSelectedFolder('All')}
            className={`min-h-[44px] px-4 py-2 rounded-xl text-xs font-semibold whitespace-nowrap transition-all cursor-pointer flex items-center gap-2 shrink-0 ${
              selectedFolder === 'All'
                ? 'bg-blue-600 text-white shadow-xs font-bold'
                : 'bg-white dark:bg-slate-900 text-slate-700 dark:text-slate-300 border border-slate-200/80 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-850'
            }`}
          >
            <span>All Folders</span>
            <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${selectedFolder === 'All' ? 'bg-white/20 text-white' : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400'}`}>
              {documents.length}
            </span>
          </button>

          {availableFolders.map((folderName) => {
            const count = documents.filter((d) => d.folder === folderName).length;
            const isSelected = selectedFolder === folderName;
            const style = AiClassifierService.getFolderStyle(folderName);
            return (
              <button
                key={folderName}
                type="button"
                onClick={() => setSelectedFolder(folderName)}
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
      </div>

      {/* Search Input Bar with OCR text hint */}
      <div className="relative">
        <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
        <input
          id="library-search-input"
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search by file name, folder, tag, or recognized OCR text contents..."
          className="w-full pl-10 pr-20 py-2.5 bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl text-sm focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20 shadow-2xs min-h-[44px] text-slate-900 dark:text-white"
        />
        {searchQuery ? (
          <div className="absolute right-3.5 top-1/2 -translate-y-1/2 flex items-center gap-1.5">
            <span className="text-[11px] text-slate-400 font-medium">
              {filteredDocs.length} match{filteredDocs.length === 1 ? '' : 'es'}
            </span>
            <button
              type="button"
              onClick={() => setSearchQuery('')}
              className="p-1 text-slate-400 hover:text-slate-600 dark:hover:text-slate-200 cursor-pointer"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          </div>
        ) : null}
      </div>

      {/* Documents List */}
      {filteredDocs.length === 0 ? (
        <div className="bg-white dark:bg-slate-900 rounded-2xl border border-dashed border-slate-300 dark:border-slate-700 p-12 text-center shadow-2xs">
          <div className="w-12 h-12 rounded-2xl bg-slate-100 dark:bg-slate-800 text-slate-400 flex items-center justify-center mx-auto mb-3">
            <FileText className="w-6 h-6" />
          </div>
          <p className="text-sm font-semibold text-slate-700 dark:text-slate-300">No documents found</p>
          <p className="text-xs text-slate-400 mt-1 mb-4">
            {searchQuery || selectedFolder !== 'All' || selectedTag
              ? 'Try adjusting your filters or search query'
              : 'Upload a PDF to get started'}
          </p>
          {(selectedFolder !== 'All' || selectedTag || searchQuery) && (
            <button
              onClick={() => {
                setSelectedFolder('All');
                setSelectedTag(null);
                setSearchQuery('');
              }}
              className="px-4 py-2 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-750 text-slate-700 dark:text-slate-300 text-xs font-bold rounded-xl min-h-[44px] cursor-pointer"
            >
              Reset Filters
            </button>
          )}
        </div>
      ) : (
        <div className="bg-white dark:bg-slate-900 rounded-2xl border border-slate-200/80 dark:border-slate-800 shadow-2xs overflow-hidden">
          <div className="divide-y divide-slate-100 dark:divide-slate-800/80">
            {filteredDocs.map((doc) => {
              const folderStyle = AiClassifierService.getFolderStyle(doc.folder || 'Reports & Notes');
              return (
                <div
                  key={doc.id}
                  id={`library-doc-row-${doc.id}`}
                  onClick={() => onOpenDocument(doc)}
                  className="p-4 sm:p-5 hover:bg-slate-50/80 dark:hover:bg-slate-850/60 flex flex-col sm:flex-row sm:items-center justify-between gap-3 transition-colors cursor-pointer group"
                >
                  <div className="flex items-start sm:items-center gap-3.5 min-w-0">
                    <div className="p-3 bg-blue-50 dark:bg-blue-950/50 text-blue-600 dark:text-blue-400 rounded-xl group-hover:bg-blue-600 group-hover:text-white transition-colors shrink-0">
                      <FileText className="w-5 h-5" />
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <h4 className="font-bold text-sm text-slate-900 dark:text-white truncate group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors max-w-[260px] sm:max-w-md">
                          {doc.fileName}
                        </h4>

                        {/* Folder Badge */}
                        <span className={`px-2 py-0.5 rounded-lg font-bold text-[10px] flex items-center gap-1 border ${folderStyle.bg} ${folderStyle.text} ${folderStyle.border} shrink-0`}>
                          <Folder className="w-2.5 h-2.5" />
                          <span>{doc.folder || 'Reports & Notes'}</span>
                        </span>

                        {doc.ocrProcessed && (
                          <span 
                            className="px-2 py-0.5 rounded-full bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300 text-[10px] font-bold border border-emerald-200 dark:border-emerald-800 flex items-center gap-1 shrink-0"
                            title={`OCR Converted: ${doc.ocrWordCount || 0} words recognized`}
                          >
                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                            <span>Searchable</span>
                          </span>
                        )}
                      </div>

                      {/* Smart Tags Chips */}
                      <div className="flex items-center gap-1.5 flex-wrap mt-1.5">
                        {doc.tags?.map((tag) => (
                          <button
                            key={tag}
                            type="button"
                            onClick={(e) => {
                              e.stopPropagation();
                              setSelectedTag(tag);
                            }}
                            className={`px-2.5 py-0.5 rounded-lg text-[10px] font-semibold border transition-all cursor-pointer ${
                              selectedTag === tag
                                ? 'bg-blue-600 text-white border-blue-600 shadow-2xs'
                                : 'bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-300 border-slate-200/80 dark:border-slate-700 hover:bg-slate-200 dark:hover:bg-slate-750'
                            }`}
                          >
                            {tag}
                          </button>
                        ))}
                        {doc.aiCategoryConfidence && (
                          <span className="text-[10px] text-slate-400 font-medium ml-1">
                            ({doc.aiCategoryConfidence}% confidence)
                          </span>
                        )}
                      </div>

                      {searchQuery && doc.searchableText && doc.searchableText.toLowerCase().includes(searchQuery.toLowerCase()) && (
                        <p className="text-[11px] text-blue-600 dark:text-blue-400 truncate mt-1 font-medium">
                          Matched OCR text: &quot;...{doc.searchableText.slice(Math.max(0, doc.searchableText.toLowerCase().indexOf(searchQuery.toLowerCase()) - 20), doc.searchableText.toLowerCase().indexOf(searchQuery.toLowerCase()) + 60)}...&quot;
                        </p>
                      )}
                    </div>
                  </div>

                  <div className="flex items-center justify-between sm:justify-end gap-3 shrink-0 pt-2 sm:pt-0 border-t sm:border-t-0 border-slate-100 dark:border-slate-800">
                    <div className="text-left sm:text-right text-xs text-slate-500 dark:text-slate-400">
                      <div className="font-semibold text-slate-700 dark:text-slate-200">
                        {doc.pageCount ? `${doc.pageCount} Pages` : '1 Page'} &bull; {doc.fileSize}
                      </div>
                      <div className="text-slate-400 flex items-center gap-1 justify-start sm:justify-end mt-0.5">
                        <Clock className="w-3 h-3" />
                        {new Date(doc.lastOpenedDate).toLocaleDateString()}
                      </div>
                    </div>

                    <div className="flex items-center gap-1" onClick={(e) => e.stopPropagation()}>
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation();
                          setAutoTagDoc(doc);
                          setIsAutoTagModalOpen(true);
                        }}
                        className="p-2.5 text-indigo-600 hover:text-indigo-800 hover:bg-indigo-50 dark:text-indigo-400 dark:hover:bg-slate-800 rounded-xl min-h-[44px] min-w-[44px] flex items-center justify-center transition-colors cursor-pointer"
                        title="Review AI tags and folder classification"
                      >
                        <Sparkles className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        onClick={(e) => handleShare(e, doc)}
                        className="p-2.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 dark:hover:bg-slate-800 rounded-xl min-h-[44px] min-w-[44px] flex items-center justify-center transition-colors cursor-pointer"
                        title="Share PDF via Android Share Sheet"
                      >
                        <Share2 className="w-4 h-4" />
                      </button>
                      <button
                        type="button"
                        onClick={(e) => handleDelete(e, doc.id)}
                        className="p-2.5 text-slate-400 hover:text-red-600 hover:bg-red-50 dark:hover:bg-slate-800 rounded-xl min-h-[44px] min-w-[44px] flex items-center justify-center transition-colors cursor-pointer"
                        title="Delete"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                      <div 
                        onClick={() => onOpenDocument(doc)}
                        className="p-2.5 text-blue-600 dark:text-blue-400 hover:bg-blue-50 dark:hover:bg-slate-800 rounded-xl min-h-[44px] min-w-[44px] flex items-center justify-center cursor-pointer transition-colors"
                        title="Open in Editor"
                      >
                        <ExternalLink className="w-4 h-4" />
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

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
    </div>
  );
};

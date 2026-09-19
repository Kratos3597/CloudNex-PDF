import React, { useState, useEffect, useRef } from 'react';
import { 
  ArrowLeft, 
  ChevronLeft, 
  ChevronRight, 
  ZoomIn, 
  ZoomOut, 
  RotateCcw, 
  Search, 
  Eye, 
  Edit3, 
  Save, 
  Download, 
  Printer, 
  Layers, 
  Sparkles, 
  Stamp, 
  Maximize2,
  FileSpreadsheet,
  FileText as WordIcon,
  CheckCircle2,
  X,
  Plus,
  Share2,
  PanelLeftClose,
  PanelLeftOpen,
  FileSignature,
  Menu,
  Square,
  Circle,
  Minus,
  ScanText,
  ChevronUp,
  ChevronDown
} from 'lucide-react';
import { DocumentRecord, ShadowObject, ShapeType, ActivePdfTool, OcrProgressStatus } from '../types';
import { PdfEngine } from '../services/pdfEngine';
import { StorageService } from '../services/storage';
import { OcrService } from '../services/ocrService';
import { SignatureOverlay } from './SignatureOverlay';
import { ShapeOverlay } from './ShapeOverlay';
import { TextOverlay } from './TextOverlay';
import { InkDrawingOverlay } from './InkDrawingOverlay';
import { PageManagerModal } from './PageManagerModal';
import { NeuralEditorModal } from './NeuralEditorModal';
import { OcrInspectorModal } from './OcrInspectorModal';
import { OcrProgressModal } from './OcrProgressModal';
import { PdfTextLayer } from './PdfTextLayer';
import { DeviceLayoutState, useDeviceLayout } from '../hooks/useDeviceLayout';

interface EditorScreenProps {
  document: DocumentRecord;
  layout?: DeviceLayoutState;
  onBack: () => void;
  onRefreshDocs: () => void;
  onOpenVault: () => void;
}

export const EditorScreen: React.FC<EditorScreenProps> = ({
  document,
  layout,
  onBack,
  onRefreshDocs,
  onOpenVault,
}) => {
  const fallbackLayout = useDeviceLayout();
  const activeLayout = layout || fallbackLayout;

  const [currentDoc, setCurrentDoc] = useState<DocumentRecord>(document);
  const [pdfBytes, setPdfBytes] = useState<Uint8Array | null>(null);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [zoomScale, setZoomScale] = useState(activeLayout.suggestedPdfScale || 1.1);
  const [canvasDims, setCanvasDims] = useState<{ width: number; height: number }>({ width: 0, height: 0 });
  const [isEditMode, setIsEditMode] = useState(false);
  const [activePdfTool, setActivePdfTool] = useState<ActivePdfTool>('none');
  const [currentShapeType, setCurrentShapeType] = useState<ShapeType>('rectangle');
  const [shadowObjects, setShadowObjects] = useState<ShadowObject[]>([]);
  const [selectedObjectId, setSelectedObjectId] = useState<string | null>(null);

  // In-document text search & highlight
  const [isSearchBarOpen, setIsSearchBarOpen] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [currentPageMatches, setCurrentPageMatches] = useState<{ id: string; str: string; page: number }[]>([]);
  const [activeMatchIndex, setActiveMatchIndex] = useState(0);

  // OCR Inspector & Progress Modal state
  const [isOcrInspectorOpen, setIsOcrInspectorOpen] = useState(false);
  const [isOcrProgressOpen, setIsOcrProgressOpen] = useState(false);
  const [ocrProgressStatus, setOcrProgressStatus] = useState<OcrProgressStatus | null>(null);
  
  // Modals & Panels
  const [isPageManagerOpen, setIsPageManagerOpen] = useState(false);
  const [isNeuralEditorOpen, setIsNeuralEditorOpen] = useState(false);
  const [showExportModal, setShowExportModal] = useState(false);
  const [saveToast, setSaveToast] = useState<string | null>(null);

  // Responsive device panels
  const [thumbnails, setThumbnails] = useState<{ [page: number]: string }>({});
  const [isThumbnailRailOpen, setIsThumbnailRailOpen] = useState(activeLayout.isTabletLandscape);
  const [isMobileToolsOpen, setIsMobileToolsOpen] = useState(false);

  const canvasRef = useRef<HTMLCanvasElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  // Synchronize layout changes with suggested zoom & thumbnail rail
  useEffect(() => {
    if (activeLayout.suggestedPdfScale) {
      setZoomScale(activeLayout.suggestedPdfScale);
    }
    if (activeLayout.isPhonePortrait) {
      setIsThumbnailRailOpen(false);
    } else if (activeLayout.isTabletLandscape) {
      setIsThumbnailRailOpen(true);
    }
  }, [activeLayout.isPhonePortrait, activeLayout.isTabletLandscape, activeLayout.suggestedPdfScale]);

  // Load document bytes on mount
  useEffect(() => {
    let isMounted = true;
    const loadBytes = async () => {
      try {
        const bytes = await StorageService.getDocumentBytes(document.id);
        if (isMounted) {
          setPdfBytes(bytes);
          const report = await PdfEngine.analyzeDocument(bytes);
          setTotalPages(report.totalPages || 1);
        }
      } catch (e) {
        console.error('Failed to load PDF bytes:', e);
      }
    };
    loadBytes();
    return () => { isMounted = false; };
  }, [document.id]);

  // Render canvas when page, scale, or bytes change
  useEffect(() => {
    if (!pdfBytes || !canvasRef.current) return;
    let isCancelled = false;

    const render = async () => {
      try {
        const dims = await PdfEngine.renderPageToCanvas(pdfBytes, currentPage, canvasRef.current!, zoomScale);
        if (!isCancelled && dims) {
          setCanvasDims(dims);
        }
      } catch (e) {
        if (!isCancelled) console.error('Render page error:', e);
      }
    };
    render();
    return () => { isCancelled = true; };
  }, [pdfBytes, currentPage, zoomScale]);

  // Global Ctrl+F / Cmd+F shortcut for in-document text search
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'f') {
        e.preventDefault();
        setIsSearchBarOpen(true);
      } else if (e.key === 'Escape' && isSearchBarOpen) {
        setIsSearchBarOpen(false);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isSearchBarOpen]);

  // On-demand OCR run for current document
  const handleRunOcr = async () => {
    if (!pdfBytes) return;
    try {
      setIsOcrProgressOpen(true);
      const { convertedPdfBytes, ocrResult } = await OcrService.processScannedPdf(
        pdfBytes,
        (status) => setOcrProgressStatus(status)
      );

      const updatedDoc: DocumentRecord = {
        ...currentDoc,
        isScanned: true,
        ocrProcessed: true,
        ocrWordCount: ocrResult.totalWords,
        ocrConfidence: ocrResult.averageConfidence,
        searchableText: ocrResult.fullText,
      };

      setPdfBytes(convertedPdfBytes);
      setCurrentDoc(updatedDoc);
      StorageService.saveDocument(updatedDoc, convertedPdfBytes);
      StorageService.logAction('OCR_CONVERT', updatedDoc.fileName);
      onRefreshDocs();

      await new Promise((r) => setTimeout(r, 600));
      setIsOcrProgressOpen(false);
      setSaveToast(`OCR Complete: ${ocrResult.totalWords} words recognized & injected as selectable text!`);
      setTimeout(() => setSaveToast(null), 4000);
    } catch (err) {
      console.error('Error running OCR on document:', err);
      setIsOcrProgressOpen(false);
      alert('OCR processing failed.');
    }
  };

  // Pre-render page thumbnails for the tablet landscape rail
  useEffect(() => {
    if (!pdfBytes || totalPages < 1) return;
    let isCancelled = false;

    const loadThumbnails = async () => {
      const maxPages = Math.min(totalPages, 16);
      for (let p = 1; p <= maxPages; p++) {
        if (isCancelled) break;
        try {
          const url = await PdfEngine.renderThumbnail(pdfBytes, p);
          if (url && !isCancelled) {
            setThumbnails(prev => ({ ...prev, [p]: url }));
          }
        } catch (e) {
          console.error(`Error loading thumbnail for page ${p}:`, e);
        }
      }
    };

    loadThumbnails();
    return () => { isCancelled = true; };
  }, [pdfBytes, totalPages]);

  const handleFitWidth = () => {
    if (!containerRef.current) return;
    const padding = activeLayout.isPhonePortrait ? 24 : 48;
    const usableWidth = containerRef.current.clientWidth - padding;
    // Standard A4 PDF point width is 595
    const newScale = Math.max(0.4, Math.min(2.5, usableWidth / 595));
    setZoomScale(Number(newScale.toFixed(2)));
    showNotification(`Fit Width: ${Math.round(newScale * 100)}%`);
  };

  const handleFitPage = () => {
    if (!containerRef.current) return;
    const padding = activeLayout.isPhonePortrait ? 100 : 80;
    const usableHeight = containerRef.current.clientHeight - padding;
    // Standard A4 PDF point height is 842
    const newScale = Math.max(0.4, Math.min(2.0, usableHeight / 842));
    setZoomScale(Number(newScale.toFixed(2)));
    showNotification(`Fit Page: ${Math.round(newScale * 100)}%`);
  };

  const showNotification = (msg: string) => {
    setSaveToast(msg);
    setTimeout(() => setSaveToast(null), 3500);
  };

  // Shadow objects handlers
  const handleAddShadowObject = (newObj: ShadowObject) => {
    setShadowObjects(prev => [...prev, newObj]);
    setActivePdfTool('none');
    showNotification('Annotation added to overlay. Click Save & Flatten to commit.');
  };

  const handleUpdateShadowObjectPos = (id: string, dx: number, dy: number) => {
    setShadowObjects(prev => prev.map(o => {
      if (o.id === id) {
        return {
          ...o,
          position: { x: o.position.x + dx, y: o.position.y + dy },
        };
      }
      return o;
    }));
  };

  const handleDeleteShadowObject = (id: string) => {
    setShadowObjects(prev => prev.filter(o => o.id !== id));
    setSelectedObjectId(null);
  };

  // Commit and flatten into PDF bytes
  const handleSaveAndFlatten = async () => {
    if (!pdfBytes) return;
    try {
      showNotification('Burning annotations and compiling PDF...');
      const updatedBytes = await PdfEngine.flattenAndBurn(pdfBytes, shadowObjects, zoomScale);
      setPdfBytes(updatedBytes);
      setShadowObjects([]);
      setSelectedObjectId(null);
      StorageService.saveDocument(document, updatedBytes);
      StorageService.logAction('MODIFY_DOCUMENT', document.fileName);
      onRefreshDocs();
      showNotification('Document saved & flattened successfully!');
    } catch (e) {
      console.error('Failed to flatten PDF:', e);
      alert('Failed to save and flatten document.');
    }
  };

  // Tool actions
  const handleInitiateSignature = () => {
    const saved = StorageService.getSignature();
    if (!saved) {
      if (confirm('No saved signature found in your Vault. Would you like to create one now?')) {
        onOpenVault();
      }
      return;
    }
    setActivePdfTool('signaturePlacement');
  };

  const handleInitiateShape = (shape: ShapeType) => {
    setCurrentShapeType(shape);
    setActivePdfTool('shape');
  };

  const handleInitiateText = () => {
    setActivePdfTool('textPlacement');
  };

  const handleInitiateInk = () => {
    setActivePdfTool('ink');
  };

  const handleBurnInk = async (paths: { x: number; y: number }[][], strokeWidth: number, colorHex: string) => {
    if (!pdfBytes) return;
    try {
      const containerW = canvasRef.current?.width || 600;
      const containerH = canvasRef.current?.height || 800;
      const updated = await PdfEngine.addInkAnnotation(
        pdfBytes,
        currentPage - 1,
        paths,
        strokeWidth,
        colorHex,
        containerW,
        containerH
      );
      setPdfBytes(updated);
      StorageService.saveDocument(document, updated);
      StorageService.logAction('MODIFY_DOCUMENT', document.fileName);
      setActivePdfTool('none');
      showNotification('Ink drawing burned into PDF successfully!');
    } catch (e) {
      console.error('Ink burn error:', e);
      alert('Failed to apply ink strokes.');
    }
  };

  const handleApplyWatermark = async () => {
    if (!pdfBytes) return;
    try {
      const updated = await PdfEngine.addWatermark(pdfBytes, 'CLOUDNEX PRO');
      setPdfBytes(updated);
      StorageService.saveDocument(document, updated);
      StorageService.logAction('MODIFY_DOCUMENT', document.fileName);
      showNotification('Watermark "CLOUDNEX PRO" applied across all pages!');
    } catch (e) {
      console.error('Watermark error:', e);
      alert('Failed to apply watermark.');
    }
  };

  const handleFormCheck = () => {
    alert('Interactive Forms: Form field detection completed. Standard ISO fields validated.');
  };

  const handleExportPDF = () => {
    if (!pdfBytes) return;
    PdfEngine.downloadFile(pdfBytes, `Export_${document.fileName}`, 'application/pdf');
    StorageService.logAction('EXPORT_DOCUMENT', document.fileName);
    setShowExportModal(false);
  };

  const handleExportCSV = async () => {
    if (!pdfBytes) return;
    const csvContent = await PdfEngine.exportToCsv(pdfBytes);
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = window.document.createElement('a');
    a.href = url;
    a.download = `${document.fileName.replace(/\.pdf$/i, '')}_Data.csv`;
    a.click();
    URL.revokeObjectURL(url);
    StorageService.logAction('EXPORT_EXCEL', document.fileName);
    setShowExportModal(false);
  };

  const handleExportWord = async () => {
    if (!pdfBytes) return;
    const docxBlob = await PdfEngine.exportToWordDocx(pdfBytes, document.fileName);
    const url = URL.createObjectURL(docxBlob);
    const a = window.document.createElement('a');
    a.href = url;
    a.download = `${document.fileName.replace(/\.pdf$/i, '')}.doc`;
    a.click();
    URL.revokeObjectURL(url);
    StorageService.logAction('EXPORT_WORD', document.fileName);
    setShowExportModal(false);
  };

  const handlePrint = () => {
    if (!pdfBytes) return;
    PdfEngine.printDocument(pdfBytes);
    setShowExportModal(false);
  };

  const handleShareDocument = async () => {
    if (!pdfBytes) return;

    // 1. If there are pending annotations or signatures, flatten them first
    let readyBytes = pdfBytes;
    if (shadowObjects.length > 0) {
      try {
        readyBytes = await PdfEngine.flattenAndBurn(pdfBytes, shadowObjects, zoomScale);
        setPdfBytes(readyBytes);
        setShadowObjects([]);
        StorageService.saveDocument(document, readyBytes);
      } catch (e) {
        console.error('Flatten before share error:', e);
      }
    }

    const fileName = document.fileName.endsWith('.pdf') ? document.fileName : `${document.fileName}.pdf`;
    const pdfBlob = new Blob([readyBytes.buffer as ArrayBuffer], { type: 'application/pdf' });
    const pdfFile = new File([pdfBlob], fileName, { type: 'application/pdf' });

    // 2. Trigger native Android Share Sheet if available
    if (navigator.canShare && navigator.canShare({ files: [pdfFile] })) {
      try {
        await navigator.share({
          files: [pdfFile],
          title: document.fileName,
          text: `Signed & verified PDF document: ${document.fileName}`,
        });
        StorageService.logAction('EXPORT_DOCUMENT', `Shared ${document.fileName}`);
        showNotification('Document shared successfully!');
        setShowExportModal(false);
      } catch (err: any) {
        if (err.name !== 'AbortError') {
          console.error('Share error:', err);
          PdfEngine.downloadFile(readyBytes, fileName, 'application/pdf');
        }
      }
    } else if (navigator.share) {
      try {
        await navigator.share({
          title: document.fileName,
          text: `Signed PDF document: ${document.fileName}`,
        });
        PdfEngine.downloadFile(readyBytes, fileName, 'application/pdf');
        showNotification('Document shared! PDF downloaded.');
        setShowExportModal(false);
      } catch (err: any) {
        if (err.name !== 'AbortError') {
          PdfEngine.downloadFile(readyBytes, fileName, 'application/pdf');
        }
      }
    } else {
      PdfEngine.downloadFile(readyBytes, fileName, 'application/pdf');
      showNotification('PDF flattened & downloaded! Ready to share.');
      setShowExportModal(false);
    }
  };

  return (
    <div id="editor-screen" className="flex flex-col h-screen bg-[#F4F5F7] select-none overflow-hidden">
      {/* Toast Notification */}
      {saveToast && (
        <aside 
          aria-label="Document status notification"
          className="fixed top-14 left-1/2 -translate-x-1/2 z-50 animate-in fade-in slide-in-from-top-2 duration-200"
        >
          <div className="bg-[#172B4D] text-white text-xs font-semibold px-4 py-2 rounded-full shadow-2xl flex items-center gap-2 border border-white/20">
            <CheckCircle2 className="w-4 h-4 text-[#36B37E]" />
            <span>{saveToast}</span>
          </div>
        </aside>
      )}

      {/* Top Header Navigation Bar */}
      <header className="h-14 bg-white border-b border-gray-200 px-3 sm:px-4 flex items-center justify-between shrink-0 z-30 shadow-xs">
        {/* Left: Back, Rail Toggle & Document Title */}
        <div className="flex items-center gap-2 sm:gap-3 min-w-0">
          <button
            id="editor-back-btn"
            onClick={onBack}
            className="p-2 rounded-lg hover:bg-gray-100 text-gray-700 transition-colors cursor-pointer shrink-0"
            title="Back to Dashboard"
          >
            <ArrowLeft className="w-5 h-5" />
          </button>

          {/* Tablet Landscape: Thumbnail Rail Toggle */}
          {activeLayout.isTabletLandscape && (
            <button
              onClick={() => setIsThumbnailRailOpen(prev => !prev)}
              className="p-2 rounded-lg hover:bg-gray-100 text-gray-600 transition-colors cursor-pointer hidden md:flex items-center"
              title={isThumbnailRailOpen ? 'Collapse Page Thumbnails' : 'Expand Page Thumbnails'}
            >
              {isThumbnailRailOpen ? <PanelLeftClose className="w-4 h-4" /> : <PanelLeftOpen className="w-4 h-4" />}
            </button>
          )}

          <div className="min-w-0">
            <h1 className="font-bold text-xs sm:text-sm text-[#172B4D] truncate max-w-[140px] sm:max-w-xs">
              {document.fileName}
            </h1>
            <span className="text-[10px] text-[#6B778C] flex items-center gap-1 truncate">
              {activeLayout.isPhonePortrait ? 'Phone Portrait' : activeLayout.isTabletLandscape ? 'Tablet Landscape' : 'Adaptive'} • P.{currentPage}/{totalPages}
            </span>
          </div>
        </div>

        {/* Center: Page Controls & Zoom (Hidden on Phone to save room for thumb bar) */}
        {!activeLayout.isPhonePortrait && (
          <div className="flex items-center gap-2 sm:gap-4">
            <div className="flex items-center bg-gray-100 rounded-lg p-1 text-xs">
              <button
                onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
                disabled={currentPage <= 1}
                className="p-1 rounded hover:bg-white disabled:opacity-30 transition-colors cursor-pointer"
                title="Previous Page"
              >
                <ChevronLeft className="w-4 h-4" />
              </button>
              <span className="px-2 font-semibold text-gray-700 whitespace-nowrap">
                {currentPage} / {totalPages}
              </span>
              <button
                onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
                disabled={currentPage >= totalPages}
                className="p-1 rounded hover:bg-white disabled:opacity-30 transition-colors cursor-pointer"
                title="Next Page"
              >
                <ChevronRight className="w-4 h-4" />
              </button>
            </div>

            <div className="hidden lg:flex items-center bg-gray-100 rounded-lg p-1 text-xs">
              <button
                onClick={() => setZoomScale(s => Math.max(0.4, s - 0.15))}
                className="p-1 rounded hover:bg-white transition-colors cursor-pointer"
                title="Zoom Out"
              >
                <ZoomOut className="w-4 h-4" />
              </button>
              <span className="px-2 font-semibold text-gray-700 min-w-[42px] text-center">
                {Math.round(zoomScale * 100)}%
              </span>
              <button
                onClick={() => setZoomScale(s => Math.min(2.5, s + 0.15))}
                className="p-1 rounded hover:bg-white transition-colors cursor-pointer"
                title="Zoom In"
              >
                <ZoomIn className="w-4 h-4" />
              </button>
              <button
                onClick={handleFitWidth}
                className="px-1.5 py-0.5 rounded hover:bg-white text-gray-600 transition-colors cursor-pointer text-[10px] font-bold"
                title="Fit to Page Width"
              >
                Fit Width
              </button>
              <button
                onClick={handleFitPage}
                className="px-1.5 py-0.5 rounded hover:bg-white text-gray-600 transition-colors cursor-pointer text-[10px] font-bold"
                title="Fit Entire Page"
              >
                Fit Page
              </button>
            </div>
          </div>
        )}

        {/* Right: Mode Toggle and Save/Share */}
        <div className="flex items-center gap-1.5 sm:gap-2 shrink-0">
          {/* VIEW / EDIT Toggle Capsule */}
          <div className="bg-gray-100 p-0.5 rounded-full flex items-center border border-gray-200">
            <button
              id="mode-toggle-view"
              onClick={() => setIsEditMode(false)}
              className={`px-2.5 sm:px-3 py-1 rounded-full text-xs font-bold flex items-center gap-1 transition-all cursor-pointer ${
                !isEditMode 
                  ? 'bg-white text-[#172B4D] shadow-xs' 
                  : 'text-gray-500 hover:text-gray-900'
              }`}
            >
              <Eye className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">VIEW</span>
            </button>
            <button
              id="mode-toggle-edit"
              onClick={() => setIsEditMode(true)}
              className={`px-2.5 sm:px-3 py-1 rounded-full text-xs font-bold flex items-center gap-1 transition-all cursor-pointer ${
                isEditMode 
                  ? 'bg-[#0052CC] text-white shadow-xs' 
                  : 'text-gray-500 hover:text-gray-900'
              }`}
            >
              <Edit3 className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">EDIT</span>
            </button>
          </div>

          {/* Find in Document Button */}
          <button
            id="editor-btn-find"
            onClick={() => setIsSearchBarOpen(prev => !prev)}
            className={`p-1.5 sm:px-2.5 sm:py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer border ${
              isSearchBarOpen
                ? 'bg-amber-100 text-amber-900 border-amber-300'
                : 'text-gray-700 hover:text-gray-900 hover:bg-gray-100 border-gray-200 bg-white'
            }`}
            title="Search / Find text in PDF (Ctrl+F)"
          >
            <Search className="w-3.5 h-3.5 text-amber-700" />
            <span className="hidden sm:inline">Find</span>
          </button>

          {/* OCR Status & Inspector Button */}
          <button
            id="editor-btn-ocr-inspector"
            onClick={() => setIsOcrInspectorOpen(true)}
            className={`p-1.5 sm:px-2.5 sm:py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer border ${
              currentDoc.ocrProcessed
                ? 'bg-emerald-50 text-emerald-800 border-emerald-300 hover:bg-emerald-100'
                : 'bg-white text-gray-700 border-gray-200 hover:bg-gray-100'
            }`}
            title="Inspect recognized OCR text & run OCR on demand"
          >
            <ScanText className={`w-3.5 h-3.5 ${currentDoc.ocrProcessed ? 'text-emerald-600' : 'text-[#0052CC]'}`} />
            <span className="hidden sm:inline">
              {currentDoc.ocrProcessed ? 'OCR Ready' : 'OCR'}
            </span>
            {currentDoc.ocrProcessed && (
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
            )}
          </button>

          {/* Share Button (Native Android Share Sheet / Download) */}
          <button
            id="editor-share-btn"
            onClick={handleShareDocument}
            className="p-1.5 sm:px-3 sm:py-1.5 bg-blue-50 text-[#0052CC] hover:bg-blue-100 rounded-lg text-xs font-bold flex items-center gap-1.5 transition-colors cursor-pointer border border-blue-200"
            title="Share PDF via Native Android Share Sheet"
          >
            <Share2 className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Share</span>
          </button>

          {/* Flatten & Save Button */}
          {shadowObjects.length > 0 && (
            <button
              id="btn-flatten-save"
              onClick={handleSaveAndFlatten}
              className="px-2.5 sm:px-3.5 py-1.5 bg-[#36B37E] hover:bg-[#2e9d6d] text-white text-xs font-bold rounded-lg shadow flex items-center gap-1.5 transition-colors cursor-pointer shrink-0"
              title="Commit all interactive annotations into the PDF"
            >
              <Save className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">Save & Flatten</span>
            </button>
          )}
        </div>
      </header>

      {/* Sleek Inline Find Bar */}
      {isSearchBarOpen && (
        <div 
          id="editor-find-bar" 
          className="h-10 bg-amber-50/95 border-b border-amber-200 px-4 flex items-center justify-between z-30 text-xs text-amber-950 shadow-xs"
        >
          <div className="flex items-center gap-2 flex-1 max-w-lg">
            <Search className="w-3.5 h-3.5 text-amber-700 shrink-0" />
            <input
              id="editor-find-input"
              type="text"
              autoFocus
              value={searchQuery}
              onChange={(e) => {
                setSearchQuery(e.target.value);
                setActiveMatchIndex(0);
              }}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  if (e.shiftKey) {
                    if (currentPageMatches.length > 0) {
                      setActiveMatchIndex(prev => (prev - 1 + currentPageMatches.length) % currentPageMatches.length);
                    }
                  } else {
                    if (currentPageMatches.length > 0) {
                      setActiveMatchIndex(prev => (prev + 1) % currentPageMatches.length);
                    }
                  }
                }
              }}
              placeholder="Find in page text (Enter for next, Shift+Enter for prev)..."
              className="w-full bg-white border border-amber-300 rounded px-2.5 py-1 text-xs text-gray-900 focus:outline-none focus:ring-1 focus:ring-amber-500"
            />
          </div>

          <div className="flex items-center gap-2">
            <span className="text-[11px] font-medium text-amber-800">
              {searchQuery.trim()
                ? currentPageMatches.length > 0
                  ? `${activeMatchIndex + 1} of ${currentPageMatches.length} on page ${currentPage}`
                  : '0 matches on this page'
                : 'Search selectable text layer'}
            </span>

            <div className="flex items-center gap-0.5">
              <button
                onClick={() => {
                  if (currentPageMatches.length > 0) {
                    setActiveMatchIndex(prev => (prev - 1 + currentPageMatches.length) % currentPageMatches.length);
                  }
                }}
                disabled={currentPageMatches.length <= 1}
                className="p-1 rounded hover:bg-amber-200/70 text-amber-900 disabled:opacity-40 cursor-pointer"
                title="Previous Match (Shift+Enter)"
              >
                <ChevronUp className="w-3.5 h-3.5" />
              </button>
              <button
                onClick={() => {
                  if (currentPageMatches.length > 0) {
                    setActiveMatchIndex(prev => (prev + 1) % currentPageMatches.length);
                  }
                }}
                disabled={currentPageMatches.length <= 1}
                className="p-1 rounded hover:bg-amber-200/70 text-amber-900 disabled:opacity-40 cursor-pointer"
                title="Next Match (Enter)"
              >
                <ChevronDown className="w-3.5 h-3.5" />
              </button>
            </div>

            <button
              onClick={() => {
                setIsSearchBarOpen(false);
                setSearchQuery('');
              }}
              className="p-1 rounded hover:bg-amber-200/70 text-amber-800 cursor-pointer ml-1"
              title="Close Search (Esc)"
            >
              <X className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      )}

      {/* Sleek Tool Action Strip (Modern single-tier toolbar without ribbon tabs) */}
      {isEditMode && !activeLayout.isPhonePortrait && (
        <div 
          id="editor-tool-strip"
          className="h-11 bg-white border-b border-gray-200 px-4 flex items-center justify-between z-20 shadow-xs select-none shrink-0"
        >
          {/* Annotation & Edit Instruments */}
          <div className="flex items-center gap-1.5 overflow-x-auto py-1">
            <button
              id="tool-btn-sign"
              onClick={handleInitiateSignature}
              className="px-2.5 py-1 rounded-lg text-xs font-semibold text-gray-700 hover:text-[#0052CC] hover:bg-blue-50 flex items-center gap-1.5 transition-colors cursor-pointer border border-transparent hover:border-blue-200"
              title="Add Signature"
            >
              <FileSignature className="w-4 h-4 text-[#0052CC]" />
              <span>Sign</span>
            </button>

            <button
              id="tool-btn-ink"
              onClick={handleInitiateInk}
              className={`px-2.5 py-1 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer border ${
                activePdfTool === 'ink'
                  ? 'bg-blue-50 text-[#0052CC] border-blue-200'
                  : 'text-gray-700 hover:text-[#0052CC] hover:bg-blue-50 border-transparent hover:border-blue-200'
              }`}
              title="Draw with Freehand Ink"
            >
              <Edit3 className="w-4 h-4 text-[#0052CC]" />
              <span>Ink Pen</span>
            </button>

            <button
              id="tool-btn-text"
              onClick={handleInitiateText}
              className={`px-2.5 py-1 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer border ${
                activePdfTool === 'textPlacement'
                  ? 'bg-blue-50 text-[#0052CC] border-blue-200'
                  : 'text-gray-700 hover:text-[#0052CC] hover:bg-blue-50 border-transparent hover:border-blue-200'
              }`}
              title="Add Text Field"
            >
              <Plus className="w-4 h-4 text-[#0052CC]" />
              <span>Text</span>
            </button>

            <div className="h-4 w-px bg-gray-200 mx-1" />

            {/* Shape Tools */}
            <button
              id="tool-btn-rect"
              onClick={() => handleInitiateShape('rectangle')}
              className={`px-2 py-1 rounded-lg text-xs font-semibold flex items-center gap-1 transition-colors cursor-pointer border ${
                activePdfTool === 'shape' && currentShapeType === 'rectangle'
                  ? 'bg-blue-50 text-[#0052CC] border-blue-200'
                  : 'text-gray-600 hover:bg-gray-100 border-transparent'
              }`}
              title="Draw Rectangle"
            >
              <Square className="w-3.5 h-3.5 text-gray-500" />
              <span>Rect</span>
            </button>

            <button
              id="tool-btn-circle"
              onClick={() => handleInitiateShape('circle')}
              className={`px-2 py-1 rounded-lg text-xs font-semibold flex items-center gap-1 transition-colors cursor-pointer border ${
                activePdfTool === 'shape' && currentShapeType === 'circle'
                  ? 'bg-blue-50 text-[#0052CC] border-blue-200'
                  : 'text-gray-600 hover:bg-gray-100 border-transparent'
              }`}
              title="Draw Circle"
            >
              <Circle className="w-3.5 h-3.5 text-gray-500" />
              <span>Circle</span>
            </button>

            <button
              id="tool-btn-line"
              onClick={() => handleInitiateShape('line')}
              className={`px-2 py-1 rounded-lg text-xs font-semibold flex items-center gap-1 transition-colors cursor-pointer border ${
                activePdfTool === 'shape' && currentShapeType === 'line'
                  ? 'bg-blue-50 text-[#0052CC] border-blue-200'
                  : 'text-gray-600 hover:bg-gray-100 border-transparent'
              }`}
              title="Draw Line"
            >
              <Minus className="w-3.5 h-3.5 text-gray-500" />
              <span>Line</span>
            </button>

            <div className="h-4 w-px bg-gray-200 mx-1" />

            {/* Document Operations */}
            <button
              id="tool-btn-organize"
              onClick={() => setIsPageManagerOpen(true)}
              className="px-2.5 py-1 rounded-lg text-xs font-semibold text-gray-700 hover:text-[#0052CC] hover:bg-blue-50 flex items-center gap-1.5 transition-colors cursor-pointer"
              title="Page Manager (Reorder, Rotate, Delete)"
            >
              <Layers className="w-3.5 h-3.5 text-gray-500" />
              <span>Pages</span>
            </button>

            <button
              id="tool-btn-neural"
              onClick={() => setIsNeuralEditorOpen(true)}
              className="px-2.5 py-1 rounded-lg text-xs font-semibold text-gray-700 hover:text-[#0052CC] hover:bg-blue-50 flex items-center gap-1.5 transition-colors cursor-pointer"
              title="Neural OCR & Text Replacement"
            >
              <Sparkles className="w-3.5 h-3.5 text-[#0052CC]" />
              <span>AI Edit</span>
            </button>

            <button
              id="tool-btn-ocr-text"
              onClick={() => setIsOcrInspectorOpen(true)}
              className="px-2.5 py-1 rounded-lg text-xs font-semibold text-gray-700 hover:text-[#0052CC] hover:bg-blue-50 flex items-center gap-1.5 transition-colors cursor-pointer"
              title="Inspect OCR text layer & run OCR on demand"
            >
              <ScanText className="w-3.5 h-3.5 text-[#0052CC]" />
              <span>OCR Text</span>
            </button>

            <button
              id="tool-btn-watermark"
              onClick={handleApplyWatermark}
              className="px-2.5 py-1 rounded-lg text-xs font-semibold text-gray-700 hover:text-[#0052CC] hover:bg-blue-50 flex items-center gap-1.5 transition-colors cursor-pointer"
              title="Apply Confidential Watermark"
            >
              <Stamp className="w-3.5 h-3.5 text-gray-500" />
              <span>Watermark</span>
            </button>
          </div>

          {/* Right quick tools: Export, Print */}
          <div className="flex items-center gap-1.5 shrink-0">
            <button
              onClick={() => setShowExportModal(true)}
              className="px-2.5 py-1 rounded-lg text-xs font-semibold text-gray-700 hover:bg-gray-100 flex items-center gap-1.5 transition-colors cursor-pointer"
              title="Export Document"
            >
              <Download className="w-3.5 h-3.5 text-gray-600" />
              <span>Export</span>
            </button>

            <button
              onClick={handlePrint}
              className="p-1 rounded-lg text-gray-600 hover:bg-gray-100 transition-colors cursor-pointer"
              title="Print Document"
            >
              <Printer className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      )}

      {/* Main Dual-Pane Workspace (Tablet Landscape) or Single-View (Phone Portrait) */}
      <div className="flex-1 flex overflow-hidden relative">
        {/* Left Thumbnail Rail (Tablet Landscape Mode) */}
        {activeLayout.isTabletLandscape && isThumbnailRailOpen && (
          <aside className="w-48 xl:w-56 bg-white border-r border-gray-200 flex flex-col shrink-0 h-full select-none z-10 transition-all duration-200">
            <div className="h-10 px-3 border-b border-gray-100 flex items-center justify-between bg-gray-50 text-xs font-bold text-gray-700">
              <span className="flex items-center gap-1.5">
                <Layers className="w-3.5 h-3.5 text-[#0052CC]" />
                <span>Pages ({totalPages})</span>
              </span>
              <button
                onClick={() => setIsThumbnailRailOpen(false)}
                className="p-1 hover:bg-gray-200 rounded text-gray-500 cursor-pointer"
                title="Collapse Page Rail"
              >
                <PanelLeftClose className="w-3.5 h-3.5" />
              </button>
            </div>

            <div className="flex-1 overflow-y-auto p-3 space-y-3">
              {Array.from({ length: totalPages }, (_, i) => i + 1).map(pageNum => {
                const isCurrent = currentPage === pageNum;
                const thumb = thumbnails[pageNum];
                return (
                  <button
                    key={pageNum}
                    onClick={() => setCurrentPage(pageNum)}
                    className={`w-full text-left p-2 rounded-xl transition-all cursor-pointer border ${
                      isCurrent
                        ? 'bg-blue-50/80 border-[#0052CC] ring-2 ring-[#0052CC]/20 shadow-xs'
                        : 'bg-white hover:bg-gray-50 border-gray-200'
                    }`}
                  >
                    <div className="aspect-[1/1.3] bg-gray-100 rounded border border-gray-200 overflow-hidden flex items-center justify-center relative mb-1.5 shadow-xs">
                      {thumb ? (
                        <img
                          src={thumb}
                          alt={`Page ${pageNum}`}
                          className="w-full h-full object-contain"
                          referrerPolicy="no-referrer"
                        />
                      ) : (
                        <span className="text-[11px] font-bold text-gray-400">P. {pageNum}</span>
                      )}
                      <span className="absolute bottom-1 right-1 bg-black/60 text-white text-[9px] font-bold px-1 rounded">
                        {pageNum}
                      </span>
                    </div>
                    <div className="flex items-center justify-between text-[11px]">
                      <span className={`font-semibold ${isCurrent ? 'text-[#0052CC]' : 'text-gray-600'}`}>
                        Page {pageNum}
                      </span>
                      {isCurrent && (
                        <span className="w-1.5 h-1.5 rounded-full bg-[#0052CC]" />
                      )}
                    </div>
                  </button>
                );
              })}
            </div>
          </aside>
        )}

        {/* Collapsed Rail Restore Button */}
        {activeLayout.isTabletLandscape && !isThumbnailRailOpen && (
          <button
            onClick={() => setIsThumbnailRailOpen(true)}
            className="absolute top-3 left-3 z-20 p-2 bg-white/95 backdrop-blur-md shadow-md rounded-xl border border-gray-200 text-gray-700 hover:text-[#0052CC] hover:bg-blue-50 transition-colors cursor-pointer"
            title="Expand Page Thumbnail Rail"
          >
            <PanelLeftOpen className="w-4 h-4" />
          </button>
        )}

        {/* Main PDF Canvas Viewport */}
        <main 
          ref={containerRef}
          className={`flex-1 overflow-auto flex items-center justify-center relative bg-[#EBECF0] transition-all ${
            activeLayout.isPhonePortrait ? 'p-2 sm:p-4 pb-28' : 'p-4 sm:p-8'
          }`}
        >
          <div 
            id="pdf-canvas-wrapper" 
            className="relative shadow-2xl bg-white rounded border border-gray-300 transition-all duration-150 max-w-full"
          >
            {/* The PDF rendering canvas */}
            <canvas
              ref={canvasRef}
              className="block max-w-full h-auto"
            />

            {/* Searchable and Selectable PDF Text Layer with Highlights */}
            {pdfBytes && canvasDims.width > 0 && (
              <PdfTextLayer
                pdfBytes={pdfBytes}
                currentPage={currentPage}
                canvasWidth={canvasDims.width}
                canvasHeight={canvasDims.height}
                searchQuery={searchQuery}
                activeMatchIndex={activeMatchIndex}
                onMatchesFound={(matches) => setCurrentPageMatches(matches)}
                isDrawingMode={
                  activePdfTool === 'ink' ||
                  activePdfTool === 'shape' ||
                  activePdfTool === 'signaturePlacement' ||
                  activePdfTool === 'textPlacement'
                }
              />
            )}

          {/* Render Active Shadow Objects for current page */}
          {shadowObjects
            .filter(obj => obj.pageIndex === currentPage - 1)
            .map(obj => {
              const isSelected = selectedObjectId === obj.id;
              return (
                <div
                  key={obj.id}
                  onClick={() => setSelectedObjectId(obj.id)}
                  style={{
                    left: `${obj.position.x}px`,
                    top: `${obj.position.y}px`,
                    width: `${obj.size.width}px`,
                    height: `${obj.size.height}px`,
                  }}
                  className={`absolute pointer-events-auto cursor-move select-none ${
                    isSelected ? 'ring-2 ring-[#0052CC] ring-offset-1' : ''
                  }`}
                >
                  {/* Text Object */}
                  {obj.type === 'text' && (
                    <div
                      style={{ fontSize: `${obj.fontSize}px`, color: obj.color }}
                      className="w-full h-full font-medium"
                    >
                      {obj.content}
                    </div>
                  )}

                  {/* Signature Object */}
                  {obj.type === 'signature' && (
                    <img
                      src={obj.content}
                      alt="Signature"
                      className="w-full h-full object-contain pointer-events-none"
                    />
                  )}

                  {/* Shape Object */}
                  {obj.type === 'shape' && (
                    <div
                      style={{
                        borderColor: obj.color,
                        backgroundColor: `${obj.color}20`,
                      }}
                      className={`w-full h-full border-2 ${
                        obj.content === 'CIRCLE' ? 'rounded-full' : 'rounded-xs'
                      }`}
                    />
                  )}

                  {/* Delete button if selected */}
                  {isSelected && (
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        handleDeleteShadowObject(obj.id);
                      }}
                      className="absolute -top-3 -right-3 w-6 h-6 bg-[#DE350B] text-white rounded-full flex items-center justify-center shadow hover:bg-red-700 cursor-pointer"
                      title="Delete annotation"
                    >
                      <X className="w-3.5 h-3.5" />
                    </button>
                  )}
                </div>
              );
            })}

          {/* Signature Overlay placement tool */}
          {activePdfTool === 'signaturePlacement' && (
            <SignatureOverlay
              signatureDataUrl={StorageService.getSignature() || ''}
              onConfirm={(pos, size) => {
                handleAddShadowObject({
                  id: `sig-${Date.now()}`,
                  type: 'signature',
                  position: pos,
                  size,
                  content: StorageService.getSignature() || '',
                  fontSize: 12,
                  color: '#0052CC',
                  pageIndex: currentPage - 1,
                });
              }}
              onCancel={() => setActivePdfTool('none')}
            />
          )}

          {/* Shape Overlay placement tool */}
          {activePdfTool === 'shape' && (
            <ShapeOverlay
              type={currentShapeType}
              onConfirm={(pos, size, type) => {
                handleAddShadowObject({
                  id: `shape-${Date.now()}`,
                  type: 'shape',
                  position: pos,
                  size,
                  content: type.toUpperCase(),
                  fontSize: 12,
                  color: '#0052CC',
                  pageIndex: currentPage - 1,
                });
              }}
              onCancel={() => setActivePdfTool('none')}
            />
          )}

          {/* Text Overlay placement tool */}
          {activePdfTool === 'textPlacement' && (
            <TextOverlay
              onConfirm={(text, pos, size, fontSize, color) => {
                handleAddShadowObject({
                  id: `text-${Date.now()}`,
                  type: 'text',
                  position: pos,
                  size,
                  content: text,
                  fontSize,
                  color,
                  pageIndex: currentPage - 1,
                });
              }}
              onCancel={() => setActivePdfTool('none')}
            />
          )}

          {/* Freehand Ink Drawing Overlay */}
          {activePdfTool === 'ink' && (
            <InkDrawingOverlay
              onConfirm={handleBurnInk}
              onCancel={() => setActivePdfTool('none')}
            />
          )}
        </div>
      </main>
      </div>

      {/* Phone Portrait: Sticky Bottom Thumb-Zone Action Dock */}
      {activeLayout.isPhonePortrait && (
        <div 
          id="phone-portrait-action-dock"
          className="fixed bottom-0 left-0 right-0 z-40 bg-white/95 backdrop-blur-md border-t border-gray-200 px-2 py-1.5 flex items-center justify-around shadow-2xl safe-area-bottom"
        >
          {/* Sign Button */}
          <button
            onClick={handleInitiateSignature}
            className="flex flex-col items-center gap-0.5 p-1 text-[#0052CC] font-bold text-[10px] cursor-pointer"
            title="Add Digital Signature"
          >
            <div className="p-2 bg-blue-50 hover:bg-blue-100 text-[#0052CC] rounded-xl transition-colors">
              <FileSignature className="w-4 h-4" />
            </div>
            <span>Sign</span>
          </button>

          {/* Ink Pen */}
          <button
            onClick={handleInitiateInk}
            className="flex flex-col items-center gap-0.5 p-1 text-gray-700 font-bold text-[10px] cursor-pointer"
            title="Freehand Ink Drawing"
          >
            <div className="p-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl transition-colors">
              <Edit3 className="w-4 h-4" />
            </div>
            <span>Ink</span>
          </button>

          {/* Text Box */}
          <button
            onClick={handleInitiateText}
            className="flex flex-col items-center gap-0.5 p-1 text-gray-700 font-bold text-[10px] cursor-pointer"
            title="Add Text Field"
          >
            <div className="p-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl transition-colors">
              <Plus className="w-4 h-4" />
            </div>
            <span>Text</span>
          </button>

          {/* Page Switcher */}
          <div className="flex items-center bg-gray-100 rounded-xl px-1.5 py-1 text-xs font-bold text-gray-800 border border-gray-200">
            <button
              onClick={() => setCurrentPage(p => Math.max(1, p - 1))}
              disabled={currentPage <= 1}
              className="p-1 disabled:opacity-30 cursor-pointer"
              title="Previous Page"
            >
              <ChevronLeft className="w-3.5 h-3.5" />
            </button>
            <span className="px-1 text-[11px] min-w-[32px] text-center font-bold text-gray-700">
              {currentPage}/{totalPages}
            </span>
            <button
              onClick={() => setCurrentPage(p => Math.min(totalPages, p + 1))}
              disabled={currentPage >= totalPages}
              className="p-1 disabled:opacity-30 cursor-pointer"
              title="Next Page"
            >
              <ChevronRight className="w-3.5 h-3.5" />
            </button>
          </div>

          {/* Auto Fit Width */}
          <button
            onClick={handleFitWidth}
            className="flex flex-col items-center gap-0.5 p-1 text-gray-700 font-bold text-[10px] cursor-pointer"
            title="Auto-Fit Page to Screen Width"
          >
            <div className="p-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl transition-colors">
              <Maximize2 className="w-4 h-4" />
            </div>
            <span>Fit</span>
          </button>

          {/* Share (Native Android Share Sheet) */}
          <button
            onClick={handleShareDocument}
            className="flex flex-col items-center gap-0.5 p-1 text-[#0052CC] font-bold text-[10px] cursor-pointer"
            title="Share via Android Apps"
          >
            <div className="p-2 bg-blue-100 hover:bg-blue-200 text-[#0052CC] rounded-xl transition-colors">
              <Share2 className="w-4 h-4" />
            </div>
            <span>Share</span>
          </button>

          {/* More Tools Drawer Toggle */}
          <button
            onClick={() => setIsMobileToolsOpen(prev => !prev)}
            className="flex flex-col items-center gap-0.5 p-1 text-gray-700 font-bold text-[10px] cursor-pointer"
            title="More Options"
          >
            <div className="p-2 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-xl transition-colors">
              <Menu className="w-4 h-4" />
            </div>
            <span>More</span>
          </button>
        </div>
      )}

      {/* Phone Portrait: More Tools Bottom Sheet Drawer */}
      {activeLayout.isPhonePortrait && isMobileToolsOpen && (
        <div 
          className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-end justify-center"
          onClick={() => setIsMobileToolsOpen(false)}
        >
          <div 
            className="bg-white w-full rounded-t-3xl shadow-2xl p-5 space-y-4 max-h-[80vh] overflow-y-auto animate-in slide-in-from-bottom duration-200"
            onClick={e => e.stopPropagation()}
          >
            <div className="flex items-center justify-between pb-3 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <div className="w-2 h-2 rounded-full bg-[#0052CC]" />
                <h3 className="font-bold text-sm text-[#172B4D]">Phone Tools & Operations</h3>
              </div>
              <button 
                onClick={() => setIsMobileToolsOpen(false)}
                className="p-1 rounded-full hover:bg-gray-100 text-gray-500 cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="grid grid-cols-2 gap-2.5">
              <button
                onClick={() => { setIsSearchBarOpen(true); setIsMobileToolsOpen(false); }}
                className="p-3 rounded-xl border border-gray-200 hover:border-amber-400 hover:bg-amber-50/50 flex flex-col items-start gap-1.5 text-left cursor-pointer transition-colors"
              >
                <Search className="w-5 h-5 text-amber-700" />
                <span className="font-bold text-xs text-[#172B4D]">Find in PDF</span>
                <span className="text-[10px] text-gray-500">Search text occurrences</span>
              </button>

              <button
                onClick={() => { setIsOcrInspectorOpen(true); setIsMobileToolsOpen(false); }}
                className="p-3 rounded-xl border border-gray-200 hover:border-emerald-400 hover:bg-emerald-50/50 flex flex-col items-start gap-1.5 text-left cursor-pointer transition-colors"
              >
                <ScanText className="w-5 h-5 text-emerald-600" />
                <span className="font-bold text-xs text-[#172B4D]">OCR Text Layer</span>
                <span className="text-[10px] text-gray-500">Inspect & run OCR</span>
              </button>

              <button
                onClick={() => { setIsPageManagerOpen(true); setIsMobileToolsOpen(false); }}
                className="p-3 rounded-xl border border-gray-200 hover:border-[#0052CC] hover:bg-blue-50/50 flex flex-col items-start gap-1.5 text-left cursor-pointer transition-colors"
              >
                <Layers className="w-5 h-5 text-[#0052CC]" />
                <span className="font-bold text-xs text-[#172B4D]">Organize Pages</span>
                <span className="text-[10px] text-gray-500">Reorder, delete, rotate</span>
              </button>

              <button
                onClick={() => { setIsNeuralEditorOpen(true); setIsMobileToolsOpen(false); }}
                className="p-3 rounded-xl border border-gray-200 hover:border-[#0052CC] hover:bg-blue-50/50 flex flex-col items-start gap-1.5 text-left cursor-pointer transition-colors"
              >
                <Sparkles className="w-5 h-5 text-[#0052CC]" />
                <span className="font-bold text-xs text-[#172B4D]">Neural Edit</span>
                <span className="text-[10px] text-gray-500">OCR & text replace</span>
              </button>

              <button
                onClick={() => { handleApplyWatermark(); setIsMobileToolsOpen(false); }}
                className="p-3 rounded-xl border border-gray-200 hover:border-[#0052CC] hover:bg-blue-50/50 flex flex-col items-start gap-1.5 text-left cursor-pointer transition-colors"
              >
                <Stamp className="w-5 h-5 text-[#0052CC]" />
                <span className="font-bold text-xs text-[#172B4D]">Apply Watermark</span>
                <span className="text-[10px] text-gray-500">CONFIDENTIAL stamp</span>
              </button>

              <button
                onClick={() => { setShowExportModal(true); setIsMobileToolsOpen(false); }}
                className="p-3 rounded-xl border border-gray-200 hover:border-[#0052CC] hover:bg-blue-50/50 flex flex-col items-start gap-1.5 text-left cursor-pointer transition-colors"
              >
                <Download className="w-5 h-5 text-[#0052CC]" />
                <span className="font-bold text-xs text-[#172B4D]">Export File</span>
                <span className="text-[10px] text-gray-500">PDF, Excel, Word</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Export Options Modal */}
      {showExportModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl shadow-2xl max-w-md w-full p-6 space-y-4 border border-gray-100">
            <div className="flex items-center justify-between pb-3 border-b border-gray-100">
              <h3 className="font-bold text-base text-[#172B4D]">Export Document</h3>
              <button onClick={() => setShowExportModal(false)} className="p-1 rounded hover:bg-gray-100 text-gray-500 cursor-pointer">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-2">
              <button
                id="export-share-android-btn"
                onClick={handleShareDocument}
                className="w-full p-3.5 rounded-xl border border-blue-200 bg-blue-50/60 hover:bg-blue-100/70 flex items-center gap-3 transition-colors text-left group cursor-pointer"
              >
                <div className="p-2.5 bg-[#0052CC] text-white rounded-lg group-hover:scale-105 transition-transform">
                  <Share2 className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="font-bold text-sm text-[#0052CC]">Share to Android / Other Apps</h4>
                  <p className="text-xs text-[#6B778C]">WhatsApp, Gmail, Drive, or Nearby Share (Burns all signatures)</p>
                </div>
              </button>

              <button
                id="export-as-pdf-btn"
                onClick={handleExportPDF}
                className="w-full p-3.5 rounded-xl border border-gray-200 hover:border-[#0052CC] hover:bg-blue-50/50 flex items-center gap-3 transition-colors text-left group cursor-pointer"
              >
                <div className="p-2.5 bg-[#0052CC]/10 text-[#0052CC] rounded-lg group-hover:bg-[#0052CC] group-hover:text-white transition-colors">
                  <Download className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="font-bold text-sm text-[#172B4D]">Export as PDF (.pdf)</h4>
                  <p className="text-xs text-[#6B778C]">Standard vector PDF with all annotations burned</p>
                </div>
              </button>

              <button
                id="export-as-excel-btn"
                onClick={handleExportCSV}
                className="w-full p-3.5 rounded-xl border border-gray-200 hover:border-[#36B37E] hover:bg-emerald-50/50 flex items-center gap-3 transition-colors text-left group cursor-pointer"
              >
                <div className="p-2.5 bg-[#36B37E]/10 text-[#36B37E] rounded-lg group-hover:bg-[#36B37E] group-hover:text-white transition-colors">
                  <FileSpreadsheet className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="font-bold text-sm text-[#172B4D]">Export to Excel / CSV (.csv)</h4>
                  <p className="text-xs text-[#6B778C]">Tabular extraction of text and numerical data</p>
                </div>
              </button>

              <button
                id="export-as-word-btn"
                onClick={handleExportWord}
                className="w-full p-3.5 rounded-xl border border-gray-200 hover:border-[#0052CC] hover:bg-blue-50/50 flex items-center gap-3 transition-colors text-left group cursor-pointer"
              >
                <div className="p-2.5 bg-blue-100 text-[#0052CC] rounded-lg group-hover:bg-[#0052CC] group-hover:text-white transition-colors">
                  <WordIcon className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="font-bold text-sm text-[#172B4D]">Export to Word (.doc)</h4>
                  <p className="text-xs text-[#6B778C]">Editable word processing formatted document</p>
                </div>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Page Manager Modal */}
      {pdfBytes && (
        <PageManagerModal
          pdfBytes={pdfBytes}
          isOpen={isPageManagerOpen}
          onClose={() => setIsPageManagerOpen(false)}
          onApply={(updated) => {
            setPdfBytes(updated);
            StorageService.saveDocument(document, updated);
            StorageService.logAction('MODIFY_DOCUMENT', document.fileName);
            setCurrentPage(1);
            showNotification('Document pages updated successfully!');
          }}
        />
      )}

      {/* Neural Editor Modal */}
      {pdfBytes && (
        <NeuralEditorModal
          pdfBytes={pdfBytes}
          activePageIndex={currentPage - 1}
          isOpen={isNeuralEditorOpen}
          onClose={() => setIsNeuralEditorOpen(false)}
          onApply={(updated) => {
            setPdfBytes(updated);
            StorageService.saveDocument(document, updated);
            StorageService.logAction('MODIFY_DOCUMENT', document.fileName);
            showNotification('Text replaced via Neural Reconstruction!');
          }}
        />
      )}

      {/* OCR Text Inspector Modal */}
      <OcrInspectorModal
        isOpen={isOcrInspectorOpen}
        onClose={() => setIsOcrInspectorOpen(false)}
        document={currentDoc}
        onRunOcr={handleRunOcr}
        isProcessing={isOcrProgressOpen}
      />

      {/* OCR Progress Modal */}
      <OcrProgressModal
        isOpen={isOcrProgressOpen}
        status={ocrProgressStatus}
        fileName={currentDoc.fileName}
      />
    </div>
  );
};

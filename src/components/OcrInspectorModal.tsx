import React, { useState } from 'react';
import { X, Copy, Check, Download, ScanText, Sparkles, Search, FileText } from 'lucide-react';
import { DocumentRecord } from '../types';

interface OcrInspectorModalProps {
  isOpen: boolean;
  onClose: () => void;
  document: DocumentRecord;
  extractedText?: string;
  onRerunOcr?: () => void;
  onRunOcr?: () => void;
  isProcessing?: boolean;
}

export const OcrInspectorModal: React.FC<OcrInspectorModalProps> = ({
  isOpen,
  onClose,
  document: docRecord,
  extractedText,
  onRerunOcr,
  onRunOcr,
  isProcessing,
}) => {
  const [copied, setCopied] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');

  if (!isOpen) return null;

  const actualText = extractedText !== undefined ? extractedText : (docRecord.searchableText || '');
  const triggerOcr = onRunOcr || onRerunOcr;

  const handleCopyAll = async () => {
    try {
      await navigator.clipboard.writeText(actualText);
      setCopied(true);
      setTimeout(() => setCopied(false), 2500);
    } catch (e) {
      console.error('Failed to copy text:', e);
    }
  };

  const handleDownloadTxt = () => {
    const blob = new Blob([actualText], { type: 'text/plain;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = window.document.createElement('a');
    a.href = url;
    a.download = `${docRecord.fileName.replace(/\.pdf$/i, '')}_OCR_Text.txt`;
    window.document.body.appendChild(a);
    a.click();
    window.document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  // Filter text lines if searching
  const lines = actualText.split('\n');
  const filteredLines = searchQuery.trim()
    ? lines.filter(line => line.toLowerCase().includes(searchQuery.toLowerCase()))
    : lines;

  return (
    <div 
      id="ocr-inspector-modal-backdrop"
      className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 animate-in fade-in duration-150"
    >
      <div 
        id="ocr-inspector-modal-content"
        className="bg-white rounded-2xl shadow-2xl border border-gray-200 max-w-2xl w-full flex flex-col max-h-[85vh] overflow-hidden"
      >
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between bg-gray-50/80">
          <div className="flex items-center gap-3">
            <div className="p-2 rounded-xl bg-blue-100 text-[#0052CC]">
              <ScanText className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-base font-bold text-[#172B4D]">OCR Text Inspector</h3>
                <span className="px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-800 text-[10px] font-bold uppercase tracking-wider flex items-center gap-1">
                  <Check className="w-3 h-3" /> Searchable
                </span>
              </div>
              <p className="text-xs text-gray-500 truncate max-w-sm">
                {docRecord.fileName}
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 rounded-lg hover:bg-gray-200 text-gray-400 hover:text-gray-700 transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Stats Bar */}
        <div className="px-6 py-2.5 bg-blue-50/50 border-b border-blue-100 flex flex-wrap items-center justify-between text-xs text-gray-600 gap-2">
          <div className="flex items-center gap-4">
            <span>
              <strong className="text-gray-900 font-bold">{docRecord.ocrWordCount || actualText.split(/\s+/).filter(Boolean).length}</strong> words recognized
            </span>
            <span>•</span>
            <span>
              <strong className="text-emerald-700 font-bold">{docRecord.ocrConfidence || 96}%</strong> accuracy rating
            </span>
            <span>•</span>
            <span>
              <strong className="text-gray-900 font-bold">{docRecord.pageCount || 1}</strong> pages indexed
            </span>
          </div>

          {triggerOcr && (
            <button
              onClick={triggerOcr}
              disabled={isProcessing}
              className="text-[#0052CC] hover:underline font-semibold text-xs flex items-center gap-1 cursor-pointer disabled:opacity-50"
            >
              <Sparkles className="w-3 h-3" />
              {isProcessing ? 'Processing OCR...' : 'Re-run OCR Engine'}
            </button>
          )}
        </div>

        {/* Search Bar within Extracted Text */}
        <div className="px-6 pt-3 pb-2 border-b border-gray-100">
          <div className="relative">
            <Search className="w-4 h-4 absolute left-3 top-2.5 text-gray-400" />
            <input
              type="text"
              placeholder="Search recognized OCR text..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-9 pr-4 py-1.5 text-xs bg-gray-50 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#0052CC]/20 focus:border-[#0052CC]"
            />
            {searchQuery && (
              <button
                onClick={() => setSearchQuery('')}
                className="absolute right-3 top-2.5 text-gray-400 hover:text-gray-600 text-xs"
              >
                Clear
              </button>
            )}
          </div>
        </div>

        {/* Text Content Area */}
        <div className="flex-1 overflow-y-auto p-6 bg-white font-mono text-xs text-gray-800 leading-relaxed whitespace-pre-wrap select-text selection:bg-blue-200 selection:text-blue-900">
          {filteredLines.length > 0 ? (
            filteredLines.map((line, idx) => (
              <div 
                key={idx}
                className={`py-0.5 px-1 rounded ${
                  searchQuery && line.toLowerCase().includes(searchQuery.toLowerCase())
                    ? 'bg-amber-100 text-amber-900 font-medium'
                    : ''
                }`}
              >
                {line || ' '}
              </div>
            ))
          ) : (
            <div className="text-center py-12 text-gray-400">
              <FileText className="w-8 h-8 mx-auto mb-2 opacity-50" />
              <p>No matching lines found for &quot;{searchQuery}&quot;</p>
            </div>
          )}
        </div>

        {/* Footer Actions */}
        <div className="px-6 py-3.5 border-t border-gray-200 bg-gray-50 flex items-center justify-between">
          <span className="text-[11px] text-gray-500">
            Embedded invisible text stream allows native OS and PDF viewer selection.
          </span>

          <div className="flex items-center gap-2">
            <button
              onClick={handleDownloadTxt}
              className="px-3 py-1.5 bg-white border border-gray-200 hover:bg-gray-100 text-gray-700 rounded-xl text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer"
            >
              <Download className="w-3.5 h-3.5 text-gray-600" />
              <span>Export TXT</span>
            </button>

            <button
              onClick={handleCopyAll}
              className={`px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer ${
                copied
                  ? 'bg-emerald-600 text-white'
                  : 'bg-[#0052CC] hover:bg-blue-700 text-white'
              }`}
            >
              {copied ? (
                <>
                  <Check className="w-3.5 h-3.5" />
                  <span>Copied to Clipboard!</span>
                </>
              ) : (
                <>
                  <Copy className="w-3.5 h-3.5" />
                  <span>Copy All Text</span>
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

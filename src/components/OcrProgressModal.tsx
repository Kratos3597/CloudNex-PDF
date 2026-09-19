import React from 'react';
import { ScanText, Sparkles, CheckCircle2, AlertCircle } from 'lucide-react';
import { OcrProgressStatus } from '../types';

interface OcrProgressModalProps {
  isOpen: boolean;
  status: OcrProgressStatus | null;
  fileName: string;
}

export const OcrProgressModal: React.FC<OcrProgressModalProps> = ({
  isOpen,
  status,
  fileName,
}) => {
  if (!isOpen || !status) return null;

  return (
    <div 
      id="ocr-progress-modal-backdrop"
      className="fixed inset-0 z-50 bg-black/60 backdrop-blur-xs flex items-center justify-center p-4 animate-in fade-in duration-200"
    >
      <div 
        id="ocr-progress-modal-content"
        className="bg-white rounded-2xl shadow-2xl border border-gray-100 max-w-md w-full p-6 text-center space-y-5"
      >
        {/* Animated Scanner Radar / Laser Icon */}
        <div className="relative mx-auto w-20 h-20 rounded-2xl bg-blue-50 border border-blue-200 flex items-center justify-center overflow-hidden">
          {status.status === 'completed' ? (
            <CheckCircle2 className="w-10 h-10 text-emerald-600 animate-in zoom-in-75 duration-200" />
          ) : status.status === 'error' ? (
            <AlertCircle className="w-10 h-10 text-red-500" />
          ) : (
            <>
              <ScanText className="w-10 h-10 text-[#0052CC] relative z-10" />
              {/* Vertical scanning laser line */}
              <div className="absolute inset-x-0 h-1 bg-gradient-to-r from-transparent via-[#0052CC] to-transparent shadow-[0_0_8px_#0052CC] animate-bounce" />
            </>
          )}
        </div>

        {/* Title and Filename */}
        <div>
          <div className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full bg-blue-100 text-[#0052CC] text-[11px] font-bold uppercase tracking-wider mb-2">
            <Sparkles className="w-3.5 h-3.5" />
            Automated OCR Engine
          </div>
          <h3 className="text-lg font-bold text-[#172B4D]">
            {status.status === 'completed'
              ? 'OCR Conversion Finished!'
              : 'Converting Scanned PDF...'}
          </h3>
          <p className="text-xs text-gray-500 truncate max-w-xs mx-auto mt-1" title={fileName}>
            {fileName}
          </p>
        </div>

        {/* Status Message */}
        <div className="bg-gray-50 border border-gray-200/80 rounded-xl p-3 text-xs text-gray-700">
          <p className="font-medium">{status.message}</p>
          {status.detectedWordsCount !== undefined && status.detectedWordsCount > 0 && (
            <p className="text-[11px] text-blue-600 font-semibold mt-1">
              {status.detectedWordsCount} words recognized so far
            </p>
          )}
        </div>

        {/* Progress Bar */}
        <div className="space-y-1.5 text-left">
          <div className="flex justify-between text-[11px] font-semibold text-gray-600">
            <span>
              {status.totalPages > 0
                ? `Page ${status.currentPage || 1} of ${status.totalPages}`
                : 'Analyzing document...'}
            </span>
            <span>{Math.round(status.progress)}%</span>
          </div>
          <div className="w-full bg-gray-100 h-2.5 rounded-full overflow-hidden border border-gray-200">
            <div
              className="h-full bg-gradient-to-r from-[#0052CC] to-blue-500 rounded-full transition-all duration-300 ease-out"
              style={{ width: `${Math.max(5, Math.min(100, status.progress))}%` }}
            />
          </div>
        </div>

        {/* Informational Subtext */}
        <p className="text-[11px] text-gray-600 leading-relaxed">
          Raster image pixels are being converted into an embedded ISO 32000 searchable text stream with selectable coordinates.
        </p>
      </div>
    </div>
  );
};

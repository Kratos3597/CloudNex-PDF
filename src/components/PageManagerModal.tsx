import React, { useState, useEffect } from 'react';
import { 
  X, 
  ArrowUp, 
  ArrowDown, 
  RotateCw, 
  Trash2, 
  Check, 
  FileCheck2 
} from 'lucide-react';
import { PdfEngine } from '../services/pdfEngine';

interface PageManagerModalProps {
  pdfBytes: Uint8Array;
  isOpen: boolean;
  onClose: () => void;
  onApply: (newPdfBytes: Uint8Array) => void;
}

interface PageItem {
  originalIndex: number;
  thumbnailUrl: string;
  rotation: number;
}

export const PageManagerModal: React.FC<PageManagerModalProps> = ({
  pdfBytes,
  isOpen,
  onClose,
  onApply,
}) => {
  const [pages, setPages] = useState<PageItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [hasChanges, setHasChanges] = useState(false);

  useEffect(() => {
    if (!isOpen) return;

    const loadThumbnails = async () => {
      setLoading(true);
      try {
        const report = await PdfEngine.analyzeDocument(pdfBytes);
        const items: PageItem[] = [];

        for (let i = 1; i <= report.totalPages; i++) {
          const thumb = await PdfEngine.renderThumbnail(pdfBytes, i);
          items.push({
            originalIndex: i - 1,
            thumbnailUrl: thumb,
            rotation: 0,
          });
        }
        setPages(items);
      } catch (e) {
        console.error('Error loading page thumbnails:', e);
      } finally {
        setLoading(false);
      }
    };

    loadThumbnails();
  }, [isOpen, pdfBytes]);

  if (!isOpen) return null;

  const handleMoveUp = (index: number) => {
    if (index === 0) return;
    const next = [...pages];
    const temp = next[index];
    next[index] = next[index - 1];
    next[index - 1] = temp;
    setPages(next);
    setHasChanges(true);
  };

  const handleMoveDown = (index: number) => {
    if (index === pages.length - 1) return;
    const next = [...pages];
    const temp = next[index];
    next[index] = next[index + 1];
    next[index + 1] = temp;
    setPages(next);
    setHasChanges(true);
  };

  const handleDelete = (index: number) => {
    if (pages.length <= 1) {
      alert('A document must have at least one page.');
      return;
    }
    setPages(pages.filter((_, i) => i !== index));
    setHasChanges(true);
  };

  const handleRotate = (index: number) => {
    const next = [...pages];
    next[index] = {
      ...next[index],
      rotation: (next[index].rotation + 90) % 360,
    };
    setPages(next);
    setHasChanges(true);
  };

  const handleApply = async () => {
    setLoading(true);
    try {
      // 1. Reorder pages according to pages list
      const order = pages.map(p => p.originalIndex);
      let updatedBytes = await PdfEngine.reorderPages(pdfBytes, order);

      // 2. Apply any rotations
      for (let i = 0; i < pages.length; i++) {
        if (pages[i].rotation > 0) {
          const rotationsCount = (pages[i].rotation / 90) % 4;
          for (let r = 0; r < rotationsCount; r++) {
            updatedBytes = await PdfEngine.rotatePage(updatedBytes, i);
          }
        }
      }

      onApply(updatedBytes);
      onClose();
    } catch (e) {
      console.error('Failed to apply page operations:', e);
      alert('Failed to reorder/update pages.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div 
      id="page-manager-modal" 
      className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4"
    >
      <div className="bg-white rounded-2xl shadow-2xl max-w-4xl w-full max-h-[85vh] flex flex-col overflow-hidden border border-gray-100">
        {/* Modal Header */}
        <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between bg-[#F4F5F7]">
          <div className="flex items-center gap-2">
            <FileCheck2 className="w-5 h-5 text-[#0052CC]" />
            <h2 className="font-bold text-[#172B4D] text-base">Page Manager</h2>
            <span className="text-xs text-[#6B778C] font-medium bg-gray-200 px-2 py-0.5 rounded-full">
              {pages.length} Pages
            </span>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 rounded-lg hover:bg-gray-200 text-gray-500 cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6 overflow-y-auto flex-1 bg-gray-50">
          {loading ? (
            <div className="flex flex-col items-center justify-center py-20 gap-3 text-gray-500">
              <div className="w-8 h-8 border-3 border-[#0052CC] border-t-transparent rounded-full animate-spin" />
              <p className="text-sm font-medium">Processing page thumbnails...</p>
            </div>
          ) : (
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
              {pages.map((page, index) => (
                <div
                  key={`${page.originalIndex}-${index}`}
                  className="bg-white rounded-xl border border-gray-200 shadow-sm p-3 flex flex-col items-center gap-2 relative group hover:border-[#0052CC] transition-all"
                >
                  {/* Page index badge */}
                  <span className="absolute top-2 left-2 bg-[#172B4D] text-white text-[10px] font-bold px-1.5 py-0.5 rounded shadow">
                    Page {index + 1}
                  </span>

                  {/* Thumbnail */}
                  <div className="w-full h-44 bg-gray-100 rounded flex items-center justify-center overflow-hidden border border-gray-100 mt-4">
                    {page.thumbnailUrl ? (
                      <img
                        src={page.thumbnailUrl}
                        alt={`Page ${index + 1}`}
                        style={{ transform: `rotate(${page.rotation}deg)` }}
                        className="max-w-full max-h-full object-contain transition-transform duration-200"
                      />
                    ) : (
                      <span className="text-xs text-gray-400">Preview</span>
                    )}
                  </div>

                  {/* Actions bar */}
                  <div className="flex items-center justify-between w-full mt-1 pt-2 border-t border-gray-100 text-gray-600">
                    <button
                      onClick={() => handleMoveUp(index)}
                      disabled={index === 0}
                      className="p-1 rounded hover:bg-gray-100 disabled:opacity-30 cursor-pointer"
                      title="Move Left/Up"
                    >
                      <ArrowUp className="w-4 h-4" />
                    </button>

                    <button
                      onClick={() => handleRotate(index)}
                      className="p-1 rounded hover:bg-gray-100 text-[#0052CC] cursor-pointer"
                      title="Rotate 90°"
                    >
                      <RotateCw className="w-4 h-4" />
                    </button>

                    <button
                      onClick={() => handleDelete(index)}
                      className="p-1 rounded hover:bg-red-50 text-[#DE350B] cursor-pointer"
                      title="Delete Page"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>

                    <button
                      onClick={() => handleMoveDown(index)}
                      disabled={index === pages.length - 1}
                      className="p-1 rounded hover:bg-gray-100 disabled:opacity-30 cursor-pointer"
                      title="Move Right/Down"
                    >
                      <ArrowDown className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Modal Footer */}
        <div className="px-6 py-3 border-t border-gray-200 flex items-center justify-between bg-white">
          <p className="text-xs text-gray-500">
            Reorder, rotate, or remove pages before finalizing document structure.
          </p>

          <div className="flex items-center gap-3">
            <button
              onClick={onClose}
              className="px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-lg transition-colors cursor-pointer"
            >
              Cancel
            </button>
            <button
              id="apply-page-order-btn"
              onClick={handleApply}
              disabled={loading || !hasChanges}
              className="px-5 py-2 text-sm font-bold text-white bg-[#0052CC] hover:bg-[#0040A0] rounded-lg shadow flex items-center gap-1.5 disabled:opacity-50 transition-colors cursor-pointer"
            >
              <Check className="w-4 h-4" />
              <span>Apply Changes</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

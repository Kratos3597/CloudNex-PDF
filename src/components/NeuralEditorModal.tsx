import React, { useState } from 'react';
import { X, Sparkles, Check, Type } from 'lucide-react';
import { NeuralZone } from '../types';
import { PdfEngine } from '../services/pdfEngine';

interface NeuralEditorModalProps {
  pdfBytes: Uint8Array;
  activePageIndex: number;
  isOpen: boolean;
  onClose: () => void;
  onApply: (newPdfBytes: Uint8Array) => void;
}

export const NeuralEditorModal: React.FC<NeuralEditorModalProps> = ({
  pdfBytes,
  activePageIndex,
  isOpen,
  onClose,
  onApply,
}) => {
  const zones = PdfEngine.scanPageZones(595, 841);
  const [selectedZone, setSelectedZone] = useState<NeuralZone>(zones[0]);
  const [textValue, setTextValue] = useState(zones[0].originalText);
  const [fontSize, setFontSize] = useState(zones[0].fontSize);
  const [loading, setLoading] = useState(false);

  if (!isOpen) return null;

  const handleZoneSelect = (z: NeuralZone) => {
    setSelectedZone(z);
    setTextValue(z.originalText);
    setFontSize(z.fontSize);
  };

  const handleApplyReconstruction = async () => {
    setLoading(true);
    try {
      const updated = await PdfEngine.neuralReconstruction(
        pdfBytes,
        activePageIndex,
        selectedZone.bounds,
        textValue,
        fontSize
      );
      onApply(updated);
      onClose();
    } catch (e) {
      console.error('Neural reconstruction failed:', e);
      alert('Failed to replace text in document.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div 
      id="neural-editor-modal"
      className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4"
    >
      <div className="bg-white rounded-2xl shadow-2xl max-w-xl w-full flex flex-col overflow-hidden border border-gray-100">
        {/* Header */}
        <div className="px-6 py-4 border-b border-gray-200 flex items-center justify-between bg-[#F4F5F7]">
          <div className="flex items-center gap-2">
            <Sparkles className="w-5 h-5 text-[#0052CC]" />
            <div>
              <h2 className="font-bold text-[#172B4D] text-base">Neural Editor</h2>
              <p className="text-[11px] text-[#6B778C]">OCR Text Block Reconstruction Engine</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg hover:bg-gray-200 text-gray-500 cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-4">
          <div>
            <label className="text-xs font-bold uppercase tracking-wider text-gray-500 mb-1.5 block">
              Select Detected Text Zone:
            </label>
            <div className="space-y-2">
              {zones.map((zone) => (
                <button
                  key={zone.id}
                  onClick={() => handleZoneSelect(zone)}
                  className={`w-full text-left p-3 rounded-lg border text-xs transition-all cursor-pointer ${
                    selectedZone.id === zone.id
                      ? 'border-[#0052CC] bg-[#0052CC]/5 text-[#172B4D] ring-1 ring-[#0052CC]'
                      : 'border-gray-200 hover:border-gray-300 text-gray-600 bg-white'
                  }`}
                >
                  <div className="flex items-center justify-between mb-1">
                    <span className="font-bold uppercase tracking-wider text-[10px] text-[#0052CC]">
                      Zone: {zone.label}
                    </span>
                    <span className="text-gray-400 text-[10px]">
                      {Math.round(zone.bounds.width)}x{Math.round(zone.bounds.height)}px
                    </span>
                  </div>
                  <p className="truncate font-medium text-gray-800">{zone.originalText}</p>
                </button>
              ))}
            </div>
          </div>

          <div>
            <div className="flex items-center justify-between mb-1.5">
              <label className="text-xs font-bold uppercase tracking-wider text-gray-500 block">
                Replacement Text:
              </label>
              <div className="flex items-center gap-2 text-xs text-gray-500">
                <Type className="w-3.5 h-3.5" />
                <span>Font Size:</span>
                <input
                  type="number"
                  value={fontSize}
                  onChange={(e) => setFontSize(Number(e.target.value))}
                  min={8}
                  max={36}
                  className="w-12 border border-gray-200 rounded px-1 text-center font-bold text-gray-800"
                />
                <span>pt</span>
              </div>
            </div>
            <textarea
              value={textValue}
              onChange={(e) => setTextValue(e.target.value)}
              rows={3}
              className="w-full border border-gray-200 rounded-lg p-3 text-sm focus:border-[#0052CC] focus:ring-1 focus:ring-[#0052CC] outline-none"
              placeholder="Enter replacement text..."
            />
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-3 border-t border-gray-200 flex items-center justify-end gap-3 bg-gray-50">
          <button
            onClick={onClose}
            className="px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-200 rounded-lg transition-colors cursor-pointer"
          >
            Cancel
          </button>
          <button
            id="apply-neural-btn"
            onClick={handleApplyReconstruction}
            disabled={loading}
            className="px-5 py-2 text-sm font-bold text-white bg-[#0052CC] hover:bg-[#0040A0] rounded-lg shadow flex items-center gap-1.5 disabled:opacity-50 transition-colors cursor-pointer"
          >
            <Check className="w-4 h-4" />
            <span>Reconstruct Text</span>
          </button>
        </div>
      </div>
    </div>
  );
};

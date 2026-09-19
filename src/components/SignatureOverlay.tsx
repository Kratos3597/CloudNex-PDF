import React, { useState, useRef } from 'react';
import { Check, X, Maximize2 } from 'lucide-react';

interface SignatureOverlayProps {
  signatureDataUrl: string;
  onConfirm: (position: { x: number; y: number }, size: { width: number; height: number }) => void;
  onCancel: () => void;
}

export const SignatureOverlay: React.FC<SignatureOverlayProps> = ({
  signatureDataUrl,
  onConfirm,
  onCancel,
}) => {
  const [position, setPosition] = useState({ x: 120, y: 180 });
  const [size, setSize] = useState({ width: 160, height: 80 });
  const isDragging = useRef(false);
  const isResizing = useRef(false);
  const dragStart = useRef({ x: 0, y: 0, posX: 0, posY: 0, width: 0, height: 0 });

  const handlePointerDown = (e: React.PointerEvent) => {
    isDragging.current = true;
    dragStart.current = {
      x: e.clientX,
      y: e.clientY,
      posX: position.x,
      posY: position.y,
      width: size.width,
      height: size.height,
    };
    (e.target as HTMLElement).setPointerCapture(e.pointerId);
  };

  const handleResizeDown = (e: React.PointerEvent) => {
    e.stopPropagation();
    isResizing.current = true;
    dragStart.current = {
      x: e.clientX,
      y: e.clientY,
      posX: position.x,
      posY: position.y,
      width: size.width,
      height: size.height,
    };
    (e.target as HTMLElement).setPointerCapture(e.pointerId);
  };

  const handlePointerMove = (e: React.PointerEvent) => {
    if (isDragging.current) {
      const dx = e.clientX - dragStart.current.x;
      const dy = e.clientY - dragStart.current.y;
      setPosition({
        x: Math.max(0, dragStart.current.posX + dx),
        y: Math.max(0, dragStart.current.posY + dy),
      });
    } else if (isResizing.current) {
      const dx = e.clientX - dragStart.current.x;
      const dy = e.clientY - dragStart.current.y;
      setSize({
        width: Math.max(60, Math.min(400, dragStart.current.width + dx)),
        height: Math.max(30, Math.min(250, dragStart.current.height + dy)),
      });
    }
  };

  const handlePointerUp = (e: React.PointerEvent) => {
    isDragging.current = false;
    isResizing.current = false;
    try {
      (e.target as HTMLElement).releasePointerCapture(e.pointerId);
    } catch {}
  };

  return (
    <div 
      id="signature-overlay-container" 
      className="absolute inset-0 pointer-events-auto z-40 select-none overflow-hidden"
    >
      {/* Draggable Box */}
      <div
        id="signature-draggable-box"
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={handlePointerUp}
        style={{
          left: `${position.x}px`,
          top: `${position.y}px`,
          width: `${size.width}px`,
          height: `${size.height}px`,
        }}
        className="absolute border-2 border-dashed border-[#0052CC] bg-[#0052CC]/10 cursor-move rounded p-1 flex items-center justify-center group"
      >
        <img
          src={signatureDataUrl}
          alt="Signature"
          className="w-full h-full object-contain pointer-events-none"
        />

        {/* Resize Handle */}
        <div
          onPointerDown={handleResizeDown}
          onPointerMove={handlePointerMove}
          onPointerUp={handlePointerUp}
          className="absolute -right-2 -bottom-2 w-5 h-5 bg-[#0052CC] text-white rounded-full flex items-center justify-center cursor-se-resize shadow-md"
        >
          <Maximize2 className="w-3 h-3" />
        </div>
      </div>

      {/* Action Controls Toolbar at Bottom */}
      <div className="absolute bottom-16 left-1/2 -translate-x-1/2 flex items-center gap-3 bg-white/95 backdrop-blur-md px-4 py-2 rounded-full shadow-xl border border-gray-200">
        <button
          id="cancel-signature-btn"
          onClick={onCancel}
          className="p-2 rounded-full hover:bg-red-50 text-[#DE350B] transition-colors cursor-pointer"
          title="Cancel"
        >
          <X className="w-5 h-5" />
        </button>

        <button
          id="confirm-signature-btn"
          onClick={() => onConfirm(position, size)}
          className="px-4 py-1.5 bg-[#0052CC] text-white text-xs font-bold rounded-full hover:bg-[#0040A0] transition-colors flex items-center gap-1.5 shadow cursor-pointer"
        >
          <Check className="w-4 h-4" />
          <span>PLACE SIGNATURE</span>
        </button>
      </div>
    </div>
  );
};

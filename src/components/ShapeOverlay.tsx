import React, { useState, useRef } from 'react';
import { Check, X, Maximize2 } from 'lucide-react';
import { ShapeType } from '../types';

interface ShapeOverlayProps {
  type: ShapeType;
  onConfirm: (position: { x: number; y: number }, size: { width: number; height: number }, type: ShapeType) => void;
  onCancel: () => void;
}

export const ShapeOverlay: React.FC<ShapeOverlayProps> = ({
  type,
  onConfirm,
  onCancel,
}) => {
  const [position, setPosition] = useState({ x: 140, y: 160 });
  const [size, setSize] = useState({ width: 140, height: 90 });
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
        width: Math.max(30, Math.min(500, dragStart.current.width + dx)),
        height: Math.max(10, Math.min(400, dragStart.current.height + dy)),
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
      id="shape-overlay-container" 
      className="absolute inset-0 pointer-events-auto z-40 select-none overflow-hidden"
    >
      <div
        id="shape-draggable-box"
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={handlePointerUp}
        style={{
          left: `${position.x}px`,
          top: `${position.y}px`,
          width: `${size.width}px`,
          height: `${size.height}px`,
        }}
        className={`absolute cursor-move flex items-center justify-center ${
          type === 'circle' 
            ? 'rounded-full border-2 border-[#0052CC] bg-[#0052CC]/15' 
            : type === 'rectangle'
            ? 'rounded-md border-2 border-[#0052CC] bg-[#0052CC]/15'
            : 'border-b-2 border-[#0052CC]'
        }`}
      >
        {type === 'line' && (
          <div className="w-full h-0.5 bg-[#0052CC]" />
        )}

        <div
          onPointerDown={handleResizeDown}
          onPointerMove={handlePointerMove}
          onPointerUp={handlePointerUp}
          className="absolute -right-2 -bottom-2 w-5 h-5 bg-[#0052CC] text-white rounded-full flex items-center justify-center cursor-se-resize shadow"
        >
          <Maximize2 className="w-3 h-3" />
        </div>
      </div>

      <div className="absolute bottom-16 left-1/2 -translate-x-1/2 flex items-center gap-3 bg-white/95 backdrop-blur-md px-4 py-2 rounded-full shadow-xl border border-gray-200">
        <button
          id="cancel-shape-btn"
          onClick={onCancel}
          className="p-2 rounded-full hover:bg-red-50 text-[#DE350B] transition-colors cursor-pointer"
        >
          <X className="w-5 h-5" />
        </button>

        <button
          id="confirm-shape-btn"
          onClick={() => onConfirm(position, size, type)}
          className="px-4 py-1.5 bg-[#0052CC] text-white text-xs font-bold rounded-full hover:bg-[#0040A0] transition-colors flex items-center gap-1.5 shadow cursor-pointer uppercase"
        >
          <Check className="w-4 h-4" />
          <span>PLACE {type}</span>
        </button>
      </div>
    </div>
  );
};

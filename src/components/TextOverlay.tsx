import React, { useState, useRef } from 'react';
import { Check, X, Plus, Minus, Maximize2 } from 'lucide-react';

interface TextOverlayProps {
  onConfirm: (
    text: string, 
    position: { x: number; y: number }, 
    size: { width: number; height: number }, 
    fontSize: number, 
    color: string
  ) => void;
  onCancel: () => void;
}

export const TextOverlay: React.FC<TextOverlayProps> = ({
  onConfirm,
  onCancel,
}) => {
  const [text, setText] = useState('New text annotation');
  const [fontSize, setFontSize] = useState(14);
  const [color, setColor] = useState('#000000');
  const [position, setPosition] = useState({ x: 120, y: 150 });
  const [size, setSize] = useState({ width: 220, height: 60 });

  const isDragging = useRef(false);
  const isResizing = useRef(false);
  const dragStart = useRef({ x: 0, y: 0, posX: 0, posY: 0, width: 0, height: 0 });

  const handlePointerDown = (e: React.PointerEvent) => {
    // Only drag when not interacting directly with text area
    if ((e.target as HTMLElement).tagName === 'TEXTAREA') return;
    isDragging.current = true;
    dragStart.current = {
      x: e.clientX,
      y: e.clientY,
      posX: position.x,
      posY: position.y,
      width: size.width,
      height: size.height,
    };
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
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
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
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
        width: Math.max(100, Math.min(500, dragStart.current.width + dx)),
        height: Math.max(40, Math.min(300, dragStart.current.height + dy)),
      });
    }
  };

  const handlePointerUp = (e: React.PointerEvent) => {
    isDragging.current = false;
    isResizing.current = false;
    try {
      (e.currentTarget as HTMLElement).releasePointerCapture(e.pointerId);
    } catch {}
  };

  const colors = ['#000000', '#DE350B', '#0052CC', '#36B37E', '#FFAB00'];

  return (
    <div 
      id="text-overlay-container" 
      className="absolute inset-0 pointer-events-auto z-40 select-none overflow-hidden"
    >
      <div
        id="text-draggable-box"
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={handlePointerUp}
        style={{
          left: `${position.x}px`,
          top: `${position.y}px`,
          width: `${size.width}px`,
          height: `${size.height}px`,
        }}
        className="absolute border border-[#0052CC] bg-white/95 rounded shadow-lg p-2 flex flex-col cursor-move"
      >
        <textarea
          id="text-annotation-input"
          value={text}
          onChange={e => setText(e.target.value)}
          style={{ fontSize: `${fontSize}px`, color }}
          className="w-full h-full bg-transparent resize-none outline-none font-medium leading-tight"
          placeholder="Type annotation text..."
          autoFocus
        />

        <div
          onPointerDown={handleResizeDown}
          onPointerMove={handlePointerMove}
          onPointerUp={handlePointerUp}
          className="absolute -right-2 -bottom-2 w-5 h-5 bg-[#0052CC] text-white rounded-full flex items-center justify-center cursor-se-resize shadow"
        >
          <Maximize2 className="w-3 h-3" />
        </div>
      </div>

      {/* Floating control toolbar above or at bottom */}
      <div className="absolute bottom-16 left-1/2 -translate-x-1/2 flex items-center gap-3 bg-white/95 backdrop-blur-md px-4 py-2 rounded-full shadow-xl border border-gray-200">
        {/* Font size adjustment */}
        <div className="flex items-center gap-1 bg-gray-100 px-2 py-1 rounded-full text-xs font-bold text-gray-700">
          <button 
            onClick={() => setFontSize(s => Math.max(9, s - 1))}
            className="p-0.5 hover:bg-gray-200 rounded cursor-pointer"
          >
            <Minus className="w-3 h-3" />
          </button>
          <span className="w-5 text-center">{fontSize}</span>
          <button 
            onClick={() => setFontSize(s => Math.min(48, s + 1))}
            className="p-0.5 hover:bg-gray-200 rounded cursor-pointer"
          >
            <Plus className="w-3 h-3" />
          </button>
        </div>

        {/* Color swatches */}
        <div className="flex items-center gap-1.5">
          {colors.map(c => (
            <button
              key={c}
              onClick={() => setColor(c)}
              style={{ backgroundColor: c }}
              className={`w-4 h-4 rounded-full transition-transform cursor-pointer ${
                color === c ? 'ring-2 ring-offset-1 ring-[#0052CC] scale-110' : ''
              }`}
            />
          ))}
        </div>

        <div className="h-4 w-[1px] bg-gray-200" />

        <button
          id="cancel-text-btn"
          onClick={onCancel}
          className="p-1.5 rounded-full hover:bg-red-50 text-[#DE350B] cursor-pointer"
        >
          <X className="w-4 h-4" />
        </button>

        <button
          id="confirm-text-btn"
          onClick={() => onConfirm(text, position, size, fontSize, color)}
          className="px-3 py-1 bg-[#0052CC] text-white text-xs font-bold rounded-full hover:bg-[#0040A0] flex items-center gap-1 shadow cursor-pointer"
        >
          <Check className="w-3.5 h-3.5" />
          <span>APPLY TEXT</span>
        </button>
      </div>
    </div>
  );
};

import React, { useState, useRef, useEffect } from 'react';
import { Edit2, Undo, Trash2, X, Check } from 'lucide-react';

interface InkDrawingOverlayProps {
  onConfirm: (paths: { x: number; y: number }[][], strokeWidth: number, colorHex: string) => void;
  onCancel: () => void;
}

export const InkDrawingOverlay: React.FC<InkDrawingOverlayProps> = ({
  onConfirm,
  onCancel,
}) => {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [paths, setPaths] = useState<{ x: number; y: number }[][]>([]);
  const [currentPath, setCurrentPath] = useState<{ x: number; y: number }[]>([]);
  const [isDrawing, setIsDrawing] = useState(false);
  const [strokeColor, setStrokeColor] = useState('#000000');
  const strokeWidth = 3;

  const redrawCanvas = (allPaths: { x: number; y: number }[][], activePath: { x: number; y: number }[]) => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.strokeStyle = strokeColor;
    ctx.lineWidth = strokeWidth;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    const drawLineList = (pts: { x: number; y: number }[]) => {
      if (pts.length === 0) return;
      ctx.beginPath();
      ctx.moveTo(pts[0].x, pts[0].y);
      for (let i = 1; i < pts.length; i++) {
        ctx.lineTo(pts[i].x, pts[i].y);
      }
      ctx.stroke();
    };

    allPaths.forEach(drawLineList);
    if (activePath.length > 0) {
      drawLineList(activePath);
    }
  };

  useEffect(() => {
    redrawCanvas(paths, currentPath);
  }, [paths, currentPath, strokeColor]);

  // Ensure canvas dimensions match parent container
  useEffect(() => {
    const canvas = canvasRef.current;
    if (canvas && canvas.parentElement) {
      canvas.width = canvas.parentElement.clientWidth;
      canvas.height = canvas.parentElement.clientHeight;
      redrawCanvas(paths, currentPath);
    }
  }, []);

  const handlePointerDown = (e: React.PointerEvent<HTMLCanvasElement>) => {
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    setIsDrawing(true);
    setCurrentPath([{ x, y }]);
    e.currentTarget.setPointerCapture(e.pointerId);
  };

  const handlePointerMove = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (!isDrawing) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    setCurrentPath(prev => [...prev, { x, y }]);
  };

  const handlePointerUp = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (isDrawing && currentPath.length > 0) {
      setPaths(prev => [...prev, currentPath]);
      setCurrentPath([]);
    }
    setIsDrawing(false);
    try {
      e.currentTarget.releasePointerCapture(e.pointerId);
    } catch {}
  };

  const handleUndo = () => {
    setPaths(prev => prev.slice(0, prev.length - 1));
  };

  const handleClear = () => {
    setPaths([]);
    setCurrentPath([]);
  };

  const colors = ['#000000', '#DE350B', '#0052CC', '#36B37E'];

  return (
    <div 
      id="ink-drawing-overlay" 
      className="absolute inset-0 pointer-events-auto z-40 select-none cursor-crosshair overflow-hidden"
    >
      <canvas
        ref={canvasRef}
        onPointerDown={handlePointerDown}
        onPointerMove={handlePointerMove}
        onPointerUp={handlePointerUp}
        className="w-full h-full block"
      />

      {/* Top Floating Pen Toolbar */}
      <div className="absolute top-4 left-1/2 -translate-x-1/2 bg-white/95 backdrop-blur-md px-4 py-2 rounded-xl shadow-lg border border-gray-200 flex items-center gap-4">
        <div className="flex items-center gap-1.5 text-xs font-bold text-[#0052CC]">
          <Edit2 className="w-4 h-4" />
          <span>INK_TOOL</span>
        </div>

        <div className="h-4 w-[1px] bg-gray-200" />

        {/* Color Buttons */}
        <div className="flex items-center gap-1.5">
          {colors.map(c => (
            <button
              key={c}
              onClick={() => setStrokeColor(c)}
              style={{ backgroundColor: c }}
              className={`w-5 h-5 rounded-full transition-transform cursor-pointer ${
                strokeColor === c ? 'ring-2 ring-offset-1 ring-[#0052CC] scale-110' : ''
              }`}
            />
          ))}
        </div>

        <div className="h-4 w-[1px] bg-gray-200" />

        <div className="flex items-center gap-1">
          <button
            onClick={handleUndo}
            disabled={paths.length === 0}
            className="p-1.5 rounded hover:bg-gray-100 disabled:opacity-40 text-gray-700 cursor-pointer"
            title="Undo stroke"
          >
            <Undo className="w-4 h-4" />
          </button>
          <button
            onClick={handleClear}
            disabled={paths.length === 0}
            className="p-1.5 rounded hover:bg-red-50 disabled:opacity-40 text-[#DE350B] cursor-pointer"
            title="Clear all ink"
          >
            <Trash2 className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Bottom Actions */}
      <div className="absolute bottom-16 left-1/2 -translate-x-1/2 flex items-center gap-4 bg-white/95 backdrop-blur-md px-4 py-2 rounded-full shadow-xl border border-gray-200">
        <button
          id="cancel-ink-btn"
          onClick={onCancel}
          className="p-2 rounded-full hover:bg-red-50 text-[#DE350B] cursor-pointer"
          title="Cancel"
        >
          <X className="w-5 h-5" />
        </button>

        <button
          id="confirm-ink-btn"
          disabled={paths.length === 0}
          onClick={() => onConfirm(paths, strokeWidth, strokeColor)}
          className="px-4 py-1.5 bg-[#0052CC] text-white text-xs font-bold rounded-full hover:bg-[#0040A0] transition-colors flex items-center gap-1.5 shadow disabled:opacity-50 cursor-pointer"
        >
          <Check className="w-4 h-4" />
          <span>BURN TO PDF</span>
        </button>
      </div>
    </div>
  );
};

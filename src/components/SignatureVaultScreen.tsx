import React, { useState, useRef, useEffect } from 'react';
import { 
  FileSignature, 
  Upload, 
  Trash2, 
  Check, 
  RotateCcw, 
  ShieldCheck, 
  Sparkles,
  Download
} from 'lucide-react';
import { StorageService } from '../services/storage';

export const SignatureVaultScreen: React.FC = () => {
  const [savedSignature, setSavedSignature] = useState<string | null>(null);
  const [isDrawing, setIsDrawing] = useState(false);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    setSavedSignature(StorageService.getSignature());
    clearCanvas();
  }, []);

  const clearCanvas = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
  };

  const startDrawing = (e: React.PointerEvent<HTMLCanvasElement>) => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;

    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.lineWidth = 3;
    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';
    ctx.strokeStyle = '#0052CC'; // Primary Blue ink
    setIsDrawing(true);
    canvas.setPointerCapture(e.pointerId);
  };

  const draw = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (!isDrawing) return;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const rect = canvas.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;

    ctx.lineTo(x, y);
    ctx.stroke();
  };

  const stopDrawing = (e: React.PointerEvent<HTMLCanvasElement>) => {
    if (isDrawing) {
      setIsDrawing(false);
      try {
        canvasRef.current?.releasePointerCapture(e.pointerId);
      } catch {}
    }
  };

  const handleSaveDrawnSignature = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const dataUrl = canvas.toDataURL('image/png');
    StorageService.saveSignature(dataUrl);
    setSavedSignature(dataUrl);
    alert('Digital signature saved to vault!');
  };

  const handleUploadImage = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      const img = new Image();
      img.onload = () => {
        // Create an offscreen canvas to perform automatic luminance background removal (transparency keying)
        const canvas = document.createElement('canvas');
        canvas.width = img.width;
        canvas.height = img.height;
        const ctx = canvas.getContext('2d');
        if (!ctx) return;

        ctx.drawImage(img, 0, 0);
        const imgData = ctx.getImageData(0, 0, canvas.width, canvas.height);
        const d = imgData.data;

        // Make nearly white pixels transparent
        for (let i = 0; i < d.length; i += 4) {
          const r = d[i];
          const g = d[i + 1];
          const b = d[i + 2];
          // If luminance is high (white/paper background), set alpha to 0
          if (r > 200 && g > 200 && b > 200) {
            d[i + 3] = 0;
          }
        }
        ctx.putImageData(imgData, 0, 0);
        const transparentDataUrl = canvas.toDataURL('image/png');

        StorageService.saveSignature(transparentDataUrl);
        setSavedSignature(transparentDataUrl);
        alert('Signature uploaded and processed with transparent background!');
      };
      img.src = event.target?.result as string;
    };
    reader.readAsDataURL(file);
    e.target.value = '';
  };

  const handleRemoveSignature = () => {
    if (confirm('Delete signature from vault?')) {
      StorageService.removeSignature();
      setSavedSignature(null);
      clearCanvas();
    }
  };

  return (
    <div id="signature-vault-screen" className="max-w-4xl mx-auto px-4 py-8 space-y-8">
      <input
        type="file"
        ref={fileInputRef}
        onChange={handleUploadImage}
        accept="image/png, image/jpeg"
        className="hidden"
      />

      {/* Header */}
      <div>
        <div className="flex items-center gap-2">
          <FileSignature className="w-6 h-6 text-[#0052CC]" />
          <h1 className="text-2xl font-extrabold text-[#172B4D] tracking-tight">
            Digital Signature Vault
          </h1>
        </div>
        <p className="text-xs text-[#6B778C] mt-1">
          Create, store, and manage your reusable cryptographic signature for one-click document signing.
        </p>
      </div>

      {/* Active Stored Signature Card */}
      {savedSignature && (
        <div className="bg-white rounded-xl border-2 border-[#0052CC] p-6 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-6">
          <div className="flex items-center gap-4">
            <div className="w-48 h-24 bg-[#F4F5F7] rounded-lg border border-gray-200 flex items-center justify-center p-2 relative overflow-hidden">
              <div className="absolute inset-0 bg-[linear-gradient(to_right,#e5e7eb_1px,transparent_1px),linear-gradient(to_bottom,#e5e7eb_1px,transparent_1px)] bg-[size:12px_12px] opacity-40 pointer-events-none" />
              <img
                src={savedSignature}
                alt="Active Signature"
                className="max-w-full max-h-full object-contain relative z-10"
              />
            </div>
            <div>
              <div className="flex items-center gap-1.5 text-[#36B37E] text-xs font-bold mb-1">
                <ShieldCheck className="w-4 h-4" />
                <span>ACTIVE SIGNATURE READY</span>
              </div>
              <p className="text-xs text-[#6B778C]">
                Ready for placement in the PDF editor with lossless vector transparency.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2 shrink-0">
            <button
              onClick={handleRemoveSignature}
              className="px-3.5 py-2 text-xs font-bold text-[#DE350B] hover:bg-red-50 rounded-lg transition-colors flex items-center gap-1 cursor-pointer"
            >
              <Trash2 className="w-4 h-4" />
              <span>Remove</span>
            </button>
          </div>
        </div>
      )}

      {/* Draw or Upload Signature Container */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm p-6 space-y-6">
        <div>
          <h2 className="text-sm font-bold uppercase tracking-wider text-[#172B4D]">
            {savedSignature ? 'Update Signature' : 'Create New Signature'}
          </h2>
          <p className="text-xs text-[#6B778C] mt-0.5">
            Draw directly on the canvas below or upload an existing signature image.
          </p>
        </div>

        {/* Drawing Pad */}
        <div className="border border-gray-300 rounded-xl overflow-hidden bg-[#FAFBFC] relative group">
          <div className="absolute top-3 left-3 flex items-center gap-1 text-[10px] font-bold uppercase tracking-wider text-gray-400 bg-white/80 px-2 py-0.5 rounded shadow-sm pointer-events-none">
            <Sparkles className="w-3 h-3 text-[#0052CC]" />
            <span>Interactive Ink Surface</span>
          </div>

          <canvas
            ref={canvasRef}
            width={700}
            height={200}
            onPointerDown={startDrawing}
            onPointerMove={draw}
            onPointerUp={stopDrawing}
            className="w-full h-48 cursor-crosshair block"
          />

          <div className="p-3 bg-white border-t border-gray-200 flex items-center justify-between">
            <button
              onClick={clearCanvas}
              className="px-3 py-1.5 text-xs text-gray-600 hover:text-gray-900 hover:bg-gray-100 rounded-lg flex items-center gap-1 cursor-pointer"
            >
              <RotateCcw className="w-3.5 h-3.5" />
              <span>Clear Pad</span>
            </button>

            <button
              onClick={handleSaveDrawnSignature}
              className="px-4 py-1.5 bg-[#0052CC] hover:bg-[#0040A0] text-white text-xs font-bold rounded-lg shadow flex items-center gap-1.5 cursor-pointer"
            >
              <Check className="w-3.5 h-3.5" />
              <span>Save to Vault</span>
            </button>
          </div>
        </div>

        {/* Or Upload Button */}
        <div className="flex items-center justify-between pt-4 border-t border-gray-100">
          <div>
            <span className="text-xs font-bold text-gray-700 block">
              Have a photographed signature?
            </span>
            <span className="text-xs text-gray-400">
              Upload PNG or JPEG. The engine will automatically key out the background.
            </span>
          </div>

          <button
            onClick={() => fileInputRef.current?.click()}
            className="px-4 py-2 border border-gray-300 hover:border-[#0052CC] hover:bg-[#0052CC]/5 text-gray-700 text-xs font-bold rounded-lg flex items-center gap-2 transition-colors cursor-pointer"
          >
            <Upload className="w-4 h-4 text-[#0052CC]" />
            <span>Upload Image</span>
          </button>
        </div>
      </div>
    </div>
  );
};

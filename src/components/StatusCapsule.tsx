import React from 'react';
import { RefreshCw, CheckCircle2 } from 'lucide-react';

interface StatusCapsuleProps {
  status: string;
  isLoading?: boolean;
}

export const StatusCapsule: React.FC<StatusCapsuleProps> = ({ status, isLoading = false }) => {
  return (
    <aside 
      aria-label="Cloud sync status notification"
      className="fixed top-2.5 left-1/2 -translate-x-1/2 z-50 pointer-events-none transition-all duration-300 animate-in fade-in slide-in-from-top-2"
    >
      <div 
        id="cloudnex-status-capsule"
        className="bg-slate-950/90 text-slate-100 px-3.5 py-1.5 rounded-full shadow-lg shadow-black/20 flex items-center gap-2 border border-slate-700/60 text-[11px] font-medium tracking-wide backdrop-blur-md"
      >
        {isLoading ? (
          <RefreshCw className="w-3 h-3 text-blue-400 animate-spin" />
        ) : (
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
            <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
          </span>
        )}
        <span className="text-[10px] uppercase font-bold tracking-wider text-slate-200">{status}</span>
      </div>
    </aside>
  );
};

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
      className="fixed top-3 left-1/2 -translate-x-1/2 z-50 pointer-events-none transition-all duration-300 animate-in fade-in slide-in-from-top-2"
    >
      <div 
        id="cloudnex-status-capsule"
        className="bg-black text-white px-4 py-1.5 rounded-full shadow-lg flex items-center gap-2 border border-white/10 text-xs font-semibold tracking-wider backdrop-blur-md"
      >
        {isLoading ? (
          <RefreshCw className="w-3.5 h-3.5 text-[#4C9AFF] animate-spin" />
        ) : (
          <CheckCircle2 className="w-3.5 h-3.5 text-[#36B37E]" />
        )}
        <span className="text-[11px] text-zinc-100 uppercase">{status}</span>
      </div>
    </aside>
  );
};

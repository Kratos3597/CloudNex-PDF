import React, { useState } from 'react';
import { 
  PenTool, 
  FileSignature, 
  FileEdit, 
  FileText, 
  Download, 
  Printer 
} from 'lucide-react';

interface FloatingToolbarProps {
  onAnnotate: () => void;
  onSign: () => void;
  onEdit: () => void;
  onForms: () => void;
  onExport: () => void;
  onPrint: () => void;
}

export const FloatingToolbar: React.FC<FloatingToolbarProps> = ({
  onAnnotate,
  onSign,
  onEdit,
  onForms,
  onExport,
  onPrint,
}) => {
  const [activeTab, setActiveTab] = useState<'Home' | 'Review' | 'View' | 'Help'>('Home');

  return (
    <header 
      id="floating-ribbon-toolbar"
      className="w-full bg-white border-b border-gray-200 shadow-sm select-none z-20"
    >
      {/* Ribbon Tabs Header */}
      <nav aria-label="Ribbon navigation" className="h-7 bg-[#F4F5F7] px-5 flex items-center gap-6 border-b border-gray-200 text-xs">
        {(['Home', 'Review', 'View', 'Help'] as const).map(tab => (
          <button
            key={tab}
            id={`ribbon-tab-${tab.toLowerCase()}`}
            onClick={() => setActiveTab(tab)}
            className={`cursor-pointer transition-colors ${
              activeTab === tab 
                ? 'font-bold text-[#0052CC] border-b-2 border-[#0052CC] h-full flex items-center' 
                : 'text-[#6B778C] hover:text-[#172B4D]'
            }`}
          >
            {tab}
          </button>
        ))}
      </nav>

      {/* Ribbon Actions Bar */}
      <div className="h-16 px-4 flex items-center gap-6 overflow-x-auto">
        {/* Tools Group */}
        <div className="flex flex-col justify-center">
          <div className="flex items-center gap-2">
            <button
              id="tool-btn-annotate"
              onClick={onAnnotate}
              className="px-3 py-1.5 rounded-lg hover:bg-gray-100 flex flex-col items-center gap-1 transition-colors cursor-pointer"
              title="Annotations & Drawing"
            >
              <PenTool className="w-5 h-5 text-[#172B4D]" />
              <span className="text-[11px] font-medium text-[#172B4D]">Annotate</span>
            </button>

            <button
              id="tool-btn-sign"
              onClick={onSign}
              className="px-3 py-1.5 rounded-lg hover:bg-gray-100 flex flex-col items-center gap-1 transition-colors cursor-pointer"
              title="Place digital signature"
            >
              <FileSignature className="w-5 h-5 text-[#172B4D]" />
              <span className="text-[11px] font-medium text-[#172B4D]">Sign</span>
            </button>

            <button
              id="tool-btn-edit"
              onClick={onEdit}
              className="px-3 py-1.5 rounded-lg hover:bg-gray-100 flex flex-col items-center gap-1 transition-colors cursor-pointer"
              title="Edit pages & neural text"
            >
              <FileEdit className="w-5 h-5 text-[#172B4D]" />
              <span className="text-[11px] font-medium text-[#172B4D]">Edit</span>
            </button>
          </div>
          <span className="text-[9px] font-bold uppercase tracking-wider text-gray-400 mt-0.5 text-center">Tools</span>
        </div>

        <div className="h-10 w-[1px] bg-gray-200" />

        {/* Document Group */}
        <div className="flex flex-col justify-center">
          <div className="flex items-center gap-2">
            <button
              id="doc-btn-forms"
              onClick={onForms}
              className="px-3 py-1.5 rounded-lg hover:bg-gray-100 flex flex-col items-center gap-1 transition-colors cursor-pointer"
              title="Check Interactive Form Fields"
            >
              <FileText className="w-5 h-5 text-[#172B4D]" />
              <span className="text-[11px] font-medium text-[#172B4D]">Forms</span>
            </button>

            <button
              id="doc-btn-export"
              onClick={onExport}
              className="px-3 py-1.5 rounded-lg hover:bg-gray-100 flex flex-col items-center gap-1 transition-colors cursor-pointer"
              title="Export as PDF, Word, or Excel"
            >
              <Download className="w-5 h-5 text-[#172B4D]" />
              <span className="text-[11px] font-medium text-[#172B4D]">Export</span>
            </button>

            <button
              id="doc-btn-print"
              onClick={onPrint}
              className="px-3 py-1.5 rounded-lg hover:bg-gray-100 flex flex-col items-center gap-1 transition-colors cursor-pointer"
              title="Print Document"
            >
              <Printer className="w-5 h-5 text-[#172B4D]" />
              <span className="text-[11px] font-medium text-[#172B4D]">Print</span>
            </button>
          </div>
          <span className="text-[9px] font-bold uppercase tracking-wider text-gray-400 mt-0.5 text-center">Document</span>
        </div>
      </div>
    </header>
  );
};

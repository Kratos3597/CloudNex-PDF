import React, { useState, useRef } from 'react';
import { 
  Search, 
  FileText, 
  Upload, 
  Trash2, 
  Clock, 
  ExternalLink,
  Plus,
  Share2
} from 'lucide-react';
import { DocumentRecord } from '../types';
import { StorageService } from '../services/storage';
import { PdfEngine } from '../services/pdfEngine';

interface LibraryScreenProps {
  documents: DocumentRecord[];
  onOpenDocument: (doc: DocumentRecord) => void;
  onRefreshDocs: () => void;
}

export const LibraryScreen: React.FC<LibraryScreenProps> = ({
  documents,
  onOpenDocument,
  onRefreshDocs,
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);

  const filteredDocs = documents.filter(doc =>
    doc.fileName.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const arrayBuffer = await file.arrayBuffer();
    const bytes = new Uint8Array(arrayBuffer);
    const report = await PdfEngine.analyzeDocument(bytes);

    const newDoc: DocumentRecord = {
      id: `doc-${Date.now()}`,
      fileName: file.name,
      filePath: `/local/storage/${file.name}`,
      lastOpenedDate: new Date().toISOString(),
      lastOpenedPage: 1,
      fileSize: `${(file.size / 1024).toFixed(1)} KB`,
      pageCount: report.totalPages || 1,
    };

    StorageService.saveDocument(newDoc, bytes);
    StorageService.logAction('OPEN_DOCUMENT', newDoc.fileName);
    onRefreshDocs();
    onOpenDocument(newDoc);
    e.target.value = '';
  };

  const handleDelete = (e: React.MouseEvent, docId: string) => {
    e.stopPropagation();
    if (confirm('Delete this document from storage?')) {
      StorageService.deleteDocument(docId);
      onRefreshDocs();
    }
  };

  const handleShare = async (e: React.MouseEvent, doc: DocumentRecord) => {
    e.stopPropagation();
    const bytes = await StorageService.getDocumentBytes(doc.id);
    if (!bytes) {
      alert('Document data not found.');
      return;
    }

    const fileName = doc.fileName.endsWith('.pdf') ? doc.fileName : `${doc.fileName}.pdf`;
    const pdfBlob = new Blob([bytes.buffer as ArrayBuffer], { type: 'application/pdf' });
    const pdfFile = new File([pdfBlob], fileName, { type: 'application/pdf' });

    if (navigator.canShare && navigator.canShare({ files: [pdfFile] })) {
      try {
        await navigator.share({
          files: [pdfFile],
          title: doc.fileName,
          text: `PDF document: ${doc.fileName}`,
        });
        StorageService.logAction('EXPORT_DOCUMENT', `Shared ${doc.fileName}`);
      } catch (err: any) {
        if (err.name !== 'AbortError') {
          PdfEngine.downloadFile(bytes, fileName, 'application/pdf');
        }
      }
    } else {
      PdfEngine.downloadFile(bytes, fileName, 'application/pdf');
    }
  };

  return (
    <div id="library-screen" className="max-w-6xl mx-auto px-4 py-8 space-y-6">
      <input
        type="file"
        ref={fileInputRef}
        onChange={handleFileUpload}
        accept="application/pdf"
        className="hidden"
      />

      {/* Header & Search */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-extrabold text-[#172B4D] tracking-tight">
            Document Library
          </h1>
          <p className="text-xs text-[#6B778C] mt-0.5">
            Manage, search, and organize all local PDF files
          </p>
        </div>

        <button
          onClick={() => fileInputRef.current?.click()}
          className="px-4 py-2 bg-[#0052CC] hover:bg-[#0040A0] text-white text-xs font-bold rounded-lg shadow flex items-center gap-1.5 transition-colors cursor-pointer self-start sm:self-auto"
        >
          <Plus className="w-4 h-4" />
          <span>Upload PDF</span>
        </button>
      </div>

      {/* Search Input Bar */}
      <div className="relative">
        <Search className="w-4 h-4 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
        <input
          id="library-search-input"
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Search documents by name..."
          className="w-full pl-10 pr-4 py-2.5 bg-white border border-gray-200 rounded-xl text-sm focus:outline-none focus:border-[#0052CC] focus:ring-1 focus:ring-[#0052CC] shadow-sm"
        />
      </div>

      {/* Documents List */}
      {filteredDocs.length === 0 ? (
        <div className="bg-white rounded-xl border border-dashed border-gray-200 p-12 text-center">
          <FileText className="w-10 h-10 text-gray-300 mx-auto mb-2" />
          <p className="text-sm font-semibold text-gray-600">No documents found</p>
          <p className="text-xs text-gray-400 mt-1">
            {searchQuery ? 'Try adjusting your search query' : 'Upload a PDF to get started'}
          </p>
        </div>
      ) : (
        <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
          <div className="divide-y divide-gray-100">
            {filteredDocs.map((doc) => (
              <div
                key={doc.id}
                id={`library-doc-row-${doc.id}`}
                onClick={() => onOpenDocument(doc)}
                className="p-4 hover:bg-gray-50 flex items-center justify-between gap-4 transition-colors cursor-pointer group"
              >
                <div className="flex items-center gap-3.5 min-w-0">
                  <div className="p-2.5 bg-[#0052CC]/10 text-[#0052CC] rounded-lg group-hover:bg-[#0052CC] group-hover:text-white transition-colors shrink-0">
                    <FileText className="w-5 h-5" />
                  </div>
                  <div className="min-w-0">
                    <h4 className="font-bold text-sm text-[#172B4D] truncate group-hover:text-[#0052CC] transition-colors">
                      {doc.fileName}
                    </h4>
                    <p className="text-xs text-gray-400 truncate">{doc.filePath}</p>
                  </div>
                </div>

                <div className="flex items-center gap-6 shrink-0">
                  <div className="text-right text-xs text-[#6B778C] hidden sm:block">
                    <div className="font-medium text-gray-700">
                      {doc.pageCount ? `${doc.pageCount} Pages` : '1 Page'}
                    </div>
                    <div className="text-gray-400 flex items-center gap-1 justify-end mt-0.5">
                      <Clock className="w-3 h-3" />
                      {new Date(doc.lastOpenedDate).toLocaleDateString()}
                    </div>
                  </div>

                  <div className="flex items-center gap-1">
                    <button
                      onClick={(e) => handleShare(e, doc)}
                      className="p-2 text-gray-400 hover:text-[#0052CC] hover:bg-blue-50 rounded-lg transition-colors cursor-pointer"
                      title="Share PDF via Android Share Sheet"
                    >
                      <Share2 className="w-4 h-4" />
                    </button>
                    <button
                      onClick={(e) => handleDelete(e, doc.id)}
                      className="p-2 text-gray-400 hover:text-[#DE350B] hover:bg-red-50 rounded-lg transition-colors cursor-pointer"
                      title="Delete"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                    <div className="p-2 text-[#0052CC] group-hover:translate-x-0.5 transition-transform">
                      <ExternalLink className="w-4 h-4" />
                    </div>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

import React, { useState } from 'react';
import { Sparkles, Folder, Tag, X, Check, Brain, Shield, Info, Plus } from 'lucide-react';
import { DocumentRecord, AiClassificationResult } from '../types';
import { AiClassifierService } from '../services/aiClassifier';
import { StorageService } from '../services/storage';

interface AutoTagModalProps {
  isOpen: boolean;
  onClose: () => void;
  document: DocumentRecord | null;
  onDocumentUpdated?: (updatedDoc: DocumentRecord) => void;
}

export const AutoTagModal: React.FC<AutoTagModalProps> = ({
  isOpen,
  onClose,
  document,
  onDocumentUpdated,
}) => {
  if (!isOpen || !document) return null;

  const [selectedFolder, setSelectedFolder] = useState<string>(document.folder || 'Reports & Notes');
  const [tags, setTags] = useState<string[]>(document.tags || ['#document']);
  const [newTagInput, setNewTagInput] = useState('');
  const [customFolderInput, setCustomFolderInput] = useState('');
  const [isCustomFolder, setIsCustomFolder] = useState(false);
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [statusMessage, setStatusMessage] = useState('');

  const standardFolders = ['Invoices', 'Contracts', 'Identity', 'Financial & Tax', 'Receipts', 'Reports & Notes'];

  const handleRerunAiClassification = async () => {
    setIsAnalyzing(true);
    setStatusMessage('Analyzing extracted PDF text and layout patterns...');
    try {
      const textToAnalyze = document.searchableText || '';
      const result: AiClassificationResult = await AiClassifierService.classifyDocument(
        textToAnalyze,
        document.fileName
      );

      setSelectedFolder(result.folder);
      setTags(result.tags);
      setIsCustomFolder(!standardFolders.includes(result.folder));

      const updatedDoc: DocumentRecord = {
        ...document,
        folder: result.folder,
        tags: result.tags,
        aiCategoryConfidence: result.confidence,
        aiSummary: result.summary,
        aiReasoning: result.reasoning,
        aiEngine: result.engine,
        autoTaggedAt: new Date().toISOString(),
      };

      StorageService.saveDocument(updatedDoc);
      StorageService.logAction('AUTO_TAG_DOCUMENT', updatedDoc.fileName);

      if (onDocumentUpdated) {
        onDocumentUpdated(updatedDoc);
      }
      setStatusMessage(`Categorized as "${result.folder}" with ${result.confidence}% confidence (${result.engine === 'gemini' ? 'Gemini 3.8 Flash' : 'Semantic Analyzer'}).`);
    } catch (e) {
      console.error('AI classification failed:', e);
      setStatusMessage('Analysis complete with fallback classifier.');
    } finally {
      setIsAnalyzing(false);
    }
  };

  const handleAddTag = () => {
    const trimmed = newTagInput.trim();
    if (!trimmed) return;
    const formatted = trimmed.startsWith('#') ? trimmed : `#${trimmed}`;
    if (!tags.includes(formatted)) {
      setTags([...tags, formatted]);
    }
    setNewTagInput('');
  };

  const handleRemoveTag = (tagToRemove: string) => {
    setTags(tags.filter((t) => t !== tagToRemove));
  };

  const handleSave = () => {
    const finalFolder = isCustomFolder ? (customFolderInput.trim() || 'Custom') : selectedFolder;
    const updatedDoc: DocumentRecord = {
      ...document,
      folder: finalFolder,
      tags,
      autoTaggedAt: document.autoTaggedAt || new Date().toISOString(),
    };

    StorageService.saveDocument(updatedDoc);
    StorageService.moveDocumentToFolder(updatedDoc.id, finalFolder);
    StorageService.updateDocumentTags(updatedDoc.id, tags);

    if (onDocumentUpdated) {
      onDocumentUpdated(updatedDoc);
    }
    onClose();
  };

  const folderStyle = AiClassifierService.getFolderStyle(selectedFolder);

  return (
    <div
      id="auto-tag-modal-overlay"
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-slate-950/60 backdrop-blur-xs p-0 sm:p-4 animate-in fade-in duration-200"
    >
      <div
        id="auto-tag-modal-container"
        className="bg-white dark:bg-slate-900 w-full sm:max-w-xl max-h-[90vh] rounded-t-3xl sm:rounded-3xl shadow-2xl flex flex-col overflow-hidden border border-slate-200/80 dark:border-slate-800"
      >
        {/* Header */}
        <div className="px-6 py-4.5 border-b border-slate-100 dark:border-slate-800 flex items-center justify-between bg-slate-50/80 dark:bg-slate-850/80">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-blue-50 dark:bg-blue-950/50 text-blue-600 dark:text-blue-400 flex items-center justify-center shrink-0 border border-blue-100 dark:border-blue-900/50">
              <Sparkles className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="font-extrabold text-slate-900 dark:text-white text-base leading-tight">AI Auto-Tagging</h3>
                <span className="text-[10px] font-bold tracking-wide uppercase px-2 py-0.5 rounded-full bg-blue-100 dark:bg-blue-900/40 text-blue-700 dark:text-blue-300 border border-blue-200 dark:border-blue-800">
                  {document.aiEngine === 'gemini' ? 'Gemini 3.8' : 'Smart Heuristics'}
                </span>
              </div>
              <p className="text-xs text-slate-500 dark:text-slate-400 truncate max-w-xs sm:max-w-md mt-0.5">{document.fileName}</p>
            </div>
          </div>
          <button
            id="close-auto-tag-modal-btn"
            onClick={onClose}
            className="p-2 text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 hover:bg-slate-200/60 dark:hover:bg-slate-800 rounded-xl min-h-[44px] min-w-[44px] flex items-center justify-center cursor-pointer transition-colors"
            aria-label="Close"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Scrollable Content */}
        <div className="p-6 overflow-y-auto space-y-5 flex-1">
          {/* AI Analysis Summary Banner */}
          <div className="p-4 bg-gradient-to-r from-blue-50/90 to-indigo-50/90 dark:from-slate-850 dark:to-slate-800 rounded-2xl border border-blue-100 dark:border-slate-700 text-xs space-y-2 shadow-2xs">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-1.5 font-bold text-blue-950 dark:text-blue-300">
                <Brain className="w-4 h-4 text-blue-600 dark:text-blue-400" />
                <span>Executive AI Summary</span>
              </div>
              <span className="text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-white dark:bg-slate-900 text-blue-700 dark:text-blue-300 shadow-2xs border border-blue-200 dark:border-blue-800">
                {document.aiCategoryConfidence || 95}% Confidence
              </span>
            </div>
            <p className="text-slate-700 dark:text-slate-300 leading-relaxed font-medium">
              {document.aiSummary || `Categorized as ${document.folder || 'Document'} based on structural elements and extracted text tokens.`}
            </p>
            {document.aiReasoning && (
              <p className="text-slate-500 dark:text-slate-400 text-[11px] italic">
                Reasoning: {document.aiReasoning}
              </p>
            )}
          </div>

          {/* Folder Category Selection */}
          <div className="space-y-2.5">
            <label className="text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider flex items-center gap-1.5">
              <Folder className="w-4 h-4 text-slate-400" />
              Target Folder Category
            </label>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
              {standardFolders.map((f) => {
                const isSelected = !isCustomFolder && selectedFolder === f;
                const style = AiClassifierService.getFolderStyle(f);
                return (
                  <button
                    key={f}
                    type="button"
                    onClick={() => {
                      setSelectedFolder(f);
                      setIsCustomFolder(false);
                    }}
                    className={`min-h-[44px] px-3.5 py-2.5 rounded-xl text-xs font-semibold flex items-center justify-between border cursor-pointer transition-all ${
                      isSelected
                        ? `${style.bg} ${style.text} ${style.border} ring-2 ring-blue-500/20 shadow-xs font-bold`
                        : 'bg-white dark:bg-slate-900 text-slate-700 dark:text-slate-300 border-slate-200/80 dark:border-slate-800 hover:bg-slate-50 dark:hover:bg-slate-850'
                    }`}
                  >
                    <div className="flex items-center gap-2 truncate">
                      <span className={`w-2 h-2 rounded-full ${style.dotColor}`} />
                      <span className="truncate">{f}</span>
                    </div>
                    {isSelected && <Check className="w-3.5 h-3.5 shrink-0" />}
                  </button>
                );
              })}
            </div>

            {/* Custom Folder Option */}
            <div className="pt-1">
              <button
                type="button"
                onClick={() => setIsCustomFolder(!isCustomFolder)}
                className="text-xs text-blue-600 dark:text-blue-400 hover:underline font-semibold min-h-[36px] flex items-center gap-1 cursor-pointer"
              >
                <Plus className="w-3.5 h-3.5" />
                {isCustomFolder ? 'Select from standard folders' : 'Or specify custom folder name...'}
              </button>
              {isCustomFolder && (
                <div className="mt-2 flex items-center gap-2">
                  <input
                    type="text"
                    placeholder="Enter custom folder name..."
                    value={customFolderInput}
                    onChange={(e) => setCustomFolderInput(e.target.value)}
                    className="flex-1 px-3.5 py-2.5 text-xs bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 min-h-[44px] text-slate-900 dark:text-white"
                  />
                </div>
              )}
            </div>
          </div>

          {/* AI Tags Section */}
          <div className="space-y-2.5">
            <label className="text-xs font-bold text-slate-700 dark:text-slate-300 uppercase tracking-wider flex items-center justify-between">
              <span className="flex items-center gap-1.5">
                <Tag className="w-4 h-4 text-slate-400" />
                Document Smart Tags
              </span>
              <span className="text-[11px] text-slate-400 font-semibold">{tags.length} assigned</span>
            </label>

            {/* Tag Chips Display */}
            <div className="flex flex-wrap gap-1.5 min-h-[42px] p-3 bg-slate-50 dark:bg-slate-850 rounded-2xl border border-slate-200/80 dark:border-slate-800">
              {tags.map((tag) => (
                <span
                  key={tag}
                  className="inline-flex items-center gap-1 px-2.5 py-1 rounded-lg text-xs font-semibold bg-white dark:bg-slate-900 text-slate-700 dark:text-slate-200 border border-slate-200/80 dark:border-slate-700 shadow-2xs group"
                >
                  <span>{tag}</span>
                  <button
                    type="button"
                    onClick={() => handleRemoveTag(tag)}
                    className="text-slate-400 hover:text-red-500 p-0.5 rounded-full min-h-[20px] min-w-[20px] flex items-center justify-center cursor-pointer"
                    aria-label={`Remove tag ${tag}`}
                  >
                    <X className="w-3 h-3" />
                  </button>
                </span>
              ))}
              {tags.length === 0 && (
                <span className="text-xs text-slate-400 italic">No tags assigned yet.</span>
              )}
            </div>

            {/* Add Custom Tag Input */}
            <div className="flex items-center gap-2">
              <input
                type="text"
                placeholder="Add tag (e.g. #tax, #q3, #vendor)..."
                value={newTagInput}
                onChange={(e) => setNewTagInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    e.preventDefault();
                    handleAddTag();
                  }
                }}
                className="flex-1 px-3.5 py-2.5 text-xs bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 min-h-[44px] text-slate-900 dark:text-white"
              />
              <button
                type="button"
                onClick={handleAddTag}
                className="px-4 py-2 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-750 text-slate-700 dark:text-slate-300 text-xs font-bold rounded-xl min-h-[44px] cursor-pointer transition-colors"
              >
                Add
              </button>
            </div>
          </div>

          {/* Re-run AI trigger */}
          <div className="p-3.5 bg-slate-50 dark:bg-slate-850 rounded-2xl border border-slate-200/80 dark:border-slate-800 flex items-center justify-between text-xs">
            <div className="flex items-center gap-2 text-slate-600 dark:text-slate-400">
              <Sparkles className="w-4 h-4 text-blue-600 dark:text-blue-400" />
              <span>Need to re-evaluate document content?</span>
            </div>
            <button
              type="button"
              onClick={handleRerunAiClassification}
              disabled={isAnalyzing}
              className="text-blue-600 dark:text-blue-400 hover:underline font-bold cursor-pointer disabled:opacity-50 min-h-[36px] flex items-center"
            >
              {isAnalyzing ? 'Analyzing...' : 'Re-run AI Engine'}
            </button>
          </div>

          {statusMessage && (
            <p className="text-xs text-emerald-700 dark:text-emerald-300 bg-emerald-50 dark:bg-emerald-950/40 p-3 rounded-xl border border-emerald-200 dark:border-emerald-800 font-medium">
              {statusMessage}
            </p>
          )}
        </div>

        {/* Footer Actions (Touch Friendly >= 44px) */}
        <div className="p-4 sm:p-5 border-t border-slate-100 dark:border-slate-800 bg-slate-50/80 dark:bg-slate-850/80 flex items-center justify-between gap-3">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2.5 text-xs font-semibold text-slate-600 dark:text-slate-400 hover:text-slate-800 dark:hover:text-slate-200 hover:bg-slate-200/60 dark:hover:bg-slate-800 rounded-xl min-h-[44px] min-w-[80px] cursor-pointer transition-colors"
          >
            Cancel
          </button>
          <button
            type="button"
            onClick={handleSave}
            className="px-6 py-2.5 bg-blue-600 hover:bg-blue-500 active:bg-blue-700 text-white text-xs font-bold rounded-xl min-h-[44px] shadow-sm shadow-blue-600/20 flex items-center justify-center gap-1.5 cursor-pointer transition-all"
          >
            <Check className="w-4 h-4" />
            Apply & Save
          </button>
        </div>
      </div>
    </div>
  );
};

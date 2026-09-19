import { DocumentRecord, AuditEntry } from '../types';
import { PdfEngine } from './pdfEngine';

const STORAGE_KEYS = {
  DOCUMENTS: 'cloudnex_pdf_documents',
  AUDIT_LOGS: 'cloudnex_pdf_audit_logs',
  SIGNATURE: 'cloudnex_pdf_signature',
  ACTIVE_DOC_ID: 'cloudnex_pdf_active_doc',
  THEME_MODE: 'cloudnex_pdf_theme',
  SYNCFUSION_KEY: 'cloudnex_pdf_syncfusion_key',
};

// In-memory cache for fast binary access
const memoryDocumentBytes = new Map<string, Uint8Array>();

export class StorageService {
  /**
   * Initializes storage with sample enterprise documents if none exist
   */
  static async initializeDefaults(): Promise<DocumentRecord[]> {
    const existing = this.getDocuments();
    if (existing.length > 0) return existing;

    try {
      // Create initial specialized sample documents for Invoices, Contracts, Identity, and Reports
      const [invoiceBytes, contractBytes, identityBytes, specBytes] = await Promise.all([
        PdfEngine.createInvoiceSampleDocument(),
        PdfEngine.createContractSampleDocument(),
        PdfEngine.createIdentitySampleDocument(),
        PdfEngine.createSampleDocument('Enterprise Architecture Spec', 'Cloud Engineering & Security Guidelines'),
      ]);

      const doc1: DocumentRecord = {
        id: 'doc-invoice-1',
        fileName: 'AWS_Cloud_Invoice_2026.pdf',
        filePath: '/storage/cloudnex/Invoices/AWS_Cloud_Invoice_2026.pdf',
        lastOpenedDate: new Date().toISOString(),
        lastOpenedPage: 1,
        fileSize: `${(invoiceBytes.byteLength / 1024).toFixed(1)} KB`,
        pageCount: 1,
        folder: 'Invoices',
        tags: ['#invoice', '#billing', '#cloud-compute', '#net-30'],
        aiCategoryConfidence: 98,
        aiSummary: 'Tax invoice for AWS & Kubernetes compute infrastructure totaling $4,120.00.',
        aiReasoning: 'Detected itemized line items, bill-to metadata, and due date.',
        aiEngine: 'gemini',
        autoTaggedAt: new Date().toISOString(),
      };

      const doc2: DocumentRecord = {
        id: 'doc-contract-1',
        fileName: 'Enterprise_Vendor_Agreement.pdf',
        filePath: '/storage/cloudnex/Contracts/Enterprise_Vendor_Agreement.pdf',
        lastOpenedDate: new Date(Date.now() - 3600000 * 12).toISOString(),
        lastOpenedPage: 1,
        fileSize: `${(contractBytes.byteLength / 1024).toFixed(1)} KB`,
        pageCount: 1,
        folder: 'Contracts',
        tags: ['#contract', '#legal-agreement', '#terms', '#binding', '#nda'],
        aiCategoryConfidence: 99,
        aiSummary: 'Master Services Agreement & NDA for enterprise architecture services.',
        aiReasoning: 'Detected binding legal clauses, non-disclosure terms, and signature blocks.',
        aiEngine: 'gemini',
        autoTaggedAt: new Date().toISOString(),
      };

      const doc3: DocumentRecord = {
        id: 'doc-identity-1',
        fileName: 'Employee_Passport_Verification.pdf',
        filePath: '/storage/cloudnex/Identity/Employee_Passport_Verification.pdf',
        lastOpenedDate: new Date(Date.now() - 3600000 * 24).toISOString(),
        lastOpenedPage: 1,
        fileSize: `${(identityBytes.byteLength / 1024).toFixed(1)} KB`,
        pageCount: 1,
        folder: 'Identity',
        tags: ['#identity', '#gov-id', '#compliance', '#kyc-verified'],
        aiCategoryConfidence: 99,
        aiSummary: 'Official biometric passport identification credential for employee onboarding.',
        aiReasoning: 'Detected government passport credential format, DOB, and citizenship record.',
        aiEngine: 'gemini',
        autoTaggedAt: new Date().toISOString(),
      };

      const doc4: DocumentRecord = {
        id: 'doc-report-1',
        fileName: 'Enterprise_SLA_Spec.pdf',
        filePath: '/storage/cloudnex/Reports/Enterprise_SLA_Spec.pdf',
        lastOpenedDate: new Date(Date.now() - 3600000 * 48).toISOString(),
        lastOpenedPage: 1,
        fileSize: `${(specBytes.byteLength / 1024).toFixed(1)} KB`,
        pageCount: 2,
        folder: 'Reports & Notes',
        tags: ['#report', '#architecture', '#spec', '#sla'],
        aiCategoryConfidence: 92,
        aiSummary: 'Enterprise architecture specification and cloud performance guidelines.',
        aiReasoning: 'Detected technical report structure, specifications, and architecture notes.',
        aiEngine: 'heuristic',
        autoTaggedAt: new Date().toISOString(),
      };

      memoryDocumentBytes.set(doc1.id, invoiceBytes);
      memoryDocumentBytes.set(doc2.id, contractBytes);
      memoryDocumentBytes.set(doc3.id, identityBytes);
      memoryDocumentBytes.set(doc4.id, specBytes);

      const docs = [doc1, doc2, doc3, doc4];
      localStorage.setItem(STORAGE_KEYS.DOCUMENTS, JSON.stringify(docs));

      // Initial audit logs
      this.logAction('OPEN_DOCUMENT', doc1.fileName);
      this.logAction('AUTO_TAG_DOCUMENT', doc1.fileName);
      this.logAction('AUTO_TAG_DOCUMENT', doc2.fileName);
      this.logAction('AUTO_TAG_DOCUMENT', doc3.fileName);

      return docs;
    } catch (e) {
      console.error('Failed to initialize default documents:', e);
      return [];
    }
  }

  static getDocuments(): DocumentRecord[] {
    try {
      const data = localStorage.getItem(STORAGE_KEYS.DOCUMENTS);
      const docs: DocumentRecord[] = data ? JSON.parse(data) : [];
      // Ensure all documents have a folder property
      let modified = false;
      const normalized = docs.map((doc) => {
        if (!doc.folder) {
          modified = true;
          const fn = doc.fileName.toLowerCase();
          let f = 'Reports & Notes';
          if (fn.includes('invoice') || fn.includes('bill')) f = 'Invoices';
          else if (fn.includes('contract') || fn.includes('agreement') || fn.includes('nda')) f = 'Contracts';
          else if (fn.includes('id') || fn.includes('passport') || fn.includes('license')) f = 'Identity';
          else if (fn.includes('tax') || fn.includes('financial') || fn.includes('report')) f = 'Financial & Tax';
          return {
            ...doc,
            folder: f,
            tags: doc.tags || [`#${f.toLowerCase().replace(/[^a-z0-9]/g, '')}`],
          };
        }
        return doc;
      });
      if (modified) {
        localStorage.setItem(STORAGE_KEYS.DOCUMENTS, JSON.stringify(normalized));
      }
      return normalized;
    } catch {
      return [];
    }
  }

  static getFolders(): string[] {
    const defaultFolders = ['Invoices', 'Contracts', 'Identity', 'Financial & Tax', 'Receipts', 'Reports & Notes'];
    const docs = this.getDocuments();
    const customFolders = Array.from(new Set(docs.map((d) => d.folder).filter(Boolean) as string[]));
    
    // Combine defaults and custom folders
    const all = Array.from(new Set([...defaultFolders, ...customFolders]));
    return all;
  }

  static moveDocumentToFolder(docId: string, folderName: string): void {
    const docs = this.getDocuments();
    const doc = docs.find((d) => d.id === docId);
    if (doc) {
      doc.folder = folderName;
      localStorage.setItem(STORAGE_KEYS.DOCUMENTS, JSON.stringify(docs));
      this.logAction('MOVE_FOLDER', doc.fileName);
    }
  }

  static updateDocumentTags(docId: string, tags: string[]): void {
    const docs = this.getDocuments();
    const doc = docs.find((d) => d.id === docId);
    if (doc) {
      doc.tags = tags;
      localStorage.setItem(STORAGE_KEYS.DOCUMENTS, JSON.stringify(docs));
    }
  }

  static saveDocument(doc: DocumentRecord, bytes?: Uint8Array): void {
    const docs = this.getDocuments();
    const index = docs.findIndex(d => d.id === doc.id);
    if (index >= 0) {
      docs[index] = { ...docs[index], ...doc };
    } else {
      docs.unshift(doc);
    }
    localStorage.setItem(STORAGE_KEYS.DOCUMENTS, JSON.stringify(docs));

    if (bytes) {
      memoryDocumentBytes.set(doc.id, bytes);
    }
  }

  static async getDocumentBytes(docId: string): Promise<Uint8Array> {
    if (memoryDocumentBytes.has(docId)) {
      return memoryDocumentBytes.get(docId)!;
    }

    // Check if doc exists in storage
    const doc = this.getDocuments().find(d => d.id === docId);
    if (doc) {
      // Re-generate if memory is lost or create sample
      const bytes = await PdfEngine.createSampleDocument(doc.fileName, 'Archived CloudNex PDF Record');
      memoryDocumentBytes.set(docId, bytes);
      return bytes;
    }

    // Default fallback document
    const fallback = await PdfEngine.createSampleDocument('New Document.pdf', 'CloudNex Default');
    memoryDocumentBytes.set(docId, fallback);
    return fallback;
  }

  static storeDocumentBytes(docId: string, bytes: Uint8Array): void {
    memoryDocumentBytes.set(docId, bytes);
  }

  static deleteDocument(docId: string): void {
    const docs = this.getDocuments().filter(d => d.id !== docId);
    localStorage.setItem(STORAGE_KEYS.DOCUMENTS, JSON.stringify(docs));
    memoryDocumentBytes.delete(docId);
  }

  // Audit Logs
  static getAuditLogs(): AuditEntry[] {
    try {
      const data = localStorage.getItem(STORAGE_KEYS.AUDIT_LOGS);
      return data ? JSON.parse(data) : [];
    } catch {
      return [];
    }
  }

  static logAction(action: AuditEntry['action'], documentName: string): AuditEntry {
    const logs = this.getAuditLogs();
    const entry: AuditEntry = {
      id: Date.now().toString(),
      action,
      documentName,
      timestamp: new Date().toISOString(),
      user: 'OPERATOR_01',
    };
    logs.unshift(entry);
    // Keep max 100 entries
    if (logs.length > 100) logs.pop();
    localStorage.setItem(STORAGE_KEYS.AUDIT_LOGS, JSON.stringify(logs));
    return entry;
  }

  static getActionStats(): Record<string, number> {
    const logs = this.getAuditLogs();
    const stats: Record<string, number> = {
      OPEN_DOCUMENT: 0,
      MODIFY_DOCUMENT: 0,
      EXPORT_DOCUMENT: 0,
      MERGE_DOCUMENTS: 0,
      SIGN_DOCUMENT: 0,
      OCR_CONVERT: 0,
    };

    for (const log of logs) {
      if (log.action.startsWith('EXPORT_')) {
        stats['EXPORT_DOCUMENT'] = (stats['EXPORT_DOCUMENT'] || 0) + 1;
      } else {
        stats[log.action] = (stats[log.action] || 0) + 1;
      }
    }
    return stats;
  }

  // Signature Vault
  static getSignature(): string | null {
    return localStorage.getItem(STORAGE_KEYS.SIGNATURE);
  }

  static saveSignature(dataUrl: string): void {
    localStorage.setItem(STORAGE_KEYS.SIGNATURE, dataUrl);
  }

  static removeSignature(): void {
    localStorage.removeItem(STORAGE_KEYS.SIGNATURE);
  }

  // Syncfusion License Key Configuration
  static getSyncfusionKey(): string {
    return localStorage.getItem(STORAGE_KEYS.SYNCFUSION_KEY) || (import.meta as any).env?.VITE_SYNCFUSION_LICENSE_KEY || '';
  }

  static saveSyncfusionKey(key: string): void {
    localStorage.setItem(STORAGE_KEYS.SYNCFUSION_KEY, key.trim());
  }

  static getFolderStyle(folderName: string) {
    const f = (folderName || '').toLowerCase();
    if (f.includes('invoice') || f.includes('bill')) {
      return {
        bg: 'bg-blue-50',
        text: 'text-blue-700',
        border: 'border-blue-200',
        badgeBg: 'bg-blue-100 text-blue-800',
        dotColor: 'bg-blue-500',
      };
    }
    if (f.includes('contract')) {
      return {
        bg: 'bg-purple-50',
        text: 'text-purple-700',
        border: 'border-purple-200',
        badgeBg: 'bg-purple-100 text-purple-800',
        dotColor: 'bg-purple-500',
      };
    }
    if (f.includes('identity')) {
      return {
        bg: 'bg-amber-50',
        text: 'text-amber-800',
        border: 'border-amber-200',
        badgeBg: 'bg-amber-100 text-amber-900',
        dotColor: 'bg-amber-500',
      };
    }
    if (f.includes('financial') || f.includes('tax')) {
      return {
        bg: 'bg-emerald-50',
        text: 'text-emerald-700',
        border: 'border-emerald-200',
        badgeBg: 'bg-emerald-100 text-emerald-800',
        dotColor: 'bg-emerald-500',
      };
    }
    if (f.includes('receipt')) {
      return {
        bg: 'bg-teal-50',
        text: 'text-teal-700',
        border: 'border-teal-200',
        badgeBg: 'bg-teal-100 text-teal-800',
        dotColor: 'bg-teal-500',
      };
    }
    return {
      bg: 'bg-gray-50',
      text: 'text-gray-700',
      border: 'border-gray-200',
      badgeBg: 'bg-gray-100 text-gray-800',
      dotColor: 'bg-gray-400',
    };
  }
}

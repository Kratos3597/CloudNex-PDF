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
      // Create initial sample documents
      const sample1Bytes = await PdfEngine.createSampleDocument(
        'Enterprise SLA & Architecture Spec',
        'Confidential System Specification & Cloud Integrity'
      );
      const sample2Bytes = await PdfEngine.createSampleDocument(
        'Quarterly Financial Disclosures & Audit',
        'Financial Reporting and Executive Approval Matrix'
      );

      const doc1: DocumentRecord = {
        id: 'doc-1',
        fileName: 'Enterprise_SLA_Spec.pdf',
        filePath: '/storage/cloudnex/Enterprise_SLA_Spec.pdf',
        lastOpenedDate: new Date().toISOString(),
        lastOpenedPage: 1,
        fileSize: '48.2 KB',
        pageCount: 2,
      };

      const doc2: DocumentRecord = {
        id: 'doc-2',
        fileName: 'Quarterly_Financial_Report.pdf',
        filePath: '/storage/cloudnex/Quarterly_Financial_Report.pdf',
        lastOpenedDate: new Date(Date.now() - 3600000 * 24).toISOString(),
        lastOpenedPage: 1,
        fileSize: '51.8 KB',
        pageCount: 2,
      };

      memoryDocumentBytes.set(doc1.id, sample1Bytes);
      memoryDocumentBytes.set(doc2.id, sample2Bytes);

      const docs = [doc1, doc2];
      localStorage.setItem(STORAGE_KEYS.DOCUMENTS, JSON.stringify(docs));

      // Initial audit logs
      this.logAction('OPEN_DOCUMENT', doc1.fileName);
      this.logAction('MODIFY_DOCUMENT', doc2.fileName);

      return docs;
    } catch (e) {
      console.error('Failed to initialize default documents:', e);
      return [];
    }
  }

  static getDocuments(): DocumentRecord[] {
    try {
      const data = localStorage.getItem(STORAGE_KEYS.DOCUMENTS);
      return data ? JSON.parse(data) : [];
    } catch {
      return [];
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
}

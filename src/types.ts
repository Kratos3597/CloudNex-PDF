export type TabType = 'home' | 'files' | 'activity' | 'profile';

export type ActivePdfTool = 
  | 'none' 
  | 'highlight' 
  | 'underline' 
  | 'strikeout' 
  | 'ink' 
  | 'shape'
  | 'rectangle' 
  | 'circle' 
  | 'line' 
  | 'signaturePlacement' 
  | 'textPlacement' 
  | 'select';

export type ShapeType = 'rectangle' | 'circle' | 'line';

export type ShadowObjectType = 'text' | 'signature' | 'shape' | 'redact';

export interface ShadowObject {
  id: string;
  type: ShadowObjectType;
  position: { x: number; y: number };
  size: { width: number; height: number };
  content: string; // text content, image data URL, or shape name
  fontSize: number;
  color: string;
  pageIndex: number;
}

export interface DocumentRecord {
  id: string;
  fileName: string;
  filePath: string;
  lastOpenedDate: string;
  lastOpenedPage: number;
  fileSize?: string;
  pageCount?: number;
  dataBase64?: string; // stored base64 or generated
}

export interface AuditEntry {
  id: string;
  action: 'OPEN_DOCUMENT' | 'MODIFY_DOCUMENT' | 'EXPORT_DOCUMENT' | 'EXPORT_EXCEL' | 'EXPORT_WORD' | 'MERGE_DOCUMENTS' | 'SIGN_DOCUMENT';
  documentName: string;
  timestamp: string;
  user: string;
}

export interface PdfSecurityReport {
  isEncrypted: boolean;
  totalPages: number;
  authorSignature: string;
  complianceStatus: 'OK' | 'FAILED' | 'PENDING';
  permissionsValid: boolean;
}

export interface NeuralZone {
  id: string;
  bounds: { x: number; y: number; width: number; height: number };
  label: 'heading' | 'paragraph' | 'cell' | 'date' | 'meta';
  originalText: string;
  fontSize: number;
}

export type ThemeMode = 'light' | 'dark';

import { AiClassificationResult, DocumentRecord } from '../types';

export class AiClassifierService {
  /**
   * Fast rule-based semantic heuristic fallback when offline or if server call fails
   */
  private static classifyLocally(text: string, fileName = ''): AiClassificationResult {
    const t = (text + ' ' + fileName).toLowerCase();

    // Invoices score
    const invoiceScore = (
      (t.includes('invoice') ? 5 : 0) +
      (t.includes('bill to') ? 4 : 0) +
      (t.includes('remit to') ? 4 : 0) +
      (t.includes('due date') ? 3 : 0) +
      (t.includes('balance due') ? 4 : 0) +
      (t.includes('amount due') ? 4 : 0) +
      (t.includes('subtotal') ? 3 : 0) +
      (t.includes('unit price') ? 3 : 0) +
      (t.includes('po #') || t.includes('p.o.') || t.includes('purchase order') ? 3 : 0) +
      (t.includes('payment terms') || t.includes('net 30') ? 3 : 0) +
      (t.includes('tax invoice') ? 5 : 0)
    );

    // Contracts score
    const contractScore = (
      (t.includes('agreement') ? 5 : 0) +
      (t.includes('contract') ? 5 : 0) +
      (t.includes('parties') ? 3 : 0) +
      (t.includes('hereby agreed') ? 4 : 0) +
      (t.includes('terms and conditions') ? 4 : 0) +
      (t.includes('confidentiality') ? 4 : 0) +
      (t.includes('non-disclosure') || t.includes('nda') ? 5 : 0) +
      (t.includes('in witness whereof') ? 5 : 0) +
      (t.includes('governing law') ? 4 : 0) +
      (t.includes('effective date') ? 3 : 0) +
      (t.includes('termination clause') || t.includes('termination') ? 3 : 0) +
      (t.includes('indemnification') ? 4 : 0) +
      (t.includes('scope of work') || t.includes('sow') ? 4 : 0)
    );

    // Identity score
    const identityScore = (
      (t.includes('passport') ? 6 : 0) +
      (t.includes('driver license') || t.includes('driver\'s license') || t.includes('driving licence') ? 6 : 0) +
      (t.includes('identification card') || t.includes('identity card') || t.includes('id card') ? 5 : 0) +
      (t.includes('date of birth') || t.includes('dob') ? 4 : 0) +
      (t.includes('social security') || t.includes('ssn') ? 5 : 0) +
      (t.includes('nationality') ? 4 : 0) +
      (t.includes('republic of') || t.includes('united states of america') || t.includes('department of state') ? 3 : 0) +
      (t.includes('citizenship') ? 4 : 0) +
      (t.includes('expires') && t.includes('issued') ? 3 : 0)
    );

    // Financial & Tax score
    const taxScore = (
      (t.includes('w-2') || t.includes('1099') || t.includes('1040') ? 5 : 0) +
      (t.includes('internal revenue service') || t.includes('irs') ? 5 : 0) +
      (t.includes('tax return') ? 5 : 0) +
      (t.includes('bank statement') || t.includes('account statement') ? 5 : 0) +
      (t.includes('balance sheet') || t.includes('income statement') ? 4 : 0) +
      (t.includes('withholding') ? 4 : 0) +
      (t.includes('dividend') ? 3 : 0) +
      (t.includes('fiscal year') ? 3 : 0)
    );

    // Receipts score
    const receiptScore = (
      (t.includes('receipt') ? 5 : 0) +
      (t.includes('cashier') ? 4 : 0) +
      (t.includes('order total') || t.includes('total paid') ? 4 : 0) +
      (t.includes('visa ending') || t.includes('mastercard') || t.includes('amex') ? 4 : 0) +
      (t.includes('store #') || t.includes('register #') ? 3 : 0) +
      (t.includes('change due') ? 3 : 0)
    );

    let folder = 'Reports & Notes';
    let tags = ['#document', '#general', '#pdf'];
    let confidence = 75;
    let reasoning = 'Categorized based on document terminology and structural layout.';

    if (invoiceScore >= 5 && invoiceScore >= Math.max(contractScore, identityScore, taxScore, receiptScore)) {
      folder = 'Invoices';
      tags = ['#invoice', '#accounts-payable', '#billing', '#finance'];
      confidence = Math.min(99, 72 + invoiceScore * 2);
      reasoning = 'Detected vendor billing terms, payment instructions, and line items.';
    } else if (contractScore >= 5 && contractScore >= Math.max(invoiceScore, identityScore, taxScore, receiptScore)) {
      folder = 'Contracts';
      tags = ['#contract', '#legal-agreement', '#terms', '#binding', '#compliance'];
      confidence = Math.min(99, 72 + contractScore * 2);
      reasoning = 'Detected binding clauses, signatory terms, and contractual covenants.';
    } else if (identityScore >= 5 && identityScore >= Math.max(invoiceScore, contractScore, taxScore, receiptScore)) {
      folder = 'Identity';
      tags = ['#identity', '#gov-id', '#kyc-verified', '#official-record'];
      confidence = Math.min(99, 75 + identityScore * 2);
      reasoning = 'Detected government/official identification, personal identifiers, and credentials.';
    } else if (taxScore >= 5 && taxScore >= Math.max(invoiceScore, contractScore, identityScore, receiptScore)) {
      folder = 'Financial & Tax';
      tags = ['#financial', '#tax', '#statements', '#fiscal'];
      confidence = Math.min(98, 72 + taxScore * 2);
      reasoning = 'Detected financial accounting statements, tax schedule, or fiscal data.';
    } else if (receiptScore >= 4) {
      folder = 'Receipts';
      tags = ['#receipt', '#expense', '#merchant', '#reimbursement'];
      confidence = Math.min(96, 70 + receiptScore * 2);
      reasoning = 'Detected point-of-sale receipt with transaction totals and merchant info.';
    }

    const dateMatch = text.match(/\b(?:\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{4})\b/i);
    const amountMatch = text.match(/\$\s*[\d,]+(?:\.\d{2})?/);

    return {
      folder,
      tags,
      confidence,
      summary: `${folder} document${fileName ? ` (${fileName})` : ''}${amountMatch ? ` for ${amountMatch[0]}` : ''}${dateMatch ? ` on ${dateMatch[0]}` : ''}.`,
      reasoning,
      metadata: {
        date: dateMatch ? dateMatch[0] : undefined,
        amount: amountMatch ? amountMatch[0] : undefined,
        parties: [],
      },
      engine: 'heuristic',
    };
  }

  /**
   * Main classifier entry point: Calls server API with Gemini AI first,
   * seamlessly falls back to fast local heuristic if server is unavailable.
   */
  public static async classifyDocument(text: string, fileName = ''): Promise<AiClassificationResult> {
    try {
      const response = await fetch('/api/classify', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          text: text ? text.slice(0, 10000) : '',
          fileName,
        }),
      });

      if (response.ok) {
        const data = await response.json();
        if (data && data.folder) {
          return {
            folder: data.folder,
            tags: Array.isArray(data.tags) ? data.tags : ['#document'],
            confidence: typeof data.confidence === 'number' ? data.confidence : 90,
            summary: data.summary || `${data.folder} document.`,
            reasoning: data.reasoning,
            metadata: data.metadata,
            engine: data.engine || 'gemini',
          };
        }
      }
    } catch (e) {
      console.warn('Network call to /api/classify failed, using local AI classifier:', e);
    }

    // Client-side fallback
    return this.classifyLocally(text, fileName);
  }

  /**
   * Returns aesthetic theme styling for folder pills and badges
   */
  public static getFolderStyle(folderName = 'Uncategorized'): {
    bg: string;
    text: string;
    border: string;
    badgeBg: string;
    dotColor: string;
  } {
    const f = folderName.toLowerCase();
    if (f.includes('invoice')) {
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

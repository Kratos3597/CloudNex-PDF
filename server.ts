import express from "express";
import path from "path";
import { createServer as createViteServer } from "vite";
import { GoogleGenAI, Type } from "@google/genai";

const app = express();
const PORT = 3000;

app.use(express.json({ limit: "50mb" }));

// Lazy initialization of Gemini client
let genAiClient: GoogleGenAI | null = null;
function getGenAI(): GoogleGenAI {
  if (!genAiClient) {
    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      throw new Error("GEMINI_API_KEY environment variable is not configured");
    }
    genAiClient = new GoogleGenAI({ apiKey });
  }
  return genAiClient;
}

// Fallback rule-based classifier for offline / no-API-key mode
function classifyHeuristic(text: string, fileName = "") {
  const t = (text + " " + fileName).toLowerCase();

  // Invoice indicators
  const invoiceScore = (
    (t.includes("invoice") ? 4 : 0) +
    (t.includes("bill to") ? 3 : 0) +
    (t.includes("remit to") ? 3 : 0) +
    (t.includes("due date") ? 2 : 0) +
    (t.includes("balance due") ? 3 : 0) +
    (t.includes("amount due") ? 3 : 0) +
    (t.includes("subtotal") ? 2 : 0) +
    (t.includes("unit price") ? 2 : 0) +
    (t.includes("po #") || t.includes("p.o.") ? 2 : 0) +
    (t.includes("payment terms") ? 2 : 0)
  );

  // Contract indicators
  const contractScore = (
    (t.includes("agreement") ? 4 : 0) +
    (t.includes("contract") ? 4 : 0) +
    (t.includes("parties") ? 2 : 0) +
    (t.includes("hereby agreed") ? 3 : 0) +
    (t.includes("terms and conditions") ? 3 : 0) +
    (t.includes("confidentiality") ? 3 : 0) +
    (t.includes("non-disclosure") || t.includes("nda") ? 4 : 0) +
    (t.includes("in witness whereof") ? 4 : 0) +
    (t.includes("governing law") ? 3 : 0) +
    (t.includes("effective date") ? 2 : 0) +
    (t.includes("termination") ? 2 : 0) +
    (t.includes("indemnification") ? 3 : 0)
  );

  // Identity indicators
  const identityScore = (
    (t.includes("passport") ? 5 : 0) +
    (t.includes("driver license") || t.includes("driver's license") || t.includes("driving licence") ? 5 : 0) +
    (t.includes("identification card") || t.includes("identity card") || t.includes("id card") ? 4 : 0) +
    (t.includes("date of birth") || t.includes("dob") ? 3 : 0) +
    (t.includes("social security") || t.includes("ssn") ? 4 : 0) +
    (t.includes("nationality") ? 3 : 0) +
    (t.includes("sex") && (t.includes("m") || t.includes("f")) ? 2 : 0) +
    (t.includes("issued") && t.includes("expires") ? 2 : 0) +
    (t.includes("republic of") ? 2 : 0) +
    (t.includes("citizenship") ? 3 : 0)
  );

  // Financial & Tax indicators
  const taxScore = (
    (t.includes("w-2") || t.includes("1099") || t.includes("1040") ? 4 : 0) +
    (t.includes("internal revenue") || t.includes("irs") ? 4 : 0) +
    (t.includes("tax return") ? 4 : 0) +
    (t.includes("bank statement") ? 4 : 0) +
    (t.includes("account balance") ? 3 : 0) +
    (t.includes("withholding") ? 3 : 0) +
    (t.includes("dividend") ? 3 : 0) +
    (t.includes("balance sheet") ? 3 : 0)
  );

  // Receipts indicators
  const receiptScore = (
    (t.includes("receipt") ? 4 : 0) +
    (t.includes("cashier") ? 3 : 0) +
    (t.includes("order total") ? 3 : 0) +
    (t.includes("visa ending") || t.includes("mastercard ending") ? 3 : 0) +
    (t.includes("store #") ? 2 : 0) +
    (t.includes("change due") ? 2 : 0)
  );

  let folder = "Reports & Notes";
  let tags = ["#document", "#general"];
  let confidence = 75;
  let reasoning = "Classified based on general textual structure.";

  if (invoiceScore >= 4 && invoiceScore >= Math.max(contractScore, identityScore, taxScore, receiptScore)) {
    folder = "Invoices";
    tags = ["#invoice", "#accounts-payable", "#billing"];
    confidence = Math.min(98, 70 + invoiceScore * 3);
    reasoning = "Detected invoice terminology, billing line-items, and payment fields.";
  } else if (contractScore >= 4 && contractScore >= Math.max(invoiceScore, identityScore, taxScore, receiptScore)) {
    folder = "Contracts";
    tags = ["#contract", "#legal-agreement", "#terms", "#binding"];
    confidence = Math.min(98, 70 + contractScore * 3);
    reasoning = "Detected legal contract structure, binding clauses, and terms.";
  } else if (identityScore >= 4 && identityScore >= Math.max(invoiceScore, contractScore, taxScore, receiptScore)) {
    folder = "Identity";
    tags = ["#identity", "#gov-id", "#compliance", "#kyc"];
    confidence = Math.min(99, 75 + identityScore * 3);
    reasoning = "Detected official identification format, personal credentials, and dates.";
  } else if (taxScore >= 4 && taxScore >= Math.max(invoiceScore, contractScore, identityScore, receiptScore)) {
    folder = "Financial & Tax";
    tags = ["#financial", "#tax", "#banking", "#statement"];
    confidence = Math.min(96, 70 + taxScore * 3);
    reasoning = "Detected financial statements, fiscal reporting, or tax identifiers.";
  } else if (receiptScore >= 4) {
    folder = "Receipts";
    tags = ["#receipt", "#expense", "#merchant"];
    confidence = Math.min(95, 70 + receiptScore * 3);
    reasoning = "Detected merchant POS transaction slip or customer purchase receipt.";
  }

  // Extract amount or date hints if possible
  const dateMatch = text.match(/\b(?:\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+\d{1,2},?\s+\d{4})\b/i);
  const amountMatch = text.match(/\$\s*[\d,]+(?:\.\d{2})?/);

  return {
    folder,
    tags,
    confidence,
    summary: `${folder} document${fileName ? ` (${fileName})` : ""}${amountMatch ? ` totaling ${amountMatch[0]}` : ""}${dateMatch ? ` dated ${dateMatch[0]}` : ""}.`,
    reasoning,
    metadata: {
      date: dateMatch ? dateMatch[0] : undefined,
      amount: amountMatch ? amountMatch[0] : undefined,
      parties: [],
      referenceId: undefined,
    },
    engine: "heuristic" as const,
  };
}

// API Health Check
app.get("/api/health", (req, res) => {
  res.json({
    status: "ok",
    aiEnabled: Boolean(process.env.GEMINI_API_KEY),
  });
});

// API Auto-tag & Categorize endpoint
app.post("/api/classify", async (req, res) => {
  const { text = "", fileName = "" } = req.body || {};
  const cleanText = typeof text === "string" ? text.trim() : "";

  if (!cleanText && !fileName) {
    return res.status(400).json({ error: "No text or fileName provided for classification" });
  }

  // If Gemini API key is available, use Gemini 3.8 Flash for intelligent classification
  if (process.env.GEMINI_API_KEY) {
    try {
      const ai = getGenAI();
      const prompt = `Analyze this PDF document content and file name: "${fileName}".
Categorize it into one of the standard folders:
- 'Invoices' (bills, invoices, payment requests, vendor bills)
- 'Contracts' (agreements, NDAs, employment terms, leases, client service agreements)
- 'Identity' (passports, driver licenses, ID cards, social security cards, birth/citizenship certificates)
- 'Financial & Tax' (tax returns, W-2, 1099, bank/account statements, balance sheets)
- 'Receipts' (retail receipts, travel expenses, merchant slips)
- 'Reports & Notes' (status reports, whitepapers, memos, general documents)

Also provide:
1. tags: 3 to 6 descriptive hashtag-style or keyword tags (e.g., ["#invoice", "#acme-corp", "#q3-expense", "#tax-deductible"]).
2. confidence: number between 50 and 99.
3. summary: one concise sentence summarizing what the document is, key entity, and purpose.
4. reasoning: short explanation why this folder was chosen.
5. metadata: extracted dates, total amounts, parties/companies involved, and reference/invoice numbers if present.

DOCUMENT CONTENT SAMPLE:
${cleanText.slice(0, 8000)}`;

      const response = await ai.models.generateContent({
        model: "gemini-3.8-flash",
        contents: prompt,
        config: {
          responseMimeType: "application/json",
          responseSchema: {
            type: Type.OBJECT,
            properties: {
              folder: {
                type: Type.STRING,
                description: "Folder category name: 'Invoices', 'Contracts', 'Identity', 'Financial & Tax', 'Receipts', or 'Reports & Notes'",
              },
              tags: {
                type: Type.ARRAY,
                items: { type: Type.STRING },
                description: "Array of 3 to 6 descriptive tags",
              },
              confidence: {
                type: Type.NUMBER,
                description: "Classification confidence score 50-99",
              },
              summary: {
                type: Type.STRING,
                description: "Concise one-sentence summary of the document",
              },
              reasoning: {
                type: Type.STRING,
                description: "Short reason for this categorization",
              },
              metadata: {
                type: Type.OBJECT,
                properties: {
                  date: { type: Type.STRING },
                  parties: { type: Type.ARRAY, items: { type: Type.STRING } },
                  amount: { type: Type.STRING },
                  referenceId: { type: Type.STRING },
                },
              },
            },
            required: ["folder", "tags", "confidence", "summary"],
          },
        },
      });

      const responseText = response.text?.trim() || "{}";
      const parsed = JSON.parse(responseText);

      return res.json({
        folder: parsed.folder || "Reports & Notes",
        tags: Array.isArray(parsed.tags) ? parsed.tags : ["#document"],
        confidence: typeof parsed.confidence === "number" ? parsed.confidence : 92,
        summary: parsed.summary || `${parsed.folder || "Document"} classified via Gemini AI.`,
        reasoning: parsed.reasoning || "Categorized using deep semantic analysis of text structure and entities.",
        metadata: parsed.metadata || {},
        engine: "gemini",
      });
    } catch (err: any) {
      console.warn("Gemini API call failed, falling back to heuristic classifier:", err?.message || err);
      // Fall through to heuristic classifier
    }
  }

  // Fast, reliable semantic heuristic fallback
  const result = classifyHeuristic(cleanText, fileName);
  return res.json(result);
});

// Vite middleware / Static Serving
async function startServer() {
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), "dist");
    app.use(express.static(distPath));
    // Express v5 wildcard route
    app.get("*all", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`CloudNex PDF Server running on port ${PORT}`);
  });
}

startServer();

import React, { useEffect, useState, useMemo, useRef } from 'react';
import * as pdfjsLib from 'pdfjs-dist';

export interface TextLayerItem {
  id: string;
  str: string;
  leftPercent: number;
  topPercent: number;
  widthPercent: number;
  heightPercent: number;
  fontSizePx: number;
}

interface PdfTextLayerProps {
  pdfBytes: Uint8Array | null;
  currentPage: number;
  canvasWidth: number;
  canvasHeight: number;
  searchQuery?: string;
  activeMatchIndex?: number;
  onMatchesFound?: (matches: { id: string; str: string; page: number }[]) => void;
  isDrawingMode?: boolean;
}

export const PdfTextLayer: React.FC<PdfTextLayerProps> = ({
  pdfBytes,
  currentPage,
  canvasWidth,
  canvasHeight,
  searchQuery = '',
  activeMatchIndex = 0,
  onMatchesFound,
  isDrawingMode = false,
}) => {
  const [textItems, setTextItems] = useState<TextLayerItem[]>([]);
  const lastReportedKeyRef = useRef<string>('');

  useEffect(() => {
    if (!pdfBytes || currentPage < 1) return;
    let isCancelled = false;

    const extractPageText = async () => {
      try {
        // Clone buffer to prevent detaching shared ArrayBuffer
        const loadingTask = pdfjsLib.getDocument({ data: pdfBytes.slice() });
        const pdfDoc = await loadingTask.promise;
        if (currentPage > pdfDoc.numPages) {
          pdfDoc.destroy();
          return;
        }

        const page = await pdfDoc.getPage(currentPage);
        const viewport = page.getViewport({ scale: 1.0 });
        const textContent = await page.getTextContent();

        if (isCancelled) {
          page.cleanup();
          pdfDoc.destroy();
          return;
        }

        const items: TextLayerItem[] = [];
        const rawItems = textContent.items as any[];

        rawItems.forEach((item, index) => {
          if (!item.str || item.str.trim().length === 0) return;

          const tx = item.transform?.[4] || 0;
          const ty = item.transform?.[5] || 0;
          const fontHeight = Math.abs(item.transform?.[3] || item.height || 12);
          const fontWidth = item.width || (item.str.length * fontHeight * 0.6);

          const left = tx;
          const top = viewport.height - ty - fontHeight;

          const leftPercent = Math.max(0, Math.min(100, (left / viewport.width) * 100));
          const topPercent = Math.max(0, Math.min(100, (top / viewport.height) * 100));
          const widthPercent = Math.max(0.5, Math.min(100, (fontWidth / viewport.width) * 100));
          const heightPercent = Math.max(0.8, Math.min(50, (fontHeight / viewport.height) * 100));

          const fontSizePx = Math.max(8, Math.min(72, (fontHeight / viewport.height) * canvasHeight));

          items.push({
            id: `text-${currentPage}-${index}`,
            str: item.str,
            leftPercent,
            topPercent,
            widthPercent,
            heightPercent,
            fontSizePx,
          });
        });

        page.cleanup();
        pdfDoc.destroy();

        if (!isCancelled) {
          setTextItems(items);
        }
      } catch (err) {
        if (!isCancelled) {
          console.error('Error extracting text layer items:', err);
        }
      }
    };

    extractPageText();
    return () => { isCancelled = true; };
  }, [pdfBytes, currentPage, canvasWidth, canvasHeight]);

  // Compute search matches on the current page
  const matchingItemIds = useMemo(() => {
    if (!searchQuery.trim()) return [];
    const q = searchQuery.toLowerCase().trim();
    return textItems
      .filter(item => item.str.toLowerCase().includes(q))
      .map(item => item.id);
  }, [textItems, searchQuery]);

  // Report matches up to parent component safely without infinite loops
  useEffect(() => {
    if (!onMatchesFound) return;
    const q = searchQuery.toLowerCase().trim();
    if (!q) {
      if (lastReportedKeyRef.current !== '') {
        lastReportedKeyRef.current = '';
        onMatchesFound([]);
      }
      return;
    }

    const matched = textItems
      .filter(item => item.str.toLowerCase().includes(q))
      .map(item => ({
        id: item.id,
        str: item.str,
        page: currentPage,
      }));

    const key = `${currentPage}:${matched.map(m => m.id).join(',')}`;
    if (lastReportedKeyRef.current !== key) {
      lastReportedKeyRef.current = key;
      onMatchesFound(matched);
    }
  }, [searchQuery, currentPage, onMatchesFound, textItems]);

  if (textItems.length === 0) {
    return null;
  }

  return (
    <div
      id="pdf-selectable-text-layer"
      className={`absolute inset-0 select-text overflow-hidden ${
        isDrawingMode ? 'pointer-events-none' : 'pointer-events-auto'
      }`}
      style={{ width: `${canvasWidth}px`, height: `${canvasHeight}px` }}
      aria-label="Searchable and Selectable PDF Text Layer"
    >
      {textItems.map((item, idx) => {
        const isMatch = searchQuery.trim() && item.str.toLowerCase().includes(searchQuery.toLowerCase().trim());
        const matchIndexInPage = matchingItemIds.indexOf(item.id);
        const isActiveMatch = isMatch && matchIndexInPage === activeMatchIndex;

        return (
          <span
            key={item.id || idx}
            style={{
              position: 'absolute',
              left: `${item.leftPercent}%`,
              top: `${item.topPercent}%`,
              width: `${item.widthPercent}%`,
              height: `${item.heightPercent}%`,
              fontSize: `${item.fontSizePx}px`,
              lineHeight: `${item.fontSizePx}px`,
              color: 'transparent',
              cursor: isDrawingMode ? 'default' : 'text',
              userSelect: isDrawingMode ? 'none' : 'text',
              whiteSpace: 'pre',
            }}
            className={`selection:bg-blue-400/40 selection:text-blue-950 transition-colors duration-150 ${
              isActiveMatch
                ? 'bg-orange-500/60 ring-2 ring-orange-500 rounded-xs z-30 shadow-xs'
                : isMatch
                ? 'bg-amber-300/50 ring-1 ring-amber-400/60 rounded-xs z-20'
                : ''
            }`}
            title={item.str}
          >
            {item.str}
          </span>
        );
      })}
    </div>
  );
};

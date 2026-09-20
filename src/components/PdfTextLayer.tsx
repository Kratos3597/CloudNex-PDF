import React, { useEffect, useState, useMemo, useRef } from 'react';
import * as pdfjsLib from 'pdfjs-dist';

export interface TextLayerItem {
  id: string;
  str: string;
  leftPercent: number;
  topPercent: number;
  widthPercent: number;
  heightPercent: number;
  fontHeightRatio: number;
  hasSpaceAfter: boolean;
  hasEOLAfter: boolean;
  charStart: number;
  charEnd: number;
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
  const onMatchesFoundRef = useRef(onMatchesFound);

  useEffect(() => {
    onMatchesFoundRef.current = onMatchesFound;
  }, [onMatchesFound]);

  useEffect(() => {
    if (!pdfBytes || currentPage < 1) {
      setTextItems([]);
      return;
    }
    let isCancelled = false;

    const extractPageText = async () => {
      let pdfDoc: any = null;
      let page: any = null;
      try {
        // Clone buffer to prevent detaching shared ArrayBuffer
        const loadingTask = pdfjsLib.getDocument({ data: pdfBytes.slice() });
        pdfDoc = await loadingTask.promise;
        if (isCancelled) return;

        if (currentPage > pdfDoc.numPages) return;

        page = await pdfDoc.getPage(currentPage);
        const viewport = page.getViewport({ scale: 1.0 });
        const textContent = await page.getTextContent();

        if (isCancelled) return;

        const rawItems = (textContent.items as any[]) || [];
        if (rawItems.length === 0) {
          if (!isCancelled) setTextItems([]);
          return;
        }

        // Pass 1: Extract geometry and text runs
        interface RawParsedItem {
          str: string;
          hasEOL: boolean;
          left: number;
          top: number;
          width: number;
          height: number;
          fontHeight: number;
          right: number;
        }

        const parsed: RawParsedItem[] = [];

        for (let idx = 0; idx < rawItems.length; idx++) {
          const raw = rawItems[idx];
          if (!raw) continue;

          // If item is empty but hasEOL, mark preceding item as EOL
          if (!raw.str || raw.str.length === 0) {
            if (raw.hasEOL && parsed.length > 0) {
              parsed[parsed.length - 1].hasEOL = true;
            }
            continue;
          }

          const tx = raw.transform?.[4] || 0;
          const ty = raw.transform?.[5] || 0;
          const fontHeight = Math.abs(raw.transform?.[3] || raw.height || 12);
          const fontWidth = raw.width || (raw.str.length * fontHeight * 0.58);

          const left = tx;
          const top = viewport.height - ty - fontHeight;

          parsed.push({
            str: raw.str,
            hasEOL: !!raw.hasEOL,
            left,
            top,
            width: fontWidth,
            height: fontHeight,
            fontHeight,
            right: left + fontWidth,
          });
        }

        // Pass 2: Detect word boundaries and line endings for flawless text selection
        const items: TextLayerItem[] = [];
        let runningOffset = 0;

        for (let i = 0; i < parsed.length; i++) {
          const curr = parsed[i];
          const next = i < parsed.length - 1 ? parsed[i + 1] : null;

          let hasEOLAfter = curr.hasEOL;
          let hasSpaceAfter = false;

          if (next) {
            const dy = Math.abs(next.top - curr.top);
            const isNextLine =
              curr.hasEOL ||
              dy > Math.min(curr.fontHeight, next.fontHeight) * 0.45 ||
              next.top > curr.top + curr.fontHeight * 0.5;

            if (isNextLine) {
              hasEOLAfter = true;
              hasSpaceAfter = false;
            } else {
              // On the same line: evaluate if a space exists between items
              hasEOLAfter = false;
              const endsWithWhitespace = /\s$/.test(curr.str);
              const nextStartsWithWhitespace = /^\s/.test(next.str);

              if (!endsWithWhitespace && !nextStartsWithWhitespace) {
                const gap = next.left - curr.right;
                // Detect gap between words or separated tokens
                if (gap >= curr.fontHeight * 0.15) {
                  hasSpaceAfter = true;
                } else if (gap >= -0.5 && /\w+$/.test(curr.str) && /^\w+/.test(next.str)) {
                  // Adjacent distinct words (e.g. OCR words or tokens)
                  hasSpaceAfter = true;
                } else if (/[:.,;!?)]$/.test(curr.str) && gap >= -0.5) {
                  // After colon/punctuation (e.g. "ITEM 01:", "QTY: 1")
                  hasSpaceAfter = true;
                }
              }
            }
          } else {
            hasEOLAfter = true;
            hasSpaceAfter = false;
          }

          const leftPercent = Math.max(0, Math.min(100, (curr.left / viewport.width) * 100));
          const topPercent = Math.max(0, Math.min(100, (curr.top / viewport.height) * 100));
          // Slightly expand width if space is appended so mouse drag covers space smoothly
          const extraSpaceWidth = hasSpaceAfter ? curr.fontHeight * 0.28 : 0;
          const widthPercent = Math.max(0.2, Math.min(100, ((curr.width + extraSpaceWidth) / viewport.width) * 100));
          const heightPercent = Math.max(0.8, Math.min(50, (curr.height / viewport.height) * 100));
          const fontHeightRatio = curr.fontHeight / viewport.height;

          const charStart = runningOffset;
          const fullTokenText = curr.str + (hasSpaceAfter ? ' ' : hasEOLAfter ? '\n' : '');
          runningOffset += fullTokenText.length;
          const charEnd = runningOffset;

          items.push({
            id: `text-${currentPage}-${i}`,
            str: curr.str,
            leftPercent,
            topPercent,
            widthPercent,
            heightPercent,
            fontHeightRatio,
            hasSpaceAfter,
            hasEOLAfter,
            charStart,
            charEnd,
          });
        }

        if (!isCancelled) {
          setTextItems(items);
        }
      } catch (err) {
        if (!isCancelled) {
          console.error('Error extracting text layer items:', err);
        }
      } finally {
        if (page) {
          try { page.cleanup(); } catch (_) {}
        }
        if (pdfDoc) {
          try { pdfDoc.destroy(); } catch (_) {}
        }
      }
    };

    extractPageText();
    return () => { isCancelled = true; };
  }, [pdfBytes, currentPage]);

  // Construct continuous full text for accurate multi-token search
  const pageFullText = useMemo(() => {
    return textItems
      .map(item => item.str + (item.hasSpaceAfter ? ' ' : item.hasEOLAfter ? '\n' : ''))
      .join('');
  }, [textItems]);

  // Compute search match groups (each query occurrence can span one or more items)
  const searchMatchGroups = useMemo(() => {
    const q = searchQuery.toLowerCase().trim();
    if (!q || textItems.length === 0 || !pageFullText) return [];

    const lowerFullText = pageFullText.toLowerCase();
    const groups: { matchIndex: number; itemIds: string[]; text: string }[] = [];
    let startIdx = 0;

    while (startIdx < lowerFullText.length) {
      const matchIdx = lowerFullText.indexOf(q, startIdx);
      if (matchIdx === -1) break;

      const matchEnd = matchIdx + q.length;
      const matchingItems = textItems.filter(
        item => item.charStart < matchEnd && item.charEnd > matchIdx
      );

      if (matchingItems.length > 0) {
        groups.push({
          matchIndex: groups.length,
          itemIds: matchingItems.map(m => m.id),
          text: pageFullText.slice(matchIdx, matchEnd),
        });
      }

      startIdx = matchIdx + Math.max(1, q.length);
    }

    return groups;
  }, [pageFullText, textItems, searchQuery]);

  // Map each item ID to its active / matched highlight status
  const { matchedItemMap, activeItemIds } = useMemo(() => {
    const matchedMap = new Set<string>();
    const activeSet = new Set<string>();

    searchMatchGroups.forEach((group, gIdx) => {
      group.itemIds.forEach(id => matchedMap.add(id));
      if (gIdx === activeMatchIndex) {
        group.itemIds.forEach(id => activeSet.add(id));
      }
    });

    return { matchedItemMap: matchedMap, activeItemIds: activeSet };
  }, [searchMatchGroups, activeMatchIndex]);

  // Report matches up to parent component safely
  useEffect(() => {
    const callback = onMatchesFoundRef.current;
    if (!callback) return;

    const q = searchQuery.toLowerCase().trim();
    if (!q || searchMatchGroups.length === 0) {
      if (lastReportedKeyRef.current !== '') {
        lastReportedKeyRef.current = '';
        callback([]);
      }
      return;
    }

    const matched = searchMatchGroups.map(group => ({
      id: group.itemIds[0] || `match-${currentPage}-${group.matchIndex}`,
      str: group.text,
      page: currentPage,
    }));

    const key = `${currentPage}:${matched.map(m => m.id).join(',')}:${matched.length}`;
    if (lastReportedKeyRef.current !== key) {
      lastReportedKeyRef.current = key;
      callback(matched);
    }
  }, [searchQuery, currentPage, searchMatchGroups]);

  // Clean clipboard copy handler ensuring spaces and line breaks are faithfully preserved
  const handleCopy = (e: React.ClipboardEvent<HTMLDivElement>) => {
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0 || selection.isCollapsed) return;
    const rawCopied = selection.toString();
    if (!rawCopied) return;

    // Clean duplicate whitespace while preserving newlines
    const cleanText = rawCopied.replace(/[ \t]{2,}/g, ' ');
    if (cleanText !== rawCopied) {
      e.clipboardData.setData('text/plain', cleanText);
      e.preventDefault();
    }
  };

  if (textItems.length === 0) {
    return null;
  }

  return (
    <div
      id="pdf-selectable-text-layer"
      onCopy={handleCopy}
      className={`absolute inset-0 select-text overflow-hidden ${
        isDrawingMode ? 'pointer-events-none' : 'pointer-events-auto'
      }`}
      style={{ width: `${canvasWidth}px`, height: `${canvasHeight}px` }}
      aria-label="Searchable and Selectable PDF Text Layer"
    >
      {textItems.map((item, idx) => {
        const isMatch = matchedItemMap.has(item.id);
        const isActiveMatch = activeItemIds.has(item.id);
        const fontSizePx = Math.max(8, Math.min(72, item.fontHeightRatio * canvasHeight));

        return (
          <React.Fragment key={item.id || idx}>
            <span
              id={`pdf-text-${item.id}`}
              style={{
                position: 'absolute',
                left: `${item.leftPercent}%`,
                top: `${item.topPercent}%`,
                width: `${item.widthPercent}%`,
                height: `${item.heightPercent}%`,
                fontSize: `${fontSizePx}px`,
                lineHeight: `${fontSizePx}px`,
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
              {item.str}{item.hasSpaceAfter ? ' ' : ''}
            </span>
            {item.hasEOLAfter && <br role="presentation" />}
          </React.Fragment>
        );
      })}
    </div>
  );
};

import { useEffect, useRef, useState, useCallback } from 'react';

interface UsePinchToZoomOptions {
  containerRef: React.RefObject<HTMLDivElement | null>;
  targetRef: React.RefObject<HTMLDivElement | null>;
  zoomScale: number;
  setZoomScale: (scale: number | ((prev: number) => number)) => void;
  minScale?: number;
  maxScale?: number;
  defaultScale?: number;
  disabled?: boolean;
}

export interface PinchState {
  isPinching: boolean;
  pinchScale: number;
  visualScale: number;
}

export function usePinchToZoom({
  containerRef,
  targetRef,
  zoomScale,
  setZoomScale,
  minScale = 0.45,
  maxScale = 3.5,
  defaultScale = 1.0,
  disabled = false,
}: UsePinchToZoomOptions): PinchState {
  const [isPinching, setIsPinching] = useState(false);
  const [pinchScale, setPinchScale] = useState(zoomScale);
  const [visualScale, setVisualScale] = useState(1);

  // References to keep event handlers fresh without re-binding
  const gestureRef = useRef<{
    active: boolean;
    initialDistance: number;
    initialMidX: number;
    initialMidY: number;
    initialZoom: number;
    currentZoom: number;
    originXPercent: number;
    originYPercent: number;
    lastTapTime: number;
    lastTapX: number;
    lastTapY: number;
  }>({
    active: false,
    initialDistance: 0,
    initialMidX: 0,
    initialMidY: 0,
    initialZoom: zoomScale,
    currentZoom: zoomScale,
    originXPercent: 50,
    originYPercent: 50,
    lastTapTime: 0,
    lastTapX: 0,
    lastTapY: 0,
  });

  const zoomScaleRef = useRef(zoomScale);
  zoomScaleRef.current = zoomScale;

  const clamp = useCallback((val: number) => Math.max(minScale, Math.min(maxScale, val)), [minScale, maxScale]);

  // Sync internal state when external zoom changes
  useEffect(() => {
    if (!gestureRef.current.active) {
      setPinchScale(zoomScale);
      setVisualScale(1);
    }
  }, [zoomScale]);

  useEffect(() => {
    const container = containerRef.current;
    if (!container || disabled) return;

    const getTouchDistance = (t1: Touch, t2: Touch) => {
      const dx = t2.clientX - t1.clientX;
      const dy = t2.clientY - t1.clientY;
      return Math.hypot(dx, dy);
    };

    const handleTouchStart = (e: TouchEvent) => {
      // Handle multi-touch pinch gesture (2 fingers)
      if (e.touches.length === 2) {
        e.preventDefault();
        const t1 = e.touches[0];
        const t2 = e.touches[1];
        const dist = getTouchDistance(t1, t2);

        const midX = (t1.clientX + t2.clientX) / 2;
        const midY = (t1.clientY + t2.clientY) / 2;

        const target = targetRef.current;
        let originXPercent = 50;
        let originYPercent = 50;

        if (target) {
          const rect = target.getBoundingClientRect();
          if (rect.width > 0 && rect.height > 0) {
            originXPercent = Math.max(0, Math.min(100, ((midX - rect.left) / rect.width) * 100));
            originYPercent = Math.max(0, Math.min(100, ((midY - rect.top) / rect.height) * 100));
          }
        }

        gestureRef.current = {
          ...gestureRef.current,
          active: true,
          initialDistance: dist,
          initialMidX: midX,
          initialMidY: midY,
          initialZoom: zoomScaleRef.current,
          currentZoom: zoomScaleRef.current,
          originXPercent,
          originYPercent,
        };

        setIsPinching(true);
        setPinchScale(zoomScaleRef.current);
        setVisualScale(1);

        if (target) {
          target.style.transformOrigin = `${originXPercent.toFixed(1)}% ${originYPercent.toFixed(1)}%`;
          target.style.willChange = 'transform';
        }
      } else if (e.touches.length === 1) {
        // Double-tap zoom detector
        const now = Date.now();
        const touch = e.touches[0];
        const { lastTapTime, lastTapX, lastTapY } = gestureRef.current;
        const timeDiff = now - lastTapTime;
        const dist = Math.hypot(touch.clientX - lastTapX, touch.clientY - lastTapY);

        if (timeDiff > 40 && timeDiff < 320 && dist < 25) {
          // Double-tap detected
          e.preventDefault();
          gestureRef.current.lastTapTime = 0; // reset
          const current = zoomScaleRef.current;
          if (current > defaultScale * 1.3) {
            setZoomScale(defaultScale);
          } else {
            setZoomScale(clamp(defaultScale * 1.85));
          }
        } else {
          gestureRef.current.lastTapTime = now;
          gestureRef.current.lastTapX = touch.clientX;
          gestureRef.current.lastTapY = touch.clientY;
        }
      }
    };

    const handleTouchMove = (e: TouchEvent) => {
      if (!gestureRef.current.active || e.touches.length !== 2) return;
      e.preventDefault();

      const t1 = e.touches[0];
      const t2 = e.touches[1];
      const dist = getTouchDistance(t1, t2);
      if (gestureRef.current.initialDistance <= 0) return;

      const scaleMultiplier = dist / gestureRef.current.initialDistance;
      const targetZoom = clamp(gestureRef.current.initialZoom * scaleMultiplier);
      const currentVisualScale = targetZoom / gestureRef.current.initialZoom;

      const currentMidX = (t1.clientX + t2.clientX) / 2;
      const currentMidY = (t1.clientY + t2.clientY) / 2;
      const panX = currentMidX - gestureRef.current.initialMidX;
      const panY = currentMidY - gestureRef.current.initialMidY;

      gestureRef.current.currentZoom = targetZoom;

      // Apply fluid hardware-accelerated 60fps CSS transform during gesture
      const target = targetRef.current;
      if (target) {
        target.style.transform = `translate3d(${panX.toFixed(1)}px, ${panY.toFixed(1)}px, 0) scale(${currentVisualScale.toFixed(3)})`;
      }

      setPinchScale(targetZoom);
      setVisualScale(currentVisualScale);
    };

    const handleTouchEnd = (e: TouchEvent) => {
      if (!gestureRef.current.active) return;

      // When dropping below 2 touches, finalize pinch gesture
      if (e.touches.length < 2) {
        const finalZoom = Number(gestureRef.current.currentZoom.toFixed(2));
        gestureRef.current.active = false;

        const target = targetRef.current;
        if (target) {
          // Clean up temporary hardware transform smoothly
          target.style.transition = 'transform 0.12s ease-out';
          target.style.transform = 'translate3d(0, 0, 0) scale(1)';

          setTimeout(() => {
            if (target) {
              target.style.transition = '';
              target.style.transform = '';
              target.style.transformOrigin = '';
              target.style.willChange = '';
            }
            setZoomScale(finalZoom);
            setIsPinching(false);
            setVisualScale(1);
          }, 120);
        } else {
          setZoomScale(finalZoom);
          setIsPinching(false);
          setVisualScale(1);
        }
      }
    };

    // Trackpad Pinch-to-zoom on Tablet Keyboards (iPad Magic Keyboard / Surface Keyboard)
    const handleWheel = (e: WheelEvent) => {
      if (e.ctrlKey) {
        // ctrlKey + wheel is standard trackpad pinch gesture
        e.preventDefault();
        const zoomDelta = -e.deltaY * 0.005;
        const newZoom = clamp(zoomScaleRef.current + zoomDelta);
        setZoomScale(Number(newZoom.toFixed(2)));
      }
    };

    // Use passive: false to allow e.preventDefault() for smooth touch zooming without page interference
    container.addEventListener('touchstart', handleTouchStart, { passive: false });
    container.addEventListener('touchmove', handleTouchMove, { passive: false });
    container.addEventListener('touchend', handleTouchEnd, { passive: false });
    container.addEventListener('touchcancel', handleTouchEnd, { passive: false });
    container.addEventListener('wheel', handleWheel, { passive: false });

    return () => {
      container.removeEventListener('touchstart', handleTouchStart);
      container.removeEventListener('touchmove', handleTouchMove);
      container.removeEventListener('touchend', handleTouchEnd);
      container.removeEventListener('touchcancel', handleTouchEnd);
      container.removeEventListener('wheel', handleWheel);
    };
  }, [containerRef, targetRef, clamp, defaultScale, disabled, setZoomScale]);

  return {
    isPinching,
    pinchScale,
    visualScale,
  };
}

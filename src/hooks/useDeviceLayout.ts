import { useState, useEffect } from 'react';

export type DeviceType = 'phone' | 'tablet' | 'desktop';
export type DeviceOrientation = 'portrait' | 'landscape';

export interface DeviceLayoutState {
  width: number;
  height: number;
  deviceType: DeviceType;
  orientation: DeviceOrientation;
  isPhone: boolean;
  isTablet: boolean;
  isDesktop: boolean;
  isPhonePortrait: boolean;
  isTabletLandscape: boolean;
  columnsCount: number;
  sidebarVisibleByDefault: boolean;
  touchTargetMinHeight: number;
  fontSizeScale: number;
  suggestedPdfScale: number;
}

export function useDeviceLayout(): DeviceLayoutState {
  const [windowSize, setWindowSize] = useState(() => ({
    width: typeof window !== 'undefined' ? window.innerWidth : 1024,
    height: typeof window !== 'undefined' ? window.innerHeight : 768,
  }));

  useEffect(() => {
    const handleResize = () => {
      setWindowSize({
        width: window.innerWidth,
        height: window.innerHeight,
      });
    };

    window.addEventListener('resize', handleResize);
    window.addEventListener('orientationchange', handleResize);
    return () => {
      window.removeEventListener('resize', handleResize);
      window.removeEventListener('orientationchange', handleResize);
    };
  }, []);

  const { width, height } = windowSize;
  const orientation: DeviceOrientation = height >= width ? 'portrait' : 'landscape';

  // Dynamic device detection based on viewport, aspect ratio, and touch profile
  let deviceType: DeviceType = 'desktop';
  if (width < 640 || (width < 768 && orientation === 'portrait')) {
    deviceType = 'phone';
  } else if (width <= 1200) {
    deviceType = 'tablet';
  } else {
    deviceType = 'desktop';
  }

  const isPhone = deviceType === 'phone';
  const isTablet = deviceType === 'tablet';
  const isDesktop = deviceType === 'desktop';
  const isPhonePortrait = isPhone && orientation === 'portrait';
  const isTabletLandscape = (isTablet || isDesktop) && orientation === 'landscape';

  const columnsCount = isPhone ? 1 : isTabletLandscape ? 3 : 2;
  const sidebarVisibleByDefault = isTabletLandscape && width >= 860;
  const touchTargetMinHeight = isPhone ? 48 : 40;
  const fontSizeScale = isPhone ? 0.95 : isTabletLandscape ? 1.05 : 1;

  // Suggested baseline PDF zoom scale to automatically fit page dimensions
  let suggestedPdfScale = 1.1;
  if (isPhonePortrait) {
    const usableWidth = Math.max(280, width - 24);
    suggestedPdfScale = Number(Math.max(0.48, Math.min(1.05, usableWidth / 595)).toFixed(2));
  } else if (isTabletLandscape) {
    const availableWidth = width - (sidebarVisibleByDefault ? 220 : 60) - 48;
    suggestedPdfScale = Number(Math.max(0.85, Math.min(1.6, availableWidth / 595)).toFixed(2));
  }

  return {
    width,
    height,
    deviceType,
    orientation,
    isPhone,
    isTablet,
    isDesktop,
    isPhonePortrait,
    isTabletLandscape,
    columnsCount,
    sidebarVisibleByDefault,
    touchTargetMinHeight,
    fontSizeScale,
    suggestedPdfScale,
  };
}

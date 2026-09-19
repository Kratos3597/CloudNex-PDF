import { useState, useEffect, useCallback } from 'react';

export type DeviceModePreset = 'auto' | 'phone-portrait' | 'tablet-landscape' | 'desktop';
export type DeviceType = 'phone' | 'tablet' | 'desktop';
export type DeviceOrientation = 'portrait' | 'landscape';

export interface DeviceLayoutState {
  preset: DeviceModePreset;
  setPreset: (preset: DeviceModePreset) => void;
  // Effective dimensions (simulated or real)
  width: number;
  height: number;
  deviceType: DeviceType;
  orientation: DeviceOrientation;
  isPhone: boolean;
  isTablet: boolean;
  isDesktop: boolean;
  isPhonePortrait: boolean;
  isTabletLandscape: boolean;
  // Dynamic scaling metrics
  columnsCount: number;
  sidebarVisibleByDefault: boolean;
  touchTargetMinHeight: number;
  fontSizeScale: number; // 1 for normal, 0.9 for compact phone, 1.05 for tablet
  suggestedPdfScale: number; // Dynamic baseline PDF zoom
}

export function useDeviceLayout(): DeviceLayoutState {
  const [preset, setPreset] = useState<DeviceModePreset>(() => {
    return (localStorage.getItem('cloudnex_device_preset') as DeviceModePreset) || 'auto';
  });

  const [windowSize, setWindowSize] = useState({
    width: typeof window !== 'undefined' ? window.innerWidth : 1024,
    height: typeof window !== 'undefined' ? window.innerHeight : 768,
  });

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

  const handleSetPreset = useCallback((newPreset: DeviceModePreset) => {
    setPreset(newPreset);
    localStorage.setItem('cloudnex_device_preset', newPreset);
  }, []);

  // Compute effective width & height based on preset or real viewport
  let effectiveWidth = windowSize.width;
  let effectiveHeight = windowSize.height;

  if (preset === 'phone-portrait') {
    effectiveWidth = Math.min(windowSize.width, 390);
    effectiveHeight = Math.max(windowSize.height, 844);
  } else if (preset === 'tablet-landscape') {
    effectiveWidth = Math.max(windowSize.width, 1024);
    effectiveHeight = Math.min(windowSize.height, 768);
  }

  // Derive device type & orientation
  const isLandscapeReal = effectiveWidth > effectiveHeight;
  const orientation: DeviceOrientation = preset === 'phone-portrait'
    ? 'portrait'
    : preset === 'tablet-landscape'
    ? 'landscape'
    : isLandscapeReal
    ? 'landscape'
    : 'portrait';

  let deviceType: DeviceType = 'desktop';
  if (preset === 'phone-portrait') {
    deviceType = 'phone';
  } else if (preset === 'tablet-landscape') {
    deviceType = 'tablet';
  } else {
    // Auto detection
    if (effectiveWidth < 640 || (effectiveWidth < 768 && orientation === 'portrait')) {
      deviceType = 'phone';
    } else if (effectiveWidth <= 1200) {
      deviceType = 'tablet';
    } else {
      deviceType = 'desktop';
    }
  }

  const isPhone = deviceType === 'phone';
  const isTablet = deviceType === 'tablet';
  const isDesktop = deviceType === 'desktop';
  const isPhonePortrait = isPhone && orientation === 'portrait';
  const isTabletLandscape = (isTablet || isDesktop) && orientation === 'landscape';

  // Dynamic layout calculations
  const columnsCount = isPhone ? 1 : isTabletLandscape ? 3 : 2;
  const sidebarVisibleByDefault = isTabletLandscape && effectiveWidth >= 900;
  const touchTargetMinHeight = isPhone ? 48 : 40;
  const fontSizeScale = isPhone ? 0.95 : isTabletLandscape ? 1.05 : 1;

  // Suggested baseline PDF zoom scale to fit page width
  // Standard A4 PDF point width is ~595px
  let suggestedPdfScale = 1.2;
  if (isPhonePortrait) {
    // On phone portrait, fit comfortably within screen width minus 32px padding
    const usableWidth = Math.max(280, effectiveWidth - 32);
    suggestedPdfScale = Number(Math.max(0.48, Math.min(1.0, usableWidth / 595)).toFixed(2));
  } else if (isTabletLandscape) {
    // On tablet landscape, fit comfortably into dual-pane viewport
    const availableWidth = effectiveWidth - (sidebarVisibleByDefault ? 280 : 80) - 64;
    suggestedPdfScale = Number(Math.max(0.85, Math.min(1.6, availableWidth / 595)).toFixed(2));
  }

  return {
    preset,
    setPreset: handleSetPreset,
    width: effectiveWidth,
    height: effectiveHeight,
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

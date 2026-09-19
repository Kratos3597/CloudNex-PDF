import React from 'react';
import { Smartphone, Tablet, Monitor, RotateCw, Maximize2, Minimize2 } from 'lucide-react';
import { DeviceLayoutState } from '../hooks/useDeviceLayout';

interface DeviceScaleControlProps {
  layout: DeviceLayoutState;
  onFitWidth?: () => void;
  onFitPage?: () => void;
  compact?: boolean;
}

export const DeviceScaleControl: React.FC<DeviceScaleControlProps> = ({
  layout,
  onFitWidth,
  onFitPage,
  compact = false,
}) => {
  const { preset, setPreset, isPhonePortrait, isTabletLandscape, orientation, deviceType } = layout;

  return (
    <div className="flex items-center gap-1.5 bg-gray-100 dark:bg-zinc-800 p-1 rounded-xl border border-gray-200/80 dark:border-zinc-700/80 text-xs">
      {/* Phone Portrait Mode Button */}
      <button
        id="device-preset-phone"
        onClick={() => setPreset(preset === 'phone-portrait' ? 'auto' : 'phone-portrait')}
        className={`px-2.5 py-1.5 rounded-lg font-semibold flex items-center gap-1.5 transition-all cursor-pointer ${
          preset === 'phone-portrait' || (preset === 'auto' && isPhonePortrait)
            ? 'bg-white dark:bg-zinc-700 text-[#0052CC] dark:text-blue-400 shadow-xs ring-1 ring-[#0052CC]/20'
            : 'text-gray-500 hover:text-gray-900 dark:text-zinc-400 dark:hover:text-white'
        }`}
        title="Phone Portrait Scale (Optimized for one-handed thumb reach & vertical stream)"
      >
        <Smartphone className="w-3.5 h-3.5" />
        {!compact && <span className="hidden sm:inline">Phone (Portrait)</span>}
      </button>

      {/* Tablet Landscape Mode Button */}
      <button
        id="device-preset-tablet"
        onClick={() => setPreset(preset === 'tablet-landscape' ? 'auto' : 'tablet-landscape')}
        className={`px-2.5 py-1.5 rounded-lg font-semibold flex items-center gap-1.5 transition-all cursor-pointer ${
          preset === 'tablet-landscape' || (preset === 'auto' && isTabletLandscape)
            ? 'bg-white dark:bg-zinc-700 text-[#0052CC] dark:text-blue-400 shadow-xs ring-1 ring-[#0052CC]/20'
            : 'text-gray-500 hover:text-gray-900 dark:text-zinc-400 dark:hover:text-white'
        }`}
        title="Tablet Landscape Scale (Dual-pane workspace with thumbnail rails and tool panels)"
      >
        <Tablet className="w-3.5 h-3.5" />
        {!compact && <span className="hidden sm:inline">Tablet (Landscape)</span>}
      </button>

      {/* Auto Responsive Mode */}
      <button
        id="device-preset-auto"
        onClick={() => setPreset('auto')}
        className={`px-2 py-1.5 rounded-lg font-semibold flex items-center gap-1 transition-all cursor-pointer ${
          preset === 'auto'
            ? 'text-[#0052CC] dark:text-blue-400 font-bold'
            : 'text-gray-400 hover:text-gray-700 dark:hover:text-zinc-300'
        }`}
        title="Auto Responsive (Detects actual screen dimensions and orientation)"
      >
        <Monitor className="w-3.5 h-3.5" />
        <span className="text-[10px] uppercase tracking-wider">{preset === 'auto' ? 'Auto' : 'Reset'}</span>
      </button>

      {/* Optional Fit Width / Fit Page triggers */}
      {(onFitWidth || onFitPage) && (
        <div className="hidden lg:flex items-center gap-1 pl-1 border-l border-gray-200 dark:border-zinc-700">
          {onFitWidth && (
            <button
              onClick={onFitWidth}
              className="px-2 py-1 hover:bg-white dark:hover:bg-zinc-700 rounded text-gray-600 dark:text-zinc-300 transition-colors cursor-pointer text-[11px]"
              title="Auto-Fit Width to Screen"
            >
              Fit Width
            </button>
          )}
          {onFitPage && (
            <button
              onClick={onFitPage}
              className="px-2 py-1 hover:bg-white dark:hover:bg-zinc-700 rounded text-gray-600 dark:text-zinc-300 transition-colors cursor-pointer text-[11px]"
              title="Auto-Fit Entire Page to Screen"
            >
              Fit Page
            </button>
          )}
        </div>
      )}
    </div>
  );
};

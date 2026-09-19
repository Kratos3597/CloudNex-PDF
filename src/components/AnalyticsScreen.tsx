import React from 'react';
import { 
  Eye, 
  Edit3, 
  Download, 
  Clock, 
  User, 
  FileText, 
  ShieldCheck,
  Activity
} from 'lucide-react';
import { StorageService } from '../services/storage';

export const AnalyticsScreen: React.FC = () => {
  const stats = StorageService.getActionStats();
  const auditLogs = StorageService.getAuditLogs();

  const getActionBadge = (action: string) => {
    switch (action) {
      case 'OPEN_DOCUMENT':
        return <span className="bg-blue-50 text-[#0052CC] border border-blue-200 px-2 py-0.5 rounded text-[10px] font-bold">VIEWED</span>;
      case 'MODIFY_DOCUMENT':
        return <span className="bg-amber-50 text-amber-700 border border-amber-200 px-2 py-0.5 rounded text-[10px] font-bold">EDITED</span>;
      case 'EXPORT_DOCUMENT':
      case 'EXPORT_EXCEL':
      case 'EXPORT_WORD':
        return <span className="bg-emerald-50 text-[#36B37E] border border-emerald-200 px-2 py-0.5 rounded text-[10px] font-bold">EXPORTED</span>;
      case 'MERGE_DOCUMENTS':
        return <span className="bg-purple-50 text-purple-700 border border-purple-200 px-2 py-0.5 rounded text-[10px] font-bold">MERGED</span>;
      case 'SIGN_DOCUMENT':
        return <span className="bg-indigo-50 text-indigo-700 border border-indigo-200 px-2 py-0.5 rounded text-[10px] font-bold">SIGNED</span>;
      default:
        return <span className="bg-gray-100 text-gray-700 px-2 py-0.5 rounded text-[10px] font-bold">{action}</span>;
    }
  };

  return (
    <div id="analytics-screen" className="max-w-6xl mx-auto px-4 py-8 space-y-8">
      {/* Header */}
      <div>
        <div className="flex items-center gap-2">
          <Activity className="w-6 h-6 text-[#0052CC]" />
          <h1 className="text-2xl font-extrabold text-[#172B4D] tracking-tight">
            Activity & Audit Analytics
          </h1>
        </div>
        <p className="text-xs text-[#6B778C] mt-1">
          Cryptographic audit trail tracking all document views, edits, signatures, and exports.
        </p>
      </div>

      {/* Summary KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-sm flex items-center gap-4">
          <div className="p-3 bg-[#0052CC]/10 text-[#0052CC] rounded-xl">
            <Eye className="w-6 h-6" />
          </div>
          <div>
            <span className="text-xs font-bold uppercase tracking-wider text-[#6B778C]">
              Viewed
            </span>
            <div className="text-2xl font-extrabold text-[#172B4D] mt-0.5">
              {stats.OPEN_DOCUMENT || 0}
            </div>
            <span className="text-[10px] text-gray-400">Total sessions loaded</span>
          </div>
        </div>

        <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-sm flex items-center gap-4">
          <div className="p-3 bg-[#FFAB00]/15 text-[#FFAB00] rounded-xl">
            <Edit3 className="w-6 h-6" />
          </div>
          <div>
            <span className="text-xs font-bold uppercase tracking-wider text-[#6B778C]">
              Edited
            </span>
            <div className="text-2xl font-extrabold text-[#172B4D] mt-0.5">
              {stats.MODIFY_DOCUMENT || 0}
            </div>
            <span className="text-[10px] text-gray-400">Modifications & annotations</span>
          </div>
        </div>

        <div className="bg-white p-5 rounded-xl border border-gray-200 shadow-sm flex items-center gap-4">
          <div className="p-3 bg-[#36B37E]/10 text-[#36B37E] rounded-xl">
            <Download className="w-6 h-6" />
          </div>
          <div>
            <span className="text-xs font-bold uppercase tracking-wider text-[#6B778C]">
              Exported
            </span>
            <div className="text-2xl font-extrabold text-[#172B4D] mt-0.5">
              {stats.EXPORT_DOCUMENT || 0}
            </div>
            <span className="text-[10px] text-gray-400">PDF, Excel, & Word downloads</span>
          </div>
        </div>
      </div>

      {/* Audit Log Table */}
      <div className="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden">
        <div className="p-5 border-b border-gray-100 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <ShieldCheck className="w-4 h-4 text-[#36B37E]" />
            <h3 className="font-bold text-sm text-[#172B4D]">Immutable Audit Trail</h3>
          </div>
          <span className="text-xs text-gray-400 font-medium">
            {auditLogs.length} Records Logged
          </span>
        </div>

        {auditLogs.length === 0 ? (
          <div className="p-12 text-center text-gray-400 text-xs">
            No activity logs recorded yet.
          </div>
        ) : (
          <div className="divide-y divide-gray-100">
            {auditLogs.map((entry) => (
              <div
                key={entry.id}
                className="p-4 hover:bg-gray-50 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs"
              >
                <div className="flex items-center gap-3">
                  <div className="p-2 bg-gray-100 rounded-lg text-gray-600">
                    <FileText className="w-4 h-4" />
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-gray-800 text-sm">
                        {entry.documentName}
                      </span>
                      {getActionBadge(entry.action)}
                    </div>
                    <div className="flex items-center gap-4 text-gray-400 mt-1">
                      <span className="flex items-center gap-1">
                        <Clock className="w-3 h-3" />
                        {new Date(entry.timestamp).toLocaleString()}
                      </span>
                      <span className="flex items-center gap-1">
                        <User className="w-3 h-3" />
                        {entry.user}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="text-[11px] font-mono text-gray-400 bg-gray-50 px-2 py-1 rounded border border-gray-100 self-start sm:self-auto">
                  ID: #{entry.id.slice(-6)}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};

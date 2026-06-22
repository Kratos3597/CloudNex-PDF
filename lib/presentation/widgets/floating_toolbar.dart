import 'package:flutter/material.dart';
import '../../core/theme/pdf_pro_theme.dart';

/// Point 3: Samsung DeX "Desktop mode" UI
/// A professional ribbon-style toolbar that replaces the floating dock on monitors.
class FloatingToolbar extends StatelessWidget {
  final VoidCallback onAnnotate;
  final VoidCallback onSign;
  final VoidCallback onEdit;
  final VoidCallback onForms;
  final VoidCallback onExport;
  final VoidCallback onPrint;

  const FloatingToolbar({
    super.key,
    required this.onAnnotate,
    required this.onSign,
    required this.onEdit,
    required this.onForms,
    required this.onExport,
    required this.onPrint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: Column(
        children: [
          // Ribbon Tabs (Simulation)
          Container(
            height: 24,
            color: PdfProTheme.backgroundLight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _ribbonTab("Home", true),
                _ribbonTab("Review", false),
                _ribbonTab("View", false),
                _ribbonTab("Help", false),
              ],
            ),
          ),
          // Tool Groups
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _toolGroup("Tools", [
                    _toolIcon(Icons.border_color_rounded, "Annotate", onAnnotate),
                    _toolIcon(Icons.gesture_rounded, "Sign", onSign),
                    _toolIcon(Icons.edit_document, "Edit", onEdit),
                  ]),
                  const VerticalDivider(width: 32),
                  _toolGroup("Document", [
                    _toolIcon(Icons.dynamic_form_rounded, "Forms", onForms),
                    _toolIcon(Icons.save_alt_rounded, "Export", onExport),
                    _toolIcon(Icons.print_rounded, "Print", onPrint),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ribbonTab(String label, bool active) {
    return Container(
      margin: const EdgeInsets.only(right: 20),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
          color: active ? PdfProTheme.primaryBlue : PdfProTheme.textLight,
        ),
      ),
    );
  }

  Widget _toolGroup(String label, List<Widget> children) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: children),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _toolIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: PdfProTheme.textDark),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: PdfProTheme.textDark)),
          ],
        ),
      ),
    );
  }
}

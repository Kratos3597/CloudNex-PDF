import 'package:flutter/material.dart';
import '../../../core/theme/pdf_pro_theme.dart';

/// Point 3: Samsung DeX "Desktop mode" UI
/// A professional ribbon-style toolbar that replaces the floating dock on monitors.
class DexDesktopRibbon extends StatelessWidget {
  final VoidCallback onAnnotate;
  final VoidCallback onSign;
  final VoidCallback onEdit;
  final VoidCallback onForms;
  final VoidCallback onExport;
  final VoidCallback onPrint;

  const DexDesktopRibbon({
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _ribbonGroup("Markup", [
                    _ribbonBtn(Icons.border_color_rounded, "Annotate", onAnnotate),
                    _ribbonBtn(Icons.gesture_rounded, "Signature", onSign),
                  ]),
                  const VerticalDivider(),
                  _ribbonGroup("Edit", [
                    _ribbonBtn(Icons.auto_fix_high_rounded, "Neural Edit", onEdit),
                    _ribbonBtn(Icons.text_fields_rounded, "Forms", onForms),
                  ]),
                  const VerticalDivider(),
                  _ribbonGroup("Output", [
                    _ribbonBtn(Icons.ios_share_rounded, "Export", onExport),
                    _ribbonBtn(Icons.print_rounded, "Print", onPrint),
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
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Text(label, style: TextStyle(
        fontSize: 10, 
        fontWeight: active ? FontWeight.bold : FontWeight.normal,
        color: active ? PdfProTheme.primaryBlue : PdfProTheme.textLight
      )),
    );
  }

  Widget _ribbonGroup(String groupName, List<Widget> children) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(children: children),
        const SizedBox(height: 4),
        Text(groupName.toUpperCase(), style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _ribbonBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: PdfProTheme.textDark),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: PdfProTheme.textDark)),
          ],
        ),
      ),
    );
  }
}

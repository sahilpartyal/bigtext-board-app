import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pro_badge.dart';

const Color _primaryBlue = Color(0xFF123768);
const Color _textPrimary = Color(0xFF1F2937);
const Color _textSecondary = Color(0xFF6B7280);

class FontSelector extends StatelessWidget {
  final List<String> fonts;
  final String selectedFont;
  final ValueChanged<String> onFontSelected;
  final bool isPro;
  final VoidCallback? onProTap;

  /// Number of free fonts (first N fonts are free)
  static const int freeFontCount = 2;

  const FontSelector({
    super.key,
    required this.fonts,
    required this.selectedFont,
    required this.onFontSelected,
    this.isPro = true,
    this.onProTap,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: fonts.contains(selectedFont) ? selectedFont : fonts.first,
      dropdownColor: Colors.white,
      style: const TextStyle(color: _textPrimary, fontSize: 14),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
      ),
      icon: const Icon(Icons.keyboard_arrow_down, color: _textSecondary, size: 20),
      isExpanded: true,
      menuMaxHeight: 300,
      items: fonts.asMap().entries.map((entry) {
        final index = entry.key;
        final font = entry.value;
        final isLocked = !isPro && index >= freeFontCount;

        return DropdownMenuItem<String>(
          value: font,
          enabled: !isLocked,
          child: Row(
            children: [
              Expanded(
                child: Opacity(
                  opacity: isLocked ? 0.5 : 1.0,
                  child: Text(
                    font,
                    style: GoogleFonts.getFont(
                      font,
                      textStyle: const TextStyle(color: _textPrimary, fontSize: 14),
                    ),
                  ),
                ),
              ),
              if (isLocked) ...[
                const SizedBox(width: 8),
                const ProBadge(fontSize: 8),
              ],
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          final index = fonts.indexOf(value);
          final isLocked = !isPro && index >= freeFontCount;
          if (isLocked) {
            onProTap?.call();
          } else {
            onFontSelected(value);
          }
        }
      },
    );
  }
}

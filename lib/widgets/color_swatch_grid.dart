import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Soft pastel fill colors with vibrant borders
class _ColorPalette {
  final Color softFill;
  final Color vibrantBorder;

  const _ColorPalette(this.softFill, this.vibrantBorder);
}

/// Maps each preset color to its soft fill + vibrant border version
final Map<int, _ColorPalette> _colorPalettes = {
  // Basic
  0: const _ColorPalette(Color(0xFFFAFAFA), Color(0xFFD1D5DB)),   // White
  1: const _ColorPalette(Color(0xFF1A1F3D), Color(0xFF0A0F2C)),   // Neon Ocean Dark Navy
  // Electric Sunset
  2: const _ColorPalette(Color(0xFFFFD4C4), Color(0xFFFF3C00)),   // Orange Red
  3: const _ColorPalette(Color(0xFFFFE4B8), Color(0xFFFF9A00)),   // Amber
  4: const _ColorPalette(Color(0xFFFFF6CC), Color(0xFFFFE14D)),   // Yellow
  // Neon Ocean
  5: const _ColorPalette(Color(0xFFC4D4F4), Color(0xFF0D3B8C)),   // Navy Blue
  6: const _ColorPalette(Color(0xFFB8DBFF), Color(0xFF0070FF)),   // Blue
  7: const _ColorPalette(Color(0xFFB8F0FF), Color(0xFF00C6FF)),   // Cyan
  8: const _ColorPalette(Color(0xFFD4FFF9), Color(0xFF7FFFEF)),   // Mint
  // Tropical Pop
  9: const _ColorPalette(Color(0xFFFFB8D4), Color(0xFFFF005C)),   // Hot Pink
  10: const _ColorPalette(Color(0xFFE4D4FF), Color(0xFFA855F7)),  // Purple
  11: const _ColorPalette(Color(0xFFF0FFB8), Color(0xFFCCFF00)),  // Lime
};

class ColorSwatchGrid extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onColorSelected;
  final bool isPro;
  final VoidCallback? onProTap;

  /// Number of free colors (first N colors are free)
  static const int freeColorCount = 3;

  const ColorSwatchGrid({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
    this.isPro = true,
    this.onProTap,
  });

  @override
  Widget build(BuildContext context) {
    // Fixed box size to match dropdown height (44px)
    const spacing = 8.0;
    const boxSize = 44.0;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: kPresetColors.asMap().entries.map((entry) {
        final index = entry.key;
        final color = entry.value;
        final isSelected = selectedColor.toARGB32() == color.toARGB32();
        final isLocked = !isPro && index >= freeColorCount;

        // Get soft fill and vibrant border for this color
        final palette = _colorPalettes[index] ?? _ColorPalette(color.withValues(alpha: 0.3), color);

        return GestureDetector(
          onTap: () {
            if (isLocked) {
              onProTap?.call();
            } else {
              onColorSelected(color);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: boxSize,
            height: boxSize,
            decoration: BoxDecoration(
              // Fill with vibrant border color
              color: palette.vibrantBorder,
              // Rounded rectangle shape
              borderRadius: BorderRadius.circular(10),
              // No border for selected, subtle border for unselected
              border: isSelected ? null : Border.all(
                color: palette.vibrantBorder,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: palette.vibrantBorder.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: isLocked
                ? Icon(
                    Icons.lock,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  )
                : isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white, // White check on filled color
                      )
                    : null,
          ),
        );
      }).toList(),
    );
  }
}

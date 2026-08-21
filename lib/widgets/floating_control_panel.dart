import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_settings.dart';
import '../utils/constants.dart';
import 'color_swatch_grid.dart';

class FloatingControlPanel extends StatelessWidget {
  final AppSettings settings;
  final VoidCallback onEditTitle;
  final VoidCallback onEditSubtitle;
  final ValueChanged<double> onTitleFontSizeChanged;
  final ValueChanged<double> onSubtitleFontSizeChanged;
  final ValueChanged<Color> onTitleColorChanged;
  final ValueChanged<Color> onSubtitleColorChanged;
  final ValueChanged<String> onFontChanged;
  final ValueChanged<String> onSubtitleFontChanged;
  final VoidCallback onClose;

  const FloatingControlPanel({
    super.key,
    required this.settings,
    required this.onEditTitle,
    required this.onEditSubtitle,
    required this.onTitleFontSizeChanged,
    required this.onSubtitleFontSizeChanged,
    required this.onTitleColorChanged,
    required this.onSubtitleColorChanged,
    required this.onFontChanged,
    required this.onSubtitleFontChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final panelWidth = screenWidth > 600
        ? screenWidth * 0.4
        : screenWidth * 0.85;
    // Use 80% of screen height, with min 400 and max 750
    final panelMaxHeight = (screenHeight * 0.80).clamp(400.0, 750.0);

    return Stack(
      children: [
        // Tap outside to dismiss
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Panel - centered horizontally
        Positioned(
          left: (screenWidth - panelWidth) / 2,
          top: 60,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: () {}, // Prevent tap from passing through
              child: Container(
                width: panelWidth,
                constraints: BoxConstraints(maxHeight: panelMaxHeight),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Sticky header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Controls',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: onClose,
                            child: const Icon(Icons.close, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                    // Scrollable content
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                // Edit buttons
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Edit Title',
                        onTap: onEditTitle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ActionButton(
                        label: 'Edit Subtitle',
                        onTap: onEditSubtitle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title font size
                _SliderRow(
                  label: 'Title Size',
                  value: settings.titleFontSize,
                  min: 20,
                  max: 300,
                  onChanged: onTitleFontSizeChanged,
                ),
                const SizedBox(height: 8),

                // Subtitle font size
                _SliderRow(
                  label: 'Subtitle Size',
                  value: settings.subtitleFontSize,
                  min: 10,
                  max: 100,
                  onChanged: onSubtitleFontSizeChanged,
                ),
                const SizedBox(height: 16),

                // Title color
                const Text(
                  'Title Color',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ColorSwatchGrid(
                  selectedColor: settings.titleColor,
                  onColorSelected: onTitleColorChanged,
                ),
                const SizedBox(height: 16),

                // Subtitle color
                const Text(
                  'Subtitle Color',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ColorSwatchGrid(
                  selectedColor: settings.subtitleColor,
                  onColorSelected: onSubtitleColorChanged,
                ),
                const SizedBox(height: 16),

                // Title Font
                const Text(
                  'Title Font',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: kAllFontFamilies.map((font) {
                    final isSelected = font == settings.fontFamily;
                    return GestureDetector(
                      onTap: () => onFontChanged(font),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blue.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          font,
                          style: GoogleFonts.getFont(
                            font,
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Subtitle Font
                const Text(
                  'Subtitle Font',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: kAllFontFamilies.map((font) {
                    final isSelected = font == settings.subtitleFontFamily;
                    return GestureDetector(
                      onTap: () => onSubtitleFontChanged(font),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orange.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? Colors.orange
                                : Colors.transparent,
                          ),
                        ),
                        child: Text(
                          font,
                          style: GoogleFonts.getFont(
                            font,
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.blue, fontSize: 14),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label: ${value.round()}',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FixedSizeDisplay extends StatelessWidget {
  final String text;
  final String placeholderText;
  final String fontFamily;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final double maxWidth;
  final double maxHeight;

  const FixedSizeDisplay({
    super.key,
    required this.text,
    this.placeholderText = 'TAP TO TYPE',
    required this.fontFamily,
    required this.textColor,
    required this.fontSize,
    this.fontWeight = FontWeight.bold,
    required this.maxWidth,
    required this.maxHeight,
  });

  TextStyle _style(double size, [Color? color]) {
    return GoogleFonts.getFont(
      fontFamily,
      textStyle: TextStyle(
        color: color,
        fontWeight: fontWeight,
        fontSize: size,
        height: 1.15,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = text.isEmpty;
    final displayText = isEmpty ? placeholderText : text;
    final color = isEmpty ? textColor.withValues(alpha: 0.3) : textColor;

    final effectiveFontSize = _calculateFontSize(displayText);

    return Text(
      displayText,
      textAlign: TextAlign.center,
      softWrap: true,
      style: _style(effectiveFontSize, color),
    );
  }

  double _calculateFontSize(String text) {
    if (maxWidth <= 0 || maxHeight <= 0) return fontSize;

    const double minSize = 14;
    const double step = 2;
    double size = fontSize;

    while (size > minSize) {
      if (_textFits(text, size)) break;
      size -= step;
    }

    return math.max(size, minSize);
  }

  bool _textFits(String text, double size) {
    final style = _style(size);

    // Check that every individual word fits within maxWidth
    final lines = text.split('\n');
    for (final line in lines) {
      for (final word in line.split(RegExp(r'\s+'))) {
        if (word.isEmpty) continue;
        final tp = TextPainter(
          text: TextSpan(text: word, style: style),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout();
        if (tp.width > maxWidth) return false;
      }
    }

    // Check total height when laid out with wrapping
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return tp.height <= maxHeight;
  }
}

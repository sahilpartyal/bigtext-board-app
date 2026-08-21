import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class LogoDisplay extends StatefulWidget {
  final double scale;
  final String? customLogoBase64;

  const LogoDisplay({super.key, this.scale = 1.0, this.customLogoBase64});

  @override
  State<LogoDisplay> createState() => _LogoDisplayState();
}

class _LogoDisplayState extends State<LogoDisplay> {
  Uint8List? _cachedBytes;
  String? _cachedBase64;

  @override
  Widget build(BuildContext context) {
    final size = 60.0 * widget.scale;

    if (widget.customLogoBase64 != null &&
        widget.customLogoBase64!.isNotEmpty) {
      // Only decode if the base64 string changed
      if (_cachedBase64 != widget.customLogoBase64) {
        try {
          _cachedBytes = Uint8List.fromList(
            base64Decode(widget.customLogoBase64!),
          );
          _cachedBase64 = widget.customLogoBase64;
        } catch (_) {
          _cachedBytes = null;
          _cachedBase64 = widget.customLogoBase64;
        }
      }

      if (_cachedBytes != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            _cachedBytes!,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildPlaceholder(size),
          ),
        );
      }
    }

    return _buildPlaceholder(size);
  }

  Widget _buildPlaceholder(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Icon(Icons.business, color: Colors.white54, size: size * 0.5),
    );
  }
}

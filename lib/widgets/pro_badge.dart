import 'package:flutter/material.dart';

/// A small PRO badge to indicate locked/premium features
class ProBadge extends StatelessWidget {
  final double fontSize;
  final EdgeInsets padding;

  const ProBadge({
    super.key,
    this.fontSize = 9,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        border: Border.all(color: const Color(0xFFFDE68A)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          color: const Color(0xFFD97706),
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// A small lock icon badge for mode cards
class ProLockBadge extends StatelessWidget {
  const ProLockBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        Icons.lock,
        size: 10,
        color: Colors.white,
      ),
    );
  }
}

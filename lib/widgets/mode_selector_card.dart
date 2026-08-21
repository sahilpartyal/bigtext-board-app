import 'package:flutter/material.dart';

import '../models/display_mode.dart';

const Color _primaryBlue = Color(0xFF123768);
const Color _textPrimary = Color(0xFF1F2937);
const Color _textSecondary = Color(0xFF6B7280);

class ModeSelectorCard extends StatelessWidget {
  final DisplayMode mode;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isPro;
  final VoidCallback? onProTap;

  const ModeSelectorCard({
    super.key,
    required this.mode,
    required this.isSelected,
    required this.onTap,
    this.isPro = true,
    this.onProTap,
  });

  IconData get _icon {
    switch (mode) {
      case DisplayMode.simple:
        return Icons.person;
      case DisplayMode.business:
        return Icons.dashboard_outlined;
      case DisplayMode.presentation:
        return Icons.play_arrow;
    }
  }

  bool get _requiresPro {
    return mode == DisplayMode.business || mode == DisplayMode.presentation;
  }

  bool get _isLocked => _requiresPro && !isPro;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isLocked ? onProTap : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? _primaryBlue.withValues(alpha: 0.08)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _primaryBlue : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? _primaryBlue
                    : _primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _icon,
                color: isSelected ? Colors.white : _primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Title and description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode.label,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mode.description,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            // Checkmark for selected, Lock for locked
            if (isSelected && !_isLocked)
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: _primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
            if (_isLocked)
              Icon(Icons.lock, color: _textSecondary.withValues(alpha: 0.5), size: 22),
          ],
        ),
      ),
    );
  }
}

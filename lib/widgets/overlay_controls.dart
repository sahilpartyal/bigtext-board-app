import 'package:flutter/material.dart';

class OverlayControls extends StatelessWidget {
  final bool visible;
  final VoidCallback onSettingsTap;
  final VoidCallback onRecentsTap;
  final VoidCallback? onControlsTap;
  final VoidCallback onCloseTap;
  final bool showControlsButton;
  final bool isLightBackground;
  final Color? backgroundColor;

  const OverlayControls({
    super.key,
    required this.visible,
    required this.onSettingsTap,
    required this.onRecentsTap,
    required this.onCloseTap,
    this.onControlsTap,
    this.showControlsButton = false,
    this.isLightBackground = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // App bar uses the same background color as the main screen
    final barBgColor = backgroundColor ?? (isLightBackground
        ? Colors.white.withValues(alpha: 0.95)
        : const Color(0xFF1C1C1E).withValues(alpha: 0.95));
    final secondaryColor = isLightBackground ? Colors.black54 : Colors.white70;

    return Container(
      decoration: BoxDecoration(
        color: barBgColor,
        border: Border(
          bottom: BorderSide(
            // High-contrast divider so the top bar edge stays clearly visible
            // against any background color.
            color: isLightBackground
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.35),
            width: 0.75,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              // Left side - Back/Close button (simple icon)
              IconButton(
                onPressed: onCloseTap,
                icon: Icon(
                  Icons.chevron_left_rounded,
                  color: isLightBackground ? Colors.black87 : Colors.white,
                  size: 28,
                ),
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),

              // Spacer to push buttons to the right
              const Spacer(),

              // Right side buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Recent button
                  _AppBarButton(
                    icon: Icons.access_time_rounded,
                    label: 'Recent',
                    onTap: onRecentsTap,
                    fgColor: secondaryColor,
                  ),

                  // Controls button (if enabled)
                  if (showControlsButton && onControlsTap != null) ...[
                    const SizedBox(width: 16),
                    _AppBarButton(
                      icon: Icons.tune_rounded,
                      label: 'Controls',
                      onTap: onControlsTap!,
                      fgColor: secondaryColor,
                    ),
                  ],

                  // Settings button
                  const SizedBox(width: 16),
                  _AppBarButton(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    onTap: onSettingsTap,
                    fgColor: secondaryColor,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Clean app bar style button with icon and label
class _AppBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color fgColor;

  const _AppBarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.fgColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fgColor, size: 18),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fgColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../models/app_settings.dart';
import '../models/display_mode.dart';
import '../providers/settings_provider.dart';
import '../providers/subscription_provider.dart';
import '../utils/constants.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/color_swatch_grid.dart';
import '../widgets/font_selector.dart';
import '../widgets/logo_display.dart';
import '../widgets/mode_selector_card.dart';
import '../widgets/pro_badge.dart';
import '../widgets/upgrade_banner.dart';
import '../widgets/upgrade_bottom_sheet.dart';

// New primary color
const Color _primaryBlue = Color(0xFF123768);
const Color _backgroundColor = Color(0xFFF9FAFB);
const Color _cardColor = Colors.white;
const Color _textPrimary = Color(0xFF1F2937);
const Color _textSecondary = Color(0xFF6B7280);

class SettingsScreen extends ConsumerStatefulWidget {
  final String? initialExpandedSection;

  const SettingsScreen({super.key, this.initialExpandedSection});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _companyNameController;

  // Collapsible card states - all minimized except Display Mode
  bool _appearanceExpanded = false;
  bool _displayOptionsExpanded = false;
  bool _fontSizesExpanded = false;
  bool _logoPositionExpanded = false;
  bool _presentationExpanded = false;
  bool _preferencesExpanded = false;

  // Accordion behavior - collapse all others when one expands
  void _toggleSection(String section) {
    setState(() {
      // If the section is already expanded, just collapse it
      // Otherwise, collapse all and expand the selected one
      final isCurrentlyExpanded = switch (section) {
        'appearance' => _appearanceExpanded,
        'displayOptions' => _displayOptionsExpanded,
        'fontSizes' => _fontSizesExpanded,
        'logoPosition' => _logoPositionExpanded,
        'presentation' => _presentationExpanded,
        'preferences' => _preferencesExpanded,
        _ => false,
      };

      // Collapse all sections
      _appearanceExpanded = false;
      _displayOptionsExpanded = false;
      _fontSizesExpanded = false;
      _logoPositionExpanded = false;
      _presentationExpanded = false;
      _preferencesExpanded = false;

      // If it wasn't expanded, expand it now
      if (!isCurrentlyExpanded) {
        switch (section) {
          case 'appearance':
            _appearanceExpanded = true;
          case 'displayOptions':
            _displayOptionsExpanded = true;
          case 'fontSizes':
            _fontSizesExpanded = true;
          case 'logoPosition':
            _logoPositionExpanded = true;
          case 'presentation':
            _presentationExpanded = true;
          case 'preferences':
            _preferencesExpanded = true;
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // Force portrait orientation for settings screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    _companyNameController = TextEditingController(
      text: ref.read(settingsProvider).companyName,
    );
    // Set initial expanded section if provided
    if (widget.initialExpandedSection != null) {
      switch (widget.initialExpandedSection) {
        case 'appearance':
          _appearanceExpanded = true;
        case 'displayOptions':
          _displayOptionsExpanded = true;
        case 'fontSizes':
          _fontSizesExpanded = true;
        case 'logoPosition':
          _logoPositionExpanded = true;
        case 'presentation':
          _presentationExpanded = true;
        case 'preferences':
          _preferencesExpanded = true;
      }
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Upgrade Banner (only for free users)
                const UpgradeBanner(),

                // Display Mode Section (always expanded, no collapse button)
                _buildSectionCard(
                  title: 'Display Mode',
                  isExpanded: true,
                  showCollapseButton: false,
                  onToggle: null,
                  child: Column(
                    children: DisplayMode.values.map((mode) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ModeSelectorCard(
                        mode: mode,
                        isSelected: settings.displayMode == mode,
                        isPro: isPro,
                        onTap: () => notifier.update((s) => s.copyWith(displayMode: mode)),
                        onProTap: () => UpgradeBottomSheet.show(context),
                      ),
                    )).toList(),
                  ),
                ),

                const SizedBox(height: 12),

                // Appearance Section (collapsible)
                _buildSectionCard(
                  title: 'Appearance',
                  isExpanded: _appearanceExpanded,
                  showCollapseButton: true,
                  onToggle: () => _toggleSection('appearance'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Font Selector - no PRO badge on row
                      _buildSettingRow(
                        label: 'Font',
                        trailing: !isPro ? Text(
                          '2 / 12',
                          style: TextStyle(color: _textSecondary.withValues(alpha: 0.6), fontSize: 12),
                        ) : null,
                      ),
                      const SizedBox(height: 8),
                      FontSelector(
                        fonts: settings.displayMode == DisplayMode.simple
                          ? kFontFamilies
                          : kAllFontFamilies,
                        selectedFont: settings.fontFamily,
                        onFontSelected: (font) => notifier.update((s) => s.copyWith(fontFamily: font)),
                        isPro: isPro,
                        onProTap: () => UpgradeBottomSheet.show(context),
                      ),

                      const SizedBox(height: 20),

                      // Text Color - no PRO badge on row
                      _buildSettingRow(
                        label: 'Text Color',
                        trailing: !isPro ? Text(
                          '3 / 12',
                          style: TextStyle(color: _textSecondary.withValues(alpha: 0.6), fontSize: 12),
                        ) : null,
                      ),
                      const SizedBox(height: 8),
                      ColorSwatchGrid(
                        selectedColor: settings.textColor,
                        onColorSelected: (c) => notifier.update((s) => s.copyWith(textColor: c)),
                        isPro: isPro,
                        onProTap: () => UpgradeBottomSheet.show(context),
                      ),

                      const SizedBox(height: 20),

                      // Background Color - no PRO badge on row
                      _buildSettingRow(
                        label: 'Background Color',
                        trailing: !isPro ? Text(
                          '3 / 12',
                          style: TextStyle(color: _textSecondary.withValues(alpha: 0.6), fontSize: 12),
                        ) : null,
                      ),
                      const SizedBox(height: 8),
                      ColorSwatchGrid(
                        selectedColor: settings.backgroundColor,
                        onColorSelected: (c) => notifier.update((s) => s.copyWith(backgroundColor: c)),
                        isPro: isPro,
                        onProTap: () => UpgradeBottomSheet.show(context),
                      ),
                    ],
                  ),
                ),

                // Display Options Section (only for Business/Presentation modes)
                if (settings.displayMode != DisplayMode.simple) ...[
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    title: 'Display Options',
                    isExpanded: _displayOptionsExpanded,
                    showCollapseButton: true,
                    onToggle: () => _toggleSection('displayOptions'),
                    titleTrailing: !isPro ? const ProBadge() : null,
                    child: Column(
                      children: [
                        _ToggleRow(
                          label: 'Show Company Name',
                          value: settings.showCompanyName,
                          onChanged: isPro
                            ? (v) => notifier.update((s) => s.copyWith(showCompanyName: v))
                            : null,
                          isDisabled: !isPro,
                          onDisabledTap: () => UpgradeBottomSheet.show(context),
                        ),
                        if (settings.showCompanyName && isPro) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _companyNameController,
                            style: const TextStyle(color: _textPrimary, fontSize: 15),
                            decoration: InputDecoration(
                              hintText: 'Enter company name',
                              hintStyle: TextStyle(color: _textSecondary.withValues(alpha: 0.5)),
                              filled: true,
                              fillColor: _backgroundColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: _primaryBlue, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            onChanged: (v) => notifier.update((s) => s.copyWith(companyName: v)),
                          ),
                        ],
                        // Full-width minimal divider
                        const Divider(
                          height: 16,
                          thickness: 0.5,
                          color: Color(0xFFE8E8E8),
                          indent: 0,
                          endIndent: 0,
                        ),
                        _ToggleRow(
                          label: 'Show Logo',
                          value: settings.showLogo,
                          onChanged: isPro
                            ? (v) => notifier.update((s) => s.copyWith(showLogo: v))
                            : null,
                          isDisabled: !isPro,
                          onDisabledTap: () => UpgradeBottomSheet.show(context),
                        ),
                        if (settings.showLogo && isPro) ...[
                          const SizedBox(height: 16),
                          _LogoUploadSection(settings: settings, notifier: notifier),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Font Sizes Section (collapsible)
                _buildSectionCard(
                  title: 'Font Sizes',
                  isExpanded: _fontSizesExpanded,
                  showCollapseButton: true,
                  onToggle: () => _toggleSection('fontSizes'),
                  child: Column(
                    children: [
                      if (settings.displayMode != DisplayMode.simple) ...[
                        _SliderSetting(
                          label: 'Title Size',
                          value: settings.titleFontSize,
                          min: 20,
                          max: 300,
                          onChanged: (v) => notifier.update((s) => s.copyWith(titleFontSize: v)),
                        ),
                        _SliderSetting(
                          label: 'Subtitle Size',
                          value: settings.subtitleFontSize,
                          min: 10,
                          max: 100,
                          onChanged: (v) => notifier.update((s) => s.copyWith(subtitleFontSize: v)),
                        ),
                      ],
                      if (settings.displayMode == DisplayMode.simple)
                        _SliderSetting(
                          label: 'Passenger Name',
                          value: settings.passengerNameFontSize,
                          min: 20,
                          max: 300,
                          onChanged: (v) => notifier.update((s) => s.copyWith(passengerNameFontSize: v)),
                        ),
                    ],
                  ),
                ),

                // Logo Position (Business/Presentation)
                if (settings.displayMode != DisplayMode.simple && settings.showLogo && isPro) ...[
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    title: 'Logo Position',
                    isExpanded: _logoPositionExpanded,
                    showCollapseButton: true,
                    onToggle: () => _toggleSection('logoPosition'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Top Left, Top Center, Top Right
                        Row(
                          children: [
                            for (final pos in [LogoPosition.topLeft, LogoPosition.topCenter, LogoPosition.topRight])
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: pos != LogoPosition.topRight ? 8 : 0,
                                  ),
                                  child: _LogoPositionButton(
                                    position: pos,
                                    isSelected: settings.logoPosition == pos,
                                    onTap: () => notifier.update((s) => s.copyWith(logoPosition: pos)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Row 2: Bottom Left, Bottom Center, Bottom Right
                        Row(
                          children: [
                            for (final pos in [LogoPosition.bottomLeft, LogoPosition.bottomCenter, LogoPosition.bottomRight])
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: pos != LogoPosition.bottomRight ? 8 : 0,
                                  ),
                                  child: _LogoPositionButton(
                                    position: pos,
                                    isSelected: settings.logoPosition == pos,
                                    onTap: () => notifier.update((s) => s.copyWith(logoPosition: pos)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SliderSetting(
                          label: 'Logo Scale',
                          value: settings.logoScale,
                          min: 1.0,
                          max: 4.0,
                          divisions: 3,
                          onChanged: (v) => notifier.update((s) => s.copyWith(logoScale: v)),
                        ),
                      ],
                    ),
                  ),
                ],

                // Presentation Settings
                if (settings.displayMode == DisplayMode.presentation) ...[
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    title: 'Presentation',
                    isExpanded: _presentationExpanded,
                    showCollapseButton: true,
                    onToggle: () => _toggleSection('presentation'),
                    child: _SliderSetting(
                      label: 'Auto Advance (seconds)',
                      value: settings.autoAdvanceSeconds,
                      min: 1,
                      max: 30,
                      onChanged: (v) => notifier.update((s) => s.copyWith(autoAdvanceSeconds: v)),
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Preferences Section (collapsible)
                _buildSectionCard(
                  title: 'Preferences',
                  isExpanded: _preferencesExpanded,
                  showCollapseButton: true,
                  onToggle: () => _toggleSection('preferences'),
                  child: _ToggleRow(
                    label: 'Keep Screen Awake',
                    value: settings.keepScreenAwake,
                    onChanged: (v) => notifier.update((s) => s.copyWith(keepScreenAwake: v)),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
    required bool isExpanded,
    required bool showCollapseButton,
    required VoidCallback? onToggle,
    Widget? titleTrailing,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and collapse button
          GestureDetector(
            onTap: showCollapseButton ? onToggle : null,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (titleTrailing != null) ...[
                    const SizedBox(width: 10),
                    titleTrailing,
                  ],
                  const Spacer(),
                  if (showCollapseButton)
                    _CollapseButton(isExpanded: isExpanded),
                ],
              ),
            ),
          ),
          // Content - animated collapse
          AnimatedCrossFade(
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: child,
            ),
            secondChild: const SizedBox(height: 4),
            crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow({required String label, Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: _textSecondary, fontSize: 15, fontWeight: FontWeight.w400),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}

/// Collapse button widget
class _CollapseButton extends StatelessWidget {
  final bool isExpanded;

  const _CollapseButton({required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: AnimatedRotation(
        turns: isExpanded ? 0.5 : 0,
        duration: const Duration(milliseconds: 200),
        child: const Icon(
          Icons.keyboard_arrow_down,
          size: 20,
          color: _textSecondary,
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isDisabled;
  final VoidCallback? onDisabledTap;

  const _ToggleRow({
    required this.label,
    required this.value,
    this.onChanged,
    this.isDisabled = false,
    this.onDisabledTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? onDisabledTap : null,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: _textSecondary, fontSize: 15, fontWeight: FontWeight.w400),
          ),
          Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Transform.scale(
              scale: 0.65,
              child: Switch(
                value: value,
                onChanged: isDisabled ? null : onChanged,
                activeTrackColor: _primaryBlue,
                inactiveTrackColor: const Color(0xFFE5E7EB),
                thumbColor: WidgetStateProperty.all(Colors.white),
                trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoUploadSection extends StatelessWidget {
  final AppSettings settings;
  final SettingsNotifier notifier;

  const _LogoUploadSection({required this.settings, required this.notifier});

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    final base64String = base64Encode(bytes);
    await notifier.setCustomLogo(base64String);
  }

  @override
  Widget build(BuildContext context) {
    final hasCustomLogo = settings.customLogoBase64 != null &&
        settings.customLogoBase64!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Full-width Upload Logo button
        GestureDetector(
          onTap: _pickLogo,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _primaryBlue.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  hasCustomLogo ? Icons.swap_horiz : Icons.upload,
                  color: _primaryBlue,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  hasCustomLogo ? 'Change Logo' : 'Upload Logo',
                  style: const TextStyle(color: _primaryBlue, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        if (hasCustomLogo) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              // Logo preview with light theme background
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: Image.memory(
                    base64Decode(settings.customLogoBase64!),
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image,
                      color: _textSecondary,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => notifier.clearCustomLogo(),
                child: const Text(
                  'Remove Logo',
                  style: TextStyle(
                    color: Color(0xFFFF453A),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SliderSetting extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int? divisions;

  const _SliderSetting({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: _textSecondary, fontSize: 15, fontWeight: FontWeight.w400),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value.round().toString(),
                  style: const TextStyle(color: _primaryBlue, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _primaryBlue,
              inactiveTrackColor: _primaryBlue.withValues(alpha: 0.15),
              thumbColor: _primaryBlue,
              overlayColor: _primaryBlue.withValues(alpha: 0.1),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Transform.translate(
              offset: const Offset(-12, 0),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoPositionButton extends StatelessWidget {
  final LogoPosition position;
  final bool isSelected;
  final VoidCallback onTap;

  const _LogoPositionButton({
    required this.position,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _primaryBlue.withValues(alpha: 0.1) : _backgroundColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _primaryBlue : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            position.label,
            style: TextStyle(
              color: isSelected ? _primaryBlue : _textSecondary,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

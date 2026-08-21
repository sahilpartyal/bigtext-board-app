import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_settings.dart';
import '../models/display_mode.dart';
import '../providers/ad_provider.dart';
import '../providers/message_provider.dart';
import '../providers/recents_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/toast_helper.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/floating_control_panel.dart';
import '../widgets/logo_display.dart';
import '../widgets/overlay_controls.dart';
import 'settings_wrapper.dart';

class MainDisplayScreen extends ConsumerStatefulWidget {
  const MainDisplayScreen({super.key});

  @override
  ConsumerState<MainDisplayScreen> createState() => _MainDisplayScreenState();
}

class _MainDisplayScreenState extends ConsumerState<MainDisplayScreen>
    with SingleTickerProviderStateMixin {
  Timer? _hideTimer;
  bool _controlsVisible = true;
  bool _showControlPanel = false;

  // The field the user just tapped to edit. Its editable TextField is mounted
  // (so it can receive focus) even before focus is actually gained; every other
  // field renders as a plain, perfectly-centered Text. Cleared on blur.
  FocusNode? _pendingEditNode;

  // Top bar drawer state
  bool _topBarVisible = false;
  late AnimationController _topBarAnimationController;
  late Animation<Offset> _topBarSlideAnimation;

  // Pinch-to-zoom. The size is held here for the duration of the gesture and
  // committed to settings once, on scale end: SettingsNotifier.update() rewrites
  // every preference key (including the base64 logo), so calling it per
  // onScaleUpdate would mean dozens of full prefs writes a second.
  double? _zoomLiveSize;
  double? _zoomStartSize;
  Timer? _zoomLabelTimer;

  // Presentation mode
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoAdvanceTimer;
  bool _showSlideSubtitle = false;

  // Text editing controllers for inline editing
  late TextEditingController _passengerNameController;
  late TextEditingController _companyNameController;
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _slideTitleController;
  late TextEditingController _slideSubtitleController;
  final FocusNode _passengerNameFocusNode = FocusNode();
  final FocusNode _companyNameFocusNode = FocusNode();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _subtitleFocusNode = FocusNode();
  final FocusNode _slideTitleFocusNode = FocusNode();
  final FocusNode _slideSubtitleFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Force landscape orientation for home screen
    SystemChrome.setPreferredOrientations(_kLandscape);
    _pageController = PageController();

    // Initialize top bar animation
    _topBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _topBarSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0), // Start off-screen to the left
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _topBarAnimationController,
      curve: Curves.easeOut,
    ));

    // Initialize controllers with current values
    final settings = ref.read(settingsProvider);
    _passengerNameController = TextEditingController(text: settings.passengerName);
    _companyNameController = TextEditingController(text: settings.companyName);
    _titleController = TextEditingController(text: settings.passengerName);
    _subtitleController = TextEditingController(text: settings.subtitle);
    _slideTitleController = TextEditingController();
    _slideSubtitleController = TextEditingController();

    // Add listeners to save on text change
    _passengerNameController.addListener(_onPassengerNameChanged);
    _companyNameController.addListener(_onCompanyNameChanged);
    _titleController.addListener(_onTitleChanged);
    _subtitleController.addListener(_onSubtitleChanged);
    _slideTitleController.addListener(_onSlideTitleChanged);
    _slideSubtitleController.addListener(_onSlideSubtitleChanged);

    // Add focus listeners to exit immersive mode when editing
    _passengerNameFocusNode.addListener(_onFocusChange);
    _companyNameFocusNode.addListener(_onFocusChange);
    _titleFocusNode.addListener(_onFocusChange);
    _subtitleFocusNode.addListener(_onFocusChange);
    _slideTitleFocusNode.addListener(_onFocusChange);
    _slideSubtitleFocusNode.addListener(_onFocusChange);

    _resetHideTimer();
    _enterImmersiveMode();
    // Initialize ad provider
    Future.microtask(() {
      ref.read(adProvider);
    });
  }

  void _onFocusChange() {
    if (_anyFieldFocused) {
      _exitImmersiveMode();
      _hideTimer?.cancel();
    } else {
      // Keyboard is gone — rotate back to the landscape display.
      _exitEditOrientation();
      _enterImmersiveMode();
      _resetHideTimer();
      // Editing finished: drop back to the centered Text display and hide an
      // empty subtitle field.
      setState(() {
        _pendingEditNode = null;
        if (_showSlideSubtitle && _slideSubtitleController.text.isEmpty) {
          _showSlideSubtitle = false;
        }
      });
    }
  }

  void _onPassengerNameChanged() {
    final text = _passengerNameController.text;
    ref.read(settingsProvider.notifier).update((s) => s.copyWith(passengerName: text));
    if (text.isNotEmpty) {
      ref.read(autoSaveProvider).onTextChanged(text);
    }
  }

  void _onCompanyNameChanged() {
    final text = _companyNameController.text;
    ref.read(settingsProvider.notifier).update((s) => s.copyWith(companyName: text));
  }

  void _onTitleChanged() {
    final text = _titleController.text;
    ref.read(settingsProvider.notifier).update((s) => s.copyWith(passengerName: text));
    if (text.isNotEmpty) {
      ref.read(autoSaveProvider).onTextChanged(text);
    }
  }

  void _onSubtitleChanged() {
    final text = _subtitleController.text;
    ref.read(settingsProvider.notifier).update((s) => s.copyWith(subtitle: text));
    if (text.isNotEmpty) {
      ref.read(autoSaveProvider).onTextChanged(text);
    }
  }

  void _onSlideTitleChanged() {
    final text = _slideTitleController.text;
    final slides = ref.read(slidesProvider);
    if (_currentPage < slides.length) {
      final slide = slides[_currentPage];
      ref.read(slidesProvider.notifier).updateSlide(
        _currentPage,
        slide.copyWith(title: text),
      );
      if (text.isNotEmpty) {
        ref.read(autoSaveProvider).onTextChanged(text);
      }
    }
  }

  void _onSlideSubtitleChanged() {
    final text = _slideSubtitleController.text;
    final slides = ref.read(slidesProvider);
    if (_currentPage < slides.length) {
      final slide = slides[_currentPage];
      ref.read(slidesProvider.notifier).updateSlide(
        _currentPage,
        slide.copyWith(subtitle: text),
      );
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    _orientationTimer?.cancel();
    _zoomLabelTimer?.cancel();
    _pageController.dispose();
    _topBarAnimationController.dispose();
    _passengerNameController.removeListener(_onPassengerNameChanged);
    _companyNameController.removeListener(_onCompanyNameChanged);
    _titleController.removeListener(_onTitleChanged);
    _subtitleController.removeListener(_onSubtitleChanged);
    _slideTitleController.removeListener(_onSlideTitleChanged);
    _slideSubtitleController.removeListener(_onSlideSubtitleChanged);
    _passengerNameController.dispose();
    _companyNameController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _slideTitleController.dispose();
    _slideSubtitleController.dispose();
    _passengerNameFocusNode.dispose();
    _companyNameFocusNode.dispose();
    _titleFocusNode.dispose();
    _subtitleFocusNode.dispose();
    _slideTitleFocusNode.dispose();
    _slideSubtitleFocusNode.dispose();
    _exitImmersiveMode();
    super.dispose();
  }

  void _enterImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _exitImmersiveMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  // ---------------------------------------------------------------------------
  // Portrait-while-editing
  //
  // The display itself is landscape, but the system keyboard is far easier to
  // use in portrait. Tapping a field rotates to portrait; blurring it (keyboard
  // dismissed) rotates back to landscape. The rotation must finish *before* the
  // keyboard is raised — running both animations at once makes them fight each
  // other and the field visibly jumps around.
  // ---------------------------------------------------------------------------

  static const Duration _kOrientationSettle = Duration(milliseconds: 250);

  static const List<DeviceOrientation> _kLandscape = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];

  Timer? _orientationTimer;
  bool _editingInPortrait = false;

  /// True while a child screen (settings, recents, …) sits on top of this
  /// route. Those screens pick their own orientation, and this screen stays
  /// mounted underneath them, so its deferred rotate-back must stand down
  /// until they pop or it will rotate the child.
  bool _childRouteActive = false;

  bool get _anyFieldFocused =>
      _passengerNameFocusNode.hasFocus ||
      _companyNameFocusNode.hasFocus ||
      _titleFocusNode.hasFocus ||
      _subtitleFocusNode.hasFocus ||
      _slideTitleFocusNode.hasFocus ||
      _slideSubtitleFocusNode.hasFocus;

  // ---------------------------------------------------------------------------
  // Pinch to zoom
  //
  // Two fingers on the display resize the main text in place, so the size can be
  // set without a trip to the settings screen. Simple mode resizes the passenger
  // name; business mode resizes the title. The company name, subtitle and logo
  // are left alone.
  // ---------------------------------------------------------------------------

  /// The font size pinching acts on for the current display mode.
  double _zoomTargetSize(AppSettings settings) =>
      settings.displayMode == DisplayMode.simple
          ? settings.passengerNameFontSize
          : settings.titleFontSize;

  void _onScaleStart(ScaleStartDetails details, AppSettings settings) {
    // Editing: leave the pointers to the text field's own selection handling.
    if (_anyFieldFocused || _pendingEditNode != null) return;
    _zoomStartSize = _zoomTargetSize(settings);
    _hideTimer?.cancel();
    _zoomLabelTimer?.cancel();
  }

  void _onScaleUpdate(ScaleUpdateDetails details, AppSettings settings) {
    final base = _zoomStartSize;
    // pointerCount < 2 is a one-finger drag that the scale recognizer also
    // reports; only an actual pinch should resize.
    if (base == null || details.pointerCount < 2) return;

    final size = (base * details.scale)
        .clamp(kMinDisplayFontSize, kMaxDisplayFontSize)
        .toDouble();
    if (size == _zoomLiveSize) return;
    setState(() => _zoomLiveSize = size);
  }

  void _onScaleEnd(ScaleEndDetails details, AppSettings settings) {
    final size = _zoomLiveSize;
    _zoomStartSize = null;
    if (size == null) return;

    // Commit once, now that the gesture is over.
    ref.read(settingsProvider.notifier).update(
          (s) => settings.displayMode == DisplayMode.simple
              ? s.copyWith(passengerNameFontSize: size)
              : s.copyWith(titleFontSize: size),
        );

    // Keep the size label up briefly, then drop back to the stored value.
    _zoomLabelTimer?.cancel();
    _zoomLabelTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _zoomLiveSize = null);
    });
    _resetHideTimer();
  }

  /// iPad is landscape-only in `ios/Runner/Info.plist`, so a portrait request
  /// there has no orientation in common with the app's supported set. Leave
  /// iPad on the existing landscape-only behaviour.
  bool get _canRotateToPortrait {
    if (defaultTargetPlatform != TargetPlatform.iOS) return true;
    return MediaQuery.of(context).size.shortestSide < 600;
  }

  /// Rotates to portrait, then runs [onSettled] once the rotation has had time
  /// to finish. Re-entrant: when already in portrait [onSettled] runs
  /// immediately, so nested edit calls don't stack up extra delays.
  void _enterEditOrientation(VoidCallback onSettled) {
    if (_editingInPortrait) {
      // Already in portrait — cancel any rotate-back queued by a blur that is
      // being immediately followed by a tap on another field.
      _orientationTimer?.cancel();
      onSettled();
      return;
    }
    if (!_canRotateToPortrait) {
      onSettled();
      return;
    }
    _editingInPortrait = true;
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _orientationTimer?.cancel();
    _orientationTimer = Timer(_kOrientationSettle, () {
      if (mounted) onSettled();
    });
  }

  /// Returns to landscape once editing ends.
  void _exitEditOrientation() {
    if (!_editingInPortrait) return;
    _orientationTimer?.cancel();
    // Moving focus straight from one field to another briefly reports no
    // focused node. Re-check before rotating so that doesn't bounce the device
    // back to landscape and immediately into portrait again.
    _orientationTimer = Timer(_kOrientationSettle, () {
      if (!mounted || _anyFieldFocused || _childRouteActive) return;
      _editingInPortrait = false;
      SystemChrome.setPreferredOrientations(_kLandscape);
    });
  }

  /// Unconditionally returns to landscape, cancelling any pending rotation.
  /// Used on entry and when coming back from a portrait child screen.
  void _forceLandscape() {
    _orientationTimer?.cancel();
    _editingInPortrait = false;
    SystemChrome.setPreferredOrientations(_kLandscape);
  }

  /// Opens a child screen that sets its own orientation.
  ///
  /// Leaving a focused field to tap a toolbar button queues a rotate-back in
  /// [_exitEditOrientation]. That timer would otherwise fire a moment after the
  /// child screen has already asked for portrait and drag it into landscape, so
  /// drop it before navigating and keep this screen out of the way until the
  /// child pops.
  Future<void> _openOrientationOwningChild(
    Future<Object?>? Function() navigate,
  ) async {
    _orientationTimer?.cancel();
    _editingInPortrait = false;
    _childRouteActive = true;
    try {
      await navigate();
    } finally {
      _childRouteActive = false;
    }
  }

  /// Focuses [node] for editing, rotating to portrait first.
  void _focusForEditing(FocusNode node) {
    _enterEditOrientation(() {
      if (mounted && !node.hasFocus) node.requestFocus();
    });
  }

  void _openTopBar() {
    setState(() => _topBarVisible = true);
    _topBarAnimationController.forward();
  }

  void _closeTopBar() {
    _topBarAnimationController.reverse().then((_) {
      if (mounted) setState(() => _topBarVisible = false);
    });
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    setState(() => _controlsVisible = true);
    _hideTimer = Timer(const Duration(seconds: kControlsHideSeconds), () {
      if (mounted) setState(() => _controlsVisible = false);
    });
  }

  void _startAutoAdvance(double seconds) {
    _autoAdvanceTimer?.cancel();
    if (seconds <= 0) return;
    final slides = ref.read(slidesProvider);
    if (slides.length <= 1) return;

    _autoAdvanceTimer = Timer.periodic(Duration(milliseconds: (seconds * 1000).round()), (_) {
      final slides = ref.read(slidesProvider);
      if (slides.isEmpty) return;
      final nextPage = (_currentPage + 1) % slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  void _editPassengerName(AppSettings settings) {
    if (settings.hapticFeedback) triggerHaptic();
    // Sync controller with current value before focusing
    if (_passengerNameController.text != settings.passengerName) {
      _passengerNameController.text = settings.passengerName;
    }
    _focusForEditing(_passengerNameFocusNode);
  }

  void _editCompanyName(AppSettings settings) {
    if (settings.hapticFeedback) triggerHaptic();
    // Sync controller with current value before focusing
    if (_companyNameController.text != settings.companyName) {
      _companyNameController.text = settings.companyName;
    }
    _focusForEditing(_companyNameFocusNode);
  }

  void _editTitle(AppSettings settings) {
    // Sync controller with current value before focusing
    if (_titleController.text != settings.passengerName) {
      _titleController.text = settings.passengerName;
    }
    _focusForEditing(_titleFocusNode);
  }

  void _editSubtitle(AppSettings settings) {
    // Sync controller with current value before focusing
    if (_subtitleController.text != settings.subtitle) {
      _subtitleController.text = settings.subtitle;
    }
    _focusForEditing(_subtitleFocusNode);
  }

  void _editSlide(int index) {
    final slides = ref.read(slidesProvider);
    if (index >= slides.length) return;
    final slide = slides[index];

    // Sync controller with current slide title
    if (_slideTitleController.text != slide.title) {
      _slideTitleController.text = slide.title;
    }
    _focusForEditing(_slideTitleFocusNode);
  }

  void _editSlideSubtitle() {
    final slides = ref.read(slidesProvider);
    if (_currentPage >= slides.length) return;
    final slide = slides[_currentPage];

    // Sync controller with current slide subtitle
    if (_slideSubtitleController.text != slide.subtitle) {
      _slideSubtitleController.text = slide.subtitle;
    }
    // Rotate to portrait first, then show the subtitle field and focus it.
    _enterEditOrientation(() {
      setState(() {
        _showSlideSubtitle = true;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_slideSubtitleFocusNode.hasFocus) {
          _slideSubtitleFocusNode.requestFocus();
        }
      });
    });
  }

  Future<void> _confirmDeleteSlide(BuildContext context) async {
    _hideTimer?.cancel(); // Pause timer while dialog is open
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete Slide', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete slide ${_currentPage + 1}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    _resetHideTimer(); // Resume timer after dialog closes

    if (confirmed == true) {
      final deletedSlide = ref.read(slidesProvider)[_currentPage];
      final deletedIndex = _currentPage;
      ref.read(slidesProvider.notifier).removeSlide(_currentPage);
      if (_currentPage > 0) {
        setState(() => _currentPage--);
      }
      if (mounted) {
        ToastHelper.showWithUndo(
          context,
          'Slide deleted',
          onUndo: () {
            ref.read(slidesProvider.notifier).insertSlide(deletedIndex, deletedSlide);
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final slides = ref.watch(slidesProvider);

    // Handle display mode changes - cancel auto-advance timer when leaving presentation mode
    ref.listen<AppSettings>(settingsProvider, (previous, next) {
      if (previous?.displayMode == DisplayMode.presentation &&
          next.displayMode != DisplayMode.presentation) {
        _autoAdvanceTimer?.cancel();
        _autoAdvanceTimer = null;
      }
    });

    // Sync controllers with settings when they differ (e.g., after returning from recents)
    // Remove listeners temporarily to prevent feedback loop, then restore
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Sync passengerName controller (Simple mode)
      if (_passengerNameController.text != settings.passengerName) {
        _passengerNameController.removeListener(_onPassengerNameChanged);
        _passengerNameController.text = settings.passengerName;
        _passengerNameController.addListener(_onPassengerNameChanged);
      }

      // Sync title controller (Business mode)
      if (_titleController.text != settings.passengerName) {
        _titleController.removeListener(_onTitleChanged);
        _titleController.text = settings.passengerName;
        _titleController.addListener(_onTitleChanged);
      }

      // Sync slide title controller (Presentation mode)
      if (slides.isNotEmpty && _currentPage < slides.length) {
        final currentSlideTitle = slides[_currentPage].title;
        if (_slideTitleController.text != currentSlideTitle) {
          _slideTitleController.removeListener(_onSlideTitleChanged);
          _slideTitleController.text = currentSlideTitle;
          _slideTitleController.addListener(_onSlideTitleChanged);
        }
      }
    });

    final isPresentation = settings.displayMode == DisplayMode.presentation;

    return Scaffold(
      key: ValueKey(settings.displayMode),
      backgroundColor: settings.backgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: GestureDetector(
        onHorizontalDragEnd: (details) {
          // Detect swipe from left to right to open top bar
          if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
            _openTopBar();
          }
        },
        // Pinch to resize the main text. Null in presentation mode: the slide
        // PageView owns horizontal drags there, and a scale recognizer competing
        // with it makes page swipes unreliable.
        onScaleStart:
            isPresentation ? null : (d) => _onScaleStart(d, settings),
        onScaleUpdate:
            isPresentation ? null : (d) => _onScaleUpdate(d, settings),
        onScaleEnd: isPresentation ? null : (d) => _onScaleEnd(d, settings),
        child: Stack(
          children: [
            // Main content
            if (isPresentation)
              _buildPresentationMode(settings, slides)
            else
              _buildMainContent(settings),

            // Drawer open button - placed at the exact same spot as the close
            // button in the top bar (OverlayControls), so the chevron stays put
            // when toggling the drawer open/closed instead of shifting position.
            if (!_topBarVisible)
              Positioned(
                top: 0,
                left: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: IconButton(
                      onPressed: _openTopBar,
                      icon: Icon(
                        Icons.chevron_right_rounded,
                        color: settings.backgroundColor.computeLuminance() > 0.5
                            ? Colors.black87
                            : Colors.white,
                        size: 28,
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(),
                    ),
                  ),
                ),
              ),

            // Top bar drawer - slides in from left
            if (_topBarVisible)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SlideTransition(
                  position: _topBarSlideAnimation,
                  child: OverlayControls(
                    visible: true,
                    isLightBackground: settings.backgroundColor.computeLuminance() > 0.5,
                    backgroundColor: settings.backgroundColor,
                    onCloseTap: _closeTopBar,
                    onSettingsTap: () async {
                      _closeTopBar();
                      _exitImmersiveMode();
                      await _openOrientationOwningChild(
                        () => Get.toNamed('/settings'),
                      );
                      // Restore landscape when returning to home
                      _forceLandscape();
                      // Force rebuild when returning from settings
                      if (mounted) {
                        // Invalidate and re-read the provider to ensure fresh state
                        ref.invalidate(settingsProvider);
                        setState(() {});
                      }
                      _enterImmersiveMode();
                    },
                    onRecentsTap: () async {
                      _closeTopBar();
                      _exitImmersiveMode();
                      await _openOrientationOwningChild(
                        () => Get.toNamed('/recents'),
                      );
                      // Restore landscape when returning to home
                      _forceLandscape();
                      // Force rebuild when returning from recents.
                      // The recents screen runs in its own ProviderScope and
                      // only persists the selected name to SharedPreferences,
                      // so invalidate here to reload the fresh value.
                      //
                      // recentsProvider must be invalidated too: this scope
                      // holds its own copy of the list, and without this a
                      // clear-all done over there leaves a stale list here that
                      // the next addMessage would write straight back to prefs,
                      // resurrecting every deleted name.
                      if (mounted) {
                        ref.invalidate(settingsProvider);
                        ref.invalidate(slidesProvider);
                        ref.invalidate(recentsProvider);
                        setState(() {});
                      }
                      _enterImmersiveMode();
                    },
                    showControlsButton: settings.displayMode != DisplayMode.simple && !_showControlPanel,
                    onControlsTap: () {
                      _closeTopBar();
                      setState(() => _showControlPanel = true);
                    },
                  ),
                ),
              ),

            // Floating control panel (Business/Presentation)
            if (_showControlPanel &&
                settings.displayMode != DisplayMode.simple)
              FloatingControlPanel(
                settings: settings,
                onEditTitle: () => _editTitle(settings),
                onEditSubtitle: () => _editSubtitle(settings),
                onTitleFontSizeChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .update((s) => s.copyWith(titleFontSize: v)),
                onSubtitleFontSizeChanged: (v) => ref
                    .read(settingsProvider.notifier)
                    .update((s) => s.copyWith(subtitleFontSize: v)),
                onTitleColorChanged: (c) => ref
                    .read(settingsProvider.notifier)
                    .update((s) => s.copyWith(titleColor: c)),
                onSubtitleColorChanged: (c) => ref
                    .read(settingsProvider.notifier)
                    .update((s) => s.copyWith(subtitleColor: c)),
                onFontChanged: (f) => ref
                    .read(settingsProvider.notifier)
                    .update((s) => s.copyWith(fontFamily: f)),
                onSubtitleFontChanged: (f) => ref
                    .read(settingsProvider.notifier)
                    .update((s) => s.copyWith(subtitleFontFamily: f)),
                onClose: () => setState(() => _showControlPanel = false),
              ),

            // Presentation mode: add slide + page indicator
            // Parent controls visibility based on isPresentation
            if (isPresentation)
              _PresentationControlsBar(
                pageController: _pageController,
                currentPage: _currentPage,
                autoAdvanceTimer: _autoAdvanceTimer,
                onAutoAdvanceToggle: (start) {
                  if (start) {
                    _startAutoAdvance(settings.autoAdvanceSeconds);
                  } else {
                    _autoAdvanceTimer?.cancel();
                    _autoAdvanceTimer = null;
                  }
                  setState(() {});
                },
                onDeleteSlide: () => _confirmDeleteSlide(context),
                onAddSubtitle: _editSlideSubtitle,
              ),

            // Banner ad at bottom (all modes)
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: BannerAdWidget(),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildMainContent(AppSettings settings) {
    final isSimple = settings.displayMode == DisplayMode.simple;

    return Stack(
      children: [
        // Tap target for the entire content area — resets hide timer only
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _resetHideTimer,
          ),
        ),

        // Centered content - centers within the area above the banner ad
        Positioned(
          top: _topBarVisible ? 56 : 0, // Account for top bar when visible
          left: 0,
          right: 0,
          bottom: 0, // Use full height for centering (ad overlays on top)
          child: LayoutBuilder(
            builder: (context, constraints) {
              // The pinched size wins while a zoom gesture is in flight, before
              // it has been committed to settings on scale end.
              //
              // No auto-shrink cap: the size the user pinched is the size that
              // renders, even when that overflows the screen. Capping it to the
              // available height would make pinching out do nothing at all once
              // the text reached the fit limit, which reads as a broken gesture.
              // Anything taller than the screen can be scrolled or pinched back.
              final effectivePassengerFontSize =
                  _zoomLiveSize ?? settings.passengerNameFontSize;
              final effectiveTitleFontSize =
                  _zoomLiveSize ?? settings.titleFontSize;

              final contentWidget = Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                        // Logo (top positions only in column layout) - only show if custom logo exists
                        if (settings.showLogo &&
                            settings.customLogoBase64 != null &&
                            settings.customLogoBase64!.isNotEmpty &&
                            (isSimple || _isTopPosition(settings.logoPosition))) ...[
                          _buildPositionedLogo(settings, isSimple),
                          const SizedBox(height: 16),
                        ],

                        // Company name - editable inline (not shown in simple mode)
                        if (settings.showCompanyName && !isSimple)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _buildInlineTextField(
                              controller: _companyNameController,
                              focusNode: _companyNameFocusNode,
                              hintText: 'Enter company name',
                              style: GoogleFonts.getFont(
                                settings.fontFamily,
                                textStyle: TextStyle(
                                  color: const Color(0xFFFF6B2B), // Electric Sunset Orange - vibrant
                                  fontSize: settings.companyNameFontSize,
                                ),
                              ),
                              onTap: () {
                                _resetHideTimer();
                                _editCompanyName(settings);
                              },
                            ),
                          ),

                        // Main text — editable inline (with capped font size)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: isSimple
                              ? _buildInlineTextField(
                                  controller: _passengerNameController,
                                  focusNode: _passengerNameFocusNode,
                                  hintText: 'Enter Message',
                                  style: GoogleFonts.getFont(
                                    settings.fontFamily,
                                    textStyle: TextStyle(
                                      color: settings.textColor,
                                      fontSize: effectivePassengerFontSize,
                                    ),
                                  ),
                                  actualFontSize: settings.passengerNameFontSize,
                                  onTap: () {
                                    _resetHideTimer();
                                    _editPassengerName(settings);
                                  },
                                )
                              : _buildBusinessTextField(settings, effectiveTitleFontSize),
                        ),

                    // Logo (bottom positions) - only show if custom logo exists
                    if (settings.showLogo &&
                        settings.customLogoBase64 != null &&
                        settings.customLogoBase64!.isNotEmpty &&
                        !isSimple &&
                        !_isTopPosition(settings.logoPosition)) ...[
                      const SizedBox(height: 16),
                      _buildPositionedLogo(settings, isSimple),
                  ],
                ],
              ),
            );

              // While the system keypad is up the content must be scrollable so
              // text hidden behind the keyboard can be reached. The Scaffold
              // sets resizeToAvoidBottomInset: false, so the layout keeps the
              // full screen height and the keyboard simply covers the bottom of
              // it — subtract the inset to get the genuinely visible box.
              final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
              final keypadOpen = keyboardInset > 0;
              final boxHeight = keypadOpen
                  ? math.max(constraints.maxHeight - keyboardInset, 0.0)
                  : constraints.maxHeight;

              // IMPORTANT: this tree must keep the SAME widget types in every
              // state — only the parameters may change. Swapping widget types
              // when the keypad opens rebuilds the element tree, which destroys
              // the focused TextField's state and tears down its connection to
              // the platform text input: the keyboard closes the instant it
              // opens, viewInsets drops back to 0, and the two states flip-flop.
              //
              // The inner SizedBox height is null, so height reaches the
              // FittedBox unbounded and BoxFit.scaleDown has no vertical ratio
              // to shrink by (it never scales up either). That is deliberate:
              // pinch-to-zoom sets an exact size, and auto-shrinking would
              // silently undo it. Text taller than the viewport overflows into
              // the scroll view instead. Width stays bounded by the
              // ConstrainedBox, so the text still wraps rather than running off
              // the side.
              return SizedBox(
                width: constraints.maxWidth,
                height: boxHeight,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: boxHeight),
                    child: Center(
                      child: SizedBox(
                        height: null,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth,
                            ),
                            child: contentWidget,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Size readout while pinching — without it there is no signal that a
        // stored setting is being changed rather than the view being nudged.
        if (_zoomLiveSize != null)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Text(
                      '${_zoomLiveSize!.round()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  bool _isTopPosition(LogoPosition position) {
    return position == LogoPosition.topLeft ||
        position == LogoPosition.topCenter ||
        position == LogoPosition.topRight;
  }

  Future<void> _openDisplayOptions() async {
    _exitImmersiveMode();
    await _openOrientationOwningChild(
      () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SettingsWrapper(initialExpandedSection: 'displayOptions'),
        ),
      ),
    );
    // Restore landscape when returning to home
    _forceLandscape();
    // Force rebuild when returning from settings
    if (mounted) {
      ref.invalidate(settingsProvider);
      setState(() {});
    }
    _enterImmersiveMode();
  }

  Widget _buildPositionedLogo(AppSettings settings, bool isSimple) {
    final logo = GestureDetector(
      onTap: _openDisplayOptions,
      child: LogoDisplay(
        customLogoBase64: settings.customLogoBase64,
        scale: isSimple ? 1.0 : settings.logoScale,
      ),
    );

    if (isSimple) {
      return logo;
    }

    // Handle horizontal alignment based on position
    switch (settings.logoPosition) {
      case LogoPosition.topLeft:
      case LogoPosition.bottomLeft:
        return Align(alignment: Alignment.centerLeft, child: logo);
      case LogoPosition.topRight:
      case LogoPosition.bottomRight:
        return Align(alignment: Alignment.centerRight, child: logo);
      default:
        return logo; // Center aligned by default
    }
  }

  Widget _buildInlineTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required TextStyle style,
    VoidCallback? onTap,
    int? maxLines,
    double? actualFontSize, // Pass actual font size setting for 2-line check
  }) {
    // A multi-line TextField cannot be vertically centered inside the
    // surrounding FittedBox: the FittedBox measures its child with an
    // unbounded height, and under that the field stretches to fill the space
    // and top-aligns its text. That made large / wrapping text drift to the
    // top while small single-line text still looked centered.
    //
    // Fix: only use the editable TextField while the field is focused (i.e.
    // the user is actively editing). The rest of the time we render the value
    // as a plain, center-aligned Text. A Text reports its true intrinsic size,
    // so the FittedBox scales it down and Center keeps it perfectly centered
    // at any font size or line count.
    return ListenableBuilder(
      listenable: Listenable.merge([focusNode, controller]),
      builder: (context, _) {
        if (focusNode.hasFocus || _pendingEditNode == focusNode) {
          // A height-capped TextField scrolls internally and keeps the caret on
          // screen by itself — EditableText calls bringIntoView on every
          // selection change. Left uncapped (maxLines: null) the field just
          // grows, so the line being typed slides out of view behind the keypad.
          //
          // The cap only applies while the keypad is up; the surrounding
          // FittedBox measures its child with unbounded constraints, so this
          // ConstrainedBox is what genuinely bounds the field. It stays in the
          // tree in both states (maxHeight: infinity when the keypad is down) so
          // no widget type ever changes — swapping types here would rebuild the
          // element and tear down the platform text input connection.
          final inset = MediaQuery.viewInsetsOf(context).bottom;
          final maxFieldHeight = inset > 0
              ? math.max(
                  MediaQuery.sizeOf(context).height - inset - 96, 120.0)
              : double.infinity;

          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxFieldHeight),
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textAlign: TextAlign.center,
              style: style,
              maxLines: maxLines,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: style.copyWith(
                  color: style.color?.withValues(alpha: 0.3),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onTap: onTap,
            ),
          );
        }

        final isEmpty = controller.text.isEmpty;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // Rotate to portrait before mounting the editable field so the
            // rotation and the keyboard animation don't overlap. Then mount
            // this field's TextField and run the original tap handler (which
            // syncs the controller and requests focus) once the node is
            // attached to the focus tree.
            _enterEditOrientation(() {
              setState(() => _pendingEditNode = focusNode);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                onTap?.call();
                if (!focusNode.hasFocus) focusNode.requestFocus();
              });
            });
          },
          child: Text(
            isEmpty ? hintText : controller.text,
            textAlign: TextAlign.center,
            style: isEmpty
                ? style.copyWith(color: style.color?.withValues(alpha: 0.3))
                : style,
          ),
        );
      },
    );
  }

  Widget _buildBusinessTextField(AppSettings settings, [double? effectiveFontSize]) {
    return _buildInlineTextField(
      controller: _titleController,
      focusNode: _titleFocusNode,
      hintText: 'TAP TO TYPE',
      style: GoogleFonts.getFont(
        settings.fontFamily,
        textStyle: TextStyle(
          color: settings.titleColor,
          fontSize: effectiveFontSize ?? settings.titleFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      actualFontSize: settings.titleFontSize, // Pass actual setting for 2-line check
      onTap: () {
        _resetHideTimer();
        _editTitle(settings);
      },
    );
  }

  Widget _buildPresentationMode(AppSettings settings, List<SlideData> slides) {
    return PageView.builder(
      controller: _pageController,
      itemCount: slides.length,
      onPageChanged: (index) {
        setState(() => _currentPage = index);
        _resetHideTimer();
      },
      itemBuilder: (context, index) {
        final slide = slides[index];
        // Sync slide controllers when viewing this slide
        if (index == _currentPage) {
          if (_slideTitleController.text != slide.title) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _slideTitleController.text != slide.title) {
                _slideTitleController.text = slide.title;
              }
            });
          }
          if (_slideSubtitleController.text != slide.subtitle) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _slideSubtitleController.text != slide.subtitle) {
                _slideSubtitleController.text = slide.subtitle;
              }
            });
          }
        }
        return GestureDetector(
          onTap: () {
            _resetHideTimer();
            _editSlide(index);
          },
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 48,
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo (top positions) - only show if custom logo exists
                      if (settings.showLogo &&
                          settings.customLogoBase64 != null &&
                          settings.customLogoBase64!.isNotEmpty &&
                          _isTopPosition(settings.logoPosition)) ...[
                        _buildPositionedLogo(settings, false),
                        const SizedBox(height: 16),
                      ],
                      // Company name
                      if (settings.showCompanyName &&
                          settings.companyName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            settings.companyName,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.getFont(
                              settings.fontFamily,
                              textStyle: TextStyle(
                                color: settings.textColor.withValues(alpha: 0.7),
                                fontSize: settings.companyNameFontSize,
                              ),
                            ),
                          ),
                        ),
                      // Slide title - editable inline with system keyboard
                      _buildInlineTextField(
                        controller: _slideTitleController,
                        focusNode: _slideTitleFocusNode,
                        hintText: 'TAP TO EDIT',
                        style: GoogleFonts.getFont(
                          settings.fontFamily,
                          textStyle: TextStyle(
                            color: settings.titleColor,
                            fontSize: settings.titleFontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          _resetHideTimer();
                          _editSlide(index);
                        },
                      ),
                      // Slide subtitle - only show when has content or editing
                      if (slide.subtitle.isNotEmpty || _showSlideSubtitle) ...[
                        const SizedBox(height: 16),
                        _buildInlineTextField(
                          controller: _slideSubtitleController,
                          focusNode: _slideSubtitleFocusNode,
                          hintText: '',
                          style: GoogleFonts.getFont(
                            settings.subtitleFontFamily,
                            textStyle: TextStyle(
                              color: settings.subtitleColor,
                              fontSize: settings.subtitleFontSize,
                            ),
                          ),
                          onTap: () {
                            _resetHideTimer();
                            _editSlideSubtitle();
                          },
                        ),
                      ],
                      // Logo (bottom positions) - only show if custom logo exists
                      if (settings.showLogo &&
                          settings.customLogoBase64 != null &&
                          settings.customLogoBase64!.isNotEmpty &&
                          !_isTopPosition(settings.logoPosition)) ...[
                        const SizedBox(height: 16),
                        _buildPositionedLogo(settings, false),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}

class _PresentationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLightBackground;

  const _PresentationButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLightBackground = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isLightBackground
        ? Colors.black.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.5);
    final fgColor = isLightBackground ? Colors.black87 : Colors.white70;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fgColor, size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: fgColor, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

/// Separate StatefulWidget that manages collapse/expand state for the controls bar.
class _PresentationControlsBar extends ConsumerStatefulWidget {
  final PageController pageController;
  final int currentPage;
  final Timer? autoAdvanceTimer;
  final void Function(bool start) onAutoAdvanceToggle;
  final VoidCallback onDeleteSlide;
  final VoidCallback onAddSubtitle;

  const _PresentationControlsBar({
    super.key,
    required this.pageController,
    required this.currentPage,
    required this.autoAdvanceTimer,
    required this.onAutoAdvanceToggle,
    required this.onDeleteSlide,
    required this.onAddSubtitle,
  });

  @override
  ConsumerState<_PresentationControlsBar> createState() =>
      _PresentationControlsBarState();
}

class _PresentationControlsBarState
    extends ConsumerState<_PresentationControlsBar> {
  bool _isMinimized = false;

  @override
  Widget build(BuildContext context) {
    final slides = ref.watch(slidesProvider);
    final settings = ref.watch(settingsProvider);

    // Determine if background is light
    final bgLuminance = settings.backgroundColor.computeLuminance();
    final isLightBackground = bgLuminance > 0.5;

    // Adaptive colors
    final barBgColor = isLightBackground
        ? Colors.black.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.7);
    final toggleBgColor = isLightBackground
        ? Colors.black.withValues(alpha: 0.08)
        : Colors.white.withValues(alpha: 0.1);
    final iconColor = isLightBackground ? Colors.black87 : Colors.white70;
    final inactiveDotColor = isLightBackground
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.4);

    // Get safe area padding for home indicator
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Position at bottom, accounting for safe area
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: _isMinimized ? 6 : 10,
          bottom: (_isMinimized ? 4 : 8) + bottomPadding,
          left: 12,
          right: 12,
        ),
        decoration: BoxDecoration(
          color: barBgColor,
        ),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle button + Page indicator row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Expand/Collapse toggle button
                  GestureDetector(
                    onTap: () => setState(() => _isMinimized = !_isMinimized),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: toggleBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isMinimized
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: iconColor,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Page indicator dots
                  ...List.generate(slides.length, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == widget.currentPage ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == widget.currentPage
                            ? Colors.blue
                            : inactiveDotColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ],
              ),
              // Controls row (hidden when minimized)
              if (!_isMinimized) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _PresentationButton(
                      icon: Icons.add,
                      label: 'Add',
                      isLightBackground: isLightBackground,
                      onTap: () {
                        ref.read(slidesProvider.notifier).addSlide();
                        Future.delayed(const Duration(milliseconds: 100), () {
                          widget.pageController.animateToPage(
                            slides.length,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _PresentationButton(
                      icon: widget.autoAdvanceTimer != null
                          ? Icons.pause
                          : Icons.play_arrow,
                      label: widget.autoAdvanceTimer != null
                          ? 'Pause'
                          : 'Play',
                      isLightBackground: isLightBackground,
                      onTap: () => widget
                          .onAutoAdvanceToggle(widget.autoAdvanceTimer == null),
                    ),
                    const SizedBox(width: 8),
                    _PresentationButton(
                      icon: Icons.subtitles_outlined,
                      label: 'Subtitle',
                      isLightBackground: isLightBackground,
                      onTap: widget.onAddSubtitle,
                    ),
                    if (slides.length > 1) ...[
                      const SizedBox(width: 8),
                      _PresentationButton(
                        icon: Icons.delete_outline,
                        label: 'Remove',
                        isLightBackground: isLightBackground,
                        onTap: widget.onDeleteSlide,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      );
  }
}


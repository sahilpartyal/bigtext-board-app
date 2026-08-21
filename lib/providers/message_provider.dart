import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/constants.dart';
import 'recents_provider.dart';
import 'settings_provider.dart';

/// Handles debounced auto-save of the current message to recents.
final autoSaveProvider = Provider<AutoSaveService>((ref) {
  final service = AutoSaveService(ref);
  ref.onDispose(() => service.dispose());
  return service;
});

class AutoSaveService {
  final Ref _ref;
  Timer? _debounceTimer;

  AutoSaveService(this._ref);

  void onTextChanged(String text) {
    _debounceTimer?.cancel();
    if (text.trim().isEmpty) return;

    _debounceTimer = Timer(
      const Duration(milliseconds: kAutoSaveDebounceMs),
      () {
        _ref.read(recentsProvider.notifier).addMessage(text);
      },
    );
  }

  void saveNow(String text) {
    _debounceTimer?.cancel();
    if (text.trim().isNotEmpty) {
      _ref.read(recentsProvider.notifier).addMessage(text);
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
  }
}

/// Provider for presentation mode slides.
final slidesProvider =
    NotifierProvider<SlidesNotifier, List<SlideData>>(SlidesNotifier.new);

class SlideData {
  final String title;
  final String subtitle;

  const SlideData({this.title = '', this.subtitle = ''});

  SlideData copyWith({String? title, String? subtitle}) {
    return SlideData(
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
    );
  }

  /// Convert to JSON map for persistence
  Map<String, dynamic> toJson() => {
    'title': title,
    'subtitle': subtitle,
  };

  /// Create from JSON map
  factory SlideData.fromJson(Map<String, dynamic> json) {
    return SlideData(
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
    );
  }
}

class SlidesNotifier extends Notifier<List<SlideData>> {
  static const _storageKey = 'presentation_slides';

  @override
  List<SlideData> build() {
    // Listen for passengerName changes and sync first slide
    ref.listen<String>(
      settingsProvider.select((s) => s.passengerName),
      (previous, next) {
        if (previous != null && previous != next && state.isNotEmpty) {
          // Update first slide title if it matches the old name or is empty
          final firstSlide = state.first;
          if (firstSlide.title == previous || firstSlide.title.isEmpty) {
            updateSlide(0, firstSlide.copyWith(title: next));
          }
        }
      },
    );

    // Load saved slides from SharedPreferences
    final prefs = ref.read(sharedPreferencesProvider);
    final slidesJson = prefs.getString(_storageKey);

    if (slidesJson != null && slidesJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(slidesJson);
        final slides = decoded
            .map((e) => SlideData.fromJson(e as Map<String, dynamic>))
            .toList();
        if (slides.isNotEmpty) return slides;
      } catch (_) {
        // If parsing fails, fall back to default
      }
    }

    // Default: one slide with passenger name
    final settings = ref.read(settingsProvider);
    return [SlideData(title: settings.passengerName)];
  }

  Future<void> _saveSlides() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final jsonList = state.map((s) => s.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(jsonList));
  }

  void updateSlide(int index, SlideData slide) {
    final updated = [...state];
    if (index < updated.length) {
      updated[index] = slide;
      state = updated;
      _saveSlides();
    }
  }

  void addSlide() {
    state = [...state, const SlideData()];
    _saveSlides();
  }

  void insertSlide(int index, SlideData slide) {
    final updated = [...state];
    updated.insert(index.clamp(0, updated.length), slide);
    state = updated;
    _saveSlides();
  }

  void removeSlide(int index) {
    if (state.length <= 1) return;
    final updated = [...state];
    updated.removeAt(index);
    state = updated;
    _saveSlides();
  }
}

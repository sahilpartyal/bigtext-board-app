import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recent_message.dart';
import '../utils/constants.dart';
import 'settings_provider.dart';

final recentsProvider =
    NotifierProvider<RecentsNotifier, List<RecentMessage>>(RecentsNotifier.new);

class RecentsNotifier extends Notifier<List<RecentMessage>> {
  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<RecentMessage> build() {
    return _loadFromPrefs();
  }

  List<RecentMessage> _loadFromPrefs() {
    final json = _prefs.getString('recentMessages');
    if (json == null || json.isEmpty) return [];
    try {
      return RecentMessage.fromJsonList(json);
    } catch (_) {
      return [];
    }
  }

  Future<void> addMessage(String text) async {
    if (text.trim().isEmpty) return;

    final trimmed = text.trim();
    // Merge onto what is actually on disk, not onto `state`. Each screen runs
    // in its own ProviderScope, so this notifier's in-memory list can be stale
    // — e.g. after a clear-all performed from the recents screen. Building from
    // `state` would write those deleted names straight back to prefs.
    final current = _loadFromPrefs();
    // Remove duplicate if exists
    final filtered = current.where((m) => m.text != trimmed).toList();
    final updated = [
      RecentMessage(text: trimmed, timestamp: DateTime.now()),
      ...filtered,
    ];

    // Limit to max
    if (updated.length > kMaxRecentMessages) {
      state = updated.sublist(0, kMaxRecentMessages);
    } else {
      state = updated;
    }
    await _save();
  }

  Future<void> removeMessage(int index) async {
    final updated = [...state];
    updated.removeAt(index);
    state = updated;
    await _save();
  }

  Future<void> insertMessage(int index, RecentMessage message) async {
    final updated = [...state];
    updated.insert(index.clamp(0, updated.length), message);
    state = updated;
    await _save();
  }

  Future<void> clearAll() async {
    state = [];
    await _save();
  }

  Future<void> _save() async {
    await _prefs.setString(
        'recentMessages', RecentMessage.toJsonList(state));
  }
}

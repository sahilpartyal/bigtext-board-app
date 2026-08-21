import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/settings_provider.dart';
import 'recents_screen.dart';

/// Wrapper that provides ProviderScope for RecentsScreen
/// when used within GetX navigation.
class RecentsWrapper extends StatefulWidget {
  const RecentsWrapper({super.key});

  @override
  State<RecentsWrapper> createState() => _RecentsWrapperState();
}

class _RecentsWrapperState extends State<RecentsWrapper> {
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _prefs = prefs);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_prefs == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1C1C1E),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(_prefs!),
      ],
      child: const RecentsScreen(),
    );
  }
}

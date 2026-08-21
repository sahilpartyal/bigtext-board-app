import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/settings_provider.dart';
import 'main_display_screen.dart';

/// Wrapper that provides ProviderScope for MainDisplayScreen
/// when used within GetX navigation.
class MainDisplayWrapper extends StatefulWidget {
  const MainDisplayWrapper({super.key});

  @override
  State<MainDisplayWrapper> createState() => _MainDisplayWrapperState();
}

class _MainDisplayWrapperState extends State<MainDisplayWrapper> {
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
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(_prefs!),
      ],
      child: const MainDisplayScreen(),
    );
  }
}

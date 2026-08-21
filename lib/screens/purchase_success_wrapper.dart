import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/settings_provider.dart';
import 'purchase_success_screen.dart';

/// Wrapper that provides ProviderScope for PurchaseSuccessScreen
/// when used within GetX navigation.
class PurchaseSuccessWrapper extends StatefulWidget {
  const PurchaseSuccessWrapper({super.key});

  @override
  State<PurchaseSuccessWrapper> createState() => _PurchaseSuccessWrapperState();
}

class _PurchaseSuccessWrapperState extends State<PurchaseSuccessWrapper> {
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
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(_prefs!),
      ],
      child: const PurchaseSuccessScreen(),
    );
  }
}

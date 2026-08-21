import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/services/storage_service.dart';
import 'data/services/purchase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow all orientations - screens control their own orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  final prefs = await SharedPreferences.getInstance();

  // Initialize purchase service for in-app purchases
  await PurchaseService().init();

  // Ads are deliberately NOT initialized here. The App Tracking Transparency
  // prompt has to appear before any ad SDK starts, and iOS will not show it
  // until the app is on screen — which it is not yet at this point.
  // SplashController calls AdService().init() instead.

  runApp(BigTextApp(storageService: StorageService(prefs)));
}

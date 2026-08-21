import 'package:flutter/services.dart';

Future<void> triggerHaptic() async {
  await HapticFeedback.lightImpact();
}

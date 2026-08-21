import 'package:flutter/material.dart';

/// Simple toast/snackbar helper for user feedback
class ToastHelper {
  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    SnackBarAction? action,
    bool isError = false,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFF323232),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: action,
        dismissDirection: DismissDirection.down,
      ),
    );

    // Force hide after duration
    Future.delayed(duration, () {
      scaffoldMessenger.hideCurrentSnackBar();
    });
  }

  /// Show success toast
  static void success(BuildContext context, String message) {
    show(context, message);
  }

  /// Show error toast
  static void error(BuildContext context, String message) {
    show(context, message, isError: true);
  }

  /// Show toast with undo action
  static void showWithUndo(
    BuildContext context,
    String message, {
    required VoidCallback onUndo,
  }) {
    show(
      context,
      message,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: 'UNDO',
        textColor: Colors.blue,
        onPressed: onUndo,
      ),
    );
  }
}

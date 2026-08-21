import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../models/display_mode.dart';
import '../providers/message_provider.dart';
import '../providers/recents_provider.dart';
import '../providers/settings_provider.dart';
import '../utils/toast_helper.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/recent_message_tile.dart';

// Light theme tokens, kept in step with settings_screen.dart so both screens
// read as the same surface.
const Color _backgroundColor = Color(0xFFF9FAFB);
const Color _cardColor = Colors.white;
const Color _textPrimary = Color(0xFF1F2937);
const Color _textSecondary = Color(0xFF6B7280);
const Color _subtleFill = Color(0xFFF1F5F9);
const Color _destructive = Color(0xFFFF453A);

class RecentsScreen extends ConsumerStatefulWidget {
  const RecentsScreen({super.key});

  @override
  ConsumerState<RecentsScreen> createState() => _RecentsScreenState();
}

class _RecentsScreenState extends ConsumerState<RecentsScreen> {
  @override
  void initState() {
    super.initState();
    // Force portrait orientation for recents screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final recents = ref.watch(recentsProvider);
    final hasRecents = recents.isNotEmpty;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Recents',
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
        actions: [
          if (hasRecents)
            TextButton(
              onPressed: () => _confirmClearAll(context, ref),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: _destructive,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: hasRecents
                ? _buildRecentsList(context, ref, recents)
                : _buildEmptyState(),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Empty state illustration
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: _subtleFill,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 56,
              color: _textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Recent Names',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Names you enter will appear here\nfor quick access',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentsList(BuildContext context, WidgetRef ref, List recents) {
    return ListView.builder(
      // Only scroll when the content actually overflows the viewport.
      // ClampingScrollPhysics has no overscroll, so a short list that fits
      // on screen can't be dragged or bounced.
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      // One extra leading item for the hint line that used to sit under the
      // old custom app bar title.
      itemCount: recents.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Text(
              'Tap to select, swipe to delete',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          );
        }

        final itemIndex = index - 1;
        final message = recents[itemIndex];
        return RecentMessageTile(
          message: message,
          onTap: () {
            final settings = ref.read(settingsProvider);

            // Update passengerName (used in Simple and Business modes)
            ref.read(settingsProvider.notifier).update(
                (s) => s.copyWith(passengerName: message.text));

            // For Presentation mode, also update first slide directly
            if (settings.displayMode == DisplayMode.presentation) {
              final slides = ref.read(slidesProvider);
              if (slides.isNotEmpty) {
                ref.read(slidesProvider.notifier).updateSlide(
                  0,
                  slides.first.copyWith(title: message.text),
                );
              }
            }

            Get.back();
          },
          onDismissed: () {
            final deletedMessage = recents[itemIndex];
            ref.read(recentsProvider.notifier).removeMessage(itemIndex);
            ToastHelper.showWithUndo(
              context,
              'Removed from recents',
              onUndo: () {
                ref.read(recentsProvider.notifier).insertMessage(itemIndex, deletedMessage);
              },
            );
          },
        );
      },
    );
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _destructive.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: _destructive,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Clear All',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to clear all recent names? This action cannot be undone.',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 15,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              ref.read(recentsProvider.notifier).clearAll();
              Navigator.pop(context);
              ToastHelper.success(context, 'All recents cleared');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _destructive,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

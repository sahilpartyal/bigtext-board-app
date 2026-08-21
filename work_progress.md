# BigText App - Work Progress



**Date:** April 10, 2026
**Session Duration:** ~2 hours

---

## Summary

Today we reviewed the codebase against a Codex-generated bug list and fixed **13 issues** across functionality, UI, and UX improvements.

---

## Bugs Fixed from Codex Report

### Critical (2/2 Fixed - Previously)
| Bug | Status | Notes |
|-----|--------|-------|
| Wakelock never toggles after startup | ✅ Already Fixed | `settings_provider.dart` |
| Startup crash on corrupt prefs | ✅ Already Fixed | `_safeLogoPosition()` validates input |

### Functional (6/6 Fixed Today)
| Bug | Status | File Changed |
|-----|--------|--------------|
| Slides not persisted | ✅ Fixed | `message_provider.dart` - Added JSON serialization & SharedPreferences |
| Slides don't sync with passenger name | ✅ Fixed | `message_provider.dart` - Added `ref.listen` for passengerName |
| Recents only works in Simple mode | ✅ Fixed | `recents_screen.dart` - Updates slides in Presentation mode |
| Auto-save only in Simple mode | ✅ Fixed | `main_display_screen.dart` - Added to all edit methods |
| Subtitle font family no UI | ✅ Fixed | `floating_control_panel.dart` - Added separate font selector |
| No Cancel button in dialog | ✅ Already Fixed | `edit_text_dialog.dart` |

### UX/Polish (2/2 Fixed Today)
| Bug | Status | File Changed |
|-----|--------|--------------|
| Controls hide timer during dialog | ✅ Fixed | `main_display_screen.dart` - Timer pauses during dialogs |
| No error feedback to user | ✅ Fixed | Added `toast_helper.dart` - Toast/snackbar system |

---

## New Features Implemented

### 1. Toast/Snackbar Feedback System
**File:** `lib/utils/toast_helper.dart` (NEW)

| Action | Toast Message |
|--------|---------------|
| Save text | "Saved!" |
| Clear text | "Cleared" |
| Save title | "Title saved!" |
| Save subtitle | "Subtitle saved!" |
| Save slide | "Slide X saved!" |
| Delete slide | "Slide deleted" + UNDO button |
| Delete recent | "Removed from recents" + UNDO button |
| Clear all recents | "All recents cleared" |

### 2. Undo Functionality
- Delete slide → Can undo within 4 seconds
- Delete recent → Can undo within 4 seconds
- Added `insertSlide()` to `SlidesNotifier`
- Added `insertMessage()` to `RecentsNotifier`

### 3. Subtitle Font Selector
- Separate font control for subtitles
- Orange highlight for subtitle font (vs blue for title)
- Available in Business and Presentation modes

---

## UI Improvements

### 1. Controls Button Moved
**Before:** Floating "Controls" button with text below the top bar
**After:** Icon-only button in top bar next to Settings

**Files Changed:**
- `overlay_controls.dart` - Added `onControlsTap` and `showControlsButton`
- `main_display_screen.dart` - Removed separate floating button

### 2. Frosted Glass Top Bar
**File:** `overlay_controls.dart`

- Added `BackdropFilter` with 10px blur
- Semi-transparent dark tint
- Subtle bottom border
- Premium iOS-style appearance

### 3. Responsive Control Panel Height
**File:** `floating_control_panel.dart`

- Changed from fixed `maxHeight: 500` to dynamic
- Now uses 70% of screen height
- Clamped between 300-650px
- Works properly in landscape mode

---

## Files Modified

```
lib/
├── providers/
│   ├── message_provider.dart      # Slides persistence, sync, insertSlide
│   └── recents_provider.dart      # insertMessage for undo
├── screens/
│   ├── main_display_screen.dart   # Toast messages, timer pause, auto-save
│   └── recents_screen.dart        # Toast messages, undo support
├── widgets/
│   ├── overlay_controls.dart      # Controls button, frosted glass
│   └── floating_control_panel.dart # Subtitle font, responsive height
└── utils/
    └── toast_helper.dart          # NEW - Toast/snackbar utility
```

---

## Remaining Issues (Not Fixed)

### Code Quality
| Issue | File | Priority |
|-------|------|----------|
| Company name TextField desyncs | `settings_screen.dart` | Low |
| TextEditingController not disposed | `edit_text_dialog.dart` | Low |
| Lint: triple underscore `(_, _, _)` | `logo_display.dart:44` | Low |

### Missing Features
| Feature | Priority |
|---------|----------|
| Test coverage | Medium |
| Firebase/API configuration | Unknown |

---

## Testing Checklist

### Functional Tests
- [x] Slides persist after app restart
- [x] First slide syncs with passenger name changes
- [x] Recents work in all modes (Simple, Business, Presentation)
- [x] Auto-save works in all modes
- [x] Subtitle font can be changed independently

### UI Tests
- [x] Controls button appears in top bar (Business/Presentation)
- [x] Frosted glass effect visible on top bar
- [x] Control panel scrolls properly in landscape
- [x] Subtitle font selector visible and functional

### UX Tests
- [x] Toast appears after saving text
- [x] Toast appears after deleting with UNDO option
- [x] UNDO restores deleted slide/recent
- [x] Controls stay visible while dialog is open
- [x] Controls reappear after dialog closes

---

## How to Run

```bash
cd /Users/lovleenghumaan/Downloads/bigtext-main
flutter run -d <device_id>
```

---

## Next Steps (Recommended)

1. **Add test coverage** - Unit tests for providers, widget tests for screens
2. **Fix remaining lint warnings** - Minor code quality improvements
3. **Add onboarding** - First-time user tutorial
4. **Add quick mode switcher** - Switch modes from main screen without going to settings

---

*Generated by Claude Code*

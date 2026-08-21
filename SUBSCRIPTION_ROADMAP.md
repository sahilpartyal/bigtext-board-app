# BigText Subscription Implementation Roadmap

> Complete Implementation Guide for In-App Purchases
> Version 1.0 | May 2025

---

## Table of Contents

1. [Overview & Strategy](#1-overview--strategy)
2. [Subscription Plans](#2-subscription-plans)
3. [Platform Setup](#3-platform-setup)
4. [Dependencies](#4-dependencies)
5. [File Structure](#5-file-structure)
6. [Implementation Steps](#6-implementation-steps)
7. [UI/UX Changes](#7-uiux-changes)
8. [New Screens](#8-new-screens)
9. [Feature Gating](#9-feature-gating)
10. [Testing Checklist](#10-testing-checklist)

---

## 1. Overview & Strategy

Implement a freemium model where users can unlock premium features through subscription or one-time purchase.

### Monetization Model

| Tier | Features |
|------|----------|
| **Free** | Simple mode only, 4 fonts, 6 colors, no custom logo, watermark displayed |
| **Pro** | All 3 modes, 12 fonts, all colors + custom, custom logo, no watermark |

### User Flow

```
App Launch → Check Subscription → Load Features Based on Tier

Tap Locked Feature → Upgrade Screen → Purchase → Unlock Features
```

---

## 2. Subscription Plans

### Pricing Tiers

| Plan | Price | Product ID |
|------|-------|------------|
| Monthly | $1.99/month | `bigtext_pro_monthly` |
| Yearly ⭐ | $9.99/year (save 58%) | `bigtext_pro_yearly` |
| Lifetime | $19.99 one-time | `bigtext_pro_lifetime` |

### Feature Comparison

| Feature | Free | Pro |
|---------|------|-----|
| Simple Mode | ✅ | ✅ |
| Business Mode | 🔒 | ✅ |
| Presentation Mode | 🔒 | ✅ |
| Font Families | 4 | 12 |
| Color Presets | 6 | 12 + custom |
| Custom Logo | 🔒 | ✅ |
| Watermark | Shown | Hidden |
| Recent Messages | 10 max | 50 max |

---

## 3. Platform Setup

> ⚠️ **Important:** Complete platform setup BEFORE writing code. Products must exist in stores for testing.

### Apple App Store Connect

#### Step 1: Agreements
- Go to **App Store Connect → Agreements, Tax, and Banking**
- Accept the "Paid Applications" agreement
- Set up banking information

#### Step 2: Create Products
- Go to **Your App → In-App Purchases → Manage**
- Create the following products:

| Type | Product ID |
|------|------------|
| Auto-Renewable Subscription | `bigtext_pro_monthly` |
| Auto-Renewable Subscription | `bigtext_pro_yearly` |
| Non-Consumable | `bigtext_pro_lifetime` |

#### Step 3: Subscription Group
- Create a subscription group called "BigText Pro"
- Add monthly and yearly subscriptions to this group

#### Step 4: Sandbox Testers
- Go to **Users and Access → Sandbox Testers**
- Create test accounts for development testing

### Google Play Console

#### Step 1: Merchant Account
- Go to **Play Console → Setup → Payments profile**
- Set up your merchant account

#### Step 2: Create Products
- Go to **Your App → Monetize → Products**

| Section | Product ID |
|---------|------------|
| Subscriptions | `bigtext_pro_monthly` |
| Subscriptions | `bigtext_pro_yearly` |
| In-app products | `bigtext_pro_lifetime` |

#### Step 3: License Testers
- Go to **Setup → License testing**
- Add Gmail accounts for testing purchases without charges

---

## 4. Dependencies

### Add to pubspec.yaml

```yaml
dependencies:
  # Add for subscriptions:
  in_app_purchase: ^3.2.0
```

### iOS Configuration

**File:** `ios/Runner/Runner.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
    <key>com.apple.developer.in-app-payments</key>
    <array>
        <string>merchant.com.yourcompany.bigtext</string>
    </array>
</dict>
</plist>
```

### Android Configuration

**File:** `android/app/src/main/AndroidManifest.xml`

```xml
<manifest>
    <uses-permission android:name="com.android.vending.BILLING"/>
    ...
</manifest>
```

---

## 5. File Structure

### Files to Create & Modify

```
lib/
├── data/
│   ├── models/
│   │   └── app_settings.dart              [MODIFY] - Add isPro field
│   └── services/
│       └── purchase_service.dart          [NEW] - IAP logic
│
├── providers/
│   ├── subscription_provider.dart         [NEW] - Subscription state
│   └── settings_provider.dart             [MODIFY] - Add Pro checks
│
├── screens/
│   ├── subscription/                      [NEW FOLDER]
│   │   ├── subscription_screen.dart       [NEW] - Purchase UI
│   │   └── components/
│   │       ├── plan_card.dart             [NEW]
│   │       ├── feature_list.dart          [NEW]
│   │       └── restore_button.dart        [NEW]
│   │
│   ├── settings/
│   │   ├── settings_screen.dart           [MODIFY] - Lock Pro features
│   │   └── components/
│   │       └── mode_selector.dart         [MODIFY] - Lock modes
│   │
│   └── home/
│       └── main_display_screen.dart       [MODIFY] - Add watermark
│
├── widgets/
│   ├── font_selector.dart                 [MODIFY] - Limit free fonts
│   ├── color_swatch_grid.dart             [MODIFY] - Limit free colors
│   ├── pro_badge.dart                     [NEW] - "PRO" indicator
│   ├── locked_feature.dart                [NEW] - Lock overlay
│   └── watermark.dart                     [NEW] - Free tier watermark
│
├── utils/
│   └── constants.dart                     [MODIFY] - Add product IDs
│
└── app/routes/
    └── app_pages.dart                     [MODIFY] - Add subscription route
```

### Summary

| Action | Count |
|--------|-------|
| **NEW FILES** | 9 files |
| **MODIFY FILES** | 9 files |

---

## 6. Implementation Steps

### Phase 1: Core Infrastructure

1. Add `in_app_purchase` dependency to pubspec.yaml
2. Configure iOS entitlements and Android permissions
3. Create `PurchaseService` class with:
   - `init()` - Initialize IAP connection
   - `buy(productId)` - Trigger purchase
   - `restore()` - Restore previous purchases
4. Create `SubscriptionProvider` with Riverpod
5. Add product IDs to `constants.dart`

### Phase 2: Data Layer

1. Add `isPro` boolean to `AppSettings` model
2. Add `subscriptionType` enum:
   ```dart
   enum SubscriptionType { free, monthly, yearly, lifetime }
   ```
3. Add `subscriptionExpiry` DateTime for recurring subscriptions
4. Update SharedPreferences persistence logic

### Phase 3: Subscription Screen

1. Create `SubscriptionScreen` with plan selection UI
2. Build `PlanCard` widget for each tier (Monthly, Yearly, Lifetime)
3. Add `FeatureList` widget showing Pro benefits
4. Implement `RestoreButton` for restoring previous purchases
5. Add route `/subscription` to `app_pages.dart`

### Phase 4: Feature Gating

1. Create `LockedFeature` overlay widget
2. Create `ProBadge` indicator widget
3. Modify `ModeSelector`:
   - Add lock icon to Business mode
   - Add lock icon to Presentation mode
   - Tap locked mode → Navigate to subscription screen
4. Modify `FontSelector`:
   - Show only 4 fonts for free users
   - Show remaining 8 fonts with lock + PRO badge
5. Modify `ColorSwatchGrid`:
   - Show only 6 colors for free users
   - Lock custom color picker
6. Lock custom logo feature in settings

### Phase 5: Free Tier Restrictions

1. Create `Watermark` widget (semi-transparent "BigText" text)
2. Add watermark to `MainDisplayScreen` for free users
3. Limit recent messages to 10 for free tier (vs 50 for Pro)
4. Add "Upgrade to Pro" button/banner in settings header

### Phase 6: Testing & Polish

1. Test purchase flow on iOS sandbox (physical device)
2. Test purchase flow on Android license testing (physical device)
3. Test restore purchases functionality
4. Test subscription expiry handling
5. Add loading states during purchase
6. Add error handling for failed purchases

---

## 7. UI/UX Changes

### Settings Screen Changes

| Location | Change | Details |
|----------|--------|---------|
| Header | Add upgrade banner | "Upgrade to Pro" card with benefits preview |
| Mode Selector | Add lock icons | 🔒 on Business & Presentation, tap opens subscription |
| Font Selector | Limit & lock | Show 4 fonts free, lock remaining 8 with PRO badge |
| Color Picker | Limit & lock | Show 6 colors free, lock custom picker |
| Logo Section | Lock section | Disable toggle, show "Pro Feature" overlay |
| Footer | Add restore | "Restore Purchases" link |

### Main Display Screen Changes

| Element | Free Tier | Pro Tier |
|---------|-----------|----------|
| Watermark | "BigText" in corner (semi-transparent) | No watermark |
| Overlay Controls | Add "⭐ Upgrade" button | Show "PRO" badge or hide |

### New UI Components

#### 1. LockedFeature Widget
- Semi-transparent overlay with lock icon
- "Upgrade to unlock" text
- Tap navigates to subscription screen

#### 2. ProBadge Widget
- Small "PRO" pill badge
- Gold/gradient styling
- Displayed next to locked features

#### 3. Watermark Widget
- Positioned in bottom-right corner
- Semi-transparent "BigText" text
- Does not interfere with main content

#### 4. UpgradeBanner Widget
- Card at top of settings
- Shows Pro benefits summary
- Gradient background with "Upgrade Now" CTA button

---

## 8. New Screens

### Subscription Screen Layout

```
┌─────────────────────────────────────────┐
│  ← Back                    Restore 🔄   │  ← AppBar
├─────────────────────────────────────────┤
│                                         │
│         ⭐ Unlock BigText Pro           │  ← Header
│    Access all features, no limits       │
│                                         │
├─────────────────────────────────────────┤
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │ Monthly │ │ Yearly  │ │Lifetime │   │  ← PlanCards
│  │  $1.99  │ │  $9.99  │ │ $19.99  │   │
│  │ /month  │ │  /year  │ │  once   │   │
│  │         │ │ POPULAR │ │         │   │
│  └─────────┘ └─────────┘ └─────────┘   │
│                                         │
├─────────────────────────────────────────┤
│  What you get with Pro:                 │  ← FeatureList
│  ✓ Business & Presentation modes        │
│  ✓ All 12 font families                 │
│  ✓ All colors + custom picker           │
│  ✓ Custom logo upload                   │
│  ✓ No watermark                         │
│  ✓ 50 recent messages                   │
│                                         │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │      Continue with Yearly       │   │  ← CTA Button
│  └─────────────────────────────────┘   │
│                                         │
│  Terms • Privacy • Auto-renews          │  ← Legal
└─────────────────────────────────────────┘
```

### Screen States

| State | UI |
|-------|-----|
| **Loading** | Shimmer/skeleton while fetching products from store |
| **Processing** | Full-screen loader with "Processing purchase..." during transaction |
| **Success** | Celebration animation, "Welcome to Pro!" message, auto-dismiss |
| **Error** | Error message with retry button, "Purchase cancelled" for user-cancelled |

---

## 9. Feature Gating

### Where to Add Pro Checks

| Feature | File | Location |
|---------|------|----------|
| Business Mode | `mode_selector.dart` | ~Line 45-60 |
| Presentation Mode | `mode_selector.dart` | ~Line 65-80 |
| Font Selection | `font_selector.dart` | ~Line 30-50 |
| Color Selection | `color_swatch_grid.dart` | ~Line 25-45 |
| Custom Color | `color_swatch_grid.dart` | ~Line 80-100 |
| Logo Toggle | `settings_screen.dart` | ~Line 180-200 |
| Watermark | `main_display_screen.dart` | Build method |
| Recent Messages | `recents_provider.dart` | ~Line 40 |

### Provider Check Pattern

```dart
// In any widget that needs Pro check:

class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(subscriptionProvider).isPro;

    if (!isPro) {
      return LockedFeature(
        onTap: () => Navigator.pushNamed(context, '/subscription'),
        child: /* locked UI */,
      );
    }

    return /* unlocked UI */;
  }
}
```

### Font Filtering Example

```dart
// In font_selector.dart

final allFonts = ['Roboto', 'Poppins', 'Montserrat', ...]; // 12 fonts

final availableFonts = isPro
    ? allFonts
    : allFonts.take(4).toList();
```

### Color Filtering Example

```dart
// In color_swatch_grid.dart

final allColors = [Colors.red, Colors.blue, ...]; // 12 colors

final availableColors = isPro
    ? allColors
    : allColors.take(6).toList();

// Custom color picker
if (isPro) {
  // Show custom color picker button
}
```

---

## 10. Testing Checklist

> 📱 **Note:** In-app purchases CANNOT be tested on simulators. Use physical devices with sandbox accounts.

### Pre-Launch Checklist

- [ ] **iOS Sandbox Testing** - Test all 3 purchase types on physical iPhone
- [ ] **Android License Testing** - Test all 3 purchase types on physical Android
- [ ] **Restore Purchases** - Uninstall, reinstall, verify restore works
- [ ] **Subscription Expiry** - Test features lock when subscription expires
- [ ] **Network Errors** - Test with airplane mode / poor connectivity
- [ ] **User Cancellation** - Verify cancelled purchases show proper message
- [ ] **Feature Gating** - Verify ALL Pro features locked for free users
- [ ] **Watermark Display** - Shows for free, hidden for Pro
- [ ] **Upgrade Flow UX** - Tap locked features → subscription screen works smoothly
- [ ] **Legal Links** - Terms & Privacy Policy links work

### Sandbox Test Durations

| Platform | Monthly Duration | Yearly Duration |
|----------|------------------|-----------------|
| iOS Sandbox | 5 minutes | 1 hour |
| Android License | 5 minutes | 30 minutes |

### Testing Notes

- **iOS:** Use a separate Apple ID for sandbox testing
- **Android:** Add tester email in Play Console before testing
- **Restore:** Always test restore on a fresh install
- **Expiry:** Sandbox subscriptions renew automatically (up to 6 times on iOS)

---

## Quick Reference

### Product IDs

```dart
// lib/utils/constants.dart

class ProductIds {
  static const String monthly = 'bigtext_pro_monthly';
  static const String yearly = 'bigtext_pro_yearly';
  static const String lifetime = 'bigtext_pro_lifetime';

  static const List<String> all = [monthly, yearly, lifetime];
}
```

### New Routes

```dart
// lib/app/routes/app_pages.dart

GetPage(
  name: '/subscription',
  page: () => const SubscriptionScreen(),
),
```

### Free Tier Limits

```dart
// lib/utils/constants.dart

class FreeTierLimits {
  static const int maxFonts = 4;
  static const int maxColors = 6;
  static const int maxRecentMessages = 10;
  static const bool canUseLogo = false;
  static const bool showWatermark = true;
}
```

---

## Ready to Implement?

**Start with Phase 1: Core Infrastructure**

1. Add dependency
2. Configure platforms
3. Create PurchaseService
4. Create SubscriptionProvider

---

*Generated for BigText v1.0.0 | May 2025*

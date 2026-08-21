# In-App Purchase Implementation Guide

This guide covers StoreKit (iOS) and Google Play Billing (Android) testing, sandbox testing, and production purchases for BigText Pro.

---

## Table of Contents

1. [Overview](#overview)
2. [Testing Methods Comparison](#testing-methods-comparison)
3. [Method 1: Local Testing (kTestPurchaseMode)](#method-1-local-testing-ktestpurchasemode)
4. [Method 2: StoreKit Configuration File (iOS Only)](#method-2-storekit-configuration-file-ios-only)
5. [Method 3: Sandbox Testing](#method-3-sandbox-testing)
6. [Method 4: Production (Real Purchases)](#method-4-production-real-purchases)
7. [Product IDs Reference](#product-ids-reference)
8. [Troubleshooting](#troubleshooting)

---

## Overview

BigText Pro uses the `in_app_purchase` Flutter package which supports both iOS (StoreKit) and Android (Google Play Billing).

**Key Files:**
- `lib/data/services/purchase_service.dart` - Purchase logic
- `lib/utils/constants.dart` - Product IDs
- `lib/providers/subscription_provider.dart` - State management

### Platform Differences

| Feature | iOS (StoreKit) | Android (Google Play) |
|---------|---------------|----------------------|
| Console | App Store Connect | Google Play Console |
| Test Account | Sandbox Tester | License Tester |
| Local Testing | StoreKit Config File | Not available |
| Subscription Groups | Required | Optional |
| Review Required | Yes (each product) | Yes (app level) |

---

## Testing Methods Comparison

| Method | iOS Simulator | iOS Device | Android Emulator | Android Device | Setup Effort |
|--------|--------------|------------|------------------|----------------|--------------|
| kTestPurchaseMode | ✅ | ✅ | ✅ | ✅ | None |
| StoreKit Config File | ✅ | ✅ | ❌ | ❌ | Low |
| Sandbox/License Tester | ❌ | ✅ | ❌ | ✅ | Medium |
| Production | ❌ | ✅ | ❌ | ✅ | High |

---

## Method 1: Local Testing (kTestPurchaseMode)

**Best for:** Quick UI testing, development, debugging on both iOS and Android

### What It Does

- Bypasses real StoreKit (iOS) and Google Play Billing (Android) entirely
- Simulates a successful purchase after 1 second delay
- Saves Pro status locally via SharedPreferences
- Works on ALL platforms: iOS Simulator, Android Emulator, physical devices

### Setup

#### Step 1: Enable Test Mode

Edit `lib/data/services/purchase_service.dart`:

```dart
/// Set to true to test purchases without StoreKit/Play Billing (for development only!)
const bool kTestPurchaseMode = true;  // ← Enable this
```

#### Step 2: Run on iOS

```bash
# List available devices
flutter devices

# Run on iOS Simulator
flutter run -d "iPhone 16 Pro"

# Or run on physical iPhone
flutter run -d <your-iphone-id>
```

#### Step 3: Run on Android

```bash
# Run on Android Emulator
flutter run -d emulator-5554

# Or run on physical Android device
flutter run -d <your-android-id>

# Example with your device
flutter run -d RZCY61F5JPY
```

### How It Works (Code Flow)

```
1. User taps "Continue" on subscription screen
2. subscription_screen.dart calls notifier.buy(productId)
3. subscription_provider.dart calls _purchaseService.buy(productId)
4. purchase_service.dart checks kTestPurchaseMode:

   if (kTestPurchaseMode) {
     // Simulate purchase (no real store connection)
     await Future.delayed(Duration(seconds: 1));
     // Save Pro status to SharedPreferences
     await prefs.setBool('isPro', true);
     // Navigate to success screen
     return true;
   }
```

### Code Reference

Location: `lib/data/services/purchase_service.dart` (lines 97-123)

```dart
Future<bool> buy(String productId) async {
  // TEST MODE: Simulate successful purchase
  if (kTestPurchaseMode) {
    debugPrint('PurchaseService: [TEST MODE] Simulating purchase for $productId');
    _isPurchasing = true;
    onPurchasingStateChanged?.call(true);

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Simulate successful purchase
    final prefs = await SharedPreferences.getInstance();
    final subscriptionType = SubscriptionType.fromProductId(productId);

    await prefs.setBool('isPro', true);
    await prefs.setString('subscriptionType', subscriptionType.name);
    await prefs.setString('subscriptionProductId', productId);
    await prefs.setString('purchaseDate', DateTime.now().toIso8601String());

    debugPrint('PurchaseService: [TEST MODE] Pro unlocked - $productId');

    _isPurchasing = false;
    onPurchasingStateChanged?.call(false);
    onPurchaseUpdated?.call(true, subscriptionType);

    return true;
  }

  // ... real purchase flow continues
}
```

### Testing the Flow

1. Run the app
2. Go to Settings → Tap "Upgrade to Pro" or the upgrade banner
3. Select any plan (Monthly, Yearly, or Lifetime)
4. Tap "Continue"
5. See loading spinner for 1 second
6. Automatically redirected to success screen
7. Pro features now unlocked

### Reset Pro Status (For Re-testing)

To test the purchase flow again, clear the Pro status:

**Option A: Clear App Data**

```bash
# iOS Simulator - Reset entire simulator
# Device → Erase All Content and Settings

# Android - Clear app data
adb shell pm clear com.bigtext.bigtext
```

**Option B: Add Debug Reset Button**

Add temporary code to settings screen:

```dart
ElevatedButton(
  onPressed: () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isPro', false);
    await prefs.remove('subscriptionType');
    // Restart app
  },
  child: Text('Reset Pro Status (Debug)'),
)
```

### Advantages

| Advantage | Description |
|-----------|-------------|
| No setup required | Just change one boolean |
| Works everywhere | Simulator, emulator, physical devices |
| Fast iteration | No waiting for store responses |
| Offline capable | No internet needed |
| Cross-platform | Same code works on iOS and Android |

### Limitations

| Limitation | Description |
|------------|-------------|
| Not real flow | Doesn't test actual purchase dialogs |
| No receipt | No receipt validation testing |
| No renewals | Can't test subscription renewal logic |
| No restore | Restore purchases won't work |
| No edge cases | Can't test payment failures, cancellations |

### When to Use

- ✅ Building and testing UI
- ✅ Testing navigation flow after purchase
- ✅ Testing Pro features unlock/lock
- ✅ Quick demos
- ❌ Testing actual purchase experience
- ❌ Testing receipt validation
- ❌ Pre-release validation

---

## Method 2: StoreKit Configuration File (iOS Only)

**Best for:** Testing purchase UI flow on iOS Simulator without App Store Connect

> **Note:** This method is iOS only. Android does not have an equivalent local testing feature.

### Setup

1. **Open Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Create StoreKit Configuration File:**
   - File → New → File
   - Search for "StoreKit Configuration File"
   - Name: `Products.storekit`
   - Save in `ios/Runner/` folder

3. **Add Products in the StoreKit Editor:**

   | Reference Name | Product ID | Type | Price |
   |---------------|------------|------|-------|
   | Monthly | `bigtext_pro_month_` | Auto-Renewable Subscription | $1.99 |
   | Yearly | `bigtext_pro_year_` | Auto-Renewable Subscription | $14.99 |
   | Lifetime | `bigtext_pro_lifetime` | Non-Consumable | $29.99 |

   For subscriptions, create a Subscription Group named "BigText Pro" first.

4. **Link to Xcode Scheme:**
   - Product → Scheme → Edit Scheme
   - Select "Run" on the left
   - Go to "Options" tab
   - Under "StoreKit Configuration", select `Products.storekit`

5. **Update Code:**
   ```dart
   const bool kTestPurchaseMode = false;  // Use real StoreKit
   ```

6. **Run from Xcode** (not `flutter run`) to use the StoreKit configuration

### Features

- Test full purchase flow locally
- Simulated subscription renewals (faster than real time)
- Transaction management in Xcode
- Works on Simulator

### Renewal Times (StoreKit Config)

| Real Duration | Test Duration |
|---------------|---------------|
| 1 week | 3 minutes |
| 1 month | 5 minutes |
| 2 months | 10 minutes |
| 3 months | 15 minutes |
| 6 months | 30 minutes |
| 1 year | 1 hour |

---

## Method 3: Sandbox Testing

**Best for:** Testing real store products before release on physical devices

### iOS Sandbox Testing

#### Prerequisites

- Apple Developer Account ($99/year)
- App registered in App Store Connect
- Products created in App Store Connect

#### Step 1: Create Products in App Store Connect

1. Login to [App Store Connect](https://appstoreconnect.apple.com)

2. Go to **My Apps** → Select your app → **In-App Purchases**

3. Click **+** and create each product:

   **For Subscriptions (Monthly & Yearly):**
   - First create a Subscription Group: "BigText Pro"
   - Then add subscriptions to the group

   | Field | Monthly | Yearly |
   |-------|---------|--------|
   | Reference Name | Pro Monthly | Pro Yearly |
   | Product ID | `bigtext_pro_month_` | `bigtext_pro_year_` |
   | Subscription Duration | 1 Month | 1 Year |
   | Price | $1.99 | $14.99 |
   | Localization | Add display name & description |

   **For Lifetime (Non-Consumable):**

   | Field | Value |
   |-------|-------|
   | Reference Name | Pro Lifetime |
   | Product ID | `bigtext_pro_lifetime` |
   | Type | Non-Consumable |
   | Price | $29.99 |
   | Localization | Add display name & description |

4. Add **Review Screenshot** for each product (required for approval)

5. Save and wait for **"Ready to Submit"** status

#### Step 2: Create Sandbox Tester Account

1. App Store Connect → **Users and Access**

2. Click **Sandbox** in the left sidebar (under Testers)

3. Click **+** to add tester:
   - First Name / Last Name
   - Email (doesn't need to be real, e.g., `tester1@bigtext.test`)
   - Password (remember this!)
   - App Store Territory (your country)

4. Click **Create**

#### Step 3: Configure iOS Device

**For iOS 14+:**

1. On your iPhone, go to **Settings → App Store**

2. Scroll down to **Sandbox Account**

3. Tap and sign in with your sandbox tester credentials

4. Keep your regular Apple ID signed in at the top

**For iOS 13 and earlier:**

1. Settings → iTunes & App Store → Sign Out

2. Don't sign in yet - wait for purchase prompt

3. When purchase dialog appears, sign in with sandbox account

#### Step 4: Test Purchases on iOS

1. Update code:
   ```dart
   const bool kTestPurchaseMode = false;
   ```

2. Run app on physical device:
   ```bash
   flutter run -d <your-iphone-device-id>
   ```

3. Go to BigText Pro screen

4. Tap Continue on any plan

5. Authenticate with Face ID / Touch ID

6. Purchase completes (no real charge)

---

### Android License Testing

#### Prerequisites

- Google Play Developer Account ($25 one-time)
- App uploaded to Google Play Console (internal testing track is fine)
- Products created in Google Play Console

#### Step 1: Upload App to Google Play Console

1. Login to [Google Play Console](https://play.google.com/console)

2. Create your app if not already created

3. Go to **Release** → **Testing** → **Internal testing**

4. Create a new release and upload your AAB:
   ```bash
   flutter build appbundle
   # Upload build/app/outputs/bundle/release/app-release.aab
   ```

5. Complete the release (doesn't need to be reviewed for testing)

#### Step 2: Create Products in Google Play Console

1. Go to **Monetize** → **Products** → **Subscriptions**

2. Click **Create subscription**

3. Create subscription products:

   | Field | Monthly | Yearly |
   |-------|---------|--------|
   | Product ID | `bigtext_pro_month_` | `bigtext_pro_year_` |
   | Name | Pro Monthly | Pro Yearly |
   | Description | Monthly subscription | Yearly subscription |
   | Base plan | 1 Month, $1.99 | 1 Year, $14.99 |

4. Go to **Monetize** → **Products** → **In-app products**

5. Create lifetime product:

   | Field | Value |
   |-------|-------|
   | Product ID | `bigtext_pro_lifetime` |
   | Name | Pro Lifetime |
   | Description | One-time purchase |
   | Price | $29.99 |

6. **Activate** each product

#### Step 3: Add License Testers

1. Go to **Settings** → **License testing**

2. Add your Gmail addresses (testers' emails)

3. Set **License response** to **RESPOND_NORMALLY**

#### Step 4: Add Testers to Internal Track

1. Go to **Release** → **Testing** → **Internal testing**

2. Click **Testers** tab

3. Create an email list and add tester Gmail addresses

4. Share the **opt-in URL** with testers

5. Testers must accept the invitation via the link

#### Step 5: Test Purchases on Android

1. Update code:
   ```dart
   const bool kTestPurchaseMode = false;
   ```

2. **Important:** Install the app from Google Play (internal track), not via `flutter run`

   Or use `flutter run` but ensure:
   - Same signing key as uploaded AAB
   - Device logged into a license tester Google account

3. Run on physical Android device:
   ```bash
   flutter run -d RZCY61F5JPY
   ```

4. Go to BigText Pro screen

5. Tap Continue on any plan

6. Google Play purchase dialog appears

7. Use **test card** option (no real charge)

### Sandbox/License Tester Renewal Times

#### iOS Sandbox

| Real Duration | Sandbox Duration |
|---------------|------------------|
| 1 week | 3 minutes |
| 1 month | 5 minutes |
| 2 months | 10 minutes |
| 3 months | 15 minutes |
| 6 months | 30 minutes |
| 1 year | 1 hour |

Subscriptions auto-renew up to 6 times in sandbox, then cancel automatically.

#### Android License Testing

| Real Duration | Test Duration |
|---------------|---------------|
| 1 week | 5 minutes |
| 1 month | 5 minutes |
| 3 months | 10 minutes |
| 6 months | 15 minutes |
| 1 year | 30 minutes |

---

## Method 4: Production (Real Purchases)

**Best for:** Live app with real customers

### iOS Production

#### Prerequisites Checklist

- [ ] Apple Developer Account active
- [ ] Paid Applications Agreement signed
- [ ] Banking information added
- [ ] Tax forms completed
- [ ] Products approved in App Store Connect
- [ ] App approved and live on App Store

#### Step 1: Complete Agreements & Banking

1. App Store Connect → **Agreements, Tax, and Banking**

2. Accept **Paid Applications** agreement

3. Add banking information:
   - Bank account details
   - Tax information (W-9 for US, W-8BEN for international)

4. Wait 24-48 hours for approval

#### Step 2: Verify Products are Approved

1. App Store Connect → My Apps → Your App → In-App Purchases

2. Each product should show **"Ready to Submit"** or **"Approved"**

3. Products are approved alongside app review

#### Step 3: Submit App for Review

1. Archive app in Xcode (Product → Archive)

2. Upload to App Store Connect

3. In your app submission, add in-app purchases

4. Submit for review

---

### Android Production

#### Prerequisites Checklist

- [ ] Google Play Developer Account active
- [ ] Merchant account set up
- [ ] Products created and activated
- [ ] App published (at least internal track)

#### Step 1: Set Up Payments Profile

1. Google Play Console → **Settings** → **Payments profile**

2. Create or link a payments profile

3. Add banking information

4. Complete tax information

#### Step 2: Verify Products are Active

1. Google Play Console → **Monetize** → **Products**

2. All products should show **Active** status

#### Step 3: Publish App

1. Complete store listing

2. Submit for review

3. Publish to production track

---

### Production Code Settings

```dart
// lib/data/services/purchase_service.dart
const bool kTestPurchaseMode = false;

// lib/utils/constants.dart
static const bool isTestMode = false;  // For ads
```

### Server-Side Receipt Validation (Recommended)

For production, validate receipts server-side to prevent fraud:

```
Purchase Flow:
1. User initiates purchase
2. Store processes payment
3. App receives receipt
4. App sends receipt to YOUR backend server
5. Server validates with Apple/Google servers
6. Server grants entitlement
7. App unlocks Pro features
```

**Apple's Verification Endpoints:**
- Sandbox: `https://sandbox.itunes.apple.com/verifyReceipt`
- Production: `https://buy.itunes.apple.com/verifyReceipt`

**Google's Verification:**
- Use Google Play Developer API
- Requires service account credentials

### Production Checklist

| Task | iOS | Android |
|------|-----|---------|
| Developer account active | ☐ | ☐ |
| Banking info added | ☐ | ☐ |
| Tax forms completed | ☐ | ☐ |
| All products created | ☐ | ☐ |
| All products active/approved | ☐ | ☐ |
| `kTestPurchaseMode = false` | ☐ | ☐ |
| `isTestMode = false` (ads) | ☐ | ☐ |
| Real AdMob IDs added | ☐ | ☐ |
| Server-side validation | ☐ | ☐ |
| App submitted for review | ☐ | ☐ |

---

## Product IDs Reference

| Product | ID | Type |
|---------|-----|------|
| Monthly | `bigtext_pro_month_` | Auto-Renewable Subscription |
| Yearly | `bigtext_pro_year_` | Auto-Renewable Subscription |
| Lifetime | `bigtext_pro_lifetime` | Non-Consumable |

These IDs are defined in `lib/utils/constants.dart`:

```dart
class ProductIds {
  static const String monthly = 'bigtext_pro_month_';
  static const String yearly = 'bigtext_pro_year_';
  static const String lifetime = 'bigtext_pro_lifetime';

  static const Set<String> all = {monthly, yearly, lifetime};
  static const Set<String> subscriptions = {monthly, yearly};
}
```

**Important:** Product IDs must match EXACTLY in:
- Your code (`constants.dart`)
- App Store Connect (iOS)
- Google Play Console (Android)

---

## Troubleshooting

### iOS Issues

#### "Cannot connect to iTunes Store"

- Check internet connection
- Sign out and sign in to sandbox account again
- Ensure products are "Ready to Submit" in App Store Connect

#### Products not loading

- Verify product IDs match exactly (case-sensitive)
- Check products are approved in App Store Connect
- Ensure Paid Applications Agreement is signed

#### Sandbox login not appearing

- Sign out of regular App Store first
- Or use Settings → App Store → Sandbox Account (iOS 14+)

#### "This In-App Purchase has already been bought"

- For non-consumables, this is expected behavior
- Use "Restore Purchases" to restore ownership
- In sandbox, you can clear purchase history in App Store Connect

### Android Issues

#### "Item not found" or "Item unavailable"

- Product IDs must match exactly
- Products must be **Active** in Google Play Console
- App must be published (at least internal track)
- Wait 15-30 minutes after creating products

#### Purchase dialog not appearing

- Device must be logged into a license tester account
- User must have accepted internal testing invitation
- App signing must match (use same keystore)

#### "Authentication required"

- Add Google account to device
- Ensure Google Play Store is updated

#### Test purchases charging real money

- Verify email is in License Testing list
- Verify user accepted internal testing invite
- Check License response is set to RESPOND_NORMALLY

### Both Platforms

#### Purchase stuck on pending

- Check all agreements are signed
- Verify banking/tax information is complete
- Wait a few minutes and try again

#### Subscription not renewing in test

- iOS: Sandbox subscriptions auto-cancel after 6 renewals
- Android: Test subscriptions cancel after 6 renewals
- Create a new test account to test again

---

## Quick Reference Commands

```bash
# List all connected devices
flutter devices

# Run on iOS Simulator
flutter run -d "iPhone 16 Pro"

# Run on physical iPhone
flutter run -d <iphone-device-id>

# Run on Android Emulator
flutter run -d emulator-5554

# Run on physical Android
flutter run -d RZCY61F5JPY

# Open iOS project in Xcode
open ios/Runner.xcworkspace

# Open Android project in Android Studio
open -a "Android Studio" android/

# Build iOS
flutter build ios

# Build Android AAB (for Play Store)
flutter build appbundle

# Build Android APK (for testing)
flutter build apk

# Clean build
flutter clean && flutter pub get
```

---

## Support

For issues with:
- **Flutter in_app_purchase package:** [pub.dev/packages/in_app_purchase](https://pub.dev/packages/in_app_purchase)
- **App Store Connect:** [Apple Developer Support](https://developer.apple.com/support/)
- **StoreKit:** [Apple StoreKit Documentation](https://developer.apple.com/documentation/storekit)
- **Google Play Billing:** [Android Developer Docs](https://developer.android.com/google/play/billing)
- **Google Play Console:** [Play Console Help](https://support.google.com/googleplay/android-developer)

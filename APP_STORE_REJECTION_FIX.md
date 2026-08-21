# App Store Rejection — Full Analysis & Fix Plan

**App:** BigText
**Submission ID:** 75731537-6314-494b-94e2-60b9402d679f
**Review date:** August 12, 2026
**Review device:** iPhone 17 Pro Max (iOS 26.6)
**Version reviewed:** 1.0 (10)
**Status:** Not rejected — Apple paused the review and asked for information

---

## Read this first

Apple sent **two** "Information Needed" messages. Neither is a hard rejection. The review is paused until you respond.

But while checking the code I found **four more problems** that Apple has not flagged yet. Three of them will get you rejected on the very next submission. So the plan is not "reply to Apple" — the plan is **fix everything in one build, then reply once.**

Replying now without a new build wastes a review cycle: you'd clear the two current questions and immediately fail on the subscription rules instead.

### All six issues at a glance

| # | Issue | Raised by Apple? | Severity | Needs new build? |
|---|-------|------------------|----------|------------------|
| 1 | Tracking permission popup never appears | Yes — Guideline 2.1 | Blocking | Yes |
| 2 | Business model questions | Yes — Guideline 2.1(b) | Reply only | No |
| 3 | No Terms of Use / Privacy Policy links | Not yet | Will block next | Yes |
| 4 | Subscription prices hardcoded in USD | Not yet | Will block next | Yes |
| 5 | Product IDs may not match App Store Connect | Not yet | Will block next | No — verify only |
| 6 | Banner and interstitial share one ad unit ID | Not yet | Lost revenue only | Yes |

---

## Background: what this app actually does

Understanding this makes every decision below obvious.

BigText displays large text on screen — fonts, colors, a logo, saved recent messages, display modes. Here is what the code actually does with data:

| Data | What really happens |
|------|---------------------|
| Messages and text | Saved on device only, via `shared_preferences`. Never uploaded. |
| Fonts, colors, settings | Device only. |
| Uploaded logo image | Device only. |
| Name and email from signup | Device only. `lib/data/repositories/auth_repository.dart` is entirely local — a fake delay, then a local save. There is no server. |
| Purchases | Handled by Apple StoreKit. The app never sees payment details. |
| **Google AdMob** | **The only third party.** May collect device identifiers to serve ads. |

Two consequences that drive this whole document:

1. **The only thing in the app that could "track" a user is AdMob.** The app itself collects nothing and sends nothing anywhere.
2. **The privacy policy is short and honest** — everything stays on the device, plus one ad network.

---

# Issue 1 — Guideline 2.1: Tracking permission popup never appears

## What Apple said

> The app uses the AppTrackingTransparency framework, but we are unable to locate the App Tracking Transparency permission request when reviewed on iOS 26.6.

## What is actually wrong

Three things are true at the same time, and they contradict each other.

**a) The tracking framework is in your app.**
The `google_mobile_ads` package automatically links Apple's `AppTrackingTransparency` framework into the binary. You did not add it by hand and you cannot remove it while you use AdMob.

**b) You declared a tracking permission message.**

`ios/Runner/Info.plist:57-58`

```xml
<key>NSUserTrackingUsageDescription</key>
<string>This identifier will be used to deliver personalized ads to you.</string>
```

That key is a promise to Apple: *"my app will show a tracking popup."*

**c) No popup is ever requested.**

There is no ATT code anywhere in the project. Verified with:

```bash
grep -rn "requestTrackingAuthorization\|AppTrackingTransparency\|ATTracking" lib ios/Runner
# → no matches
```

So Apple sees the framework, reads the promise, opens the app, waits for the popup — and it never comes. That is the entire complaint.

## The hidden reason a naive fix will fail

There is a second, subtler problem that will bite you if you just drop an ATT call into `main()`.

`lib/main.dart:26-30`

```dart
// Initialize ad service for free users only
final isPro = prefs.getBool('isPro') ?? false;
if (!isPro) {
  await AdService().init();
}
```

This runs **before `runApp()`**. At that moment the app is not yet on screen.

**iOS refuses to display the tracking popup unless the app is already visible and active.** If you request it here, iOS silently returns `notDetermined` and shows nothing. You would resubmit and get the identical rejection.

So the popup request has to move to *after* the first screen is drawn — and ad initialization has to move with it, because the popup must come **before** any ad loads.

## There is also a second place that starts AdMob

`lib/providers/ad_provider.dart:117-120`

```dart
if (!_adService.isInitialized) {
  debugPrint('AdProvider: Initializing AdService');
  await _adService.init();
}
```

So AdMob can start from **two** places: `main.dart` and `ad_provider.dart`. If you only guard one of them, ads can start before the popup on some launch paths.

**The clean solution: put the ATT request inside `AdService.init()` itself.** Every route to ads goes through that one method, so there is exactly one gate and it cannot be bypassed.

## Why implement the popup instead of declaring "no tracking"

Apple's message offers an alternative — declare that you do not track, and remove the plist key. I do **not** recommend it here.

`google_mobile_ads` links the tracking framework into the binary whether you use it or not. Apple's scanner detects the linked framework. There is a real chance you strip the plist key, resubmit, and receive the same 2.1 message a second time — with another review cycle gone.

Implementing the popup ends the contradiction permanently, and you keep personalized ad rates, which for an ad-supported free tier is meaningful revenue.

*Choose the alternative only if you would rather ship faster and accept lower ad income. In that case: set "Used to Track You" = No for every data type in App Store Connect, delete `Info.plist:57-58`, and set AdMob to non-personalized ads. Your `SKAdNetworkItems` list at `Info.plist:60-100` already handles ad attribution without tracking.*

---

## Solution — step by step

### Step 1.1 — Add the package

`pubspec.yaml`, under `dependencies:`

```yaml
  app_tracking_transparency: ^2.0.6
```

Then:

```bash
flutter pub get
cd ios && pod install && cd ..
```

### Step 1.2 — Move the ATT request inside `AdService.init()`

`lib/data/services/ad_service.dart`

Add these imports at the top:

```dart
import 'dart:io';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
```

Replace the existing `init()` method (currently lines 38-51) with:

```dart
  /// Initialize the Google Mobile Ads SDK.
  ///
  /// Requests App Tracking Transparency permission first. Apple requires the
  /// prompt to appear before any tracking data is collected, so nothing in the
  /// ads SDK may start until this returns. Must be called once the app is on
  /// screen — iOS will not display the prompt while the app is still launching.
  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('AdService: Already initialized');
      return;
    }

    await _requestTrackingPermission();

    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdService: Initialized successfully');
    } catch (e) {
      debugPrint('AdService: Failed to initialize - $e');
    }
  }

  /// Show the iOS tracking prompt if the user has not answered it yet.
  /// No-op on Android, where the framework does not exist.
  Future<void> _requestTrackingPermission() async {
    if (!Platform.isIOS) return;

    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // A short pause lets the splash screen finish presenting. Without it
        // the prompt can be requested while the app is still becoming active,
        // and iOS silently discards it.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        final result = await AppTrackingTransparency.requestTrackingAuthorization();
        debugPrint('AdService: ATT result = $result');
      } else {
        debugPrint('AdService: ATT already answered - $status');
      }
    } catch (e) {
      debugPrint('AdService: ATT request failed - $e');
    }
  }
```

Two things worth noting:

- The whole thing is wrapped in `try`/`catch`. If ATT fails for any reason, ads still initialize — the app never gets stuck.
- It only prompts when the status is `notDetermined`. Apple allows the prompt **once**; asking again after the user has answered does nothing.

### Step 1.3 — Remove ad initialization from `main.dart`

`lib/main.dart` — delete lines 26-30 and replace with a comment:

```dart
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

  // Ads are NOT initialized here. The App Tracking Transparency prompt must
  // appear before any ad SDK starts, and iOS will not show it until the app is
  // on screen. AdService.init() is called from SplashController instead.

  runApp(BigTextApp(storageService: StorageService(prefs)));
}
```

The `import 'data/services/ad_service.dart';` line can go too, since `main.dart` no longer references it.

### Step 1.4 — Initialize ads from the splash screen

`lib/modules/splash/controllers/splash_controller.dart`

Replace `_initAndNavigate()` (currently lines 21-59) with:

```dart
  Future<void> _initAndNavigate() async {
    // Wait for splash animation
    await Future<void>.delayed(const Duration(seconds: 2));

    // Check if user is Pro (no ads for Pro users)
    final prefs = await SharedPreferences.getInstance();
    final isPro = prefs.getBool('isPro') ?? false;

    if (!isPro) {
      // Requests the ATT prompt, then starts the ads SDK. The app is on screen
      // by now, which is what iOS requires for the prompt to appear.
      await _adService.init();
      await _adService.loadInterstitialAd();

      // Wait for the ad to load (up to 3 seconds)
      for (int i = 0; i < 6; i++) {
        if (_adService.isInterstitialAdLoaded) break;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    if (!isPro && _adService.isInterstitialAdLoaded) {
      debugPrint('SplashController: Showing interstitial ad before home');

      _adService.onInterstitialAdDismissed = () {
        debugPrint('SplashController: Ad dismissed, navigating to home');
        Get.offAllNamed(AppRoutes.home);
      };

      final shown = await _adService.showInterstitialAd();
      if (!shown) {
        debugPrint('SplashController: Ad not shown, navigating to home');
        Get.offAllNamed(AppRoutes.home);
      }
    } else {
      debugPrint('SplashController: Navigating to home (isPro: $isPro)');
      Get.offAllNamed(AppRoutes.home);
    }
  }
```

**This also fixes an existing bug.** In the current code the splash waits for `isInterstitialAdLoaded`, but nothing ever calls `loadInterstitialAd()` before that point — `ad_provider.dart` only runs once the home screen builds, which is *after* the splash. So on a cold start the splash ad could never appear. The explicit `loadInterstitialAd()` call above fixes that.

### Step 1.5 — Improve the permission message (optional but recommended)

`ios/Runner/Info.plist:58`. The current wording is fine, but a clearer message gets more people to tap Allow:

```xml
<key>NSUserTrackingUsageDescription</key>
<string>Allow tracking so BigText can show more relevant ads. This keeps the app free — your text and settings never leave your device.</string>
```

### Step 1.6 — Confirm the resulting launch order

```
App launches
   ↓
Splash screen appears  (app is now active — required by iOS)
   ↓
2 second splash animation
   ↓
ATT prompt appears  ← what Apple was looking for
   ↓
User taps "Allow" or "Ask App Not to Track"
   ↓
Google Mobile Ads SDK initializes
   ↓
Interstitial loads (up to 3s)
   ↓
Interstitial shows
   ↓
Home screen
```

No ad request of any kind happens before the user answers the prompt.

### Step 1.7 — Record the video Apple asked for

Apple explicitly requires a **physical device** — the simulator will not do. Apple asked the recording to show three things:

1. Launching from a fresh install (or after resetting tracking permissions)
2. The ATT prompt appearing before any tracking data is collected
3. The user flow that follows the prompt

How to record it:

1. Delete BigText from the iPhone completely
   *(or keep it and reset via Settings → Privacy & Security → Tracking → toggle "Allow Apps to Request to Track" off and back on)*
2. Install the new build via TestFlight
3. Start a screen recording: Control Centre → record button
4. Launch the app from the home screen
5. Let the splash play, wait for the prompt
6. Tap **Allow**
7. Let it continue into the home screen and use it for a few seconds
8. Stop the recording

Upload it somewhere with a public link (Google Drive with link sharing on, Dropbox, YouTube unlisted) and put that link in **App Store Connect → App Review Information → Notes**, as Apple requested for future submissions.

---

# Issue 2 — Guideline 2.1(b): Business model questions

## What Apple said

> It appears the app may access or include paid digital content or services, and we want to understand your business model before completing our review.

## Why they asked

**Nothing is wrong with your app.** This is a standard questionnaire.

Apple's scanner saw the `in_app_purchase` package plus subscription-shaped product IDs, and wants to confirm you are not selling access outside their payment system — which would cost them the 15–30% commission.

**No code change is needed. You just answer four questions.**

## The facts from your code, for reference

Products (`lib/utils/constants.dart:44-63`):

| Product ID | Type |
|------------|------|
| `bigtext_pro_month_` | Auto-renewing subscription |
| `bigtext_pro_year_` | Auto-renewing subscription |
| `bigtext_pro_lifetime` | One-time purchase |

Free vs Pro (`lib/utils/constants.dart:88-105`):

| Feature | Free | Pro |
|---------|------|-----|
| Fonts | 4 | 12 |
| Colors | 6 | 15 |
| Saved recent messages | 10 | 50 |
| Custom logo upload | No | Yes |
| Ads | Yes | No |
| Business / Presentation modes | Yes | Yes |

Purchases go through `in_app_purchase` → Apple StoreKit. There is no server, no website, no external checkout. `subscription_screen.dart:140` has a Restore button that uses StoreKit's standard restore.

## Solution — the reply to send

Copy this into your reply to Apple:

> **1. Who are the users that will use the paid content and subscriptions in the app?**
>
> All users. BigText is a free consumer utility for displaying large on-screen text. Anyone who downloads it can use the core features for free with advertisements, and any individual user may optionally upgrade to Pro. There are no business accounts, enterprise licences, or externally-provisioned users.
>
> **2. Where can users purchase the content and subscriptions that can be accessed in the app?**
>
> Only inside the app, on the Subscription screen, entirely through Apple In-App Purchase. There is no website, no external checkout, no promotional codes, and no other purchase path anywhere in or outside the app.
>
> **3. What specific types of previously purchased content and subscriptions can a user access in the app?**
>
> Only purchases the user previously made through Apple using the same Apple ID. The Subscription screen provides a "Restore" button that uses StoreKit's standard restore flow. No content purchased through any other channel can be accessed.
>
> **4. What paid content, subscriptions, or features are unlocked within the app that do not use In-App Purchase?**
>
> None. Every paid feature is unlocked exclusively via Apple In-App Purchase. The Pro upgrade — available as a monthly subscription, a yearly subscription, or a one-time lifetime purchase — removes advertisements and unlocks 12 font families, the full colour palette, custom logo upload, and an extended recent-messages history. Nothing is unlocked by any other means.

---

# Issue 3 — Guideline 3.1.2: Missing Terms of Use and Privacy Policy links

**Apple has not flagged this yet. It is the most common subscription rejection in the App Store, and you will hit it on the next submission.**

## What the rule requires

Any app with an **auto-renewing subscription** must show all of the following **inside the app, on the screen where the purchase happens**:

1. Subscription title
2. Subscription length (billing period)
3. Price, and price per unit if relevant
4. A functional link to the **Privacy Policy**
5. A functional link to the **Terms of Use (EULA)**

## What is wrong

You have two auto-renewing products — `bigtext_pro_month_` and `bigtext_pro_year_`.

`lib/screens/subscription_screen.dart` contains the Restore button at line 140, but **no Privacy Policy link and no Terms of Use link anywhere.** Verified with:

```bash
grep -rn "Terms\|Privacy\|url\|launch" lib/screens/subscription_screen.dart
# → only the Restore button matched
```

The same two URLs are also **mandatory fields in App Store Connect**. You cannot submit without the privacy policy URL.

---

## Solution — step by step

### Step 3.1 — Host a privacy policy page

This is the one item that is not code, and the only thing that can block the whole release. Start it first.

You need a **public web page** — a real URL anyone can open in a browser. Not a PDF, not a local file, not a screen inside the app.

**Hosting options, fastest first:**

| Option | Cost | Time | Notes |
|--------|------|------|-------|
| GitHub Pages | Free | ~10 min | Public repo + `index.html` + enable Pages. Apple accepts this without issue. |
| Public Notion page | Free | ~5 min | Share → Publish to web. Works, but an ugly URL. |
| Your own domain | Domain cost | ~20 min | `yourdomain.com/privacy`. Best long term. |

**Avoid free "privacy policy generator" sites** — they produce generic text about cookies and web analytics that does not describe your app, and some inject their own ads onto your policy page.

**GitHub Pages walkthrough:**

1. Create a new public repo, e.g. `bigtext-legal`
2. Add a file named `index.html` containing the policy (draft below)
3. Repo → Settings → Pages → Source: `main` branch, `/ (root)` → Save
4. Wait about a minute
5. Your URL is `https://<your-username>.github.io/bigtext-legal/`

### Step 3.2 — Privacy policy content

This is accurate to what your code actually does. Fill in the two bracketed values.

```
Privacy Policy for BigText
Last updated: [DATE]

BigText is designed to work entirely on your device.

INFORMATION WE COLLECT
We do not operate any servers and we do not collect, transmit, or store
your personal information. Everything you create in BigText — your
messages, saved recent messages, font and colour preferences, display
settings, any logo image you upload, and any name or email you enter —
is stored locally on your device only. None of it is sent to us or to
anyone else. Deleting the app removes all of it permanently.

ADVERTISING
The free version of BigText displays advertisements provided by Google
AdMob. Google may collect and use device identifiers and similar
information to serve and measure ads. On iOS, BigText asks for your
permission before any such tracking takes place, and you may decline.
You can also change this at any time in Settings > Privacy & Security >
Tracking. Google's privacy policy is available at:
https://policies.google.com/privacy

Upgrading to BigText Pro removes all advertisements.

PURCHASES
Purchases and subscriptions are processed entirely by Apple through the
App Store. We never receive or store your payment details.

CHILDREN
BigText is not directed at children under 13 and we do not knowingly
collect information from children.

CHANGES
If this policy changes we will update this page and revise the date above.

CONTACT
Questions about this policy: [YOUR EMAIL ADDRESS]
```

### Step 3.3 — Get a Terms of Use URL

You do not need to write one. Apple's standard EULA is free, permitted, and accepted:

```
https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

Link that unless you have a specific reason to write your own.

### Step 3.4 — Add `url_launcher`

`pubspec.yaml`, under `dependencies:`

```yaml
  url_launcher: ^6.3.0
```

Then `flutter pub get`.

### Step 3.5 — Store the URLs in one place

`lib/utils/constants.dart` — add near the top:

```dart
// ═══════════════════════════════════════════
// LEGAL URLS
// ═══════════════════════════════════════════
// Required by App Store Guideline 3.1.2 — both must be reachable from the
// subscription screen, and both must match what is entered in App Store Connect.
class LegalUrls {
  static const String privacyPolicy = 'https://YOUR-URL-HERE/privacy';
  static const String termsOfUse =
      'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/';
}
```

### Step 3.6 — Add the links to the subscription screen

`lib/screens/subscription_screen.dart` — add the import:

```dart
import 'package:url_launcher/url_launcher.dart';
```

Add this widget method to the screen's state class:

```dart
  Widget _buildLegalLinks() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: Column(
        children: [
          const Text(
            'Subscriptions renew automatically unless cancelled at least '
            '24 hours before the end of the current period. Manage or cancel '
            'in your App Store account settings.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegalLink(label: 'Terms of Use', url: LegalUrls.termsOfUse),
              const Text('  •  ', style: TextStyle(color: Color(0xFF9CA3AF))),
              _LegalLink(label: 'Privacy Policy', url: LegalUrls.privacyPolicy),
            ],
          ),
        ],
      ),
    );
  }
```

And this small widget at the bottom of the file:

```dart
class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF123768),
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
```

Then call `_buildLegalLinks()` in the screen's layout, directly **below the purchase button** so it is visible on the same screen as the price.

### Step 3.7 — Enter both URLs in App Store Connect

- **App Privacy → Privacy Policy URL** → your privacy page (mandatory field)
- **App Information → Licence Agreement** → leave as Apple's standard EULA, or paste your own

The URLs in the app and in App Store Connect must match.

---

# Issue 4 — Subscription prices are hardcoded in US dollars

**Apple has not flagged this yet. It will cause a rejection, and it is wrong for every non-US customer you have.**

## What is wrong

`lib/screens/subscription_screen.dart:293-306`

```dart
if (_selectedPlan == ProductIds.monthly) {
  price = '\$1.99';
  buttonText = 'Continue with Monthly — $price';
} else if (_selectedPlan == ProductIds.yearly) {
  price = '\$14.99';
  buttonText = 'Continue with Yearly — $price';
} else if (_selectedPlan == ProductIds.lifetime) {
  price = '\$29.99';
  buttonText = 'Continue with Lifetime — $price';
}
```

The prices are typed into the UI as fixed US dollar strings.

Meanwhile the correct, localized price from Apple is already available and **is never used**:

- `lib/providers/subscription_provider.dart:145` — `getPrice(productId)`
- `lib/data/services/purchase_service.dart:356` — the underlying implementation

`ProductDetails.price` comes straight from StoreKit, already formatted in the user's own currency.

## Why it causes a rejection

App Review is frequently performed outside the US. A reviewer in India sees "$1.99" on the button, taps it, and Apple's payment sheet says "₹169". That mismatch is Guideline 2.3.1 (accurate metadata) and Guideline 3.1.2 (price must be displayed correctly).

It also means every customer outside the US currently sees a price that is not what they will be charged.

## Solution — step by step

### Step 4.1 — Use the real price

In `_buildCTAButton`, replace the hardcoded block with:

```dart
  Widget _buildCTAButton(SubscriptionState state, SubscriptionNotifier notifier) {
    // Price comes from StoreKit, already formatted in the user's own currency.
    // Never hardcode it — App Review runs from many countries.
    final price = notifier.getPrice(_selectedPlan);

    String buttonText;
    if (price.isEmpty) {
      // Products have not loaded yet, or the IDs do not match App Store Connect.
      buttonText = 'Continue';
    } else if (_selectedPlan == ProductIds.monthly) {
      buttonText = 'Continue with Monthly — $price';
    } else if (_selectedPlan == ProductIds.yearly) {
      buttonText = 'Continue with Yearly — $price';
    } else if (_selectedPlan == ProductIds.lifetime) {
      buttonText = 'Continue with Lifetime — $price';
    } else {
      buttonText = 'Continue';
    }

    // ... rest of the method unchanged
```

### Step 4.2 — Check the plan cards too

Search the rest of `subscription_screen.dart` and `lib/widgets/upgrade_bottom_sheet.dart` for any other hardcoded price:

```bash
grep -rn '\$1\.99\|\$14\.99\|\$29\.99\|1\.99\|14\.99\|29\.99' lib/
```

Every one of them must come from `getPrice()`.

### Step 4.3 — Handle the "no products" state

If `queryProductDetails` returns nothing, the screen currently shows plans with fake prices that cannot be bought. Show a clear message instead:

> "Subscriptions are temporarily unavailable. Please try again later."

A reviewer who sees prices but cannot purchase files a 2.1 rejection. A reviewer who sees an honest unavailable message usually does not.

---

# Issue 5 — Verify product IDs and the Paid Applications Agreement

**No code change. Do this before you write anything else — it is free and it is the highest-probability silent failure in the list.**

## What is suspicious

`lib/utils/constants.dart:46-51`

```dart
static const String _monthlyIos = 'bigtext_pro_month_';
static const String _yearlyIos  = 'bigtext_pro_year_';
```

Those **trailing underscores** look like a typo. The lifetime ID at line 54 has none:

```dart
static const String lifetime = 'bigtext_pro_lifetime';
```

## Why it matters

Product IDs must match App Store Connect **character for character**. If they do not:

1. `queryProductDetails` returns them in `notFoundIDs` (`purchase_service.dart:77-79`)
2. `products` stays empty
3. The subscription screen shows no purchasable plans
4. The reviewer reports "in-app purchase did not work" → Guideline 2.1 rejection

The same happens — regardless of IDs — if the **Paid Applications Agreement** is not active. Without it the store returns zero products every time. This is already noted in the code comment at `purchase_service.dart:9-11`.

## Solution — step by step

1. Open **App Store Connect → your app → Subscriptions / In-App Purchases**
2. Copy each Product ID **exactly** as it appears there
3. Compare against `lib/utils/constants.dart:46-54`, character by character, including any trailing underscore
4. If they differ, change the **code** to match App Store Connect (changing IDs in App Store Connect is not possible once created)
5. Confirm every product's status is **Ready to Submit** or **Approved** — not *Missing Metadata*
6. Go to **Business → Agreements, Tax, and Banking** and confirm the **Paid Applications** agreement shows **Active**. If it shows *Pending*, complete the tax and banking forms — nothing will sell until this is done.
7. Confirm each product has: a display name, a description, a price for at least one territory, and a review screenshot

## Already correct — do not change

`lib/data/services/purchase_service.dart:12`

```dart
const bool kTestPurchaseMode = false;
```

This is set correctly. If it were `true`, `buy()` would unlock Pro locally without contacting the store and every user would get Pro for free. Verify it is still `false` before you build.

---

# Issue 6 — Banner and interstitial share the same ad unit ID

**Cannot cause a rejection. Costs you money on every screen.**

## What is wrong

`lib/utils/constants.dart:15-18`

```dart
static const String prodInterstitialIos = 'ca-app-pub-3514291097789357/5685681330';
static const String prodInterstitialAndroid = '';
static const String prodBannerIos = 'ca-app-pub-3514291097789357/5685681330';
static const String prodBannerAndroid = 'ca-app-pub-3514291097789357/8512670592';
```

`prodInterstitialIos` and `prodBannerIos` are the **same ID**.

An AdMob ad unit has a fixed format. An interstitial unit cannot serve a banner. So every banner request on iOS fails, hits `onAdFailedToLoad` at `ad_service.dart:169-175`, and the banner silently disappears. Users never see it and you earn nothing from it.

Separately, `prodInterstitialAndroid` is an **empty string** — interstitials will fail on Android too, though that does not affect this App Store submission.

## Solution — step by step

1. Open the **AdMob console → Apps → BigText (iOS) → Ad units**
2. Check whether a **Banner** unit already exists
3. If not: **Add ad unit → Banner** → name it `BigText iOS Banner` → create
4. Copy the new unit ID
5. Update `lib/utils/constants.dart:17`:

```dart
static const String prodBannerIos = 'ca-app-pub-3514291097789357/YOUR-NEW-BANNER-ID';
```

6. While you are there, create an **Interstitial** unit for Android and fill in line 16
7. Confirm `isTestMode` at `constants.dart:21` is `false` before building — it currently is

New ad units can take a few hours before they start serving. Do not panic if the banner is empty right after you create it.

---

# Order of operations

Hardest and riskiest first, so problems surface early. Items 4 and 6 are last because they can only be verified on a device, and because item 6 cannot cause a rejection.

| Order | Task | Type | Depends on |
|-------|------|------|-----------|
| 1 | Verify product IDs + Paid Apps Agreement (Issue 5) | Console | — |
| 2 | Host the privacy policy page (Issue 3, step 3.1-3.2) | External | — |
| 3 | ATT popup + startup reorder (Issue 1) | Code | — |
| 4 | Terms + Privacy links (Issue 3, step 3.4-3.7) | Code | Item 2 |
| 5 | Real StoreKit prices (Issue 4) | Code | — |
| 6 | Banner ad unit ID (Issue 6) | Code + console | — |
| 7 | Test everything on a physical iPhone | Testing | Items 3-6 |
| 8 | Record the ATT video (Issue 1, step 1.7) | Testing | Item 7 |
| 9 | Upload build, reply to Apple (Issue 2) | Submission | All |

**Realistic timeline: one working day**, assuming the privacy policy URL is not a bottleneck. Start items 1 and 2 first thing — they need nothing from anyone else and they gate the rest.

---

# Pre-submission testing checklist

Everything below must be tested on a **physical iPhone**, not the simulator. ATT and In-App Purchase both behave differently on a simulator.

**Tracking prompt**
- [ ] Delete the app completely, then install the new build
- [ ] Launch — the ATT prompt appears after the splash animation
- [ ] Tap **Allow** — the app continues normally into the home screen
- [ ] Delete and reinstall, this time tap **Ask App Not to Track** — the app still works and still shows ads
- [ ] Relaunch the app — the prompt does **not** appear a second time
- [ ] Confirm no ad is requested before the prompt is answered (watch the debug console)

**Subscription screen**
- [ ] All three plans load and show prices
- [ ] Prices display in the correct local currency, not hardcoded dollars
- [ ] The **Terms of Use** link opens Apple's EULA in the browser
- [ ] The **Privacy Policy** link opens your page in the browser
- [ ] Auto-renewal disclosure text is visible on the same screen as the price
- [ ] A sandbox purchase completes and Pro unlocks
- [ ] **Restore** works on a fresh install with the same sandbox Apple ID
- [ ] After upgrading to Pro, all ads disappear

**Ads (free user)**
- [ ] The splash interstitial appears on a cold start
- [ ] Banner ads appear where expected — this verifies the Issue 6 fix
- [ ] Ads do not block or break any core feature

**General**
- [ ] `kTestPurchaseMode` is `false` (`purchase_service.dart:12`)
- [ ] `AdUnitIds.isTestMode` is `false` (`constants.dart:21`)
- [ ] Test on both iPhone and iPad — the iPad landscape lock at `Info.plist:44-48` still behaves
- [ ] Build number incremented above 10

---

# Submission checklist

- [ ] New build uploaded and processed in App Store Connect
- [ ] Build number is higher than 10
- [ ] **App Privacy** section completed and matching reality:
  - Identifiers → Device ID → **Used for Tracking: Yes** (because AdMob does)
  - Everything else the app stores stays on device and is not collected by you
- [ ] **Privacy Policy URL** filled in
- [ ] **Licence Agreement** set (Apple standard EULA or your own)
- [ ] **App Review Information → Notes** contains the ATT screen recording link
- [ ] Notes also mention: *"The App Tracking Transparency prompt appears on first launch, immediately after the splash screen, before any ad is requested."*
- [ ] Reply sent to Apple containing:
  - The four business-model answers from Issue 2
  - Confirmation that the ATT prompt is now implemented
  - The video link

---

# Summary of every file that changes

| File | Change | Issue |
|------|--------|-------|
| `pubspec.yaml` | Add `app_tracking_transparency`, `url_launcher` | 1, 3 |
| `lib/data/services/ad_service.dart` | ATT request inside `init()` | 1 |
| `lib/main.dart` | Remove `AdService().init()` | 1 |
| `lib/modules/splash/controllers/splash_controller.dart` | Init ads + load interstitial after ATT | 1 |
| `ios/Runner/Info.plist` | Improve tracking permission wording (optional) | 1 |
| `lib/utils/constants.dart` | Add `LegalUrls`; fix `prodBannerIos`; verify product IDs | 3, 5, 6 |
| `lib/screens/subscription_screen.dart` | Add legal links; use `getPrice()` | 3, 4 |
| `lib/widgets/upgrade_bottom_sheet.dart` | Check for hardcoded prices | 4 |

Nothing outside these files needs to change.

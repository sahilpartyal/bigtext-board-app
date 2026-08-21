# App Review Information — BigText Board

Everything Apple asked for in the Guideline 2.1 "Information Needed" message.

**Where this goes:** App Store Connect → your app → the version being reviewed → **App Review Information → Notes**.
Paste the same text as your **reply in the App Review message thread**.

**Before you paste this anywhere, all four must be true:**

1. The four `[SQUARE BRACKET]` placeholders are filled in. Do not guess at them — Apple checks the video, and item 2 must be devices you really used.
2. **The video actually shows the Apple purchase sheet.** Item 1 below states that it does. In the recording of 20 August it does not — Pro was unlocked by tapping Restore, and StoreKit's payment sheet never appeared. Either re-shoot so a plan is tapped and the sheet is seen, or delete the words "the Apple purchase sheet," from item 1. Sending a claim the video does not support is worse than sending nothing.
3. The video holds the App Tracking Transparency prompt on screen for a slow count of five. The 20 August take showed it for 1.1 seconds.
4. The link opens in a private browser window with no sign-in.

---

## Part 1 — Paste this into the Notes field

> **DEMO ACCOUNT: NOT REQUIRED.** BigText Board has no user accounts, no login, no sign-up and no account deletion, because it has no server and stores nothing about the user. Every feature is reachable immediately on launch. There is nothing to unlock with credentials.
>
> ---
>
1. SCREEN RECORDING :-

Recorded on a physical [iPhone MODEL] running the current release of iOS, version [VERSION], on the build submitted for review:
**[VIDEO LINK]**

The recording is one unbroken take and shows, in order: the iPhone home screen, tapping the app icon, the splash screen, the App Tracking Transparency permission request, the main display screen, typing and displaying a message, changing font / text colour / background colour / text size, the Recents list, the Settings screen, the display-mode switch, the logo upload opening the system photo picker, the Subscription screen showing each plan's title, length and price with the Terms of Use and Privacy Policy links, the Apple purchase sheet, and the Restore Purchases button.

There is no registration, login or account deletion flow to record — the app has no accounts. There is no user-generated content shared with other people, so there is no reporting or blocking flow to record. The only permission request in the app is App Tracking Transparency, and it is shown in the recording.

2. DEVICES AND OPERATING SYSTEMS TESTED :-

FILL IN THE REAL LIST. Example format — replace with what you actually used:
  - iPhone 15 Pro — iOS 26.6 (physical device)
  - iPhone 12 — iOS 18.5 (physical device)
  - iPad (10th generation) — iPadOS 26.6 (physical device)
  - iPhone SE (3rd generation) — iOS 26.6 (Simulator, layout checks only)

The app supports iPhone and iPad, iOS 13 and later. Testing covered portrait and landscape on iPhone, landscape on iPad, cold launch, the tracking prompt, the full purchase and restore flow in Sandbox, and the free-tier limits.


3. WHAT THE APP DOES, THE PROBLEM IT SOLVES, AND WHO IT IS FOR :- 

BigText Board turns an iPhone or iPad into a large, readable sign. The user types a short message and the app displays it full screen at the largest size that will fit, with a choice of font, text colour, background colour and an optional logo. The screen can be kept awake while a message is on display.

The problem it solves:** people who need to be read from a distance currently improvise — a handwritten sheet of paper, or a note app whose text is far too small to read across an arrivals hall or a counter. BigText Board makes a legible sign in a few seconds, with no printing and no preparation.
Value it provides:** the name or message is readable from many metres away, it can be changed instantly, it can carry a company name and logo, and it works entirely offline.

Target audience:** drivers, chauffeurs and people meeting arrivals at airports and railway stations; small businesses showing an open/closed, queue-position, price or "back in 5 minutes" message at a counter; teachers, presenters and event hosts showing a room number, a title or a short instruction to a room. General audience, no age-restricted content, rated 4+.

Three display modes:** Basic — a single message, clean and full screen. Pro — the message plus a company name and a positioned logo. Premium — several messages that auto-advance on a timer.


4. HOW TO SET UP AND REACH EVERY MAIN FEATURE :-

No setup, no login, no credentials and no sample files are needed. Install, open, and the app is usable.
On first launch: the splash screen appears, then the App Tracking Transparency request, then the main display screen.

  - Enter or edit the message** — tap the text in the middle of the main display screen. An edit dialog opens. Type and confirm, and the text is shown full screen at maximum readable size.
  - Change the look** — tap the gear (Settings) button. Font, text colour, background colour, title/subtitle/name text sizes, show or hide the company name, show or hide the logo, logo position and scale, and Keep Screen Awake are all there.
  - Switch display mode** — Settings → Display Mode → Basic, Pro or Premium. All three modes are free.
  - Saved messages** — the Recents button on the main screen lists previously displayed messages; tap one to show it again.
  - Upload a logo (paid feature)** — Settings → Upload Logo. The iOS system photo picker opens; the chosen image is stored on the device only.
  - Paid features** — tap the upgrade banner on the main screen, or the Pro badge next to any locked option. The Subscription screen opens. It offers a monthly subscription, a yearly subscription and a one-time lifetime purchase. Each plan shows its title, its length and its price, taken live from StoreKit in the reviewer's local currency. Links to the Terms of Use (Apple's standard EULA) and the Privacy Policy are on the same screen, directly under the plans. **Restore** is at the top right and uses StoreKit's standard restore flow.
  - What upgrading unlocks** — advertisements are removed, the font list goes from 2 to 12 families (14 in Pro and Premium modes), the colour palette from 3 to 12 colours, custom logo upload is enabled, and the recent-messages history goes from 10 to 50 entries.


5. EXTERNAL SERVICES, TOOLS AND PLATFORMS USED :-

  - Apple In-App Purchase / StoreKit** — every payment in the app, and the restore flow. No other payment processor is used anywhere.
  - Google AdMob (Google Mobile Ads SDK)** — banner advertising shown to users on the free tier. This is the only third party that receives any data from the app, and the only reason the app requests tracking permission.
  - Apple App Tracking Transparency framework** — used to ask permission before the advertising SDK is initialised.
  - Google Fonts** — the display typefaces are fetched from Google's public font host the first time each font is used and are then cached on the device. Only the font file is requested; no user data is sent.
  - The iOS system photo picker (PHPickerViewController)** — used for the optional logo. The app reads only the single image the user selects.
  - What the app does NOT use:** we operate no backend server of our own. There is no user database, no authentication provider, no cloud storage, no analytics SDK, no crash-reporting service, no advertising attribution service beyond AdMob, and no AI or machine-learning service. The typed messages, the recents list, all settings and the uploaded logo are stored only in local device storage and are never uploaded anywhere.
  - User-generated content:** the only content is the text the user types and an optional logo image they choose from their own photo library. Both stay on their own device. Nothing is uploaded, published, shared, or visible to any other user, so the app has no feed, no other users' content, and therefore no need for reporting or blocking mechanisms.


6. REGIONAL DIFFERENCES :-

The app functions consistently across all regions. Every feature and all content is identical everywhere, and nothing is geo-gated, region-locked or feature-flagged by country. The app is currently available in English only.
Two things vary by region but are not controlled by the app: subscription prices are displayed in the local currency exactly as returned by the App Store for the reviewer's storefront, and the specific advertisements served by Google AdMob differ by region as AdMob's inventory differs.


7. REGULATED INDUSTRY OR PROTECTED THIRD-PARTY MATERIAL :-

The app does not operate in a regulated industry. It contains no health, medical, financial, banking, insurance, gambling, betting, lottery, dating, cannabis, alcohol, tobacco, firearms, telehealth, legal-services or government-services functionality, and no age-restricted content. It makes no claims and provides no advice. It is a text-display utility.

It ships no protected third-party material. The display typefaces come from Google Fonts under open-source licences (SIL Open Font Licence 1.1 and Apache Licence 2.0), which permit use in applications. Any logo or image shown in the app is supplied by the user from their own photo library, stays on their own device, and is never distributed by us. The app contains no other party's trademarks, artwork, music, video or copyrighted text.



> ---

> **APP TRACKING TRANSPARENCY (carried over from the previous message)**
>
> The App Tracking Transparency permission request appears on first launch, immediately after the splash screen, before the Google Mobile Ads SDK is initialised and before any tracking data is collected. It is shown in the recording linked in item 1.
>
> **BUSINESS MODEL (carried over from the previous message)**
>
> The paid features are for all users — this is a free consumer utility that any individual may optionally upgrade. There are no business, enterprise or externally provisioned accounts. Purchases can be made only inside the app, on the Subscription screen, entirely through Apple In-App Purchase; there is no website, no external checkout and no other purchase path. Users can access only purchases they previously made through Apple with the same Apple ID, via the standard StoreKit restore flow. No paid content, subscription or feature in the app is unlocked by any means other than Apple In-App Purchase.

---

## Part 2 — The video, shot by shot

One continuous take on a **physical device running the latest iOS** (26.x — Apple asked for this explicitly), no cuts, no trims, no speed-up, no music. Aim for 2–3 minutes. A simulator recording is rejected on sight, and so is a recording made on an older iOS version.

Get to a clean state first: delete the app, install the review build from TestFlight, and **do not open it**. (Or, to re-arm just the tracking prompt: Settings → Privacy & Security → Tracking → toggle *Allow Apps to Request to Track* off and back on.)

| # | Show this | Notes |
|---|---|---|
| 1 | iPhone home screen with the app icon | Proves a cold start |
| 2 | Your finger tapping the icon | |
| 3 | Splash screen | Let it play |
| 4 | **App Tracking Transparency prompt** | **Hold 5+ seconds**, then tap **Allow** |
| 5 | Main display screen appears | |
| 6 | Tap the text, type a message, confirm | The core feature — linger here |
| 7 | Settings → change font, text colour, background colour, a size slider | Go back to the display each time so the change is visible |
| 8 | Settings → Display Mode → switch modes | |
| 9 | Recents → tap a saved message | |
| 10 | Settings → Upload Logo → system photo picker opens → pick an image → logo appears | This is the only other system dialog in the app |
| 11 | Upgrade banner → **Subscription screen** | Show all three plans with **title, length and price visible** |
| 12 | Tap **Terms of Use**, come back, tap **Privacy Policy**, come back | Guideline 3.1.2 — the reviewer checks these open |
| 13 | Tap a plan → **Apple purchase sheet appears** | You may cancel it. It must be seen. |
| 14 | Tap **Restore** | |
| 15 | Back to the display screen, banner ad visible | Ends on the app working |

Then: upload to Google Drive, Dropbox or unlisted YouTube → set sharing to **anyone with the link** → **open the link in a private browser window to confirm no login is required** → paste the link into both the Notes field and your reply. A link that asks Apple to sign in is the single most common way this goes wrong.

---

## Part 3 — Check these before you resubmit

Ordered by how likely each one is to cost you another review cycle.

- [ ] **In-app purchase product IDs match App Store Connect exactly.** The app asks the store for `bigtext_pro_month_`, `bigtext_pro_year_` and `bigtext_pro_lifetime` (`lib/utils/constants.dart`). The trailing underscores on the first two are real, not typos — the 20 August recording shows live prices loading on a physical device, and `ios/Products.storekit` uses the same strings. If a single character differs from App Store Connect, StoreKit returns nothing, the Subscription screen shows `--` instead of prices, and the buy button does nothing — the reviewer sees a broken paid feature and rejects on 2.1 and 3.1.2.
- [ ] **All three products are in the "Ready to Submit" state and attached to this build**, and the Paid Applications Agreement is active with banking and tax details complete. Any of these missing produces the same empty product list as a wrong ID.
- [ ] **Open the Subscription screen on a real device and confirm real prices appear.** This is the one-line version of the two checks above. If you see `--`, do not submit.
- [ ] **Version number.** `pubspec.yaml` says `0.0.13+13`. The build previously reviewed was `1.0 (10)`. The version string in the build must match the version you are submitting in App Store Connect, and the build number must be higher than any build already uploaded for it.
- [ ] **Screenshots show the app in use** — the display screen with real text on it, the settings, the subscription screen. Not the splash screen, not title art (Guideline 2.3.3). iPad screenshots too, since the app supports iPad.
- [ ] **App Privacy answers.** Identifiers → Device ID → *Used for Tracking: Yes* (because of AdMob). Privacy Policy URL entered: https://sahilpartyal.github.io/bigtext-privacy/
- [ ] **Test the logo upload on a physical device** end to end. It is the paid feature the reviewer is most likely to try.
- [ ] **`kTestPurchaseMode` is `false`** in `lib/data/services/purchase_service.dart`. It is currently false. Confirm it stays false.

### Code cleanups — two done, two open

None is what Apple asked about; all remove a way this can go wrong.

0. **OPEN — The free-tier limit constants disagree with the actual gates.** `FreeTierLimits.maxFonts = 4` and `maxColors = 6` in `lib/utils/constants.dart` are never read. The real gates are `FontSelector.freeFontCount = 2` (`lib/widgets/font_selector.dart:18`) and `ColorSwatchGrid.freeColorCount = 3` (`lib/widgets/color_swatch_grid.dart:43`). A reviewer counting locked items sees 2 free fonts and 3 free colours, so the review notes must say 2 and 3 — not 4 and 6. Either delete the unused constants or make the widgets read them.

1. **DONE — The unreachable login and sign-up screens.** Both screens, the old GetX home screen, and their route registrations in `lib/app/routes/app_pages.dart` were deleted. Apple's message asks specifically about registration, login and account deletion; the app now visibly has none of them, so the question no longer applies. `AuthController` and `AuthRepository` still load on launch but drive nothing — harmless, and worth deleting whenever convenient.

2. **OPEN — The photo picker's metadata request.** `picker.pickImage(...)` at `lib/screens/settings_screen.dart:632` leaves `requestFullMetadata` at its default of `true`, which asks for full photo-library access the app does not need — it only needs the bytes of one image. Passing `requestFullMetadata: false` keeps the picker on the permission-free path, and `Info.plist` then correctly needs no photo-library purpose string.

3. **DONE — The dead game-launcher screen.** `lib/screens/game_launcher_screen.dart`, its wrapper and `lib/widgets/game_launcher/` have been deleted — a mock currency UI with `Player123`, XP, coins and gems no longer sits in the bundle of a text-display utility.

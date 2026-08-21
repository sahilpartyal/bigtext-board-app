# Reply to Apple — ready to paste

**Submission ID:** 75731537-6314-494b-94e2-60b9402d679f
**Where to paste:** App Store Connect → App Review → the message thread from Apple

Send **one** reply covering both questions. Replace `[YOUR VIDEO LINK]` before sending.

---

## The reply

> **Guideline 2.1 — App Tracking Transparency**
>
> Thank you for the feedback. The App Tracking Transparency permission request has now been implemented and appears on first launch, immediately after the splash screen, before the Google Mobile Ads SDK is initialised and before any tracking data is collected.
>
> A screen recording captured on a physical iPhone is available here: **[YOUR VIDEO LINK]**
>
> The recording shows a fresh install, the app launching, the App Tracking Transparency permission request appearing, and the user flow that follows. The recording has also been added to the Notes field of the App Review Information section in App Store Connect.
>
> **Advertising — why no advertisement appears in the recording**
>
> The free tier shows a Google AdMob banner at the bottom of the display, Settings and Recents screens. AdMob does not serve live advertisements to an app that is not yet published on the App Store: the request is made and answered, but returns "no ad to show" until the app is live and its AdMob listing has been approved. No advertisement therefore appears in the recording. The advertising code is present and active in the build submitted for review, and the App Tracking Transparency request is made before the Google Mobile Ads SDK is initialised, which is shown in the recording.
>
> **Guideline 2.1(b) — Business model**
>
> **1. Who are the users that will use the paid content and subscriptions in the app?**
>
> All users. BigText Board is a free consumer utility for displaying large on-screen text. Anyone who downloads it can use the core features for free with advertisements, and any individual user may optionally upgrade to Pro. There are no business accounts, enterprise licences, or externally-provisioned users.
>
> **2. Where can users purchase the content and subscriptions that can be accessed in the app?**
>
> Only inside the app, on the Subscription screen, entirely through Apple In-App Purchase. There is no website, no external checkout, no promotional codes, and no other purchase path in or outside the app.
>
> **3. What specific types of previously purchased content and subscriptions can a user access in the app?**
>
> Only purchases the user previously made through Apple using the same Apple ID. The Subscription screen provides a "Restore" button that uses StoreKit's standard restore flow. No content purchased through any other channel can be accessed.
>
> **4. What paid content, subscriptions, or features are unlocked within the app that do not use In-App Purchase?**
>
> None. Every paid feature is unlocked exclusively via Apple In-App Purchase. The Pro upgrade — available as a monthly subscription, a yearly subscription, or a one-time lifetime purchase — removes advertisements and unlocks 12 font families, the full colour palette, custom logo upload, and an extended recent-messages history. Nothing is unlocked by any other means.

---

## Also paste into App Review Information → Notes

> The App Tracking Transparency permission request appears on first launch, immediately after the splash screen, before the Google Mobile Ads SDK is initialised and before any tracking data is collected.
>
> Screen recording captured on a physical iPhone: [YOUR VIDEO LINK]
>
> The recording shows a fresh install, the app launching, the ATT permission request appearing, and the user flow that follows.
>
> No advertisement appears in the recording. AdMob does not serve live ads to an app that is not yet published on the App Store — the request returns "no ad to show" until the app is live and its AdMob listing is approved. The advertising code is present and active in this build, and the tracking request is made before the ads SDK is initialised.

---

## Before sending, confirm

- [ ] Video is recorded on a **physical iPhone**, not a simulator
- [ ] Video holds the **tracking prompt on screen for a slow count of five** before tapping Allow
- [ ] Video shows the **Apple purchase sheet** — tap a plan, let the sheet appear, cancel it, *then* tap Restore
- [ ] Do **not** wait for an advertisement to appear; end on the display screen with a message on it
- [ ] Video link opens in a **private browser window** without a login
- [ ] `[YOUR VIDEO LINK]` replaced in **both** places above
- [ ] New build uploaded, build number **above 10**
- [ ] App Privacy → Identifiers → Device ID → **Used for Tracking: Yes**
- [ ] Privacy Policy URL entered: https://sahilpartyal.github.io/bigtext-privacy/

---

## Why each answer is accurate

Kept here so you can defend the answers if Apple follows up.

| Answer | Evidence in the code |
|---|---|
| No server, no external checkout | `auth_repository.dart` is entirely local; no networking code anywhere except AdMob |
| All purchases via Apple | `purchase_service.dart` uses `in_app_purchase` → StoreKit only |
| Restore uses StoreKit | `subscription_screen.dart:179` → `notifier.restore()` |
| Pro unlocks listed features | `constants.dart` — `FreeTierLimits` vs `ProTierLimits` |
| No free-Pro bypass shipped | `purchase_service.dart:13` — `kTestPurchaseMode = false` |

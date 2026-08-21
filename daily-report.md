# Daily Report — 20 August 2026

**Project:** BigText Board (iOS) | **By:** Sahil Partyal

---

## Done today

- Reviewed the App Review video frame by frame and scored it against Apple's requirements: 12 of 15 points covered
- Found the one thing that would get us rejected again — the Apple payment sheet never appears in the video, because Pro was unlocked by tapping Restore instead of buying a plan
- Also found the tracking permission prompt is only on screen for about one second in the video, where five is advised
- Reduced the colour palette from 15 colours to 12, as requested
- Fixed a false claim on the paid screen: it advertised "Save 37%" when the real saving at our prices is 16%
- That discount now works itself out from the live prices, so it can never be wrong again, in any country
- Corrected the test prices used for local testing so they match App Store Connect: $0.99 monthly, $9.99 yearly, $19.99 lifetime
- Removed the "/month", "/year" and "once" labels from the plan cards and centred the prices
- Deleted around 1,400 lines of screens no user could ever reach, including an unused login and sign-up
- That also removes Apple's question about account deletion, since the app now clearly has no accounts at all
- Found the real reason no adverts appear on TestFlight: Google does not serve live adverts to an app that is not yet on the App Store
- Confirmed our advert setup is correct — test adverts display fine, so nothing is broken on our side
- Updated the reply to Apple to explain the missing adverts up front, so the reviewer does not have to ask
- Corrected several out-of-date statements in the review notes, including wrong colour counts and wrong feature names
- Checked the app builds and runs cleanly on the iPhone 15 Pro simulator on the latest iOS, with the paid screen showing correct prices

---

## Still open

- The video needs re-recording: show the Apple payment sheet, and hold the tracking prompt for a slow count of five
- Pro does not switch on after buying — each screen keeps its own copy of the paid status, so the main screen only notices after a restart. Cause found, fix not yet made
- Restore gives up after three seconds and can wrongly say "no purchases found" when Apple simply answers slowly
- Version number is 0.0.13+13, but the build Apple reviewed was 1.0 (10) — needs deciding before we submit
- Adverts cannot be shown to Apple, and will not appear for real users until the app is live and Google approves the listing
- The video link still needs pasting into the reply to Apple and the review notes

---
# Daily Report — 19 August 2026

**Project:** BigText Board (iOS) | **By:** Sahil Partyal

---

## Done today

- Found why paid users were not getting Pro: the app only listened for the App Store's follow-up message and ignored the purchase result it already had, so a successful payment could vanish silently
- Fixed the purchase button jamming permanently on "Purchase already in progress" — two separate copies of the same on/off switch were drifting apart, and force-quitting the app was the only way out
- Stopped the wall of red error text appearing on the subscription screen: backing out of Apple's payment sheet was being treated as a crash and the raw crash report was printed straight onto the page
- Backing out of Apple's payment sheet is now completely silent, as it should be
- Every remaining store error now shows a short readable sentence instead of technical output
- Added a one-minute safety timeout so a lost reply from the App Store can no longer lock the purchase button forever
- Purchases waiting on approval now say so instead of spinning silently with no explanation
- Fixed error messages being wiped off the screen before the user could read them
- Confirmed the free-Pro test switch is off, so nobody gets Pro without paying
- Bumped the version to 0.0.13+13 so App Store Connect will accept the next TestFlight upload
- Confirmed the app builds cleanly in both debug and release, with no code warnings in the files touched

---

## Still open

- **The fix has not been proven with a real purchase yet.** It cannot be tested on the simulator, so it needs one sandbox purchase on TestFlight or from Xcode to confirm
- **Pro is still just a switch stored on the phone.** Fine for TestFlight, but once live a determined user can turn it on without paying. Fixing it needs a server to check receipts against — waiting on confirmation of whether one exists
- The "waiting for approval" notice currently appears in the red error box, which makes a normal delay look like a failure. Cosmetic only

---
# Daily Report — 18 August 2026

**Project:** BigText Board (iOS) | **By:** Sahil Partyal

---

## Done today

- Got the app building and running on the iPhone simulator again, start to finish — clean build, no code errors. Roughly 30 seconds to build once packages are in place
- Cleared out all old build files and re-downloaded every package the app depends on, so we are building from a known-good clean state
- **Went through the advertisement setup properly and found the real reason no ad appears** — this corrects part of yesterday's conclusion (details below)
- Confirmed the Terms of Use and Privacy Policy links are already in the app and sit on the subscription screen, which is exactly where Apple requires them
- Confirmed the tracking permission prompt is asked *before* the ad system starts up. Apple requires that order, and getting it wrong is a common rejection — ours is correct
- Found two smaller problems worth fixing before the next build (screen rotation warning, and an ad setting still on its test value)

---

## Advertisement setup — what we actually found

Yesterday's report said the ad slot is live and correctly set up, and that the missing ad was simply Google having nothing to serve. That is **true for the small banner ad, but not for the full-screen ad.**

There are two kinds of ad in the app:

| Type | Where users see it | Working? |
|---|---|---|
| Small banner strip | Bottom of main screen, Saved messages, Settings | Set up correctly |
| Full-screen ad | Between actions | **Switched off — never shown to anyone** |

The full-screen ad is switched off because of a setup mistake in our own AdMob account: **the ID we use for the full-screen ad is a copy of the banner ID.** One AdMob slot can only serve one kind of ad, so asking a banner slot for a full-screen ad fails every single time. Android has no full-screen ID entered at all — it is blank.

Whoever wrote the code noticed this and made it skip the request rather than fail noisily on every launch. So nothing is broken or crashing — the feature is simply dormant and earning nothing.

**This is fixed in the AdMob website, not in code.** Create a Full-screen (Interstitial) ad slot under each app, iOS and Android, then paste the two new IDs into the app. The feature switches itself back on with no other changes.

---

## Status

- App builds and runs cleanly — no code problems found today
- Legal links requirement is already satisfied
- Banner ads correctly configured; full-screen ads dormant due to the AdMob account, not the code
- Nothing found today that blocks replying to Apple

---

## Two things to fix before the next build

1. **Full-screen ads are set to appear after every single action.** The setting is on `1`, which the code comments themselves mark as a testing value. Left as is, users get interrupted constantly — bad for retention and enough to draw an AdMob policy warning. Should be `3` or higher
2. **Screen rotation warning.** The app is built for landscape only, but something still asks for portrait on launch. Harmless today, but it is the kind of loose end that shows up as odd behaviour on some devices

---

## Note on simulator testing

Two things fail on the simulator but are known to work on a real iPhone, so they are not faults:

- **Prices do not load** on the simulator. Yesterday we confirmed on a real iPhone that all three genuine Apple prices appear, so this is a simulator limitation only
- **No ads load** on the simulator — network error. The app currently asks for real live ads rather than Google's test ads, and live ads generally do not fill on a simulator. Repeatedly requesting our own live ads can also get an AdMob account flagged, so testing should be switched to Google's test ads

---

## Pending — carried over from yesterday, still open

- Re-record the review video with the iPhone's own screen recording
- Add the missing shots, above all **the Apple payment sheet** — still the top risk of another rejection
- Correct the "all three modes are free" line in the review notes
- Fill in the four blanks in the notes — iPhone model, iOS version, video link, devices tested
- Upload the video and check in a private browser window that Apple will not be asked to sign in
- Paste the notes into App Store Connect and reply in the review thread

---

## Risk

- **The Apple payment sheet is still the top risk** — unchanged from yesterday, and nothing found today reduces it
- Full-screen ads earning nothing is a revenue loss, not a review risk. It will not affect the Apple submission
- The privacy policy sits on a personal GitHub page. It should be checked that it is live and that it mentions advertising data, since the app serves ads — a policy that omits ads is a rejection cause

---

## Timeline

- The two small fixes: about 10 minutes
- Creating the AdMob full-screen slots: about 15 minutes on the AdMob website, then a one-line change each for iOS and Android
- Video and Apple reply unchanged from yesterday: about 40 minutes

---

## Reference

- `lib/utils/constants.dart` — legal links and all ad slot IDs, including the duplicated one
- `lib/providers/ad_provider.dart` — the "after every action" setting
- `APPLE_REVIEW_INFO.md` — the full reply to Apple and video plan
- `VIDEO_RECORDING_GUIDE.md` — walkthrough for the screen recording

---
---

# Daily Report — 17 August 2026

**Project:** BigText Board (iOS) | **By:** Sahil Partyal

--- 

## Done today

- Read Apple's new message (14 August, Guideline 2.1 — Information Needed) and confirmed it is a **request for information, not a bug report** — no new build is needed, we reply to the existing one
- **Closed the biggest risk from the last report:** checked the subscription screen on a real iPhone and it shows genuine Apple prices — $0.99 monthly, $9.99 yearly, $19.99 lifetime. That proves our 3 product codes do match App Store Connect and the payment system is talking to Apple correctly
- Reviewed the recorded app review video end to end and listed exactly what Apple asked for that is missing from it
- Found a contradiction between our review notes and the app: the notes tell Apple all three display modes are free, but the app locks Business and Presentation behind the paid upgrade — confirmed in the code
- Worked out why no advertisement appears in the video: the ad slot is live and correctly set up, so this is Google having no ad to serve yet, not a fault on our side. Apple never asked to see an ad, so it does not block us
- Established that the two shots we thought we could not record — the Apple payment sheet and Restore — are in fact both recordable at no cost

---

## Status

- **No new build required.** Apple wants information and a video, nothing more
- Payments verified working on a real device — last report's highest risk item is now closed
- Video needs re-recording before we reply
- Review notes need one factual correction

---

## Video — what Apple asked for and what we have

| Apple asked for | In the video? |
|---|---|
| Recording starts by launching the app | No — starts mid-loading screen |
| Tracking permission prompt | Yes, but on screen barely 1 second |
| Typing and displaying a message | Yes |
| Changing colours | Yes |
| Changing font | No |
| Saved messages list | No |
| Logo upload / photo access prompt | No |
| Subscription screen with prices | Yes — all three plans, real prices |
| Terms of Use and Privacy Policy open | Yes |
| **Apple payment sheet appearing** | **No — this is the main gap** |
| Restore purchases | No |

Length is 55 seconds; Apple expects roughly 2–3 minutes for an app this size.

---

## Pending

- Re-record the video using the iPhone's own screen recording instead of a camera — the current one is dark and hard to read
- Add the missing shots: home screen and tapping the icon, changing the font, saved messages, logo upload, the Apple payment sheet, Restore
- Hold the tracking prompt on screen for 5 seconds before tapping Allow
- Correct the "all three modes are free" line in the review notes
- Fill in the four blanks in the notes — iPhone model, iOS version, video link, list of devices tested
- Upload the video, set sharing to anyone with the link, and open it in a private browser window to confirm Apple will not be asked to sign in
- Paste the notes into App Store Connect and reply in the review thread

---

## Risk

- **Missing Apple payment sheet is the top risk.** Apple's letter asks for purchase flows in writing. Showing the price list but never tapping a plan is the most likely reason for a third rejection
- No cost or danger in recording it — TestFlight builds always use Apple's test environment, so tapping a plan charges nothing and the sheet can simply be cancelled
- Telling Apple a paid feature is free is the kind of mismatch reviewers check for and will start another round
- A video link that asks Apple to sign in is the single most common way this loop repeats

---

## Timeline

- About 30 minutes to re-record the video, 10 minutes to correct the notes
- Can reply to Apple the same day

---

## Reference

- `APPLE_REVIEW_INFO.md` — the full reply to Apple, plus the shot-by-shot video plan and pre-submit checklist
- `VIDEO_RECORDING_GUIDE.md` — walkthrough for the screen recording
- `APP_STORE_REJECTION_FIX.md` — technical analysis of the earlier rejection

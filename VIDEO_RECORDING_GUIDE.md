# ATT Screen Recording — what Apple wants to see

For Submission ID 75731537-6314-494b-94e2-60b9402d679f, Guideline 2.1.

---

## Apple's exact words

> Reply to this message with a screen recording captured on a physical device that demonstrates:
>
> - Launching the app from a fresh install or after resetting tracking permissions
> - The App Tracking Transparency permission request appearing before any tracking data is collected
> - The user flow that follows the permission request

Three things. The video must show all three, in that order, in one unbroken take.

---

## Rules

| Rule | Why |
|---|---|
| **Physical iPhone only** | A simulator recording is rejected outright. Apple can tell. |
| **The new build** | The current App Store version has no prompt. Install from TestFlight first. |
| **One continuous take** | No cuts, trims, speed-ups, or music. Edits read as staged. |
| **30-60 seconds** | Long enough to show the flow, short enough to watch. |
| **Portrait or landscape** | Either is fine. Just don't rotate mid-recording. |

---

## Step 1 — Get to a fresh state

Pick one.

**Option A — Delete and reinstall (preferred)**
1. Long-press the BigText Board icon → Remove App → Delete App
2. Install the new build from TestFlight
3. **Do not open it**

**Option B — Reset tracking permission**
1. Settings → Privacy & Security → Tracking
2. Toggle **Allow Apps to Request to Track** OFF
3. Toggle it back ON
4. This clears every app's answer, so the prompt will fire again

---

## Step 2 — The recording, second by second

| Time | What is on screen | What you do |
|---|---|---|
| 0:00-0:04 | iPhone **home screen**, BigText Board icon visible | Start recording, dismiss Control Centre |
| 0:04-0:05 | Home screen | **Tap the app icon** |
| 0:05-0:08 | **Splash screen** | Nothing. Let it play. |
| 0:08-0:15 | **⭐ TRACKING PROMPT ⭐** | **Wait 5+ full seconds. Do not rush this.** |
| 0:15-0:16 | Prompt | Tap **Allow** |
| 0:16-0:20 | Splash finishes → home screen | Let it happen |
| 0:20-0:35 | App in normal use | Type a short message, let the banner ad show |
| 0:35 | — | Stop recording |

### The prompt reads

> **Allow "BigText Board" to track your activity across other companies' apps and websites?**
>
> Allow tracking so BigText can show more relevant ads. This keeps the app free — your text and settings never leave your device.
>
> [ Ask App Not to Track ]
> [ Allow ]

### Why the 5-second hold matters most

Reviewers scrub through videos quickly. A prompt that flashes past in half a second gets missed, and you get rejected a third time for "we could not locate the request." Let it sit there. Count to five out loud.

---

## Step 3 — What must be visible

| ✓ | Must appear |
|---|---|
| ☐ | iPhone home screen **before** launch — proves a cold start |
| ☐ | Your finger tapping the app icon |
| ☐ | The splash screen |
| ☐ | **The tracking prompt, clearly, for 5+ seconds** |
| ☐ | You tapping **Allow** |
| ☐ | The app continuing into normal use afterwards |
| ☐ | No cuts anywhere |

---

## Step 4 — Mistakes that cause another rejection

| Mistake | Result |
|---|---|
| Recorded on a simulator | Instant rejection |
| Prompt visible under 1 second | "We could not locate the request" |
| App already open when recording starts | Doesn't prove a cold launch |
| Recorded the old build | No prompt exists in it |
| Tapped "Ask App Not to Track" | Apple wants to see the tracking path work |
| Edited or trimmed | Reads as staged |
| **Video link needs a login** | Most common self-inflicted failure |

---

## Step 5 — Share it

1. Video saves to **Photos** automatically
2. Upload to **Google Drive**, **Dropbox**, or **YouTube (unlisted)**
3. Google Drive: right-click → Share → change **"Restricted"** to **"Anyone with the link"** → Copy link
4. **Open the link in a private/incognito browser window.** If it asks you to sign in, Apple cannot watch it.
5. Put the link in **both** places:
   - App Store Connect → App Review Information → **Notes**
   - Your written reply to Apple (see `APPLE_REPLY.md`)

---

## Step 6 — Notes field text

> The App Tracking Transparency permission request appears on first launch, immediately after the splash screen, before the Google Mobile Ads SDK is initialised and before any tracking data is collected.
>
> Screen recording captured on a physical iPhone: [YOUR LINK]
>
> The recording shows a fresh install, the app launching, the ATT permission request appearing, and the user flow that follows.

---

## What the prompt looks like

Confirmed rendering on a fresh iPhone 16 Pro simulator during development — it appears over the splash screen, before the Google Mobile Ads SDK initialises. On your physical device it will look identical.

If the prompt does **not** appear on your iPhone, stop and check:

1. Is this the new TestFlight build, or the old App Store version?
2. Did you fully delete the app, or reset tracking permissions?
3. Settings → Privacy & Security → Tracking → is **Allow Apps to Request to Track** switched ON? If a user has that off globally, no app can ask.

Point 3 catches people out often — check it before concluding anything is broken.

# Padel Battle for iPhone and Apple Watch

Native iPhone and Apple Watch apps that work together:

1. **On the iPhone**, tap **New match**, enter the names, who serves first and the rule at 40–40,
   and tap **Send to watch**. The watch holds one match at a time; sending another replaces it.
2. **On the watch**, open Padel Battle: the match is shown under **From your phone**. Tap it to
   start, then tap the top or bottom half to score. Nothing is sent while you play.
3. **When you stop playing**, tap **✕** on the watch → **End match** (or finish the match), then
   **Sync to phone**: the score so far goes to the iPhone's **History**, straight away if the
   phone is near, otherwise the next time they're together. Matches don't have to be finished;
   one or two sets in an hour is fine. **Don't sync** discards it; **Resume** goes back to it.

The watch still works on its own: you can set up a match on the watch itself. The iPhone can also
score a match by itself: **Play on phone**.

- `PadelScoreKit/` – the scoring rules in Swift (a port of `src/scoring/` in the Expo app),
  match records, history and their tests.
- `PadelScorePhone/` – the iPhone app (SwiftUI).
- `PadelScoreWatch/` – the watch app (SwiftUI).
- `Shared/` – code used by both apps: colours and the phone ↔ watch link (WatchConnectivity:
  the next match goes to the watch, finished matches come back).
- `project.yml` – the Xcode project definition, used by XcodeGen.

## Run the tests (on your Mac)

```bash
cd apple/PadelScoreKit
swift test
```

## Install on your iPhone and Apple Watch

**One-time setup on your Mac:** Xcode with the iOS and watchOS platforms
(`xcodebuild -downloadPlatform iOS`, `xcodebuild -downloadPlatform watchOS`), your Apple ID in
**Xcode → Settings → Accounts**, and XcodeGen (`brew install xcodegen`). Developer Mode must be
on for both the iPhone and the watch (see *If the watch won't connect* below).

**Build and install** (and again every 7 days with a free Apple ID):

1. Generate and open the project:
   ```bash
   cd apple
   xcodegen
   open PadelScore.xcodeproj
   ```
2. **iPhone:** choose the **PadelScorePhone** scheme and **your iPhone** at the top of Xcode, and
   press **▶**. This replaces the earlier Expo version of the app (same app ID).
3. **Watch:** choose the **PadelScoreWatch** scheme and **your Apple Watch**, and press **▶**.
   (Installing the iPhone app can also install the watch app by itself, but that can take a
   while; running it directly is quicker.)
4. If either device says the developer isn't trusted: on the **iPhone**, go to **Settings →
   General → VPN & Device Management** and trust your Apple ID.

If the earlier watch-only version is still on the watch and the new one won't install, delete
Padel Battle from the watch first (press and hold the app icon) and run again.

## If the watch won't connect

These came up during the first install:

- **Xcode can't see the watch** (`xcrun devicectl list devices` shows only the iPhone): Xcode reaches
  the watch over the local network through the iPhone. Allow **Xcode** under **System Settings →
  Privacy & Security → Local Network** (Xcode asks the first time it looks for devices), keep
  the Mac, iPhone and watch on the same home Wi-Fi with VPN off, and restart the watch and iPhone.
- **"Developer mode is not enabled"**: the watch needs a **passcode**. Turn on **Settings →
  Privacy & Security → Developer Mode**, and after the restart unlock the watch and tap **Turn On**
  in the popup. Check with
  `xcrun devicectl device info details --device <watch id> | grep -i developer`.
- **"The device rejected the Bluetooth connection"**: unplug and replug the iPhone, unlock both
  devices and try again.
- **"This provisioning profile cannot be installed on this device"**: the app was signed before the
  watch was registered. Select **your real watch** in Xcode and press **▶** so Xcode adds it to
  the profile.
- The first install shows **"Fetching debug symbols"** for 10–30 minutes. That happens once per
  watchOS version.

## Keep the app on screen during a match

By default the watch goes back to the clock face a couple of minutes after you lower your wrist.
On the watch: **Settings → General → Return to Clock → Padel Battle → After 1 hour**.

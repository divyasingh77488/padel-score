# Padel Score for Apple Watch

A watch-only app: score a match from your wrist, with your phone left in the bag. It works
offline and saves the match after every point.

- `PadelScoreKit/` – the scoring rules in Swift (a port of `src/scoring/` in the Expo app) and
  their tests.
- `PadelScoreWatch/` – the watch app (SwiftUI).
- `project.yml` – the Xcode project definition, used by XcodeGen.

## Run the tests (on your Mac)

```bash
cd apple/PadelScoreKit
swift test
```

## Install on your Apple Watch

**One-time setup on your Mac:**

1. Xcode with the watchOS platform: `xcodebuild -downloadPlatform watchOS`.
2. Your Apple ID in **Xcode → Settings → Accounts**.
3. XcodeGen: `brew install xcodegen`.

**One-time setup on the watch:** turn on **Settings → Privacy & Security → Developer Mode** on
the watch (it appears after Xcode has seen the watch, see below) and restart when asked.

**Build and install** (and again every 7 days with a free Apple ID):

1. Generate and open the project:
   ```bash
   cd apple
   xcodegen
   open PadelScore.xcodeproj
   ```
2. In Xcode, select the **PadelScoreWatch** target → **Signing & Capabilities** → **Team**:
   your Personal Team (divyasingh77488@gmail.com).
3. Make sure your iPhone is unlocked, on the same Wi-Fi as the Mac, and paired with the watch;
   keep the watch on your wrist, unlocked and charging if possible.
4. At the top of Xcode, choose your **Apple Watch** as the run destination (Xcode may take a few
   minutes to prepare it the first time) and press **▶ Run**.
5. If the watch says the developer isn't trusted: on the **iPhone**, go to **Settings → General →
   VPN & Device Management** and trust your Apple ID.

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
On the watch: **Settings → General → Return to Clock → Padel Score → After 1 hour**.

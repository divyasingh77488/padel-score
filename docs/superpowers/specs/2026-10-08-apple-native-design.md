# Padel Score — Native iPhone + Apple Watch Design

Date: 2026-10-08

## Goal

Score a padel match from the **Apple Watch** without carrying the phone, and publish the app
(iPhone + Watch) on the **App Store**. Android comes later, from the existing Expo code.

**Success:** during a real match, with the phone left in a bag, one tap on the watch per point
keeps an accurate score through deuces, sets and tiebreaks; mis-taps are fixable with undo; the
watch stays on the app for the whole match; the app passes App Store review.

## Decisions

- **Native Swift + SwiftUI** for both apps, in one Xcode project. React Native/Expo cannot run on
  Apple Watch, and a single Swift codebase lets both apps share one copy of the scoring rules.
- **Devices:** iPhone and Apple Watch. No Mac or iPad app in v1.
- **The watch app runs on its own.** It needs no phone, Mac or internet during a match.
- **No phone ↔ watch sync in v1.** Each device keeps its own match.
- **The watch records the match as a workout in Apple Health.** That keeps the app on screen all
  match and logs heart rate and calories.
- **The existing Expo app stays in the repo** as the starting point for Android. It is not
  published to the App Store.

## Requirements (on the user's side)

- **Apple Developer Program**, $99/year: needed for TestFlight and the App Store.
- **A Mac with Xcode** (free, Mac App Store): needed to build, run and upload. Claude's cloud
  environment is Linux, so it writes the code and tests, and the user builds on the Mac with
  step-by-step instructions.
- **XcodeGen** (`brew install xcodegen`): generates the Xcode project from a readable text file
  (`project.yml`), so the project file isn't hand-edited.
- Minimum versions: **iOS 18, watchOS 11** (to confirm against the Xcode version installed).

## Scoring rules (unchanged from the Expo app)

- Games: 0, 15, 30, 40. At 40–40 the rule chosen at setup applies: **advantage**, **golden
  point** (next point wins) or **star point** (advantage at the first two deuces, deciding point
  at the third).
- Sets: first to 6 with a 2-game lead; tiebreak at 6–6 to 7, win by 2.
- Match: best of 3 sets.
- Serve: alternates every game; in a tiebreak the first server serves 1 point, then teams
  alternate every 2; the team that received first in the tiebreak serves the next set.

## Architecture

```
apple/
  project.yml                 XcodeGen spec: iOS app, watchOS app, shared package
  PadelScoreKit/              Swift package, shared by both apps (no UI)
    Sources/PadelScoreKit/      Team, MatchSetup, DeuceRule, MatchScore, computeScore,
                                formatSets, MatchStore (save/restore)
    Tests/PadelScoreKitTests/   ports of all existing Jest tests
  PadelScore/                 iPhone app (SwiftUI)
  PadelScoreWatch/            Watch app (SwiftUI + HealthKit workout)
```

### PadelScoreKit (shared scoring engine)

- A **direct port of the TypeScript engine**. A match is `setup` + `points: [Team]`;
  `computeScore(setup, points)` replays the points; undo removes the last point. This is the
  same model that keeps undo and score from ever disagreeing today.
- All 45 existing tests are ported, so both versions are held to the same cases.
- `MatchStore` saves `{ version, setup, points }` as JSON after every change and restores it on
  launch. Missing or unreadable data → setup screen.

### Watch app

- **Setup screen:** who serves first (Us / Them), rule at 40–40 (Advantage / Golden / Star)
  with an ⓘ explaining each, **Start**. Team names default to "Us" and "Them"; typing on a watch
  is awkward, so names can be changed but aren't required.
- **Match screen:**
  - Top half = Us, bottom half = Them, in teal and lilac. Tap a half to give that team the point.
  - Large game score (`15`, `40`, `AD`, tiebreak numbers), small games/sets line, serve dot.
  - "Golden point" / "Star point" label when the next point decides the game.
  - **Haptic tap** on every point so you know it registered without looking.
  - **Undo** button. Scrolling the Digital Crown is not used, so it can't trigger by accident.
- **Match over:** winner, final score (e.g. `7–6(5) 6–4`), **New match**, **Undo last point**.
- **Workout:** starting a match starts an `HKWorkoutSession`. Padel has no HealthKit activity
  type of its own, as far as I know, so v1 records it as **tennis**, the closest match (to
  verify; `other` is the fallback). The session ends when the match ends or a new match starts.
  The first match asks for Health permission; if the user declines, scoring still works but the
  watch may return to the clock face between points.
- The in-progress match survives the app being closed or the watch restarting.

### iPhone app

- The same three screens as the current Expo app (setup with team names, server and deuce rule
  with ⓘ; match screen with two tap halves; match-over overlay), rebuilt in SwiftUI on top of
  PadelScoreKit. The screen stays awake during a match.
- It hosts the watch app for installation. The App Store requires a watch app to come with an
  iPhone app.

## App Store

- Bundle IDs, e.g. `com.<you>.padelscore` and `com.<you>.padelscore.watchkitapp`.
- **Name:** "Padel Score" may be taken; check in App Store Connect and pick a variation if so.
- Icon (reuse the teal/lilac/ball design), iPhone and Watch screenshots, description.
- **Privacy policy URL** (required): a one-page site saying no data is collected; workouts are
  saved to the user's own Apple Health and never leave the device.
- Privacy questionnaire: **Data Not Collected**. Health usage descriptions in the app explain the
  workout.
- Release path: TestFlight on the user's own iPhone/Watch first → real matches → submit for
  review.

## Testing

- **Engine:** the ported unit tests (Swift Testing/XCTest). They run with `swift test` on the
  Mac; Claude will try to install a Swift toolchain in its Linux environment to run them there
  too.
- **Apps:** run by hand in the iPhone and Watch simulators, then on the real watch through
  TestFlight during a match.

## Build order

1. PadelScoreKit + ported tests.
2. Watch app (the main device).
3. iPhone app.
4. XcodeGen project, signing, a build on the user's Mac, then TestFlight.
5. App Store listing, privacy page, submission.

Each step is shown to the user and committed only after approval.

## Not in v1

Phone ↔ watch live sync, match history, stats, Mac/iPad apps, Android, a match tie-break to 10
for the third set, "change ends" prompts, complications/widgets.

## Open questions

- HealthKit activity type for padel: tennis vs other (to verify against Apple's current list).
- Minimum iOS/watchOS versions, depending on the user's Xcode version and watch model.

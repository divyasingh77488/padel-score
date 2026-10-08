# Padel Score — v1 Design

Date: 2026-10-08

## Goal

A simple scorekeeper for a padel match, used on an iPhone during play. Players tap to award
each point; the app handles padel scoring rules, serve rotation and undo. iOS first; Android
later from the same codebase. Apple Watch may come later.

**Success:** during a real match, one tap per point keeps an accurate score through deuces,
sets and tiebreaks, mis-taps are fixable with undo, and closing the app never loses the match.

## Platform

- Expo (React Native) + TypeScript, latest Expo SDK.
- Run on iPhone through Expo Go during development. A standalone install (EAS Build +
  TestFlight, requires the $99/yr Apple Developer Program) is out of scope for v1.
- Xcode is not required.

## Scoring rules

- Game points: 0, 15, 30, 40, game. At 40–40 (deuce) play **advantage**: a team must win two
  consecutive points from deuce. Displayed as `40–40`, `AD–40`, `40–AD`.
- Set: first to 6 games with a 2-game lead (6–0 … 6–4, 7–5). At 6–6 a **tiebreak** is played.
- Tiebreak: first to 7 points with a 2-point lead (e.g. 7–5, 10–8). Winner takes the set 7–6.
  Points displayed as plain numbers.
- Match: **best of 3 sets**; the first team to win 2 sets wins. No further points are accepted.
- Serve (tracked per team, not per player):
  - The first server is chosen at setup (default Team A).
  - The serving team alternates every game.
  - In a tiebreak, the team due to serve serves point 1, then the teams alternate every 2
    points (B serves points 2–3, A serves 4–5, …).
  - The game after a tiebreak (first game of the next set) is served by the team that
    received first in the tiebreak.

## Scope

**In v1**

- Setup screen: two team names (defaults "Team A", "Team B"), first server, Start match.
- Match screen:
  - Two large tap zones, one per team. A tap awards that team the point.
  - Shows current game points (or tiebreak points), games in the current set, completed set
    scores, and a serve indicator.
  - Undo button: removes the last point. It can be repeated back to the start of the match.
  - Screen stays awake while the match screen is shown.
- Match-over overlay: winner, final score (e.g. `6–4 3–6 7–6(5)`), New match, Undo last point.
  The tiebreak score in brackets is the loser's tiebreak points.
- Auto-save after every change; relaunching restores the match in progress.

**Not in v1:** match history, stats, golden point, other formats, Apple Watch, sounds, voice
input, standalone App Store/TestFlight build.

## Architecture

```
src/
  scoring/      pure TypeScript scoring engine (no React)
  state/        useMatch hook: state + persistence
  screens/      SetupScreen, MatchScreen, MatchOverOverlay
App.tsx         chooses screen from state
```

### Scoring engine (`src/scoring/`)

- Types: `Team = 'A' | 'B'`; `MatchSetup = { teamNames: { A: string; B: string }; firstServer: Team }`.
- A match is represented as `setup` + `points: Team[]` (winner of each point, in order).
- `computeScore(setup, points): MatchScore` replays the points and returns:
  - `completedSets: { A: number; B: number; tiebreak?: { A: number; B: number } }[]`
  - `currentSet: { A: number; B: number }` (games)
  - `currentGame`: either `{ kind: 'regular', display: { A: string; B: string } }` or
    `{ kind: 'tiebreak', A: number, B: number }`
  - `server: Team`
  - `setsWon: { A: number; B: number }`
  - `winner: Team | null`
- Points after the match is won are ignored by `computeScore`.
- Undo = drop the last element of `points`, so score and undo can never diverge.

### State (`src/state/useMatch.ts`)

- Holds `setup | null` and `points`. Exposes `score`, `addPoint(team)`, `undo()`,
  `startMatch(setup)`, `newMatch()`.
- `addPoint` is a no-op when the match has a winner.
- Persists `{ version: 1, setup, points }` to AsyncStorage after each change. Loads it on
  launch; missing, unreadable or invalid data → start at the setup screen.

### Screens

- `App.tsx` shows a loading view until storage has been read. After that it shows
  `SetupScreen` when there is no setup, otherwise `MatchScreen`.
- `MatchScreen` renders `score` only; no scoring logic in UI. It uses `expo-keep-awake`.
  When `score.winner` is set, it shows `MatchOverOverlay`.

## Testing

- Jest unit tests for the scoring engine, written test-first:
  - normal games
  - deuce/advantage swings
  - set endings 6–4 and 7–5
  - 6–6 → tiebreak
  - tiebreaks 7–5 and 10–8
  - serve rotation in games and tiebreaks, and after a tiebreak
  - match ends at 2 sets
  - points after the end are ignored
  - undo across game and set boundaries
- Unit tests for persistence parsing (valid, missing, corrupt data).
- UI checked by hand in Expo Go on iPhone.

## Repository

- github.com/divyasingh77488/padel-score (private). Work happens on a feature branch and is
  merged to `main` via PR.

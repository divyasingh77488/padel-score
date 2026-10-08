# padel-score

Simple padel match scorekeeper for iOS (Expo / React Native, so Android works from the same code).

Design: [docs/superpowers/specs/2026-10-08-padel-score-design.md](docs/superpowers/specs/2026-10-08-padel-score-design.md)

## Run it on your iPhone

1. Install **Expo Go** from the App Store.
2. On your computer (same Wi-Fi as the phone):
   ```bash
   npm install
   npm start
   ```
3. Scan the QR code with the iPhone Camera app. It opens in Expo Go.

The match is saved on the phone after every point, so closing the app or locking the phone
doesn't lose it.

## Using it

- Tap anywhere on a team's half to give that team the point.
- The yellow ball shows who is serving.
- The middle bar shows games per set (yellow = current set) and has **Undo** (one point at a
  time, back to the start) and **New** (asks before discarding the match).

Rules: advantage at deuce, best of 3 sets, sets to 6 with a 2-game lead, tiebreak at 6–6 to 7
(win by 2).

## Development

```bash
npm test           # scoring engine + storage unit tests
npm run typecheck
npm run web        # quick check in a browser
```

Code layout:

- `src/scoring/` – pure TypeScript scoring engine. A match is the list of point winners;
  `computeScore` replays it, so undo is just dropping the last point.
- `src/state/` – `useMatch` hook and AsyncStorage persistence.
- `src/screens/` – setup screen, match screen, match-over overlay.

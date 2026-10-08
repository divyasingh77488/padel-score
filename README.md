# padel-score

Simple padel match scorekeeper for iOS (Expo / React Native, so Android works from the same code).

Design: [docs/superpowers/specs/2026-10-08-padel-score-design.md](docs/superpowers/specs/2026-10-08-padel-score-design.md)

<p>
  <img src="docs/screenshots/setup.png" width="200" alt="Setup screen">
  <img src="docs/screenshots/match.png" width="200" alt="Match screen">
  <img src="docs/screenshots/tiebreak.png" width="200" alt="Tiebreak">
  <img src="docs/screenshots/match-over.png" width="200" alt="Match over">
</p>

## Install on your iPhone

You need a Mac (or any computer) with [Node.js](https://nodejs.org) installed, and an iPhone on
the **same Wi-Fi network**.

1. On the iPhone, install **Expo Go** from the App Store.
2. On the computer, get the code and start the app server:
   ```bash
   git clone https://github.com/divyasingh77488/padel-score.git
   cd padel-score
   npm install
   npm start
   ```
   A QR code appears in the terminal.
3. On the iPhone, open the **Camera** app, point it at the QR code and tap the banner. The app
   opens in Expo Go.

Next time, just run `npm start` in the `padel-score` folder and scan the QR code again. Expo Go
also lists the app under **Recently opened**.

> **Before you go to the court:** Expo Go loads the app from your computer. Open the app at home,
> then keep it open. Locking the phone or switching to another app is fine. If the app gets
> fully closed (swiped away) while you're away from the computer, Expo Go can't load it again
> until you're back on the same Wi-Fi as a computer running `npm start`. Your match isn't
> lost: it's saved on the phone and comes back when the app reopens.
>
> If the phone can't reach the computer (for example on office or hotel Wi-Fi), use
> `npx expo start --tunnel` instead of `npm start`.

## How to use it

### 1. Set up the match

- **Team names:** type a name for each team, or leave them blank to use "Team A" and "Team B".
- **Serves first:** tap the team that serves the first game.
- Tap **Start match**.

### 2. Score each point

The screen is split in two: the top half (blue) is the first team and the bottom half (red) is
the second team.

- **After each rally, tap anywhere on the half of the team that won the point.** The whole half
  is a button, so you don't need to aim.
- The big number is the score in the current game: `0`, `15`, `30`, `40`. At 40–40 (deuce) the
  team that wins the next point shows `AD`; if they lose the next point it goes back to `40–40`.
- The **yellow ball** next to a team's name shows which team is serving. It moves automatically.
- The bar in the middle shows the **games** for each team:
  - the yellow number is the set being played now;
  - earlier sets are shown to its left (the set winner's number is brighter);
  - after a tiebreak, the small number next to the set score is that team's tiebreak points.

The screen stays on while the match screen is open, so it doesn't lock between points.

### 3. Fix a mistake

- Tap **Undo** to remove the last point. Tap it again to keep going back, one point at a time,
  all the way to the start of the match. Undo works across games and sets too.

### 4. Tiebreak

At 6–6 in a set the app switches to a tiebreak automatically ("Tiebreak" appears under the
score). Points are counted 1, 2, 3… and the first team to 7 with a 2-point lead wins the set
7–6. The serve indicator follows tiebreak serving: one point for the first server, then two
points each.

### 5. End of the match

When a team wins two sets the match is over and a summary shows:

- the winner and the final score, for example `7–6(2)  6–0` (written from the winner's side;
  the number in brackets is the loser's tiebreak points);
- **New match:** go back to the setup screen;
- **Undo last point:** if the last point was a mis-tap, reopens the match.

To abandon a match before it ends, tap **New** in the middle bar. The app asks before it
discards the match.

### If the app closes

Every point is saved on the phone. If the app is closed or the phone restarts, the match comes
back exactly where you left it when you open the app again.

## Scoring rules

- Games: 0, 15, 30, 40, game. Advantage at deuce (no golden point).
- Sets: first to 6 games with a 2-game lead (6–4, 7–5). Tiebreak at 6–6.
- Tiebreak: first to 7 points with a 2-point lead (7–5, 10–8).
- Match: best of 3 sets.
- Serve changes every game. In a tiebreak the first server serves 1 point, then teams alternate
  every 2 points. The team that received first in the tiebreak serves first in the next set.

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

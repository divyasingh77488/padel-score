import { CompletedSet, CurrentGame, MatchScore, MatchSetup, PerTeam, Team, other } from './types';

const SETS_TO_WIN = 2;
const GAMES_PER_SET = 6;
const TIEBREAK_POINTS = 7;
const GAME_LABELS = ['0', '15', '30', '40'];

const zero = (): PerTeam<number> => ({ A: 0, B: 0 });

/** Display for a regular (non-tiebreak) game from raw point counts. */
function regularDisplay(p: PerTeam<number>): PerTeam<string> {
  if (p.A >= 3 && p.B >= 3) {
    if (p.A === p.B) return { A: '40', B: '40' };
    return p.A > p.B ? { A: 'AD', B: '40' } : { A: '40', B: 'AD' };
  }
  return { A: GAME_LABELS[p.A], B: GAME_LABELS[p.B] };
}

/** Whether `p` is a won game/tiebreak for `team`: at least `target` points and a 2-point lead. */
function hasWon(p: PerTeam<number>, team: Team, target: number): boolean {
  return p[team] >= target && p[team] - p[other(team)] >= 2;
}

/**
 * Tiebreak server for the point about to be played, given how many tiebreak points
 * have been played. The first server serves 1 point, then teams alternate every 2.
 */
function tiebreakServer(firstServer: Team, played: number): Team {
  if (played === 0) return firstServer;
  return Math.floor((played - 1) / 2) % 2 === 0 ? other(firstServer) : firstServer;
}

/**
 * Replays the points of a match and returns everything the screen shows.
 * Points after the match has been won are ignored.
 */
export function computeScore(setup: MatchSetup, points: readonly Team[]): MatchScore {
  const completedSets: CompletedSet[] = [];
  const setsWon = zero();
  let games = zero();
  let gamePoints = zero();
  let inTiebreak = false;
  /** Server of the current regular game, or the first server of the current tiebreak. */
  let gameServer: Team = setup.firstServer;
  let winner: Team | null = null;

  const winSet = (team: Team, tiebreak?: PerTeam<number>) => {
    completedSets.push(tiebreak ? { ...games, tiebreak } : { ...games });
    setsWon[team] += 1;
    games = zero();
    if (setsWon[team] >= SETS_TO_WIN) winner = team;
  };

  for (const team of points) {
    if (winner) break;
    gamePoints[team] += 1;

    if (inTiebreak) {
      if (hasWon(gamePoints, team, TIEBREAK_POINTS)) {
        games[team] += 1;
        winSet(team, gamePoints);
        gamePoints = zero();
        inTiebreak = false;
        // The team that received first in the tiebreak serves the next set.
        gameServer = other(gameServer);
      }
      continue;
    }

    if (hasWon(gamePoints, team, 4)) {
      games[team] += 1;
      gamePoints = zero();
      gameServer = other(gameServer);
      if (hasWon(games, team, GAMES_PER_SET)) {
        winSet(team);
      } else if (games.A === GAMES_PER_SET && games.B === GAMES_PER_SET) {
        inTiebreak = true;
      }
    }
  }

  const currentGame: CurrentGame = inTiebreak
    ? { kind: 'tiebreak', A: gamePoints.A, B: gamePoints.B }
    : { kind: 'regular', display: regularDisplay(gamePoints) };

  const server = inTiebreak
    ? tiebreakServer(gameServer, gamePoints.A + gamePoints.B)
    : gameServer;

  return { completedSets, currentSet: games, currentGame, server, setsWon, winner };
}

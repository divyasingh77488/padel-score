import { computeScore } from './computeScore';
import { MatchSetup, Team } from './types';

const setup: MatchSetup = {
  teamNames: { A: 'Team A', B: 'Team B' },
  firstServer: 'A',
  deuceRule: 'advantage',
};

const rep = (team: Team, n: number): Team[] => Array(n).fill(team);
/** Points for one game won to love by `team`. */
const game = (team: Team) => rep(team, 4);
/** Points for `n` games won to love by `team`. */
const games = (team: Team, n: number): Team[] => Array.from({ length: n }, () => game(team)).flat();
/** A 6–0 set for `team`. */
const set = (team: Team) => games(team, 6);
/** Alternate games until 6–6 (A, B, A, B, ...). */
const toSixAll = (): Team[] =>
  Array.from({ length: 12 }, (_, i) => game(i % 2 === 0 ? 'A' : 'B')).flat();

describe('regular games', () => {
  it('starts at 0–0 with nothing played', () => {
    const s = computeScore(setup, []);
    expect(s.currentGame).toEqual({ kind: 'regular', display: { A: '0', B: '0' } });
    expect(s.currentSet).toEqual({ A: 0, B: 0 });
    expect(s.completedSets).toEqual([]);
    expect(s.setsWon).toEqual({ A: 0, B: 0 });
    expect(s.winner).toBeNull();
  });

  it('counts 15, 30, 40', () => {
    expect(computeScore(setup, ['A']).currentGame).toEqual({
      kind: 'regular',
      display: { A: '15', B: '0' },
    });
    expect(computeScore(setup, ['A', 'B', 'A']).currentGame).toEqual({
      kind: 'regular',
      display: { A: '30', B: '15' },
    });
    expect(computeScore(setup, ['A', 'A', 'A', 'B', 'B']).currentGame).toEqual({
      kind: 'regular',
      display: { A: '40', B: '30' },
    });
  });

  it('awards the game on the fourth point and resets the game score', () => {
    const s = computeScore(setup, game('B'));
    expect(s.currentSet).toEqual({ A: 0, B: 1 });
    expect(s.currentGame).toEqual({ kind: 'regular', display: { A: '0', B: '0' } });
  });

  it('wins from 40–30', () => {
    const s = computeScore(setup, ['A', 'A', 'A', 'B', 'B', 'A']);
    expect(s.currentSet).toEqual({ A: 1, B: 0 });
  });
});

describe('deuce and advantage', () => {
  const deuce: Team[] = ['A', 'A', 'A', 'B', 'B', 'B'];

  it('shows 40–40 at deuce', () => {
    expect(computeScore(setup, deuce).currentGame).toEqual({
      kind: 'regular',
      display: { A: '40', B: '40' },
    });
  });

  it('shows advantage and returns to deuce', () => {
    expect(computeScore(setup, [...deuce, 'A']).currentGame).toEqual({
      kind: 'regular',
      display: { A: 'AD', B: '40' },
    });
    expect(computeScore(setup, [...deuce, 'A', 'B']).currentGame).toEqual({
      kind: 'regular',
      display: { A: '40', B: '40' },
    });
    expect(computeScore(setup, [...deuce, 'A', 'B', 'B']).currentGame).toEqual({
      kind: 'regular',
      display: { A: '40', B: 'AD' },
    });
  });

  it('needs two points in a row from deuce to win', () => {
    const long = [...deuce, 'A', 'B', 'B', 'A', 'A', 'B', 'B', 'B'] as Team[];
    const s = computeScore(setup, long);
    expect(s.currentSet).toEqual({ A: 0, B: 1 });
    expect(s.currentGame).toEqual({ kind: 'regular', display: { A: '0', B: '0' } });
  });
});

describe('sets', () => {
  it('wins a set 6–4', () => {
    const pts = [...games('A', 4), ...games('B', 4), ...games('A', 2)];
    const s = computeScore(setup, pts);
    expect(s.completedSets).toEqual([{ A: 6, B: 4 }]);
    expect(s.currentSet).toEqual({ A: 0, B: 0 });
    expect(s.setsWon).toEqual({ A: 1, B: 0 });
  });

  it('does not end the set at 6–5', () => {
    const pts = [...games('A', 5), ...games('B', 5), ...game('A')];
    const s = computeScore(setup, pts);
    expect(s.completedSets).toEqual([]);
    expect(s.currentSet).toEqual({ A: 6, B: 5 });
    expect(s.currentGame.kind).toBe('regular');
  });

  it('wins a set 7–5', () => {
    const pts = [...games('A', 5), ...games('B', 5), ...games('A', 2)];
    const s = computeScore(setup, pts);
    expect(s.completedSets).toEqual([{ A: 7, B: 5 }]);
    expect(s.setsWon).toEqual({ A: 1, B: 0 });
  });

  it('plays a tiebreak at 6–6', () => {
    const s = computeScore(setup, toSixAll());
    expect(s.currentSet).toEqual({ A: 6, B: 6 });
    expect(s.currentGame).toEqual({ kind: 'tiebreak', A: 0, B: 0 });
  });
});

describe('tiebreaks', () => {
  it('counts tiebreak points as plain numbers', () => {
    const s = computeScore(setup, [...toSixAll(), 'A', 'A', 'B']);
    expect(s.currentGame).toEqual({ kind: 'tiebreak', A: 2, B: 1 });
  });

  it('wins a tiebreak 7–5 and the set 7–6', () => {
    const pts = [...toSixAll(), ...rep('A', 5), ...rep('B', 5), 'A', 'A'] as Team[];
    const s = computeScore(setup, pts);
    expect(s.completedSets).toEqual([{ A: 7, B: 6, tiebreak: { A: 7, B: 5 } }]);
    expect(s.currentSet).toEqual({ A: 0, B: 0 });
    expect(s.currentGame).toEqual({ kind: 'regular', display: { A: '0', B: '0' } });
    expect(s.setsWon).toEqual({ A: 1, B: 0 });
  });

  it('does not end a tiebreak at 7–6', () => {
    const pts = [...toSixAll(), ...rep('A', 6), ...rep('B', 6), 'A'] as Team[];
    const s = computeScore(setup, pts);
    expect(s.currentGame).toEqual({ kind: 'tiebreak', A: 7, B: 6 });
    expect(s.completedSets).toEqual([]);
  });

  it('wins a tiebreak 10–8', () => {
    const tb: Team[] = [...rep('A', 6), ...rep('B', 6), 'A', 'B', 'A', 'B', 'B', 'B'];
    const s = computeScore(setup, [...toSixAll(), ...tb]);
    expect(s.completedSets).toEqual([{ A: 6, B: 7, tiebreak: { A: 8, B: 10 } }]);
    expect(s.setsWon).toEqual({ A: 0, B: 1 });
  });
});

describe('serve', () => {
  it('starts with the chosen first server', () => {
    expect(computeScore(setup, []).server).toBe('A');
    expect(computeScore({ ...setup, firstServer: 'B' }, []).server).toBe('B');
  });

  it('stays with the server during a game', () => {
    expect(computeScore(setup, ['B', 'B', 'A']).server).toBe('A');
  });

  it('alternates every game', () => {
    expect(computeScore(setup, games('A', 1)).server).toBe('B');
    expect(computeScore(setup, games('A', 2)).server).toBe('A');
    expect(computeScore(setup, games('B', 3)).server).toBe('B');
  });

  it('keeps alternating across sets', () => {
    // A 6–0 set is 6 games, so A serves game 7 (first game of set 2).
    expect(computeScore(setup, set('A')).server).toBe('A');
    // 6–4 is 10 games; A serves game 11.
    const pts = [...games('A', 4), ...games('B', 4), ...games('A', 2)];
    expect(computeScore(setup, pts).server).toBe('A');
    // 7–5 is 12 games; A serves game 13.
    const pts75 = [...games('A', 5), ...games('B', 5), ...games('A', 2)];
    expect(computeScore(setup, pts75).server).toBe('A');
  });

  it('rotates 1 then every 2 points in a tiebreak', () => {
    // 12 games played, so A (first server) is due to serve the tiebreak.
    const base = toSixAll();
    const serverAfter = (n: number) =>
      computeScore(setup, [...base, ...rep('A', Math.min(n, 3)), ...rep('B', Math.max(0, n - 3))])
        .server;
    expect([0, 1, 2, 3, 4, 5, 6, 7, 8].map(serverAfter)).toEqual([
      'A', // point 1
      'B', // points 2–3
      'B',
      'A', // points 4–5
      'A',
      'B', // points 6–7
      'B',
      'A', // points 8–9
      'A',
    ]);
  });

  it('uses the team due to serve as first tiebreak server', () => {
    const s = computeScore({ ...setup, firstServer: 'B' }, toSixAll());
    expect(s.server).toBe('B');
  });

  it('gives the next set to the team that received first in the tiebreak', () => {
    const pts = [...toSixAll(), ...rep('A', 7)] as Team[];
    expect(computeScore(setup, pts).server).toBe('B');
    expect(computeScore({ ...setup, firstServer: 'B' }, pts).server).toBe('A');
  });
});

describe('match end', () => {
  it('ends when a team wins two sets', () => {
    const s = computeScore(setup, [...set('A'), ...set('A')]);
    expect(s.winner).toBe('A');
    expect(s.setsWon).toEqual({ A: 2, B: 0 });
    expect(s.completedSets).toEqual([
      { A: 6, B: 0 },
      { A: 6, B: 0 },
    ]);
  });

  it('goes to a third set at one set all', () => {
    const s = computeScore(setup, [...set('A'), ...set('B')]);
    expect(s.winner).toBeNull();
    expect(s.setsWon).toEqual({ A: 1, B: 1 });
    const done = computeScore(setup, [...set('A'), ...set('B'), ...set('B')]);
    expect(done.winner).toBe('B');
  });

  it('can be won with a tiebreak in the final set', () => {
    const pts = [...set('A'), ...set('B'), ...toSixAll(), ...rep('B', 7)] as Team[];
    const s = computeScore(setup, pts);
    expect(s.winner).toBe('B');
    expect(s.completedSets[2]).toEqual({ A: 6, B: 7, tiebreak: { A: 0, B: 7 } });
  });

  it('ignores points after the match is over', () => {
    const finished = [...set('A'), ...set('A')];
    expect(computeScore(setup, [...finished, 'B', 'B', 'B'])).toEqual(
      computeScore(setup, finished),
    );
  });
});

describe('undo (dropping the last point)', () => {
  it('goes back across a game boundary', () => {
    const pts = [...game('A'), ...game('B')];
    const s = computeScore(setup, pts.slice(0, -1));
    expect(s.currentSet).toEqual({ A: 1, B: 0 });
    expect(s.currentGame).toEqual({ kind: 'regular', display: { A: '0', B: '40' } });
    expect(s.server).toBe('B');
  });

  it('goes back across a set boundary', () => {
    const s = computeScore(setup, set('A').slice(0, -1));
    expect(s.completedSets).toEqual([]);
    expect(s.currentSet).toEqual({ A: 5, B: 0 });
    expect(s.currentGame).toEqual({ kind: 'regular', display: { A: '40', B: '0' } });
  });

  it('reopens a finished match', () => {
    const s = computeScore(setup, [...set('A'), ...set('A')].slice(0, -1));
    expect(s.winner).toBeNull();
    expect(s.setsWon).toEqual({ A: 1, B: 0 });
  });

  it('goes back into a finished tiebreak', () => {
    const pts = [...toSixAll(), ...rep('A', 7)] as Team[];
    const s = computeScore(setup, pts.slice(0, -1));
    expect(s.currentGame).toEqual({ kind: 'tiebreak', A: 6, B: 0 });
    expect(s.completedSets).toEqual([]);
  });
});

describe('deuce rules', () => {
  const deuce: Team[] = ['A', 'A', 'A', 'B', 'B', 'B'];
  const golden: MatchSetup = { ...setup, deuceRule: 'golden' };
  const star: MatchSetup = { ...setup, deuceRule: 'star' };

  it('advantage never marks a deciding point', () => {
    const long = [...deuce, 'A', 'B', 'B', 'A', 'A', 'B'] as Team[];
    expect(computeScore(setup, long).decidingPoint).toBe(false);
  });

  it('golden point: the point after 40–40 wins the game', () => {
    expect(computeScore(golden, ['A', 'A', 'B']).decidingPoint).toBe(false);
    const atDeuce = computeScore(golden, deuce);
    expect(atDeuce.currentGame).toEqual({ kind: 'regular', display: { A: '40', B: '40' } });
    expect(atDeuce.decidingPoint).toBe(true);
    const s = computeScore(golden, [...deuce, 'B']);
    expect(s.currentSet).toEqual({ A: 0, B: 1 });
    expect(s.decidingPoint).toBe(false);
    expect(s.server).toBe('B');
  });

  it('golden point: a normal win from 40–30 still counts', () => {
    expect(computeScore(golden, ['A', 'A', 'A', 'B', 'B', 'A']).currentSet).toEqual({ A: 1, B: 0 });
  });

  it('star point: advantage at the first two deuces, deciding point at the third', () => {
    // First deuce: advantage.
    expect(computeScore(star, deuce).decidingPoint).toBe(false);
    expect(computeScore(star, [...deuce, 'A']).currentGame).toEqual({
      kind: 'regular',
      display: { A: 'AD', B: '40' },
    });
    // Second deuce: still advantage.
    const second = [...deuce, 'A', 'B'] as Team[];
    expect(computeScore(star, second).decidingPoint).toBe(false);
    expect(computeScore(star, [...second, 'B']).currentGame).toEqual({
      kind: 'regular',
      display: { A: '40', B: 'AD' },
    });
    // Third deuce: the next point decides.
    const third = [...second, 'B', 'A'] as Team[];
    const s = computeScore(star, third);
    expect(s.currentGame).toEqual({ kind: 'regular', display: { A: '40', B: '40' } });
    expect(s.decidingPoint).toBe(true);
    expect(computeScore(star, [...third, 'A']).currentSet).toEqual({ A: 1, B: 0 });
  });

  it('star point: winning from advantage ends the game as usual', () => {
    expect(computeScore(star, [...deuce, 'B', 'B']).currentSet).toEqual({ A: 0, B: 1 });
  });

  it('star point: the deuce count resets every game', () => {
    const starGame = [...deuce, 'A', 'B', 'B', 'A', 'A'] as Team[]; // A wins at the third deuce
    const s = computeScore(star, [...starGame, ...deuce]);
    expect(s.currentSet).toEqual({ A: 1, B: 0 });
    expect(s.decidingPoint).toBe(false);
  });

  it('does not apply to tiebreaks', () => {
    const tb = [...toSixAll(), ...rep('A', 6), ...rep('B', 6)] as Team[];
    const s = computeScore(golden, tb);
    expect(s.currentGame).toEqual({ kind: 'tiebreak', A: 6, B: 6 });
    expect(s.decidingPoint).toBe(false);
    expect(computeScore(golden, [...tb, 'A']).completedSets).toEqual([]);
  });
});

export type Team = 'A' | 'B';

/**
 * How a game is decided from 40–40:
 * - advantage: a team must win two points in a row.
 * - golden: the next point wins the game.
 * - star: advantage is played at the first two deuces; at the third deuce the next point wins.
 */
export type DeuceRule = 'advantage' | 'golden' | 'star';

export const DEUCE_RULES: readonly DeuceRule[] = ['advantage', 'golden', 'star'];

export type MatchSetup = {
  teamNames: { A: string; B: string };
  firstServer: Team;
  deuceRule: DeuceRule;
};

export type PerTeam<T> = { A: T; B: T };

export type CompletedSet = PerTeam<number> & {
  /** Tiebreak points, present only when the set was decided by a tiebreak. */
  tiebreak?: PerTeam<number>;
};

export type CurrentGame =
  | { kind: 'regular'; display: PerTeam<string> }
  | { kind: 'tiebreak'; A: number; B: number };

export type MatchScore = {
  completedSets: CompletedSet[];
  /** Games in the set being played. */
  currentSet: PerTeam<number>;
  currentGame: CurrentGame;
  server: Team;
  /** True when the next point decides the game (golden or star point at 40–40). */
  decidingPoint: boolean;
  setsWon: PerTeam<number>;
  winner: Team | null;
};

export const other = (team: Team): Team => (team === 'A' ? 'B' : 'A');

export type Team = 'A' | 'B';

export type MatchSetup = {
  teamNames: { A: string; B: string };
  firstServer: Team;
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
  setsWon: PerTeam<number>;
  winner: Team | null;
};

export const other = (team: Team): Team => (team === 'A' ? 'B' : 'A');

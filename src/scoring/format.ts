import { CompletedSet, Team, other } from './types';

/**
 * Formats completed sets from `team`'s point of view, e.g. `6–4  3–6  7–6(5)`.
 * The bracketed number is the tiebreak loser's points.
 */
export function formatSets(sets: readonly CompletedSet[], team: Team): string {
  return sets
    .map((set) => {
      const base = `${set[team]}–${set[other(team)]}`;
      if (!set.tiebreak) return base;
      return `${base}(${Math.min(set.tiebreak.A, set.tiebreak.B)})`;
    })
    .join('  ');
}

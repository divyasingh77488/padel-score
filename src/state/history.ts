import { MatchSetup, Team, computeScore } from '../scoring';
import { parseMatchFields } from './storage';

export const HISTORY_KEY = 'padel-score/history';
export const MAX_HISTORY = 200;

/** A finished match. The score is recomputed from the points, like the match in progress. */
export type HistoryEntry = {
  id: string;
  /** ISO timestamp of when the match was put into history. */
  finishedAt: string;
  setup: MatchSetup;
  points: Team[];
};

/** Adds the match to the front of the history if it has a winner; otherwise returns it as is. */
export function recordFinished(
  history: HistoryEntry[],
  setup: MatchSetup,
  points: Team[],
  now: Date,
): HistoryEntry[] {
  if (!computeScore(setup, points).winner) return history;
  const finishedAt = now.toISOString();
  return [{ id: finishedAt, finishedAt, setup, points }, ...history].slice(0, MAX_HISTORY);
}

export function serializeHistory(history: HistoryEntry[]): string {
  return JSON.stringify({ version: 1, matches: history });
}

/** Parses stored history. Missing or unreadable data gives an empty list; bad entries are dropped. */
export function parseHistory(raw: string | null): HistoryEntry[] {
  if (!raw) return [];
  let data: unknown;
  try {
    data = JSON.parse(raw);
  } catch {
    return [];
  }
  const d = data as { version?: unknown; matches?: unknown } | null;
  if (!d || d.version !== 1 || !Array.isArray(d.matches)) return [];
  return d.matches.flatMap((m: unknown) => {
    if (typeof m !== 'object' || m === null) return [];
    const { id, finishedAt } = m as Record<string, unknown>;
    if (typeof id !== 'string' || typeof finishedAt !== 'string') return [];
    const match = parseMatchFields(m);
    return match ? [{ id, finishedAt, ...match }] : [];
  });
}

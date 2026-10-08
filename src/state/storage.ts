import { MatchSetup, Team } from '../scoring';

export const STORAGE_KEY = 'padel-score/match';

export type SavedMatch = { setup: MatchSetup; points: Team[] };

const isTeam = (v: unknown): v is Team => v === 'A' || v === 'B';

function isSetup(v: unknown): v is MatchSetup {
  if (typeof v !== 'object' || v === null) return false;
  const s = v as Record<string, unknown>;
  const names = s.teamNames as Record<string, unknown> | null | undefined;
  return (
    typeof names === 'object' &&
    names !== null &&
    typeof names.A === 'string' &&
    typeof names.B === 'string' &&
    isTeam(s.firstServer)
  );
}

/** Serialises a match for storage. */
export function serializeMatch(match: SavedMatch): string {
  return JSON.stringify({ version: 1, setup: match.setup, points: match.points });
}

/** Parses stored data. Returns null when it is missing, unreadable or invalid. */
export function parseSavedMatch(raw: string | null): SavedMatch | null {
  if (!raw) return null;
  let data: unknown;
  try {
    data = JSON.parse(raw);
  } catch {
    return null;
  }
  if (typeof data !== 'object' || data === null) return null;
  const d = data as Record<string, unknown>;
  if (d.version !== 1 || !isSetup(d.setup)) return null;
  if (!Array.isArray(d.points) || !d.points.every(isTeam)) return null;
  const { teamNames, firstServer } = d.setup;
  return {
    setup: { teamNames: { A: teamNames.A, B: teamNames.B }, firstServer },
    points: d.points,
  };
}

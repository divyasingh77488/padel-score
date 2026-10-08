import { parseSavedMatch, serializeMatch } from './storage';

const match = {
  setup: {
    teamNames: { A: 'Us', B: 'Them' },
    firstServer: 'B' as const,
    deuceRule: 'star' as const,
  },
  points: ['A', 'B', 'A'] as ('A' | 'B')[],
};

describe('parseSavedMatch', () => {
  it('round-trips a saved match', () => {
    expect(parseSavedMatch(serializeMatch(match))).toEqual(match);
  });

  it('treats matches saved without a deuce rule as advantage', () => {
    const { deuceRule, ...oldSetup } = match.setup;
    const raw = JSON.stringify({ version: 1, setup: oldSetup, points: match.points });
    expect(parseSavedMatch(raw)?.setup.deuceRule).toBe('advantage');
  });

  it('returns null for missing data', () => {
    expect(parseSavedMatch(null)).toBeNull();
    expect(parseSavedMatch('')).toBeNull();
  });

  it('returns null for corrupt JSON', () => {
    expect(parseSavedMatch('{not json')).toBeNull();
    expect(parseSavedMatch('null')).toBeNull();
    expect(parseSavedMatch('42')).toBeNull();
  });

  it('returns null for an unknown version', () => {
    expect(parseSavedMatch(JSON.stringify({ ...match, version: 2 }))).toBeNull();
  });

  it('returns null for an invalid setup or points', () => {
    const v = { version: 1, ...match };
    expect(parseSavedMatch(JSON.stringify({ ...v, setup: null }))).toBeNull();
    expect(
      parseSavedMatch(JSON.stringify({ ...v, setup: { ...match.setup, firstServer: 'C' } })),
    ).toBeNull();
    expect(
      parseSavedMatch(JSON.stringify({ ...v, setup: { ...match.setup, teamNames: { A: 'x' } } })),
    ).toBeNull();
    expect(
      parseSavedMatch(JSON.stringify({ ...v, setup: { ...match.setup, deuceRule: 'silver' } })),
    ).toBeNull();
    expect(parseSavedMatch(JSON.stringify({ ...v, points: 'AB' }))).toBeNull();
    expect(parseSavedMatch(JSON.stringify({ ...v, points: ['A', 'X'] }))).toBeNull();
  });
});

import { MatchSetup, Team } from '../scoring';
import {
  HistoryEntry,
  MAX_HISTORY,
  parseHistory,
  recordFinished,
  serializeHistory,
} from './history';

const setup: MatchSetup = {
  teamNames: { A: 'Us', B: 'Them' },
  firstServer: 'A',
  deuceRule: 'golden',
};
const set = (team: Team): Team[] => Array(24).fill(team);
const finished = [...set('A'), ...set('A')];
const now = new Date('2026-10-10T18:30:00Z');

describe('recordFinished', () => {
  it('adds a finished match to the front of the history', () => {
    const older: HistoryEntry = {
      id: 'old',
      finishedAt: '2026-10-01T10:00:00.000Z',
      setup,
      points: finished,
    };
    const history = recordFinished([older], setup, finished, now);
    expect(history).toHaveLength(2);
    expect(history[0]).toEqual({
      id: now.toISOString(),
      finishedAt: now.toISOString(),
      setup,
      points: finished,
    });
    expect(history[1]).toBe(older);
  });

  it('ignores an unfinished match', () => {
    const history: HistoryEntry[] = [];
    expect(recordFinished(history, setup, finished.slice(0, -1), now)).toBe(history);
    expect(recordFinished(history, setup, [], now)).toBe(history);
  });

  it(`keeps at most ${MAX_HISTORY} matches`, () => {
    const full = Array.from({ length: MAX_HISTORY }, (_, i) => ({
      id: String(i),
      finishedAt: now.toISOString(),
      setup,
      points: finished,
    }));
    const history = recordFinished(full, setup, finished, now);
    expect(history).toHaveLength(MAX_HISTORY);
    expect(history[0].id).toBe(now.toISOString());
    expect(history[MAX_HISTORY - 1].id).toBe(String(MAX_HISTORY - 2));
  });
});

describe('parseHistory', () => {
  const entry: HistoryEntry = {
    id: 'a',
    finishedAt: now.toISOString(),
    setup,
    points: finished,
  };

  it('round-trips', () => {
    expect(parseHistory(serializeHistory([entry]))).toEqual([entry]);
  });

  it('returns an empty list for missing or corrupt data', () => {
    expect(parseHistory(null)).toEqual([]);
    expect(parseHistory('{nope')).toEqual([]);
    expect(parseHistory(JSON.stringify({ version: 2, matches: [entry] }))).toEqual([]);
  });

  it('drops invalid entries and keeps the rest', () => {
    const raw = JSON.stringify({
      version: 1,
      matches: [entry, { ...entry, points: ['X'] }, { ...entry, id: 5 }, null],
    });
    expect(parseHistory(raw)).toEqual([entry]);
  });
});

import { formatSets } from './format';

describe('formatSets', () => {
  const sets = [
    { A: 6, B: 4 },
    { A: 3, B: 6 },
    { A: 7, B: 6, tiebreak: { A: 7, B: 5 } },
  ];

  it("formats from a team's point of view with the loser's tiebreak points", () => {
    expect(formatSets(sets, 'A')).toBe('6–4  3–6  7–6(5)');
    expect(formatSets(sets, 'B')).toBe('4–6  6–3  6–7(5)');
  });

  it('is empty when no sets are complete', () => {
    expect(formatSets([], 'A')).toBe('');
  });
});

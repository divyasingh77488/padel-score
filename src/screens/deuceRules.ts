import { DeuceRule } from '../scoring';

export const DEUCE_RULE_INFO: Record<
  DeuceRule,
  { label: string; short: string; description: string }
> = {
  advantage: {
    label: 'Advantage',
    short: 'Advantage',
    description:
      'At 40–40 a team must win two points in a row. Win one and you have AD; lose the next and it is back to 40–40. Can go on for a long time.',
  },
  golden: {
    label: 'Golden point',
    short: 'Golden',
    description:
      'At 40–40 the next point wins the game. No advantage. Keeps games short; common in club padel.',
  },
  star: {
    label: 'Star point',
    short: 'Star',
    description:
      'Advantage is played the first two times the game reaches 40–40. If it reaches 40–40 a third time, the next point wins the game. The official FIP rule.',
  },
};

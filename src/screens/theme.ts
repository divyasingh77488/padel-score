import { Team } from '../scoring';

export const colors = {
  background: '#0F172A',
  surface: '#1E293B',
  text: '#F8FAFC',
  muted: '#94A3B8',
  accent: '#FACC15',
  team: { A: '#0D9488', B: '#9B7BD4' } as Record<Team, string>,
  teamPressed: { A: '#0F766E', B: '#8262BF' } as Record<Team, string>,
};

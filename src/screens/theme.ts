import { Team } from '../scoring';

export const colors = {
  background: '#0F172A',
  surface: '#1E293B',
  text: '#F8FAFC',
  muted: '#94A3B8',
  accent: '#FACC15',
  team: { A: '#2563EB', B: '#DC2626' } as Record<Team, string>,
  teamPressed: { A: '#1D4ED8', B: '#B91C1C' } as Record<Team, string>,
};

import AsyncStorage from '@react-native-async-storage/async-storage';
import { useCallback, useEffect, useMemo, useState } from 'react';

import { MatchScore, MatchSetup, Team, computeScore } from '../scoring';
import { STORAGE_KEY, parseSavedMatch, serializeMatch } from './storage';

type State = { setup: MatchSetup | null; points: Team[] };

export type UseMatch = {
  /** False until saved data has been read from storage. */
  loaded: boolean;
  setup: MatchSetup | null;
  score: MatchScore | null;
  /** Number of points played; 0 means there is nothing to undo. */
  pointCount: number;
  addPoint: (team: Team) => void;
  undo: () => void;
  startMatch: (setup: MatchSetup) => void;
  newMatch: () => void;
};

export function useMatch(): UseMatch {
  const [loaded, setLoaded] = useState(false);
  const [state, setState] = useState<State>({ setup: null, points: [] });

  useEffect(() => {
    let cancelled = false;
    AsyncStorage.getItem(STORAGE_KEY)
      .catch(() => null)
      .then((raw) => {
        if (cancelled) return;
        const saved = parseSavedMatch(raw);
        if (saved) setState(saved);
        setLoaded(true);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  // Save after every change, once the initial load has finished.
  useEffect(() => {
    if (!loaded) return;
    const write = state.setup
      ? AsyncStorage.setItem(STORAGE_KEY, serializeMatch({ setup: state.setup, points: state.points }))
      : AsyncStorage.removeItem(STORAGE_KEY);
    write.catch(() => {
      // Nothing useful to do; the match continues in memory.
    });
  }, [loaded, state]);

  const score = useMemo(
    () => (state.setup ? computeScore(state.setup, state.points) : null),
    [state],
  );

  const addPoint = useCallback((team: Team) => {
    setState((s) => {
      if (!s.setup || computeScore(s.setup, s.points).winner) return s;
      return { ...s, points: [...s.points, team] };
    });
  }, []);

  const undo = useCallback(() => {
    setState((s) => (s.points.length ? { ...s, points: s.points.slice(0, -1) } : s));
  }, []);

  const startMatch = useCallback((setup: MatchSetup) => setState({ setup, points: [] }), []);
  const newMatch = useCallback(() => setState({ setup: null, points: [] }), []);

  return {
    loaded,
    setup: state.setup,
    score,
    pointCount: state.points.length,
    addPoint,
    undo,
    startMatch,
    newMatch,
  };
}

import AsyncStorage from '@react-native-async-storage/async-storage';
import { useCallback, useEffect, useMemo, useState } from 'react';

import { MatchScore, MatchSetup, Team, computeScore } from '../scoring';
import {
  HISTORY_KEY,
  HistoryEntry,
  parseHistory,
  recordFinished,
  serializeHistory,
} from './history';
import { STORAGE_KEY, parseSavedMatch, serializeMatch } from './storage';

type State = { setup: MatchSetup | null; points: Team[]; history: HistoryEntry[] };

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
  /** Leaves the current match; a finished match is added to the history. */
  newMatch: () => void;
  /** Finished matches, newest first. */
  history: HistoryEntry[];
  deleteHistoryEntry: (id: string) => void;
  clearHistory: () => void;
};

export function useMatch(): UseMatch {
  const [loaded, setLoaded] = useState(false);
  const [state, setState] = useState<State>({ setup: null, points: [], history: [] });

  useEffect(() => {
    let cancelled = false;
    const read = (key: string) => AsyncStorage.getItem(key).catch(() => null);
    Promise.all([read(STORAGE_KEY), read(HISTORY_KEY)]).then(([rawMatch, rawHistory]) => {
      if (cancelled) return;
      const saved = parseSavedMatch(rawMatch);
      setState({
        setup: saved?.setup ?? null,
        points: saved?.points ?? [],
        history: parseHistory(rawHistory),
      });
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
      ? AsyncStorage.setItem(
          STORAGE_KEY,
          serializeMatch({ setup: state.setup, points: state.points }),
        )
      : AsyncStorage.removeItem(STORAGE_KEY);
    write.catch(() => {
      // Nothing useful to do; the match continues in memory.
    });
  }, [loaded, state.setup, state.points]);

  useEffect(() => {
    if (!loaded) return;
    AsyncStorage.setItem(HISTORY_KEY, serializeHistory(state.history)).catch(() => {});
  }, [loaded, state.history]);

  const score = useMemo(
    () => (state.setup ? computeScore(state.setup, state.points) : null),
    [state.setup, state.points],
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

  const startMatch = useCallback(
    (setup: MatchSetup) => setState((s) => ({ ...s, setup, points: [] })),
    [],
  );
  const newMatch = useCallback(
    () =>
      setState((s) => ({
        setup: null,
        points: [],
        history: s.setup ? recordFinished(s.history, s.setup, s.points, new Date()) : s.history,
      })),
    [],
  );
  const deleteHistoryEntry = useCallback(
    (id: string) => setState((s) => ({ ...s, history: s.history.filter((h) => h.id !== id) })),
    [],
  );
  const clearHistory = useCallback(() => setState((s) => ({ ...s, history: [] })), []);

  return {
    loaded,
    setup: state.setup,
    score,
    pointCount: state.points.length,
    addPoint,
    undo,
    startMatch,
    newMatch,
    history: state.history,
    deleteHistoryEntry,
    clearHistory,
  };
}

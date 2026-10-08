import { Pressable, StyleSheet, Text, View } from 'react-native';

import { MatchScore, MatchSetup, formatSets } from '../scoring';
import { colors } from './theme';

type Props = {
  setup: MatchSetup;
  score: MatchScore & { winner: NonNullable<MatchScore['winner']> };
  onNewMatch: () => void;
  onUndo: () => void;
};

export function MatchOverOverlay({ setup, score, onNewMatch, onUndo }: Props) {
  return (
    <View style={styles.backdrop}>
      <View style={styles.card}>
        <Text style={styles.caption}>Winner</Text>
        <Text style={[styles.winner, { color: colors.team[score.winner] }]}>
          {setup.teamNames[score.winner]}
        </Text>
        <Text style={styles.score}>{formatSets(score.completedSets, score.winner)}</Text>
        <Pressable accessibilityRole="button" onPress={onNewMatch} style={styles.primary}>
          <Text style={styles.primaryText}>New match</Text>
        </Pressable>
        <Pressable accessibilityRole="button" onPress={onUndo} style={styles.secondary}>
          <Text style={styles.secondaryText}>Undo last point</Text>
        </Pressable>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  backdrop: {
    ...StyleSheet.absoluteFill,
    backgroundColor: 'rgba(15, 23, 42, 0.92)',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  card: {
    width: '100%',
    maxWidth: 420,
    backgroundColor: colors.surface,
    borderRadius: 20,
    padding: 24,
    alignItems: 'center',
    gap: 12,
  },
  caption: { color: colors.muted, fontSize: 16, fontWeight: '600', textTransform: 'uppercase' },
  winner: { fontSize: 36, fontWeight: '800', textAlign: 'center' },
  score: { color: colors.text, fontSize: 28, fontWeight: '700', marginBottom: 12 },
  primary: {
    alignSelf: 'stretch',
    backgroundColor: colors.accent,
    borderRadius: 14,
    paddingVertical: 16,
    alignItems: 'center',
  },
  primaryText: { color: colors.background, fontSize: 20, fontWeight: '800' },
  secondary: { alignSelf: 'stretch', paddingVertical: 14, alignItems: 'center' },
  secondaryText: { color: colors.text, fontSize: 18, fontWeight: '600' },
});

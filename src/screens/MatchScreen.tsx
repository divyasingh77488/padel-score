import { useKeepAwake } from 'expo-keep-awake';
import { Alert, Platform, Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { MatchScore, MatchSetup, Team } from '../scoring';
import { MatchOverOverlay } from './MatchOverOverlay';
import { DEUCE_RULE_INFO } from './deuceRules';
import { colors } from './theme';

type Props = {
  setup: MatchSetup;
  score: MatchScore;
  canUndo: boolean;
  onPoint: (team: Team) => void;
  onUndo: () => void;
  onNewMatch: () => void;
};

function confirmNewMatch(onConfirm: () => void) {
  const message = 'The current match will be lost.';
  if (Platform.OS === 'web') {
    if (window.confirm(`Start a new match? ${message}`)) onConfirm();
    return;
  }
  Alert.alert('Start a new match?', message, [
    { text: 'Cancel', style: 'cancel' },
    { text: 'New match', style: 'destructive', onPress: onConfirm },
  ]);
}

export function MatchScreen({ setup, score, canUndo, onPoint, onUndo, onNewMatch }: Props) {
  useKeepAwake();
  const { winner } = score;

  const pointsText = (team: Team) =>
    score.currentGame.kind === 'tiebreak'
      ? String(score.currentGame[team])
      : score.currentGame.display[team];

  const half = (team: Team) => (
    <Pressable
      accessibilityRole="button"
      accessibilityLabel={`Point ${setup.teamNames[team]}`}
      disabled={winner !== null}
      onPress={() => onPoint(team)}
      style={({ pressed }) => [
        styles.half,
        { backgroundColor: pressed ? colors.teamPressed[team] : colors.team[team] },
      ]}
    >
      <View style={styles.nameRow}>
        <Text style={styles.teamName} numberOfLines={1}>
          {setup.teamNames[team]}
        </Text>
        {score.server === team && winner === null && (
          <View style={styles.serveBall} accessibilityLabel="Serving" />
        )}
      </View>
      <Text style={styles.points} adjustsFontSizeToFit numberOfLines={1}>
        {pointsText(team)}
      </Text>
      {score.currentGame.kind === 'tiebreak' && <Text style={styles.tiebreak}>Tiebreak</Text>}
      {score.decidingPoint && (
        <Text style={styles.tiebreak}>
          {DEUCE_RULE_INFO[setup.deuceRule].label}: next point wins
        </Text>
      )}
    </Pressable>
  );

  const scoreRow = (team: Team) => (
    <View style={styles.boardRow}>
      <Text style={styles.boardName} numberOfLines={1}>
        {setup.teamNames[team]}
      </Text>
      {score.completedSets.map((set, i) => (
        <Text
          key={i}
          style={[styles.boardCell, set[team] > set[team === 'A' ? 'B' : 'A'] && styles.boardWon]}
        >
          {set[team]}
          {set.tiebreak && <Text style={styles.boardTiebreak}>{set.tiebreak[team]}</Text>}
        </Text>
      ))}
      {winner === null && (
        <Text style={[styles.boardCell, styles.boardCurrent]}>{score.currentSet[team]}</Text>
      )}
    </View>
  );

  return (
    <SafeAreaView style={styles.container}>
      {half('A')}
      <View style={styles.middle}>
        <View style={styles.board}>
          {scoreRow('A')}
          {scoreRow('B')}
        </View>
        <View style={styles.actions}>
          <Pressable
            accessibilityRole="button"
            onPress={onUndo}
            disabled={!canUndo}
            style={[styles.action, !canUndo && { opacity: 0.4 }]}
          >
            <Text style={styles.actionText}>Undo</Text>
          </Pressable>
          <Pressable
            accessibilityRole="button"
            onPress={() => confirmNewMatch(onNewMatch)}
            style={styles.action}
          >
            <Text style={styles.actionText}>New</Text>
          </Pressable>
        </View>
      </View>
      {half('B')}

      {winner !== null && (
        <MatchOverOverlay
          setup={setup}
          score={{ ...score, winner }}
          onNewMatch={onNewMatch}
          onUndo={onUndo}
        />
      )}
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  half: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 16 },
  nameRow: { flexDirection: 'row', alignItems: 'center', gap: 10, maxWidth: '100%' },
  teamName: { color: colors.text, fontSize: 24, fontWeight: '700', flexShrink: 1 },
  serveBall: {
    width: 18,
    height: 18,
    borderRadius: 9,
    backgroundColor: colors.accent,
    borderWidth: 2,
    borderColor: colors.text,
  },
  points: { color: colors.text, fontSize: 120, fontWeight: '800', fontVariant: ['tabular-nums'] },
  tiebreak: { color: colors.text, fontSize: 16, fontWeight: '600', opacity: 0.8 },
  middle: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    paddingHorizontal: 12,
    paddingVertical: 8,
    gap: 12,
  },
  board: { flex: 1, gap: 4 },
  boardRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  boardName: { flex: 1, color: colors.muted, fontSize: 15, fontWeight: '600' },
  boardCell: {
    minWidth: 28,
    textAlign: 'center',
    color: colors.muted,
    fontSize: 20,
    fontWeight: '700',
    fontVariant: ['tabular-nums'],
  },
  boardWon: { color: colors.text },
  boardCurrent: { color: colors.accent },
  boardTiebreak: { fontSize: 11 },
  actions: { flexDirection: 'row', gap: 8 },
  action: {
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderRadius: 10,
    backgroundColor: colors.background,
  },
  actionText: { color: colors.text, fontSize: 16, fontWeight: '700' },
});

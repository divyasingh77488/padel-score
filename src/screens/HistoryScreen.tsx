import { Alert, FlatList, Pressable, StyleSheet, Text, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { computeScore, formatSets, other } from '../scoring';
import { HistoryEntry } from '../state/history';
import { DEUCE_RULE_INFO } from './deuceRules';
import { colors } from './theme';

type Props = {
  history: HistoryEntry[];
  onBack: () => void;
  onDelete: (id: string) => void;
  onClear: () => void;
};

function formatDate(iso: string): string {
  return new Date(iso).toLocaleString(undefined, {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function HistoryRow({ entry, onDelete }: { entry: HistoryEntry; onDelete: (id: string) => void }) {
  const score = computeScore(entry.setup, entry.points);
  const winner = score.winner;
  if (!winner) return null;
  const { teamNames } = entry.setup;

  const confirmDelete = () =>
    Alert.alert('Delete this match?', undefined, [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Delete', style: 'destructive', onPress: () => onDelete(entry.id) },
    ]);

  return (
    <Pressable
      onLongPress={confirmDelete}
      accessibilityHint="Long press to delete"
      style={({ pressed }) => [styles.row, pressed && { opacity: 0.7 }]}
    >
      <Text style={styles.date}>{formatDate(entry.finishedAt)}</Text>
      <Text style={styles.result} numberOfLines={2}>
        <Text style={{ color: colors.team[winner] }}>{teamNames[winner]}</Text>
        <Text style={styles.beat}> beat </Text>
        <Text style={{ color: colors.team[other(winner)] }}>{teamNames[other(winner)]}</Text>
      </Text>
      <View style={styles.rowFooter}>
        <Text style={styles.score}>{formatSets(score.completedSets, winner)}</Text>
        <Text style={styles.rule}>{DEUCE_RULE_INFO[entry.setup.deuceRule].label}</Text>
      </View>
    </Pressable>
  );
}

export function HistoryScreen({ history, onBack, onDelete, onClear }: Props) {
  const confirmClear = () =>
    Alert.alert('Delete all matches?', 'This cannot be undone.', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Delete all', style: 'destructive', onPress: onClear },
    ]);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Pressable accessibilityRole="button" onPress={onBack} hitSlop={12}>
          <Text style={styles.headerButton}>‹ Back</Text>
        </Pressable>
        <Text style={styles.title}>History</Text>
        <Pressable
          accessibilityRole="button"
          onPress={confirmClear}
          disabled={history.length === 0}
          hitSlop={12}
        >
          <Text style={[styles.headerButton, history.length === 0 && { opacity: 0 }]}>Clear</Text>
        </Pressable>
      </View>

      <FlatList
        data={history}
        keyExtractor={(entry) => entry.id}
        renderItem={({ item }) => <HistoryRow entry={item} onDelete={onDelete} />}
        contentContainerStyle={styles.list}
        ListEmptyComponent={
          <Text style={styles.empty}>
            No matches yet. Finished matches appear here when you tap New match.
          </Text>
        }
        ListFooterComponent={
          history.length > 0 ? (
            <Text style={styles.hint}>Long-press a match to delete it.</Text>
          ) : null
        }
      />
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 20,
    paddingVertical: 12,
  },
  headerButton: { color: colors.accent, fontSize: 17, fontWeight: '600' },
  title: { color: colors.text, fontSize: 20, fontWeight: '800' },
  list: { padding: 16, gap: 12 },
  row: { backgroundColor: colors.surface, borderRadius: 14, padding: 16, gap: 6 },
  date: { color: colors.muted, fontSize: 13, fontWeight: '600' },
  result: { fontSize: 18, fontWeight: '700' },
  beat: { color: colors.muted, fontWeight: '500' },
  rowFooter: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'baseline' },
  score: { color: colors.text, fontSize: 18, fontWeight: '700', fontVariant: ['tabular-nums'] },
  rule: { color: colors.muted, fontSize: 13 },
  empty: { color: colors.muted, fontSize: 16, textAlign: 'center', marginTop: 48, lineHeight: 22 },
  hint: { color: colors.muted, fontSize: 13, textAlign: 'center', marginTop: 8 },
});

import { useState } from 'react';
import { Pressable, StyleSheet, Text, TextInput, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { MatchSetup, Team } from '../scoring';
import { colors } from './theme';

type Props = { onStart: (setup: MatchSetup) => void };

const DEFAULT_NAMES = { A: 'Team A', B: 'Team B' };

export function SetupScreen({ onStart }: Props) {
  const [names, setNames] = useState({ A: '', B: '' });
  const [firstServer, setFirstServer] = useState<Team>('A');

  const nameOf = (team: Team) => names[team].trim() || DEFAULT_NAMES[team];

  const start = () =>
    onStart({ teamNames: { A: nameOf('A'), B: nameOf('B') }, firstServer });

  return (
    <SafeAreaView style={styles.container}>
      <Text style={styles.title}>Padel Score</Text>

      {(['A', 'B'] as const).map((team) => (
        <View key={team} style={styles.field}>
          <Text style={styles.label}>{DEFAULT_NAMES[team]}</Text>
          <TextInput
            style={[styles.input, { borderColor: colors.team[team] }]}
            placeholder={DEFAULT_NAMES[team]}
            placeholderTextColor={colors.muted}
            value={names[team]}
            onChangeText={(text) => setNames((n) => ({ ...n, [team]: text }))}
            returnKeyType="done"
            maxLength={24}
          />
        </View>
      ))}

      <Text style={styles.label}>Serves first</Text>
      <View style={styles.serverRow}>
        {(['A', 'B'] as const).map((team) => {
          const selected = firstServer === team;
          return (
            <Pressable
              key={team}
              accessibilityRole="radio"
              accessibilityState={{ selected }}
              onPress={() => setFirstServer(team)}
              style={[
                styles.serverOption,
                selected && { backgroundColor: colors.team[team], borderColor: colors.team[team] },
              ]}
            >
              <Text style={styles.serverText} numberOfLines={1}>
                {nameOf(team)}
              </Text>
            </Pressable>
          );
        })}
      </View>

      <Pressable
        accessibilityRole="button"
        onPress={start}
        style={({ pressed }) => [styles.start, pressed && { opacity: 0.8 }]}
      >
        <Text style={styles.startText}>Start match</Text>
      </Pressable>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.background, padding: 24, gap: 12 },
  title: { color: colors.text, fontSize: 32, fontWeight: '800', marginVertical: 24 },
  field: { gap: 6 },
  label: { color: colors.muted, fontSize: 14, fontWeight: '600', textTransform: 'uppercase' },
  input: {
    color: colors.text,
    backgroundColor: colors.surface,
    borderWidth: 2,
    borderRadius: 12,
    paddingHorizontal: 16,
    paddingVertical: 14,
    fontSize: 20,
  },
  serverRow: { flexDirection: 'row', gap: 12 },
  serverOption: {
    flex: 1,
    alignItems: 'center',
    paddingVertical: 14,
    borderRadius: 12,
    borderWidth: 2,
    borderColor: colors.surface,
    backgroundColor: colors.surface,
  },
  serverText: { color: colors.text, fontSize: 18, fontWeight: '600' },
  start: {
    marginTop: 'auto',
    backgroundColor: colors.accent,
    borderRadius: 16,
    paddingVertical: 20,
    alignItems: 'center',
  },
  startText: { color: colors.background, fontSize: 22, fontWeight: '800' },
});

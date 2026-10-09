import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, TextInput, View } from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';

import { DEUCE_RULES, DeuceRule, MatchSetup, Team } from '../scoring';
import { DEUCE_RULE_INFO } from './deuceRules';
import { colors } from './theme';

type Props = {
  onStart: (setup: MatchSetup) => void;
  historyCount: number;
  onShowHistory: () => void;
};

const DEFAULT_NAMES = { A: 'Team A', B: 'Team B' };

export function SetupScreen({ onStart, historyCount, onShowHistory }: Props) {
  const [names, setNames] = useState({ A: '', B: '' });
  const [firstServer, setFirstServer] = useState<Team>('A');
  const [deuceRule, setDeuceRule] = useState<DeuceRule>('golden');
  const [showRuleInfo, setShowRuleInfo] = useState(false);

  const nameOf = (team: Team) => names[team].trim() || DEFAULT_NAMES[team];

  const start = () =>
    onStart({ teamNames: { A: nameOf('A'), B: nameOf('B') }, firstServer, deuceRule });

  return (
    <SafeAreaView style={styles.container}>
      <ScrollView contentContainerStyle={styles.form} keyboardShouldPersistTaps="handled">
        <View style={styles.titleRow}>
          <Text style={styles.title}>Padel Battle</Text>
          <Pressable accessibilityRole="button" onPress={onShowHistory} hitSlop={12}>
            <Text style={styles.historyLink}>
              History{historyCount > 0 ? ` (${historyCount})` : ''}
            </Text>
          </Pressable>
        </View>

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
                  selected && {
                    backgroundColor: colors.team[team],
                    borderColor: colors.team[team],
                  },
                ]}
              >
                <Text style={styles.serverText} numberOfLines={1}>
                  {nameOf(team)}
                </Text>
              </Pressable>
            );
          })}
        </View>

        <View style={styles.labelRow}>
          <Text style={styles.label}>At 40–40</Text>
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="What do these options mean?"
            accessibilityState={{ expanded: showRuleInfo }}
            hitSlop={12}
            onPress={() => setShowRuleInfo((v) => !v)}
            style={[styles.infoButton, showRuleInfo && styles.infoButtonActive]}
          >
            <Text style={[styles.infoText, showRuleInfo && styles.infoTextActive]}>i</Text>
          </Pressable>
        </View>
        <View style={styles.serverRow}>
          {DEUCE_RULES.map((rule) => {
            const selected = deuceRule === rule;
            return (
              <Pressable
                key={rule}
                accessibilityRole="radio"
                accessibilityState={{ selected }}
                onPress={() => setDeuceRule(rule)}
                style={[styles.serverOption, selected && styles.ruleSelected]}
              >
                <Text
                  style={[styles.ruleText, selected && styles.ruleTextSelected]}
                  numberOfLines={1}
                  adjustsFontSizeToFit
                >
                  {DEUCE_RULE_INFO[rule].short}
                </Text>
              </Pressable>
            );
          })}
        </View>
        {showRuleInfo && (
          <View style={styles.infoPanel}>
            {DEUCE_RULES.map((rule) => (
              <View key={rule} style={styles.infoItem}>
                <Text style={[styles.infoTitle, deuceRule === rule && { color: colors.accent }]}>
                  {DEUCE_RULE_INFO[rule].label}
                </Text>
                <Text style={styles.infoBody}>{DEUCE_RULE_INFO[rule].description}</Text>
              </View>
            ))}
          </View>
        )}
      </ScrollView>

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
  container: { flex: 1, backgroundColor: colors.background, padding: 24 },
  form: { gap: 12, paddingBottom: 24 },
  titleRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginVertical: 24,
  },
  historyLink: { color: colors.accent, fontSize: 17, fontWeight: '600' },
  title: { color: colors.text, fontSize: 32, fontWeight: '800' },
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
  labelRow: { flexDirection: 'row', alignItems: 'center', gap: 8 },
  infoButton: {
    width: 22,
    height: 22,
    borderRadius: 11,
    borderWidth: 1.5,
    borderColor: colors.muted,
    alignItems: 'center',
    justifyContent: 'center',
  },
  infoButtonActive: { backgroundColor: colors.accent, borderColor: colors.accent },
  infoText: { color: colors.muted, fontSize: 13, fontWeight: '800', fontStyle: 'italic' },
  infoTextActive: { color: colors.background },
  ruleSelected: { backgroundColor: colors.text, borderColor: colors.text },
  ruleText: { color: colors.text, fontSize: 16, fontWeight: '600', paddingHorizontal: 6 },
  ruleTextSelected: { color: colors.background },
  infoPanel: { backgroundColor: colors.surface, borderRadius: 12, padding: 16, gap: 12 },
  infoItem: { gap: 2 },
  infoTitle: { color: colors.text, fontSize: 16, fontWeight: '700' },
  infoBody: { color: colors.muted, fontSize: 15, lineHeight: 21 },
  start: {
    backgroundColor: colors.accent,
    borderRadius: 16,
    paddingVertical: 20,
    alignItems: 'center',
  },
  startText: { color: colors.background, fontSize: 22, fontWeight: '800' },
});

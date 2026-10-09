import { StatusBar } from 'expo-status-bar';
import { useState } from 'react';
import { ActivityIndicator, StyleSheet, View } from 'react-native';
import { SafeAreaProvider } from 'react-native-safe-area-context';

import { HistoryScreen } from './src/screens/HistoryScreen';
import { MatchScreen } from './src/screens/MatchScreen';
import { SetupScreen } from './src/screens/SetupScreen';
import { colors } from './src/screens/theme';
import { useMatch } from './src/state/useMatch';

export default function App() {
  const match = useMatch();
  const [showHistory, setShowHistory] = useState(false);

  let content;
  if (!match.loaded) {
    content = (
      <View style={styles.loading}>
        <ActivityIndicator color={colors.text} />
      </View>
    );
  } else if (!match.setup || !match.score) {
    content = showHistory ? (
      <HistoryScreen
        history={match.history}
        onBack={() => setShowHistory(false)}
        onDelete={match.deleteHistoryEntry}
        onClear={match.clearHistory}
      />
    ) : (
      <SetupScreen
        onStart={match.startMatch}
        historyCount={match.history.length}
        onShowHistory={() => setShowHistory(true)}
      />
    );
  } else {
    content = (
      <MatchScreen
        setup={match.setup}
        score={match.score}
        canUndo={match.pointCount > 0}
        onPoint={match.addPoint}
        onUndo={match.undo}
        onNewMatch={match.newMatch}
      />
    );
  }

  return (
    <SafeAreaProvider>
      <StatusBar style="light" />
      {content}
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  loading: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: colors.background,
  },
});

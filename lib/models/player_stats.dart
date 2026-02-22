import 'match.dart';
import 'player.dart';

class PlayerStats {
  final String playerId;
  final String playerName;
  int matchesPlayed = 0;
  int wins = 0;
  int losses = 0;
  int totalPoints = 0;
  int currentStreak = 0; // positive = wins, negative = losses
  int bestStreak = 0;

  PlayerStats({required this.playerId, required this.playerName});

  double get winRate => matchesPlayed == 0 ? 0 : (wins / matchesPlayed) * 100;
  double get pointsPerMatch =>
      matchesPlayed == 0 ? 0 : totalPoints / matchesPlayed;
  int get winStreak => currentStreak > 0 ? currentStreak : 0;
}

/// Achievement awarded to a specific player.
class Achievement {
  final String icon;
  final String title;
  final String subtitle;
  final String playerId;
  final String playerName;
  final String value;

  const Achievement({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.playerId,
    required this.playerName,
    required this.value,
  });
}

/// Computes stats for every player from finished matches only.
/// Returns a map of playerId → PlayerStats.
Map<String, PlayerStats> computeAllStats(
    List<Match> matches, List<Player> players) {
  // Init stats for all known players
  final stats = <String, PlayerStats>{};
  for (final p in players) {
    stats[p.id] = PlayerStats(playerId: p.id, playerName: p.name);
  }

  // Only finished matches count
  final finished = matches.where((m) => m.status == 'finished').toList();

  // Sort by creation time so streaks are computed in chronological order
  finished.sort((a, b) =>
      (a.createdAt ?? '').compareTo(b.createdAt ?? ''));

  for (final m in finished) {
    final t1Won = m.score1 > m.score2;
    final winners = t1Won ? m.team1Ids : m.team2Ids;

    // Count individual points from scoreHistory
    final pointsByPlayer = <String, int>{};
    for (final e in m.scoreHistory) {
      pointsByPlayer[e.playerId] = (pointsByPlayer[e.playerId] ?? 0) + 1;
    }

    // If no scoreHistory (added result), split points equally among team
    if (m.scoreHistory.isEmpty) {
      for (final id in m.team1Ids) {
        final share = m.team1Ids.length == 1
            ? m.score1
            : (m.score1 / m.team1Ids.length).round();
        pointsByPlayer[id] = (pointsByPlayer[id] ?? 0) + share;
      }
      for (final id in m.team2Ids) {
        final share = m.team2Ids.length == 1
            ? m.score2
            : (m.score2 / m.team2Ids.length).round();
        pointsByPlayer[id] = (pointsByPlayer[id] ?? 0) + share;
      }
    }

    // Update each participant
    final allPlayers = {...m.team1Ids, ...m.team2Ids};
    for (final id in allPlayers) {
      final s = stats.putIfAbsent(
          id, () => PlayerStats(playerId: id, playerName: id));
      s.matchesPlayed++;
      s.totalPoints += pointsByPlayer[id] ?? 0;

      final won = winners.contains(id);
      if (won) {
        s.wins++;
        s.currentStreak = s.currentStreak > 0 ? s.currentStreak + 1 : 1;
      } else {
        s.losses++;
        s.currentStreak = s.currentStreak < 0 ? s.currentStreak - 1 : -1;
      }
      if (s.currentStreak > s.bestStreak) {
        s.bestStreak = s.currentStreak;
      }
    }
  }

  return stats;
}

/// Generates a list of achievements from player stats.
List<Achievement> computeAchievements(Map<String, PlayerStats> stats) {
  final achievements = <Achievement>[];
  final eligible = stats.values.where((s) => s.matchesPlayed >= 1).toList();
  if (eligible.isEmpty) return achievements;

  // 🔥 On Fire — longest current win streak
  final onFire = eligible
      .where((s) => s.winStreak > 0)
      .toList()
    ..sort((a, b) => b.winStreak.compareTo(a.winStreak));
  if (onFire.isNotEmpty) {
    final p = onFire.first;
    achievements.add(Achievement(
      icon: '🔥',
      title: 'On Fire',
      subtitle: 'Current win streak',
      playerId: p.playerId,
      playerName: p.playerName,
      value: '${p.winStreak} wins',
    ));
  }

  // 🎯 Sharpshooter — highest points per match (min 3 matches)
  final shooters = eligible
      .where((s) => s.matchesPlayed >= 3)
      .toList()
    ..sort((a, b) => b.pointsPerMatch.compareTo(a.pointsPerMatch));
  if (shooters.isNotEmpty) {
    final p = shooters.first;
    achievements.add(Achievement(
      icon: '🎯',
      title: 'Sharpshooter',
      subtitle: 'Points per match',
      playerId: p.playerId,
      playerName: p.playerName,
      value: p.pointsPerMatch.toStringAsFixed(1),
    ));
  }

  // 🏆 Most Wins
  final byWins = [...eligible]..sort((a, b) => b.wins.compareTo(a.wins));
  if (byWins.isNotEmpty && byWins.first.wins > 0) {
    final p = byWins.first;
    achievements.add(Achievement(
      icon: '🏆',
      title: 'Most Wins',
      subtitle: 'Total victories',
      playerId: p.playerId,
      playerName: p.playerName,
      value: '${p.wins} wins',
    ));
  }

  // 💪 Iron Player — most matches played
  final byMatches = [...eligible]
    ..sort((a, b) => b.matchesPlayed.compareTo(a.matchesPlayed));
  if (byMatches.isNotEmpty) {
    final p = byMatches.first;
    achievements.add(Achievement(
      icon: '💪',
      title: 'Iron Player',
      subtitle: 'Most matches played',
      playerId: p.playerId,
      playerName: p.playerName,
      value: '${p.matchesPlayed} matches',
    ));
  }

  // ⚡ Streak King — longest ever win streak
  final byBestStreak = [...eligible]
    ..sort((a, b) => b.bestStreak.compareTo(a.bestStreak));
  if (byBestStreak.isNotEmpty && byBestStreak.first.bestStreak > 1) {
    final p = byBestStreak.first;
    achievements.add(Achievement(
      icon: '⚡',
      title: 'Streak King',
      subtitle: 'Best ever win streak',
      playerId: p.playerId,
      playerName: p.playerName,
      value: '${p.bestStreak} wins',
    ));
  }

  return achievements;
}

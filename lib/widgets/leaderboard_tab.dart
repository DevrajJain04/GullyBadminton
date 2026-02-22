import 'package:flutter/material.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../models/player_stats.dart';

class LeaderboardTab extends StatelessWidget {
  final List<Match> matches;
  final List<Player> players;

  const LeaderboardTab({
    super.key,
    required this.matches,
    required this.players,
  });

  @override
  Widget build(BuildContext context) {
    final stats = computeAllStats(matches, players);
    final achievements = computeAchievements(stats);

    // Rank by win rate (min 1 match), then by total wins
    final ranked = stats.values
        .where((s) => s.matchesPlayed > 0)
        .toList()
      ..sort((a, b) {
        final cmp = b.winRate.compareTo(a.winRate);
        if (cmp != 0) return cmp;
        return b.wins.compareTo(a.wins);
      });

    if (ranked.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text('No stats yet',
                style: TextStyle(fontSize: 18, color: Colors.white54)),
            SizedBox(height: 4),
            Text('Finish some matches to see leaderboards!',
                style: TextStyle(fontSize: 13, color: Colors.white30)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Podium ──
        if (ranked.isNotEmpty) _buildPodium(context, ranked),
        const SizedBox(height: 20),

        // ── Achievements ──
        if (achievements.isNotEmpty) ...[
          Text('🏅 Achievements',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: achievements.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _achievementCard(context, achievements[i]),
            ),
          ),
          const SizedBox(height: 20),
        ],

        // ── Full Leaderboard ──
        Text('📊 Full Rankings',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...List.generate(ranked.length, (i) {
          return _rankRow(context, i + 1, ranked[i]);
        }),
      ],
    );
  }

  // ── Podium: top 3 cards ──
  Widget _buildPodium(BuildContext context, List<PlayerStats> ranked) {
    Widget podiumCard(PlayerStats s, int rank) {
      final colors = [
        [const Color(0xFFFFD700), const Color(0xFFFFA000)], // Gold
        [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)], // Silver
        [const Color(0xFFCD7F32), const Color(0xFF8D5524)], // Bronze
      ];
      final medals = ['🥇', '🥈', '🥉'];
      final heights = [120.0, 100.0, 100.0];
      final pair = colors[rank - 1];

      return Expanded(
        child: Container(
          height: heights[rank - 1],
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                pair[0].withValues(alpha: 0.25),
                pair[1].withValues(alpha: 0.10),
              ],
            ),
            border: Border.all(color: pair[0].withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(medals[rank - 1], style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(
                s.playerName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: pair[0],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${s.winRate.toStringAsFixed(0)}% win',
                style: TextStyle(fontSize: 11, color: pair[0].withValues(alpha: 0.8)),
              ),
              Text(
                '${s.wins}W - ${s.losses}L',
                style: const TextStyle(fontSize: 10, color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    // Show podium: 2nd | 1st | 3rd layout
    final items = <Widget>[];
    if (ranked.length > 1) items.add(podiumCard(ranked[1], 2));
    if (ranked.isNotEmpty) items.add(podiumCard(ranked[0], 1));
    if (ranked.length > 2) items.add(podiumCard(ranked[2], 3));

    // If only 1 player, center them
    if (ranked.length == 1) {
      return Center(child: SizedBox(width: 160, child: podiumCard(ranked[0], 1)));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: items,
    );
  }

  // ── Achievement card ──
  Widget _achievementCard(BuildContext context, Achievement a) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withValues(alpha: 0.15),
            Colors.deepOrange.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(a.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(a.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber)),
              ),
            ],
          ),
          const Spacer(),
          Text(a.playerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(a.value,
              style: TextStyle(
                  fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
        ],
      ),
    );
  }

  // ── Leaderboard row ──
  Widget _rankRow(BuildContext context, int rank, PlayerStats s) {
    final rankColors = {
      1: Colors.amber,
      2: Colors.grey.shade400,
      3: const Color(0xFFCD7F32),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: rank <= 3
            ? rankColors[rank]!.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.03),
        border: rank <= 3
            ? Border.all(color: rankColors[rank]!.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 28,
            child: rank <= 3
                ? Text(['🥇', '🥈', '🥉'][rank - 1],
                    style: const TextStyle(fontSize: 16))
                : Text('#$rank',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white38)),
          ),
          const SizedBox(width: 8),
          // Name
          Expanded(
            flex: 3,
            child: Text(s.playerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ),
          // Matches
          _statChip('${s.matchesPlayed}', 'M', Colors.blue),
          const SizedBox(width: 6),
          // W-L
          _statChip('${s.wins}-${s.losses}', 'W-L', Colors.green),
          const SizedBox(width: 6),
          // Win %
          SizedBox(
            width: 42,
            child: Text(
              '${s.winRate.toStringAsFixed(0)}%',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: s.winRate >= 60
                    ? Colors.greenAccent
                    : s.winRate >= 40
                        ? Colors.white70
                        : Colors.redAccent,
              ),
            ),
          ),
          // Streak indicator
          if (s.winStreak > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('🔥${s.winStreak}',
                  style: const TextStyle(fontSize: 10)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(value,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9))),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match.dart';
import '../providers/match_provider.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/court_widget.dart';

class LiveMatchScreen extends StatefulWidget {
  const LiveMatchScreen({super.key});

  @override
  State<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends State<LiveMatchScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    final match = context.read<MatchProvider>().currentMatch;
    if (match != null && match.isLive) {
      final start = DateTime.tryParse(match.startedAt ?? '');
      if (start != null) {
        _elapsed = DateTime.now().difference(start);
      }
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _elapsed += const Duration(seconds: 1));
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final matchProvider = context.watch<MatchProvider>();
    final groupProvider = context.read<GroupProvider>();
    final match = matchProvider.currentMatch;

    if (match == null) {
      return const Scaffold(body: Center(child: Text('No match selected')));
    }

    final isLive = match.isLive;
    final group = groupProvider.selectedGroup;
    final userId = context.read<AuthProvider>().user?.id;
    final isAdmin = group != null &&
        userId != null &&
        (group.createdBy == userId || group.admins.contains(userId));

    final canSetup = isLive &&
        isAdmin &&
        match.score1 == 0 &&
        match.score2 == 0 &&
        match.scoreHistory.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isLive ? 'Live Match' : 'Match Details'),
        centerTitle: true,
        actions: [
          if (isLive)
            IconButton(
              icon: const Icon(Icons.flag),
              tooltip: 'Finish Match',
              onPressed: () => _confirmFinish(context, matchProvider),
            ),
        ],
      ),
      body: Column(
        children: [
          // Timer
          if (isLive)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: Colors.red.withValues(alpha: 0.1),
              child: Center(
                child: Text(
                  '⏱ ${_formatDuration(_elapsed)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ),
            ),

          // Duration for finished
          if (!isLive && match.durationSecs > 0)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'Duration: ${_formatDuration(Duration(seconds: match.durationSecs))}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),

          // Court position diagram
          if (isLive && match.servingTeam > 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                      child: Center(
                          child: Text('LEFT',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white38,
                                  letterSpacing: 2)))),
                  const Expanded(
                      child: Center(
                          child: Text('RIGHT',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white38,
                                  letterSpacing: 2)))),
                ],
              ),
            ),
            CourtWidget(
              match: match,
              onPlayerSwap: canSetup
                  ? (draggedId, droppedId) {
                      final newT1 = List<String>.from(match.team1Ids);
                      final newT2 = List<String>.from(match.team2Ids);

                      final idx1t1 = newT1.indexOf(draggedId);
                      final idx1t2 = newT2.indexOf(draggedId);
                      final idx2t1 = newT1.indexOf(droppedId);
                      final idx2t2 = newT2.indexOf(droppedId);

                      if (idx1t1 != -1 && idx2t1 != -1) {
                        newT1[idx1t1] = droppedId;
                        newT1[idx2t1] = draggedId;
                      } else if (idx1t2 != -1 && idx2t2 != -1) {
                        newT2[idx1t2] = droppedId;
                        newT2[idx2t2] = draggedId;
                      } else if (idx1t1 != -1 && idx2t2 != -1) {
                        newT1[idx1t1] = droppedId;
                        newT2[idx2t2] = draggedId;
                      } else if (idx1t2 != -1 && idx2t1 != -1) {
                        newT2[idx1t2] = droppedId;
                        newT1[idx2t1] = draggedId;
                      }

                      matchProvider.setupMatch(match.id,
                          team1Ids: newT1, team2Ids: newT2);
                    }
                  : null,
              onPlayerTap: canSetup
                  ? (playerId) {
                      final isTeam1 = match.team1Ids.contains(playerId);
                      matchProvider.setupMatch(match.id,
                          servingTeam: isTeam1 ? 1 : 2,
                          servingPlayerId: playerId);
                    }
                  : null,
            ),
          ],

          // Scoreboard
          _buildScoreboard(match),

          const SizedBox(height: 16),

          // Score buttons (only when live)
          if (isLive) _buildScoreButtons(context, match, matchProvider),

          // Controls (undo)
          if (isLive)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: matchProvider.scoring
                        ? null
                        : () => matchProvider.undoScore(),
                    icon: const Icon(Icons.undo, size: 18),
                    label: const Text('Undo'),
                  ),
                ],
              ),
            ),

          const Divider(),

          // Point-by-point log
          Expanded(child: _buildPointLog(match)),
        ],
      ),
    );
  }

  Widget _buildScoreboard(Match match) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Team 1
          Expanded(
            child: Column(
              children: [
                Text(match.team1Label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('${match.score1}',
                    style: const TextStyle(
                        fontSize: 56, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Text('–',
              style: TextStyle(fontSize: 40, color: Colors.grey)),
          // Team 2
          Expanded(
            child: Column(
              children: [
                Text(match.team2Label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text('${match.score2}',
                    style: const TextStyle(
                        fontSize: 56, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreButtons(
      BuildContext context, Match match, MatchProvider provider) {
    final scoring = provider.scoring;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Team 1 buttons
          Expanded(
            child: Column(
              children: [
                for (int i = 0; i < match.team1Ids.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: scoring
                            ? null
                            : () => provider.updateScore(1, match.team1Ids[i]),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          '+1 ${match.team1Names[i]}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Team 2 buttons
          Expanded(
            child: Column(
              children: [
                for (int i = 0; i < match.team2Ids.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: scoring
                            ? null
                            : () => provider.updateScore(2, match.team2Ids[i]),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          '+1 ${match.team2Names[i]}',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointLog(Match match) {
    if (match.scoreHistory.isEmpty) {
      return const Center(
          child: Text('No points scored yet',
              style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: match.scoreHistory.length,
      itemBuilder: (context, index) {
        final event = match.scoreHistory[index];
        final pointNum = index + 1;
        final playerName = _resolvePlayerName(match, event);
        final isTeam1 = event.team == 1;

        // Running score at this point
        int s1 = 0, s2 = 0;
        for (int i = 0; i <= index; i++) {
          if (match.scoreHistory[i].team == 1) {
            s1++;
          } else {
            s2++;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text('$pointNum.',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ),
              Expanded(
                child: Text(
                  playerName,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isTeam1
                        ? Colors.blue.shade300
                        : Colors.orange.shade300,
                  ),
                ),
              ),
              Text(
                '$s1 – $s2',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        );
      },
    );
  }

  String _resolvePlayerName(Match match, ScoreEvent event) {
    return _findPlayerNameById(match, event.playerId);
  }

  String _findPlayerNameById(Match match, String playerId) {
    for (int i = 0; i < match.team1Ids.length; i++) {
      if (match.team1Ids[i] == playerId && i < match.team1Names.length) {
        return match.team1Names[i];
      }
    }
    for (int i = 0; i < match.team2Ids.length; i++) {
      if (match.team2Ids[i] == playerId && i < match.team2Names.length) {
        return match.team2Names[i];
      }
    }
    return 'Unknown';
  }

  void _confirmFinish(BuildContext context, MatchProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Finish Match?'),
        content: const Text('This will end the match permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              provider.finishMatch();
              Navigator.pop(ctx);
              _timer?.cancel();
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }
}

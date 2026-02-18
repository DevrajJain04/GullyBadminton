import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';

class LiveMatchScreen extends StatelessWidget {
  const LiveMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matchProv = context.watch<MatchProvider>();
    final match = matchProv.currentMatch;

    if (match == null) {
      return const Scaffold(body: Center(child: Text('No match selected')));
    }

    final isLive = match.isLive;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(isLive ? '🔴 Live Match' : 'Match Result'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isLive ? Colors.red.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isLive ? Colors.red : Colors.green),
                ),
                child: Text(
                  isLive ? '● LIVE' : '✓ FINISHED',
                  style: TextStyle(
                    color: isLive ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Scoreboard
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPlayerScore(
                    match.player1Name,
                    match.score1,
                    isLive ? () => matchProv.updateScore(1) : null,
                    const Color(0xFF00D9FF),
                  ),
                  const Text(
                    'VS',
                    style: TextStyle(color: Colors.white54, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  _buildPlayerScore(
                    match.player2Name,
                    match.score2,
                    isLive ? () => matchProv.updateScore(2) : null,
                    const Color(0xFFE94560),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Action buttons
              if (isLive) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.undo),
                      label: const Text('Undo'),
                      onPressed: () => matchProv.undoScore(),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.flag),
                      label: const Text('Finish Match'),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: const Color(0xFF16213E),
                            title: const Text('Finish Match?', style: TextStyle(color: Colors.white)),
                            content: Text(
                              'Final score: ${match.score1} - ${match.score2}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Finish'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) {
                          await matchProv.finishMatch();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerScore(String name, int score, VoidCallback? onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          children: [
            Text(
              name,
              style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              '$score',
              style: TextStyle(color: color, fontSize: 56, fontWeight: FontWeight.w900),
            ),
            if (onTap != null) ...[
              const SizedBox(height: 8),
              Text(
                'TAP +1',
                style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

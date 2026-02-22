import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/player.dart';
import '../models/player_stats.dart';
import '../providers/player_provider.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';

class PlayersTab extends StatelessWidget {
  const PlayersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProv = context.watch<PlayerProvider>();
    final matchProv = context.watch<MatchProvider>();
    final group = context.watch<GroupProvider>().selectedGroup;
    final auth = context.watch<AuthProvider>();
    final isCreator = group?.createdBy == auth.user?.id;

    final stats = computeAllStats(matchProv.matches, playerProv.players);

    if (playerProv.loading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00D9FF)));
    }

    return Stack(
      children: [
        playerProv.players.isEmpty
            ? const Center(
                child: Text('No players yet. Tap + to add!',
                    style: TextStyle(color: Colors.white54)))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: playerProv.players.length,
                itemBuilder: (ctx, i) {
                  final player = playerProv.players[i];
                  final s = stats[player.id];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      children: [
                        // Avatar
                        CircleAvatar(
                          radius: 20,
                          backgroundColor:
                              const Color(0xFF00D9FF).withValues(alpha: 0.2),
                          child: Text(
                            player.name.isNotEmpty
                                ? player.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00D9FF)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Name + stats
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(player.name,
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600)),
                              if (s != null && s.matchesPlayed > 0) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    _miniStat('${s.matchesPlayed}', 'played',
                                        Colors.blue),
                                    const SizedBox(width: 10),
                                    _miniStat(
                                        '${s.winRate.toStringAsFixed(0)}%',
                                        'win',
                                        s.winRate >= 50
                                            ? Colors.greenAccent
                                            : Colors.redAccent),
                                    const SizedBox(width: 10),
                                    _miniStat(
                                        '${s.totalPoints}', 'pts', Colors.amber),
                                    if (s.winStreak > 0) ...[
                                      const SizedBox(width: 10),
                                      Text('🔥${s.winStreak}',
                                          style:
                                              const TextStyle(fontSize: 11)),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Delete / Merge buttons (creator only)
                        if (isCreator) ...[
                          IconButton(
                            icon: Icon(Icons.merge_type,
                                color: const Color(0xFF00D9FF).withValues(alpha: 0.8),
                                size: 20),
                            onPressed: () => _showMergeDialog(
                                context, playerProv, matchProv, group!.id, player),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline,
                                color: Colors.redAccent.withValues(alpha: 0.6),
                                size: 20),
                            onPressed: () => _confirmDelete(
                                context, playerProv, group!.id, player.id,
                                player.name),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
        // FAB
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: 'add_player',
            backgroundColor: const Color(0xFF00D9FF),
            foregroundColor: const Color(0xFF1A1A2E),
            child: const Icon(Icons.person_add),
            onPressed: () => _showAddDialog(context, group?.id ?? ''),
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 2),
        Text(label,
            style: TextStyle(
                fontSize: 9, color: color.withValues(alpha: 0.6))),
      ],
    );
  }

  void _confirmDelete(BuildContext context, PlayerProvider prov, String groupId,
      String playerId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title:
            const Text('Remove Player?', style: TextStyle(color: Colors.white)),
        content: Text('Remove $name from the group?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              prov.deletePlayer(groupId, playerId);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showMergeDialog(BuildContext context, PlayerProvider playerProv,
      MatchProvider matchProv, String groupId, Player sourcePlayer) {
    // Filter out the source player from the target list
    final availableTargets =
        playerProv.players.where((p) => p.id != sourcePlayer.id).toList();

    if (availableTargets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No other players available to merge into.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    String? selectedTargetId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF16213E),
            title: const Text('Transfer Stats',
                style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transfer all of ${sourcePlayer.name}\'s match history and stats to another player. ${sourcePlayer.name} will be removed.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  dropdownColor: const Color(0xFF1A1A2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Select Registered User',
                    labelStyle: const TextStyle(color: Colors.white54),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  // ignore: deprecated_member_use
                  value: selectedTargetId,
                  items: availableTargets.map((p) {
                    return DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => selectedTargetId = val),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9FF),
                  foregroundColor: const Color(0xFF1A1A2E),
                ),
                onPressed: selectedTargetId == null
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        final success = await playerProv.mergePlayers(
                            groupId, selectedTargetId!, sourcePlayer.id);
                        if (success && context.mounted) {
                          // Refresh matches to reflect the new IDs in history
                          matchProv.loadMatches(groupId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Stats transferred successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(playerProv.error ?? 'Merge failed'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                child: const Text('Confirm Transfer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context, String groupId) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title:
            const Text('Add Player', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Player name',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF00D9FF))),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D9FF)),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await context
                  .read<PlayerProvider>()
                  .createPlayer(groupId, nameCtrl.text.trim());
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

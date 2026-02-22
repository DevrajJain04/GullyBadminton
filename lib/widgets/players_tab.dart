import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match.dart';
import '../models/player.dart';
import '../models/player_stats.dart';
import '../providers/player_provider.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/match_provider.dart';

class PlayersTab extends StatelessWidget {
  final List<Match> matches;
  const PlayersTab({super.key, required this.matches});

  @override
  Widget build(BuildContext context) {
    final playerProv = context.watch<PlayerProvider>();
    final matchProv = context.watch<MatchProvider>();
    final group = context.watch<GroupProvider>().selectedGroup;
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.id;
    final isCreator = group?.createdBy == userId;
    final isAdmin = isCreator || (group?.admins.contains(userId) ?? false);

    final stats = computeAllStats(matches, playerProv.players);

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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: s != null ? () => _showPlayerStats(context, player, s) : null,
                      child: Container(
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
                        // Admin capabilities
                        if (isAdmin && player.id != userId) ...[
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
                        // Creator capabilities (make admins)
                        if (isCreator && player.id != userId) ...[
                          IconButton(
                            icon: Icon(
                              group!.admins.contains(player.id)
                                  ? Icons.admin_panel_settings
                                  : Icons.admin_panel_settings_outlined,
                              color: group.admins.contains(player.id)
                                  ? Colors.amber
                                  : Colors.white54,
                              size: 20,
                            ),
                            tooltip: group.admins.contains(player.id)
                                ? 'Remove Admin'
                                : 'Make Admin',
                            onPressed: () async {
                              final groupProv = context.read<GroupProvider>();
                              if (group.admins.contains(player.id)) {
                                await groupProv.removeAdmin(group.id, player.id);
                              } else {
                                await groupProv.addAdmin(group.id, player.id);
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
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

  void _showPlayerStats(BuildContext context, Player player, PlayerStats stats) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E), // Match app theme
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final h2hList = stats.vsStats.values.toList()
          ..sort((a, b) => b.matchesPlayed.compareTo(a.matchesPlayed));

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text('${player.name}\'s Head-to-Head',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                  const SizedBox(height: 20),
                  if (h2hList.isEmpty)
                    const Center(child: Text('No head-to-head records yet.', style: TextStyle(color: Colors.white54)))
                  else
                    Expanded(
                      child: ListView.builder(
                        controller: controller,
                        itemCount: h2hList.length,
                        itemBuilder: (ctx, i) {
                          final h2h = h2hList[i];
                          final winRate = h2h.matchesPlayed > 0 
                              ? (h2h.wins / h2h.matchesPlayed * 100).toStringAsFixed(0) 
                              : '0';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('vs ${h2h.opponentName}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${h2h.wins}W - ${h2h.losses}L', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 2),
                                    Text('$winRate% Win Rate', style: TextStyle(color: h2h.wins >= h2h.losses ? Colors.greenAccent : Colors.redAccent, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

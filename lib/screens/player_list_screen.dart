import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../providers/group_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/player_card.dart';

class PlayerListScreen extends StatefulWidget {
  const PlayerListScreen({super.key});

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final group = context.read<GroupProvider>().currentGroup;
      if (group != null) {
        context.read<PlayerProvider>().loadPlayers(group.id);
      }
    });
  }

  bool _isCreator(BuildContext context) {
    final userId = context.read<AuthProvider>().user?.id;
    final group = context.read<GroupProvider>().currentGroup;
    return userId != null && group != null && group.createdBy == userId;
  }

  @override
  Widget build(BuildContext context) {
    final playerProv = context.watch<PlayerProvider>();
    final group = context.watch<GroupProvider>().currentGroup;
    final isCreator = _isCreator(context);

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Players'),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
      ),
      body: playerProv.loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D9FF)))
          : playerProv.players.isEmpty
              ? const Center(
                  child: Text('No players yet. Add some!', style: TextStyle(color: Colors.white54)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: playerProv.players.length,
                  itemBuilder: (ctx, i) {
                    final player = playerProv.players[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: PlayerCard(
                        player: player,
                        trailing: isCreator
                            ? IconButton(
                                icon: Icon(Icons.delete_outline, color: Colors.redAccent.withValues(alpha: 0.7), size: 20),
                                onPressed: () => _confirmDeletePlayer(context, playerProv, group!.id, player.id, player.name),
                              )
                            : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00D9FF),
        foregroundColor: const Color(0xFF1A1A2E),
        child: const Icon(Icons.person_add),
        onPressed: () => _showAddPlayerDialog(context, group?.id ?? ''),
      ),
    );
  }

  void _confirmDeletePlayer(BuildContext context, PlayerProvider playerProv, String groupId, String playerId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Remove Player?', style: TextStyle(color: Colors.white)),
        content: Text('Remove $name from the group?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              playerProv.deletePlayer(groupId, playerId);
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddPlayerDialog(BuildContext context, String groupId) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text('Add Player', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Player name',
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00D9FF))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D9FF)),
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              await context.read<PlayerProvider>().createPlayer(groupId, nameController.text.trim());
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

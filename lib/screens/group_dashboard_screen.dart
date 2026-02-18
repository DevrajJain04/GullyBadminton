import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../providers/match_provider.dart';
import '../providers/player_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/match_card.dart';

class GroupDashboardScreen extends StatefulWidget {
  const GroupDashboardScreen({super.key});

  @override
  State<GroupDashboardScreen> createState() => _GroupDashboardScreenState();
}

class _GroupDashboardScreenState extends State<GroupDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final group = context.read<GroupProvider>().currentGroup;
      if (group != null) {
        context.read<MatchProvider>().loadMatches(group.id);
        context.read<MatchProvider>().connectWebSocket(group.id);
        context.read<PlayerProvider>().loadPlayers(group.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final group = context.watch<GroupProvider>().currentGroup;
    final matchProv = context.watch<MatchProvider>();

    if (group == null) {
      return const Scaffold(body: Center(child: Text('No group selected')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: Text(group.name),
        backgroundColor: const Color(0xFF16213E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: 'Players',
            onPressed: () => Navigator.pushNamed(context, '/players'),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Match History',
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<MatchProvider>().disconnectWebSocket();
              context.read<AuthProvider>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await matchProv.loadMatches(group.id);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Join code card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F3460), Color(0xFF533483)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.vpn_key, color: Color(0xFF00D9FF), size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Join Code', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      Text(
                        group.joinCode,
                        style: const TextStyle(
                          color: Color(0xFF00D9FF),
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Live matches
            const Text('🔴 Live Matches', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (matchProv.liveMatches.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('No live matches', style: TextStyle(color: Colors.white54)),
                ),
              )
            else
              ...matchProv.liveMatches.map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MatchCard(
                      match: m,
                      onTap: () {
                        matchProv.setCurrentMatch(m);
                        Navigator.pushNamed(context, '/live');
                      },
                    ),
                  )),

            const SizedBox(height: 24),
            // Recent finished
            const Text('📋 Recent Matches', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (matchProv.finishedMatches.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('No finished matches yet', style: TextStyle(color: Colors.white54)),
                ),
              )
            else
              ...matchProv.finishedMatches.take(5).map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MatchCard(match: m),
                  )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF00D9FF),
        foregroundColor: const Color(0xFF1A1A2E),
        icon: const Icon(Icons.add),
        label: const Text('New Match'),
        onPressed: () => _showNewMatchDialog(context, group.id),
      ),
    );
  }

  void _showNewMatchDialog(BuildContext context, String groupId) {
    final players = context.read<PlayerProvider>().players;
    if (players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 2 players. Add players first!')),
      );
      return;
    }

    String? p1Id, p2Id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF16213E),
          title: const Text('New Match', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF16213E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Player 1',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                items: players
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (v) => setDialogState(() => p1Id = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                dropdownColor: const Color(0xFF16213E),
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Player 2',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                items: players
                    .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                    .toList(),
                onChanged: (v) => setDialogState(() => p2Id = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00D9FF)),
              onPressed: () async {
                if (p1Id == null || p2Id == null || p1Id == p2Id) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select two different players')),
                  );
                  return;
                }
                final nav = Navigator.of(context);
                final matchProv = context.read<MatchProvider>();
                Navigator.pop(ctx);
                final success = await matchProv.createMatch(groupId, p1Id!, p2Id!);
                if (success && mounted) {
                  nav.pushNamed('/live');
                }
              },
              child: const Text('Start Match'),
            ),
          ],
        ),
      ),
    );
  }
}

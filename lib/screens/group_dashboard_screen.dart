import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/match_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/match_card.dart';

class GroupDashboardScreen extends StatefulWidget {
  const GroupDashboardScreen({super.key});

  @override
  State<GroupDashboardScreen> createState() => _GroupDashboardScreenState();
}

class _GroupDashboardScreenState extends State<GroupDashboardScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final group = context.read<GroupProvider>().selectedGroup;
    if (group != null) {
      context.read<MatchProvider>().loadMatches(group.id);
      context.read<MatchProvider>().connectWebSocket(group.id);
      context.read<PlayerProvider>().loadPlayers(group.id);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = context.watch<GroupProvider>().selectedGroup;
    final matchProvider = context.watch<MatchProvider>();
    final auth = context.watch<AuthProvider>();
    final isCreator = group?.createdBy == auth.user?.id;

    if (group == null) {
      return const Scaffold(body: Center(child: Text('No group selected')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => Navigator.pushNamed(context, '/players'),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.pushNamed(context, '/match-history'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => matchProvider.loadMatches(group.id),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Join code card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Join Code',
                            style: Theme.of(context).textTheme.labelMedium),
                        Text(group.joinCode,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Text('${group.members.length} members',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Live matches
            if (matchProvider.liveMatches.isNotEmpty) ...[
              Text('🔴 Live Matches',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...matchProvider.liveMatches.map((m) => MatchCard(
                    match: m,
                    isCreator: isCreator,
                    onTap: () {
                      matchProvider.setCurrentMatch(m);
                      Navigator.pushNamed(context, '/live-match');
                    },
                  )),
              const SizedBox(height: 16),
            ],

            // Recent finished matches
            if (matchProvider.finishedMatches.isNotEmpty) ...[
              Text('Recent Matches',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...matchProvider.finishedMatches.take(5).map((m) => MatchCard(
                    match: m,
                    isCreator: isCreator,
                    onTap: () {
                      matchProvider.setCurrentMatch(m);
                      Navigator.pushNamed(context, '/live-match');
                    },
                  )),
            ],

            if (matchProvider.loading)
              const Center(child: CircularProgressIndicator()),

            if (!matchProvider.loading &&
                matchProvider.matches.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No matches yet. Start one!',
                      textAlign: TextAlign.center),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: isCreator
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'new_match',
                  onPressed: () => _showNewMatchDialog(context),
                  icon: const Icon(Icons.sports),
                  label: const Text('New Match'),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'add_result',
                  onPressed: () => Navigator.pushNamed(context, '/add-result'),
                  child: const Icon(Icons.add_chart),
                ),
              ],
            )
          : null,
    );
  }

  void _showNewMatchDialog(BuildContext context) {
    final players = context.read<PlayerProvider>().players;
    if (players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add players first')));
      return;
    }

    // State for team building
    String? t1p1, t1p2, t2p1, t2p2;
    bool t1HasPartner = false;
    bool t2HasPartner = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          // Get all currently selected IDs to exclude from other dropdowns
          final selectedIds = [t1p1, t1p2, t2p1, t2p2]
              .where((e) => e != null)
              .toSet();

          Widget playerDropdown(String label, String? value,
              ValueChanged<String?> onChanged) {
            final availablePlayers = players.where(
                (p) => value == p.id || !selectedIds.contains(p.id)).toList();
            return DropdownButtonFormField<String>(
              initialValue: value,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Select...')),
                ...availablePlayers.map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name),
                    )),
              ],
              onChanged: (v) {
                onChanged(v);
                setDialogState(() {});
              },
            );
          }

          return AlertDialog(
            title: const Text('New Match'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Team 1
                  Text('Team 1',
                      style: Theme.of(ctx).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  playerDropdown('Player 1', t1p1, (v) => t1p1 = v),
                  if (t1HasPartner) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: playerDropdown(
                              'Partner', t1p2, (v) => t1p2 = v),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setDialogState(() {
                            t1HasPartner = false;
                            t1p2 = null;
                          }),
                        ),
                      ],
                    ),
                  ] else
                    TextButton.icon(
                      onPressed: () => setDialogState(() {
                        t1HasPartner = true;
                      }),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Add Partner'),
                    ),

                  const Divider(height: 24),

                  // Team 2
                  Text('Team 2',
                      style: Theme.of(ctx).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  playerDropdown('Player 1', t2p1, (v) => t2p1 = v),
                  if (t2HasPartner) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: playerDropdown(
                              'Partner', t2p2, (v) => t2p2 = v),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setDialogState(() {
                            t2HasPartner = false;
                            t2p2 = null;
                          }),
                        ),
                      ],
                    ),
                  ] else
                    TextButton.icon(
                      onPressed: () => setDialogState(() {
                        t2HasPartner = true;
                      }),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Add Partner'),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (t1p1 == null || t2p1 == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content: Text('Select at least 1 player per team')));
                    return;
                  }
                  final team1 = [t1p1!, ?t1p2];
                  final team2 = [t2p1!, ?t2p2];
                  final group =
                      ctx.read<GroupProvider>().selectedGroup!;
                  final dialogNav = Navigator.of(ctx);
                  final screenNav = Navigator.of(context);
                  final matchProv = ctx.read<MatchProvider>();
                  matchProv
                      .createMatch(group.id, team1, team2)
                      .then((success) {
                    if (success) {
                      dialogNav.pop();
                      screenNav.pushNamed('/live-match');
                    }
                  });
                },
                child: const Text('Start'),
              ),
            ],
          );
        },
      ),
    );
  }
}

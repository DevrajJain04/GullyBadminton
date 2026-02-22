import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart';
import '../providers/match_provider.dart';
import '../providers/player_provider.dart';
import '../widgets/match_card.dart';
import '../widgets/leaderboard_tab.dart';
import '../widgets/players_tab.dart';
import '../models/match.dart';

class GroupDashboardScreen extends StatefulWidget {
  const GroupDashboardScreen({super.key});

  @override
  State<GroupDashboardScreen> createState() => _GroupDashboardScreenState();
}

class _GroupDashboardScreenState extends State<GroupDashboardScreen> {
  bool _loaded = false;
  int _tabIndex = 0;
  DateTimeRange? _dateRange;

  List<Match> _filteredMatches(List<Match> matches) {
    if (_dateRange == null) return matches;
    return matches.where((m) {
      if (m.createdAt == null) return true;
      final dt = DateTime.tryParse(m.createdAt!);
      if (dt == null) return true;
      final start = _dateRange!.start;
      final end = _dateRange!.end.add(const Duration(days: 1));
      return dt.isAfter(start) && dt.isBefore(end);
    }).toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final group = context.read<GroupProvider>().selectedGroup;
      if (group != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<MatchProvider>().loadMatches(group.id);
          context.read<MatchProvider>().connectWebSocket(group.id);
          context.read<PlayerProvider>().loadPlayers(group.id);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = context.watch<GroupProvider>().selectedGroup;
    final matchProvider = context.watch<MatchProvider>();
    final playerProvider = context.watch<PlayerProvider>();
    final auth = context.watch<AuthProvider>();
    final userId = auth.user?.id;
    final isCreator = group?.createdBy == userId;
    final isAdmin = isCreator || (group?.admins.contains(userId) ?? false);

    if (group == null) {
      return const Scaffold(body: Center(child: Text('No group selected')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          // Join code chip
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.key, size: 14,
                    color: Colors.white.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(group.joinCode,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2)),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _dateRange == null ? Icons.calendar_today : Icons.event_available,
              color: _dateRange == null ? Colors.white54 : const Color(0xFF00D9FF),
            ),
            tooltip: 'Filter by date',
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: _dateRange,
              );
              if (picked != null) {
                setState(() => _dateRange = picked);
              }
            },
          ),
          if (_dateRange != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white54),
              tooltip: 'Clear filter',
              onPressed: () => setState(() => _dateRange = null),
            ),
        ],
      ),
      body: IndexedStack(
        index: _tabIndex,
        children: [
          // ── Tab 0: Matches ──
          _matchesTab(context, matchProvider, isAdmin, group.id),

          // ── Tab 1: Leaderboard ──
          LeaderboardTab(
            matches: _filteredMatches(matchProvider.matches),
            players: playerProvider.players,
          ),

          // ── Tab 2: Players ──
          PlayersTab(
            matches: _filteredMatches(matchProvider.matches),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: Badge(
              isLabelVisible: matchProvider.liveMatches.isNotEmpty,
              label: Text('${matchProvider.liveMatches.length}'),
              child: const Icon(Icons.sports),
            ),
            selectedIcon: Badge(
              isLabelVisible: matchProvider.liveMatches.isNotEmpty,
              label: Text('${matchProvider.liveMatches.length}'),
              child: const Icon(Icons.sports),
            ),
            label: 'Matches',
          ),
          const NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: playerProvider.players.isNotEmpty,
              label: Text('${playerProvider.players.length}'),
              child: const Icon(Icons.people_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: playerProvider.players.isNotEmpty,
              label: Text('${playerProvider.players.length}'),
              child: const Icon(Icons.people),
            ),
            label: 'Players',
          ),
        ],
      ),
      floatingActionButton: _tabIndex == 0 && isAdmin
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
                  onPressed: () =>
                      Navigator.pushNamed(context, '/add-result'),
                  child: const Icon(Icons.add_chart),
                ),
              ],
            )
          : null,
    );
  }

  // ── Matches Tab Content ──
  Widget _matchesTab(BuildContext context, MatchProvider matchProvider,
      bool isAdmin, String groupId) {
    return RefreshIndicator(
      onRefresh: () => matchProvider.loadMatches(groupId),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Live matches
          if (matchProvider.liveMatches.isNotEmpty) ...[
            _sectionHeader(context, '🔴 Live Matches'),
            const SizedBox(height: 8),
            ...matchProvider.liveMatches.map((m) => MatchCard(
                  match: m,
                  isAdmin: isAdmin,
                  onTap: () {
                    matchProvider.setCurrentMatch(m);
                    Navigator.pushNamed(context, '/live-match');
                  },
                )),
            const SizedBox(height: 16),
          ],

          // Finished Matches
          if (_filteredMatches(matchProvider.finishedMatches).isNotEmpty) ...[
            _sectionHeader(context, 'Finished Matches'),
            const SizedBox(height: 8),
            ..._filteredMatches(matchProvider.finishedMatches).map((m) => MatchCard(
                  match: m,
                  isAdmin: isAdmin,
                  onTap: () {
                    matchProvider.setCurrentMatch(m);
                    Navigator.pushNamed(context, '/live-match');
                  },
                )),
          ],

          if (matchProvider.loading)
            const Center(child: CircularProgressIndicator()),

          if (!matchProvider.loading && matchProvider.matches.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No matches yet. Start one!',
                    textAlign: TextAlign.center),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Text(text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold));
  }

  // ── New Match Dialog ──
  void _showNewMatchDialog(BuildContext context) {
    final players = context.read<PlayerProvider>().players;
    if (players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Add players first')));
      return;
    }

    String? t1p1, t1p2, t2p1, t2p2;
    bool t1HasPartner = false;
    bool t2HasPartner = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final selectedIds =
              [t1p1, t1p2, t2p1, t2p2].where((e) => e != null).toSet();

          Widget playerDropdown(String label, String? value,
              ValueChanged<String?> onChanged) {
            final available = players
                .where(
                    (p) => value == p.id || !selectedIds.contains(p.id))
                .toList();
            return DropdownButtonFormField<String>(
              initialValue: value,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Select...')),
                ...available.map((p) => DropdownMenuItem(
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
                  Text('Team 1',
                      style: Theme.of(ctx).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  playerDropdown('Player 1', t1p1, (v) => t1p1 = v),
                  if (t1HasPartner) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: playerDropdown(
                              'Partner', t1p2, (v) => t1p2 = v)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setDialogState(() {
                          t1HasPartner = false;
                          t1p2 = null;
                        }),
                      ),
                    ]),
                  ] else
                    TextButton.icon(
                      onPressed: () =>
                          setDialogState(() => t1HasPartner = true),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Add Partner'),
                    ),
                  const Divider(height: 24),
                  Text('Team 2',
                      style: Theme.of(ctx).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  playerDropdown('Player 1', t2p1, (v) => t2p1 = v),
                  if (t2HasPartner) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                          child: playerDropdown(
                              'Partner', t2p2, (v) => t2p2 = v)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => setDialogState(() {
                          t2HasPartner = false;
                          t2p2 = null;
                        }),
                      ),
                    ]),
                  ] else
                    TextButton.icon(
                      onPressed: () =>
                          setDialogState(() => t2HasPartner = true),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Add Partner'),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  if (t1p1 == null || t2p1 == null) {
                    ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content:
                            Text('Select at least 1 player per team')));
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

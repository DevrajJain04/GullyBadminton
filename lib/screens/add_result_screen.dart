import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/group_provider.dart';
import '../providers/match_provider.dart';
import '../providers/player_provider.dart';

class AddResultScreen extends StatefulWidget {
  const AddResultScreen({super.key});

  @override
  State<AddResultScreen> createState() => _AddResultScreenState();
}

class _AddResultScreenState extends State<AddResultScreen> {
  String? _t1p1, _t1p2, _t2p1, _t2p2;
  bool _t1HasPartner = false;
  bool _t2HasPartner = false;
  final _score1 = TextEditingController();
  final _score2 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final players = context.watch<PlayerProvider>().players;
    final selectedIds = [_t1p1, _t1p2, _t2p1, _t2p2]
        .where((e) => e != null)
        .toSet();

    Widget playerDropdown(
        String label, String? value, ValueChanged<String?> onChanged) {
      final available = players
          .where((p) => value == p.id || !selectedIds.contains(p.id))
          .toList();
      return DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('Select...')),
          ...available.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name))),
        ],
        onChanged: (v) {
          onChanged(v);
          setState(() {});
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Past Result')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Team 1
            Text('Team 1', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            playerDropdown('Player 1', _t1p1, (v) => _t1p1 = v),
            if (_t1HasPartner) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child:
                        playerDropdown('Partner', _t1p2, (v) => _t1p2 = v),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _t1HasPartner = false;
                      _t1p2 = null;
                    }),
                  ),
                ],
              ),
            ] else
              TextButton.icon(
                onPressed: () => setState(() => _t1HasPartner = true),
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Add Partner'),
              ),

            const Divider(height: 24),

            // Team 2
            Text('Team 2', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            playerDropdown('Player 1', _t2p1, (v) => _t2p1 = v),
            if (_t2HasPartner) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child:
                        playerDropdown('Partner', _t2p2, (v) => _t2p2 = v),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _t2HasPartner = false;
                      _t2p2 = null;
                    }),
                  ),
                ],
              ),
            ] else
              TextButton.icon(
                onPressed: () => setState(() => _t2HasPartner = true),
                icon: const Icon(Icons.person_add, size: 16),
                label: const Text('Add Partner'),
              ),

            const Divider(height: 24),

            // Scores
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _score1,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Team 1 Score',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _score2,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Team 2 Score',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: _submit,
              child: const Text('Save Result'),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (_t1p1 == null || _t2p1 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least 1 player per team')));
      return;
    }
    final s1 = int.tryParse(_score1.text);
    final s2 = int.tryParse(_score2.text);
    if (s1 == null || s2 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter valid scores')));
      return;
    }

    final team1 = [_t1p1!, ?_t1p2];
    final team2 = [_t2p1!, ?_t2p2];
    final groupId = context.read<GroupProvider>().selectedGroup!.id;

    final nav = Navigator.of(context);
    context.read<MatchProvider>().addResult(groupId, team1, team2, s1, s2).then((success) {
      if (success && mounted) {
        nav.pop();
      }
    });
  }
}

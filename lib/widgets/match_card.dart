import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/match.dart';
import '../providers/match_provider.dart';

class MatchCard extends StatelessWidget {
  final Match match;
  final bool isCreator;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.match,
    this.isCreator = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = match.isLive;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLive
                          ? Colors.red.withValues(alpha: 0.2)
                          : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isLive ? '● LIVE' : 'DONE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isLive ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                  if (match.isDoubles)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('DOUBLES',
                          style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold)),
                    ),
                  if (isCreator)
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'delete') {
                          context.read<MatchProvider>().deleteMatch(match.id);
                        } else if (action == 'edit') {
                          _showEditScoreDialog(context);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                            value: 'edit', child: Text('Edit Score')),
                        const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete',
                                style: TextStyle(color: Colors.red))),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Score row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(match.team1Label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('${match.score1}',
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('vs',
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(match.team2Label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text('${match.score2}',
                            style: const TextStyle(
                                fontSize: 28, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditScoreDialog(BuildContext context) {
    final s1 = TextEditingController(text: '${match.score1}');
    final s2 = TextEditingController(text: '${match.score2}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Score'),
        content: Row(
          children: [
            Expanded(
                child: TextField(
              controller: s1,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: match.team1Label),
            )),
            const SizedBox(width: 16),
            Expanded(
                child: TextField(
              controller: s2,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: match.team2Label),
            )),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final sc1 = int.tryParse(s1.text) ?? match.score1;
              final sc2 = int.tryParse(s2.text) ?? match.score2;
              context
                  .read<MatchProvider>()
                  .editScore(match.id, sc1, sc2);
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

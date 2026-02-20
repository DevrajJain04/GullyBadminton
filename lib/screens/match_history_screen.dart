import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/match_provider.dart';
import '../widgets/match_card.dart';

class MatchHistoryScreen extends StatelessWidget {
  const MatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final matchProvider = context.watch<MatchProvider>();
    final finished = matchProvider.finishedMatches;

    return Scaffold(
      appBar: AppBar(title: const Text('Match History')),
      body: finished.isEmpty
          ? const Center(child: Text('No finished matches yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: finished.length,
              itemBuilder: (context, index) {
                final match = finished[index];
                return MatchCard(
                  match: match,
                  onTap: () {
                    matchProvider.setCurrentMatch(match);
                    Navigator.pushNamed(context, '/live-match');
                  },
                );
              },
            ),
    );
  }
}

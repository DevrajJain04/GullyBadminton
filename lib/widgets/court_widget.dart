import 'package:flutter/material.dart';
import '../models/match.dart';

/// Computed badminton match state derived from replaying scoreHistory.
/// Follows standard badminton serving rules:
///   - Even score → server on RIGHT, odd → LEFT
///   - Serving team wins → score + swap positions (doubles)
///   - Receiving team wins → score + serve transfer, NO swap
class _BadmintonState {
  // Which team is serving (1 or 2)
  int servingTeam = 1;

  // Positions: index 0 = LEFT court, index 1 = RIGHT court
  // Stored as player IDs
  late List<String> team1Pos;
  late List<String> team2Pos;

  int score1 = 0;
  int score2 = 0;

  _BadmintonState(Match match) {
    // Initial positions: team IDs in their original order
    team1Pos = List<String>.from(match.team1Ids);
    team2Pos = List<String>.from(match.team2Ids);
    servingTeam = 1;

    // Replay every event in the score history
    for (final event in match.scoreHistory) {
      _applyEvent(event);
    }
  }

  void _applyEvent(ScoreEvent event) {
    final servingTeamWon = (event.team == servingTeam);

    // Increment score
    if (event.team == 1) {
      score1++;
    } else {
      score2++;
    }

    if (servingTeamWon) {
      // Serving team scored → swap their positions (doubles only)
      _swapPositions(servingTeam);
    } else {
      // Receiving team scored → serve transfers, NO swap
      servingTeam = event.team;
    }
  }

  void _swapPositions(int team) {
    if (team == 1 && team1Pos.length == 2) {
      final temp = team1Pos[0];
      team1Pos[0] = team1Pos[1];
      team1Pos[1] = temp;
    } else if (team == 2 && team2Pos.length == 2) {
      final temp = team2Pos[0];
      team2Pos[0] = team2Pos[1];
      team2Pos[1] = temp;
    }
  }

  /// The serving team's score determines the service court side.
  int get servingTeamScore => servingTeam == 1 ? score1 : score2;
  bool get isScoreEven => servingTeamScore % 2 == 0;

  /// Even → RIGHT (index 1), Odd → LEFT (index 0)
  List<String> get servingTeamPos => servingTeam == 1 ? team1Pos : team2Pos;

  String get currentServerId {
    final pos = servingTeamPos;
    if (pos.length == 1) return pos[0];
    // Team 1 (top, faces down): even→LEFT(pos[0]), odd→RIGHT(pos[1])
    // Team 2 (bottom, faces up): even→RIGHT(pos[1]), odd→LEFT(pos[0])
    if (servingTeam == 1) {
      return isScoreEven ? pos[0] : pos[1];
    } else {
      return isScoreEven ? pos[1] : pos[0];
    }
  }
}

/// A visual 2×2 badminton court showing player positions and serve direction.
/// All logic is computed from scoreHistory — backend is not relied upon
/// for positions or serve tracking.
class CourtWidget extends StatelessWidget {
  final Match match;
  const CourtWidget({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    // Replay the entire score history to get correct positions & serve
    final state = _BadmintonState(match);

    // Build team slots from computed state
    final team1Slots = _buildSlots(
      teamNumber: 1,
      ids: match.team1Ids,
      names: match.team1Names,
      positions: state.team1Pos,
      isServingTeam: state.servingTeam == 1,
      serverId: state.currentServerId,
      teamScore: state.score1,
    );

    final team2Slots = _buildSlots(
      teamNumber: 2,
      ids: match.team2Ids,
      names: match.team2Names,
      positions: state.team2Pos,
      isServingTeam: state.servingTeam == 2,
      serverId: state.currentServerId,
      teamScore: state.score2,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
        color: const Color(0xFF1B3A2D),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Team 1 side (top)
          _buildHalf(
            team1Slots,
            isTopHalf: true,
            teamColor: Colors.blue.shade400,
            isServingSide: state.servingTeam == 1,
          ),
          // Net
          Container(
            height: 2,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white54,
              boxShadow: [
                BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 4)
              ],
            ),
          ),
          // Team 2 side (bottom)
          _buildHalf(
            team2Slots,
            isTopHalf: false,
            teamColor: Colors.orange.shade400,
            isServingSide: state.servingTeam == 2,
          ),
        ],
      ),
    );
  }

  /// Build left/right slots for one team.
  /// For singles: player placed by their OWN score parity.
  /// For doubles: positions[0]=LEFT, positions[1]=RIGHT (from backend replay).
  _CourtSlots _buildSlots({
    required int teamNumber,
    required List<String> ids,
    required List<String> names,
    required List<String> positions,
    required bool isServingTeam,
    required String serverId,
    required int teamScore,
  }) {
    if (names.isEmpty) return _CourtSlots();

    // Singles — same mirroring as doubles
    if (names.length == 1) {
      final isEven = teamScore % 2 == 0;
      // Team 1: even→LEFT, Team 2: even→RIGHT
      final onRight = teamNumber == 1 ? !isEven : isEven;
      final isServer = isServingTeam;
      return _CourtSlots(
        leftPlayer: onRight ? null : names[0],
        rightPlayer: onRight ? names[0] : null,
        leftIsServer: !onRight && isServer,
        rightIsServer: onRight && isServer,
      );
    }

    // Doubles: positions are already computed by _BadmintonState
    final leftName = _nameForId(positions[0], ids, names);
    final rightName = _nameForId(positions[1], ids, names);

    return _CourtSlots(
      leftPlayer: leftName,
      rightPlayer: rightName,
      leftIsServer: isServingTeam && positions[0] == serverId,
      rightIsServer: isServingTeam && positions[1] == serverId,
    );
  }

  String? _nameForId(String id, List<String> ids, List<String> names) {
    final idx = ids.indexOf(id);
    if (idx >= 0 && idx < names.length) return names[idx];
    return null;
  }

  Widget _buildHalf(
    _CourtSlots slots, {
    required bool isTopHalf,
    required Color teamColor,
    required bool isServingSide,
  }) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          Expanded(
            child: _courtCell(
              slots.leftPlayer,
              teamColor,
              isServer: slots.leftIsServer,
              serveDirection: isServingSide && slots.leftIsServer
                  ? (isTopHalf ? _ServeDir.downRight : _ServeDir.upRight)
                  : null,
            ),
          ),
          Container(width: 1, color: Colors.white24),
          Expanded(
            child: _courtCell(
              slots.rightPlayer,
              teamColor,
              isServer: slots.rightIsServer,
              serveDirection: isServingSide && slots.rightIsServer
                  ? (isTopHalf ? _ServeDir.downLeft : _ServeDir.upLeft)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _courtCell(
    String? playerName,
    Color teamColor, {
    required bool isServer,
    _ServeDir? serveDirection,
  }) {
    if (playerName == null || playerName.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        if (serveDirection != null)
          Positioned(
            top: serveDirection == _ServeDir.downLeft ||
                    serveDirection == _ServeDir.downRight
                ? null
                : 2,
            bottom: serveDirection == _ServeDir.downLeft ||
                    serveDirection == _ServeDir.downRight
                ? 2
                : null,
            left: serveDirection == _ServeDir.downLeft ||
                    serveDirection == _ServeDir.upLeft
                ? 8
                : null,
            right: serveDirection == _ServeDir.downRight ||
                    serveDirection == _ServeDir.upRight
                ? 8
                : null,
            child: Icon(
              serveDirection == _ServeDir.downLeft
                  ? Icons.south_west
                  : serveDirection == _ServeDir.downRight
                      ? Icons.south_east
                      : serveDirection == _ServeDir.upLeft
                          ? Icons.north_west
                          : Icons.north_east,
              size: 16,
              color: Colors.amber.withValues(alpha: 0.7),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isServer
                ? teamColor.withValues(alpha: 0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isServer
                ? Border.all(color: Colors.amber, width: 1.5)
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isServer)
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Icon(Icons.sports_tennis,
                      size: 12, color: Colors.amber),
                ),
              Flexible(
                child: Text(
                  playerName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isServer ? FontWeight.bold : FontWeight.w500,
                    color: isServer ? Colors.white : teamColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum _ServeDir { downLeft, downRight, upLeft, upRight }

class _CourtSlots {
  final String? leftPlayer;
  final String? rightPlayer;
  final bool leftIsServer;
  final bool rightIsServer;

  _CourtSlots({
    this.leftPlayer,
    this.rightPlayer,
    this.leftIsServer = false,
    this.rightIsServer = false,
  });
}

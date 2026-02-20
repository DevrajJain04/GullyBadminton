class ScoreEvent {
  final int team; // 1 or 2
  final String playerId;

  ScoreEvent({required this.team, required this.playerId});

  factory ScoreEvent.fromJson(Map<String, dynamic> json) {
    return ScoreEvent(
      team: json['team'] ?? 0,
      playerId: json['player_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'team': team,
        'player_id': playerId,
      };
}

class Match {
  final String id;
  final String groupId;

  // Teams
  final List<String> team1Ids;
  final List<String> team2Ids;
  final List<String> team1Names;
  final List<String> team2Names;

  // Scores
  int score1;
  int score2;
  final List<ScoreEvent> scoreHistory;

  // Serve tracking
  final int servingTeam;
  final String servingPlayerId;

  // Court positions
  final List<String> team1Positions;
  final List<String> team2Positions;

  // Match lifecycle
  String status;
  final String? startedAt;
  final String? finishedAt;
  final int durationSecs;
  final String? createdAt;
  final String? updatedAt;

  Match({
    required this.id,
    required this.groupId,
    required this.team1Ids,
    required this.team2Ids,
    required this.team1Names,
    required this.team2Names,
    required this.score1,
    required this.score2,
    required this.scoreHistory,
    this.servingTeam = 1,
    this.servingPlayerId = '',
    this.team1Positions = const [],
    this.team2Positions = const [],
    required this.status,
    this.startedAt,
    this.finishedAt,
    this.durationSecs = 0,
    this.createdAt,
    this.updatedAt,
  });

  bool get isLive => status == 'live';
  bool get isDoubles => team1Ids.length == 2 || team2Ids.length == 2;

  /// Display label for a team: "Alice & Bob" or "Alice"
  String get team1Label => team1Names.join(' & ');
  String get team2Label => team2Names.join(' & ');

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] ?? '',
      groupId: json['group_id'] ?? '',
      team1Ids: List<String>.from(json['team1_ids']?.map((e) => e.toString()) ?? []),
      team2Ids: List<String>.from(json['team2_ids']?.map((e) => e.toString()) ?? []),
      team1Names: List<String>.from(json['team1_names'] ?? []),
      team2Names: List<String>.from(json['team2_names'] ?? []),
      score1: json['score1'] ?? 0,
      score2: json['score2'] ?? 0,
      scoreHistory: (json['score_history'] as List<dynamic>?)
              ?.map((e) => ScoreEvent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      servingTeam: json['serving_team'] ?? 1,
      servingPlayerId: json['serving_player_id'] ?? '',
      team1Positions: List<String>.from(json['team1_positions'] ?? []),
      team2Positions: List<String>.from(json['team2_positions'] ?? []),
      status: json['status'] ?? 'live',
      startedAt: json['started_at'],
      finishedAt: json['finished_at'],
      durationSecs: json['duration_secs'] ?? 0,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'team1_ids': team1Ids,
        'team2_ids': team2Ids,
        'team1_names': team1Names,
        'team2_names': team2Names,
        'score1': score1,
        'score2': score2,
        'score_history': scoreHistory.map((e) => e.toJson()).toList(),
        'serving_team': servingTeam,
        'serving_player_id': servingPlayerId,
        'team1_positions': team1Positions,
        'team2_positions': team2Positions,
        'status': status,
        'started_at': startedAt,
        'finished_at': finishedAt,
        'duration_secs': durationSecs,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

class Match {
  final String id;
  final String groupId;
  final String player1Id;
  final String player2Id;
  final String player1Name;
  final String player2Name;
  int score1;
  int score2;
  final List<String> scoreHistory;
  String status;
  final String? createdAt;
  final String? updatedAt;

  Match({
    required this.id,
    required this.groupId,
    required this.player1Id,
    required this.player2Id,
    required this.player1Name,
    required this.player2Name,
    required this.score1,
    required this.score2,
    required this.scoreHistory,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  bool get isLive => status == 'live';

  factory Match.fromJson(Map<String, dynamic> json) {
    return Match(
      id: json['id'] ?? '',
      groupId: json['group_id'] ?? '',
      player1Id: json['player1_id'] ?? '',
      player2Id: json['player2_id'] ?? '',
      player1Name: json['player1_name'] ?? '',
      player2Name: json['player2_name'] ?? '',
      score1: json['score1'] ?? 0,
      score2: json['score2'] ?? 0,
      scoreHistory: List<String>.from(json['score_history'] ?? []),
      status: json['status'] ?? 'live',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'group_id': groupId,
        'player1_id': player1Id,
        'player2_id': player2Id,
        'player1_name': player1Name,
        'player2_name': player2Name,
        'score1': score1,
        'score2': score2,
        'score_history': scoreHistory,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

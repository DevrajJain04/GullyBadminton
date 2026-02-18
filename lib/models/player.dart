class Player {
  final String id;
  final String name;
  final String groupId;
  final String? createdAt;

  Player({
    required this.id,
    required this.name,
    required this.groupId,
    this.createdAt,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      groupId: json['group_id'] ?? '',
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'group_id': groupId,
        'created_at': createdAt,
      };
}

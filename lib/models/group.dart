class Group {
  final String id;
  final String name;
  final String joinCode;
  final String createdBy;
  final List<String> members;
  final String? createdAt;

  Group({
    required this.id,
    required this.name,
    required this.joinCode,
    required this.createdBy,
    required this.members,
    this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      joinCode: json['join_code'] ?? '',
      createdBy: json['created_by'] ?? '',
      members: List<String>.from(
          (json['members'] as List<dynamic>?)?.map((e) => e.toString()) ?? []),
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'join_code': joinCode,
        'created_by': createdBy,
        'members': members,
        'created_at': createdAt,
      };
}

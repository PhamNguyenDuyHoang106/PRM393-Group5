class UserRole {
  static const String manager = 'manager';
  static const String member = 'member';
}

class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'manager' or 'member'
  final DateTime createdAt;
  final String? avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.avatarUrl,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    DateTime? createdAt,
    String? avatarUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'avatar_url': avatarUrl,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle both camelCase from NestJS and snake_case from SQLite
    final rawAvatar = json['avatar_url'] ?? json['avatarUrl'];
    final rawCreatedAt = json['created_at'] ?? json['createdAt'];
    
    return User(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'member').toString(),
      createdAt: rawCreatedAt != null
          ? DateTime.parse(rawCreatedAt.toString())
          : DateTime.now(),
      avatarUrl: rawAvatar?.toString(),
    );
  }

  bool get isManager => role.toLowerCase() == UserRole.manager;
  bool get isMember => role.toLowerCase() == UserRole.member;
}

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

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isManager => role.toLowerCase() == UserRole.manager;
  bool get isMember => role.toLowerCase() == UserRole.member;
}

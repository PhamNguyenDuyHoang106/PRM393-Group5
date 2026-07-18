class Project {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.createdAt,
  });

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    DateTime? createdAt,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'].toString(),
      name: json['name'].toString(),
      description: json['description']?.toString() ?? '',
      ownerId: json['owner_id'].toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}

/// A lightweight user representation returned inside a project detail payload.
///
/// The project API does not return `created_at` for members, so using the main
/// [User] model here would make valid API responses impossible to parse.
class ProjectMember {
  final String id;
  final String name;
  final String email;
  final String role;

  const ProjectMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  bool get isManager => role.toLowerCase() == 'manager';

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'role': role};
  }

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      id: json['id'].toString(),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'Member',
    );
  }
}

/// Combines the project metadata and its member list returned by
/// `GET /projects/{id}`.
class ProjectDetails {
  final Project project;
  final List<ProjectMember> members;

  ProjectDetails({
    required this.project,
    List<ProjectMember> members = const [],
  }) : members = List.unmodifiable(members);

  ProjectDetails copyWith({Project? project, List<ProjectMember>? members}) {
    return ProjectDetails(
      project: project ?? this.project,
      members: members ?? this.members,
    );
  }

  factory ProjectDetails.fromJson(Map<String, dynamic> json) {
    final membersJson = json['members'];
    final members = membersJson is List
        ? membersJson
              .whereType<Map>()
              .map(
                (member) =>
                    ProjectMember.fromJson(Map<String, dynamic>.from(member)),
              )
              .toList()
        : <ProjectMember>[];

    return ProjectDetails(project: Project.fromJson(json), members: members);
  }
}

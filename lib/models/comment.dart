class TaskComment {
  final String id;
  final String taskId;
  final String userId;
  final String userName;
  final String? userAvatarUrl;
  final String content;
  final DateTime createdAt;

  TaskComment({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.userName,
    this.userAvatarUrl,
    required this.content,
    required this.createdAt,
  });

  factory TaskComment.fromJson(Map<String, dynamic> json) {
    String name = json['user_name'] ?? 'User';
    String? avatar = json['user_avatar_url'];
    if (json['user'] is Map) {
      name = json['user']['name'] ?? name;
      avatar = json['user']['avatarUrl'] ?? avatar;
    }

    return TaskComment(
      id: json['id'] as String,
      taskId: json['taskId'] ?? json['task_id'] ?? '',
      userId: json['userId'] ?? json['user_id'] ?? '',
      userName: name,
      userAvatarUrl: avatar,
      content: json['content'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'user_id': userId,
      'user_name': userName,
      'user_avatar_url': userAvatarUrl,
      'content': content,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

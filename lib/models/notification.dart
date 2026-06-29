class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final int readStatus; // 0 = unread, 1 = read
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.readStatus,
    required this.createdAt,
  });

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    int? readStatus,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      readStatus: readStatus ?? this.readStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'read_status': readStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      readStatus: json['read_status'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isRead => readStatus == 1;
}

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
      id: json['id'].toString(),
      userId: (json['user_id'] ?? json['userId'] ?? '').toString(),
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      readStatus: _parseReadStatus(json['read_status'] ?? json['readStatus']),
      createdAt: DateTime.parse(
        (json['created_at'] ?? json['createdAt']).toString(),
      ),
    );
  }

  static int _parseReadStatus(dynamic raw) {
    if (raw is bool) return raw ? 1 : 0;
    if (raw is num) return raw.toInt();
    return 0;
  }

  bool get isRead => readStatus == 1;
}

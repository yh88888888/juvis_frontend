class AppNotification {
  final int id;
  final int maintenanceId;
  final String title;
  final String status; // "IN_PROGRESS" 등
  final String message; // 서버가 만들어 준 문구
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.maintenanceId,
    required this.title,
    required this.status,
    required this.message,
    required this.read,
    required this.createdAt,
  });

  static DateTime _dt(dynamic v) =>
      v == null ? DateTime.now() : DateTime.parse(v as String);

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num).toInt(),
      maintenanceId: (json['maintenanceId'] as num).toInt(),
      title: (json['title'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      message: (json['message'] ?? '') as String,
      read: (json['read'] as bool?) ?? false,
      createdAt: _dt(json['createdAt']),
    );
  }

  AppNotification copyWith({
    int? id,
    int? maintenanceId,
    String? title,
    String? status,
    String? message,
    bool? read,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      maintenanceId: maintenanceId ?? this.maintenanceId,
      title: title ?? this.title,
      status: status ?? this.status,
      message: message ?? this.message,
      read: read ?? this.read,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

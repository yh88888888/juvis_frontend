class MaintenanceSimple {
  final int id;
  final String title;
  final String status;
  final DateTime createdAt;

  MaintenanceSimple({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  factory MaintenanceSimple.fromJson(Map<String, dynamic> json) {
    return MaintenanceSimple(
      id: json['id'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

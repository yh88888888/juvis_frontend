class MaintenanceListItem {
  final int id;
  final String title;
  final String status;
  final DateTime createdAt;

  MaintenanceListItem({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  factory MaintenanceListItem.fromJson(Map<String, dynamic> json) {
    return MaintenanceListItem(
      id: (json['id'] as num).toInt(),
      title: (json['title'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

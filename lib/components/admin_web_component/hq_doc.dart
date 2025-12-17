class HqDoc {
  final String title;
  final String status;
  final String docNo;
  final String drafter;
  final String date;

  HqDoc({
    required this.title,
    required this.status,
    required this.docNo,
    required this.drafter,
    required this.date,
  });

  factory HqDoc.fromJson(Map<String, dynamic> json) {
    return HqDoc(
      title: json['title'] ?? '',
      status: json['status'] ?? '',
      docNo: json['docNo'] ?? '',
      drafter: json['drafter'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

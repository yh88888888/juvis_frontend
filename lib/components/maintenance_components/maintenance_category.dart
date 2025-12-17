enum MaintenanceCategory {
  ELECTRICAL_COMMUNICATION,
  LIGHTING,
  HVAC,
  WATER_SUPPLY_DRAINAGE,
  SAFETY_HYGIENE,
  ETC,
}

extension MaintenanceCategoryExt on MaintenanceCategory {
  String get displayName {
    switch (this) {
      case MaintenanceCategory.ELECTRICAL_COMMUNICATION:
        return '전기·통신';
      case MaintenanceCategory.LIGHTING:
        return '조명';
      case MaintenanceCategory.HVAC:
        return '공조·환기';
      case MaintenanceCategory.WATER_SUPPLY_DRAINAGE:
        return '급·배수';
      case MaintenanceCategory.SAFETY_HYGIENE:
        return '안전·위생';
      case MaintenanceCategory.ETC:
        return '기타';
    }
  }

  /// ✅ 서버로 보낼 값 (Enum.name 사용)
  String get toJson => name;
}

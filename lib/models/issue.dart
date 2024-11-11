class Issue {
  final String title;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final String addr;

  Issue({
    required this.title,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.addr,
  });

  // JSON으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'addr': addr,
    };
  }
}
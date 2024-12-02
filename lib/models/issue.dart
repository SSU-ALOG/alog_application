class Issue {
  final int? issueId; // nullable, 생성 시 서버에서 자동 생성
  final String title;
  final String category;
  final String? description; // nullable
  final double latitude;
  final double longitude;
  final DateTime date; // 서버에서 생성된 LocalDateTime
  final String status; // 기본값: "진행중"
  final bool verified; // 기본값: false
  final String addr;

  // default constructor
  Issue({
    required this.issueId,
    required this.title,
    required this.category,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.status,
    required this.verified,
    required this.addr,
  });

  // constructor for accident registration
  Issue.fromUserInput({
    required this.title,
    required this.category,
    this.description,
    required this.latitude,
    required this.longitude,
    required this.addr,
  })  : issueId = null, // 사용자가 제공하지 않음
        status = '진행중', // 서버와 동일한 기본값
        verified = false, // 서버와 동일한 기본값
        date = DateTime.now(); // 현재 시간 설정

  // JSON -> Issue 객체로 변환하는 팩토리 메서드
  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      issueId: json['id'],
      title: json['title'] ?? '제목 없음',
      category: json['category'] ?? '기타',
      description: json['description'] ?? 'none',
      latitude: (json['latitude'] as num).toDouble(), // JSON 숫자를 double로 변환
      longitude: (json['longitude'] as num).toDouble(),
      date: DateTime.parse(json['date']), // 서버에서 반환된 ISO-8601 날짜 문자열 파싱
      status: json['status'] ?? '진행중',
      verified: json['verified'] ?? false,
      addr: json['addr'],
    );
  }

    // Issue 객체 -> JSON으로 변환하는 메서드
    Map<String, dynamic> toJson() {
      return {
        'id': issueId,
        'title': title,
        'category': category,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'date': date.toIso8601String(), // DateTime을 ISO-8601 문자열로 변환
        'status': status,
        'verified': verified,
        'addr': addr,
      };
    }
}
class ShortVideo {
  final int issueId;
  final String link;
  final DateTime createdAt;

  ShortVideo({required this.issueId, required this.link, required this.createdAt});

  // JSON -> ShortVideo 객체로 변환하는 팩토리 메서드
  factory ShortVideo.fromJson(Map<String, dynamic> json) {
    return ShortVideo(
      issueId: json['issue_id'],
      link: json['link'],
      createdAt: DateTime.parse(json['createAt']),
    );
  }
}

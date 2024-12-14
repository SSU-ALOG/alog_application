class Message {
  final int msgSn; // 일련번호
  final String disasterType; // 재해구분명
  final String createDate; // 생성일시
  final String msgContent; // 메시지 내용
  final String regionName; // 수신지역명
  String emergencyStep; // 긴급단계명 (mutable)


  // 기본 생성자
  Message({
    required this.msgSn,
    required this.disasterType,
    required this.createDate,
    required this.msgContent,
    required this.regionName,
    required this.emergencyStep,
  });

  // 사용자 입력 기반 생성자
  Message.fromUserInput({
    required this.disasterType,
    required this.msgContent,
    required this.regionName,
    required this.emergencyStep,
  })  : msgSn = 0, // 기본값으로 0 설정 (사용자 제공하지 않음)
        createDate = DateTime.now().toIso8601String(); // 현재 시간을 ISO 8601 문자열로 설정


  // JSON -> Message 객체로 변환하는 팩토리 메서드
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      msgSn: json['msgSn'],
      disasterType: json['dstSeNm'],
      createDate: json['crtDt'],
      msgContent: json['msgCn'],
      regionName: json['rcptnRgnNm'],
      emergencyStep: json['emrgStepNm'],
    );
  }

  // Message 객체 -> JSON으로 변환하는 메서드
  Map<String, dynamic> toJson() {
    return {
      'sn': msgSn,
      'dst_se_nm': disasterType,
      'crt_dt': createDate,
      'msg_cn': msgContent,
      'rcptn_rgn_nm': regionName,
      'emrg_step_nm': emergencyStep,
    };
  }
}

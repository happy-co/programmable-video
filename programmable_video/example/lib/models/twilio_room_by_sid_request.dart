class TwilioRoomBySidRequest {
  final String sid;

  TwilioRoomBySidRequest({
    required this.sid,
  });

  factory TwilioRoomBySidRequest.fromMap(Map<String, dynamic> data) {
    return TwilioRoomBySidRequest(
      sid: data['sid'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sid': sid,
    };
  }
}

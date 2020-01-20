class TwilioRoomBySidRequest {
  final String sid;

  TwilioRoomBySidRequest({
    this.sid,
  });

  factory TwilioRoomBySidRequest.fromMap(Map<String, dynamic> data) {
    if (data == null) {
      return null;
    }
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

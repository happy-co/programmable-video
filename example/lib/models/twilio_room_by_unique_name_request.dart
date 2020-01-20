class TwilioRoomByUniqueNameRequest {
  final String uniqueName;

  TwilioRoomByUniqueNameRequest({
    this.uniqueName,
  });

  factory TwilioRoomByUniqueNameRequest.fromMap(Map<String, dynamic> data) {
    if (data == null) {
      return null;
    }
    return TwilioRoomByUniqueNameRequest(
      uniqueName: data['uniqueName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uniqueName': uniqueName,
    };
  }
}

class TwilioRoomByUniqueNameRequest {
  final String uniqueName;

  TwilioRoomByUniqueNameRequest({
    required this.uniqueName,
  });

  factory TwilioRoomByUniqueNameRequest.fromMap(Map<String, dynamic> data) {
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

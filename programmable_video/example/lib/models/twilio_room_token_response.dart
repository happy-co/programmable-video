class TwilioRoomTokenResponse {
  final String? uniqueName;
  final String identity;
  final String token;

  TwilioRoomTokenResponse({
    this.uniqueName,
    required this.identity,
    required this.token,
  });

  factory TwilioRoomTokenResponse.fromMap(Map<String, dynamic> data) {
    return TwilioRoomTokenResponse(
      uniqueName: data['uniqueName'],
      identity: data['identity'],
      token: data['token'],
    );
  }
}

class TwilioRoomTokenResponse {
  final String uniqueName;
  final String identity;
  final String token;

  TwilioRoomTokenResponse({
    this.uniqueName,
    this.identity,
    this.token,
  });

  factory TwilioRoomTokenResponse.fromMap(Map<String, dynamic> data) {
    if (data == null) {
      return null;
    }
    return TwilioRoomTokenResponse(
      uniqueName: data['uniqueName'],
      identity: data['identity'],
      token: data['token'],
    );
  }
}

class TwilioRoomTokenRequest {
  final String uniqueName;
  final String identity;

  TwilioRoomTokenRequest({
    required this.uniqueName,
    required this.identity,
  });

  Map<String, dynamic> toMap() {
    return {
      'uniqueName': uniqueName,
      'identity': identity,
    };
  }
}

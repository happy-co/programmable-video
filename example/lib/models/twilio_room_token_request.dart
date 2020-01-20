import 'package:flutter/foundation.dart';

class TwilioRoomTokenRequest {
  final String uniqueName;
  final String identity;

  TwilioRoomTokenRequest({
    @required this.uniqueName,
    @required this.identity,
  });

  factory TwilioRoomTokenRequest.fromMap(Map<String, dynamic> data) {
    if (data == null) {
      return null;
    }
    return TwilioRoomTokenRequest(
      uniqueName: data['uniqueName'],
      identity: data['identity'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uniqueName': uniqueName,
      'identity': identity,
    };
  }
}

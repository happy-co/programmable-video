import 'package:twilio_programmable_video_example/models/twilio_enums.dart';
import 'package:twilio_programmable_video_example/room/room_validators.dart';

class RoomModel with RoomValidators {
  final String? name;
  final bool isLoading;
  final bool isSubmitted;
  final String? token;
  final String? identity;
  final TwilioRoomType type;

  RoomModel({
    this.name,
    this.isLoading = false,
    this.isSubmitted = false,
    this.token,
    this.identity,
    this.type = TwilioRoomType.groupSmall,
  });

  static String getTypeText(TwilioRoomType type) {
    switch (type) {
      case TwilioRoomType.peerToPeer:
        return 'peer 2 peer';
      case TwilioRoomType.group:
        return 'large (max 50 participants)';
      case TwilioRoomType.groupSmall:
        return 'small (max 4 participants)';
    }
  }

  String? get nameErrorText {
    return isSubmitted && !nameValidator.isValid(name) ? invalidNameErrorText : null;
  }

  String get typeText {
    return RoomModel.getTypeText(type);
  }

  bool get canSubmit {
    return nameValidator.isValid(name);
  }

  RoomModel copyWith({
    String? name,
    bool? isLoading,
    bool? isSubmitted,
    String? token,
    String? identity,
    TwilioRoomType? type,
  }) {
    return RoomModel(
      name: name ?? this.name,
      token: token ?? this.token,
      identity: identity ?? this.identity,
      isLoading: isLoading ?? this.isLoading,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      type: type ?? this.type,
    );
  }
}

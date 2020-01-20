import 'package:twilio_unofficial_programmable_video_example/room/room_validators.dart';

class RoomModel with RoomValidators {
  final String name;
  final bool isLoading;
  final bool isSubmitted;
  final String token;
  final String identity;

  RoomModel({
    this.name,
    this.isLoading = false,
    this.isSubmitted = false,
    this.token,
    this.identity,
  });

  String get nameErrorText {
    return isSubmitted && !nameValidator.isValid(name) ? invalidNameErrorText : null;
  }

  bool get canSubmit {
    return nameValidator.isValid(name);
  }

  RoomModel copyWith({
    String name,
    bool isLoading,
    bool isSubmitted,
    String token,
    String identity,
  }) {
    return RoomModel(
      name: name ?? this.name,
      token: token ?? this.token,
      identity: identity ?? this.identity,
      isLoading: isLoading ?? this.isLoading,
      isSubmitted: isSubmitted ?? this.isSubmitted,
    );
  }
}

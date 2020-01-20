import 'package:twilio_unofficial_programmable_video_example/shared/validators/validators.dart';

mixin RoomValidators {
  final StringValidator nameValidator = NonEmptyStringValidator();
  final String invalidNameErrorText = 'Room name can\'t be empty';
}

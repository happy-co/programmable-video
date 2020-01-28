import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import 'package:flutter/services.dart';
import 'package:twilio_unofficial_programmable_video_example/models/twilio_enums.dart';
import 'package:twilio_unofficial_programmable_video_example/models/twilio_room_request.dart';
import 'package:twilio_unofficial_programmable_video_example/models/twilio_room_token_request.dart';
import 'package:twilio_unofficial_programmable_video_example/room/room_model.dart';
import 'package:twilio_unofficial_programmable_video_example/shared/services/backend_service.dart';
import 'package:twilio_unofficial_programmable_video_example/shared/services/platform_service.dart';

class RoomBloc {
  final BackendService backendService;

  final BehaviorSubject<RoomModel> _modelSubject = BehaviorSubject<RoomModel>.seeded(RoomModel());

  RoomBloc({@required this.backendService}) : assert(backendService != null);

  Stream<RoomModel> get modelStream => _modelSubject.stream;

  RoomModel get model => _modelSubject.value;

  void dispose() {
    _modelSubject.close();
  }

  Future<void> submit() async {
    updateWith(isSubmitted: true, isLoading: true);
    try {
      try {
        await backendService.createRoom(
          TwilioRoomRequest(
            uniqueName: model.name,
            type: model.type,
          ),
        );
      } on PlatformException catch (err) {
        if (err.code != 'functionsError' || err.details['message'] != 'Error: Room exists') {
          rethrow;
        }
      } catch (err) {
        rethrow;
      }
      final twilioRoomTokenResponse = await backendService.createToken(
        TwilioRoomTokenRequest(
          uniqueName: model.name,
          identity: await PlatformService.deviceId ?? 'noIdentity',
        ),
      );
      updateWith(
        token: twilioRoomTokenResponse.token,
        identity: twilioRoomTokenResponse.identity,
      );
    } catch (err) {
      rethrow;
    } finally {
      updateWith(isLoading: false);
    }
  }

  void updateName(String name) => updateWith(name: name);

  void updateType(TwilioRoomType type) => updateWith(type: type);

  void updateWith({
    String name,
    bool isLoading,
    bool isSubmitted,
    String token,
    String identity,
    TwilioRoomType type,
  }) {
    _modelSubject.value = model.copyWith(
      name: name,
      isLoading: isLoading,
      isSubmitted: isSubmitted,
      token: token,
      identity: identity,
      type: type,
    );
  }
}

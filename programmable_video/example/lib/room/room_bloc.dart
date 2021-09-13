import 'dart:async';

import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';
import 'package:twilio_programmable_video_example/debug.dart';
import 'package:twilio_programmable_video_example/models/twilio_enums.dart';
import 'package:twilio_programmable_video_example/models/twilio_room_request.dart';
import 'package:twilio_programmable_video_example/models/twilio_room_token_request.dart';
import 'package:twilio_programmable_video_example/room/room_model.dart';
import 'package:twilio_programmable_video_example/shared/services/backend_service.dart';
import 'package:twilio_programmable_video_example/shared/services/platform_service.dart';

class RoomBloc {
  final BackendService backendService;

  final BehaviorSubject<RoomModel> _modelSubject = BehaviorSubject<RoomModel>.seeded(RoomModel());
  final StreamController<bool> _loadingController = StreamController<bool>.broadcast();

  RoomBloc({required this.backendService});

  Stream<RoomModel> get modelStream => _modelSubject.stream;

  Stream<bool> get onLoading => _loadingController.stream;

  RoomModel get model => _modelSubject.value;

  void dispose() {
    _modelSubject.close();
    _loadingController.close();
  }

  Future<RoomModel> submit() async {
    updateWith(isSubmitted: true, isLoading: true);
    try {
      await _createRoom();
      await _createToken();
      return model;
    } catch (e) {
      try {
        await _createToken();
        return model;
      } catch (err) {
        rethrow;
      }
    } finally {
      updateWith(isLoading: false);
    }
  }

  Future<String> _getDeviceId() async {
    try {
      return await PlatformService.deviceId;
    } catch (err) {
      Debug.log(err);
      return DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  Future _createToken() async {
    final name = model.name;

    if (name != null) {
      final twilioRoomTokenResponse = await backendService.createToken(
        TwilioRoomTokenRequest(
          uniqueName: name,
          identity: await _getDeviceId(),
        ),
      );
      updateWith(
        token: twilioRoomTokenResponse.token,
        identity: twilioRoomTokenResponse.identity,
      );
    }
  }

  Future _createRoom() async {
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
  }

  void updateName(String name) => updateWith(name: name);

  void updateType(TwilioRoomType? type) => updateWith(type: type);

  void updateWith({
    String? name,
    bool? isLoading,
    bool? isSubmitted,
    String? token,
    String? identity,
    TwilioRoomType? type,
  }) {
    var raiseLoading = false;
    if (isLoading != null && _modelSubject.value.isLoading != isLoading) {
      raiseLoading = true;
    }
    _modelSubject.add(model.copyWith(
      name: name,
      isLoading: isLoading,
      isSubmitted: isSubmitted,
      token: token,
      identity: identity,
      type: type,
    ));

    if (raiseLoading) {
      _loadingController.add(_modelSubject.value.isLoading);
    }
  }
}

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

class MockInterface extends ProgrammableVideoPlatform {
  var setNativeDebugWasCalled = false;
  var nativeDebug;
  var setSpeakerPhoneOnWasCalled = false;
  var speakerPhoneOn;
  var getSpeakerPhoneOnWasCalled = false;
  var connectToRoomWasCalled = false;
  var enableAudioTrackWasCalled = false;
  var enableVideoTrackWasCalled = false;
  var switchCameraWasCalled = false;
  var hasTorchWasCalled = false;
  var torchEnabled = false;
  var sendMessageWasCalled = false;
  var sendBufferWasCalled = false;
  var disconnectWasCalled = false;

  @override
  Future<void> disconnect() {
    disconnectWasCalled = true;
    return Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Future<void> setNativeDebug(bool native) {
    setNativeDebugWasCalled = true;
    nativeDebug = native;
    return Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Stream<BaseCameraEvent> cameraStream() {
    return Stream<BaseCameraEvent>.periodic(Duration(seconds: 1));
  }

  @override
  Stream<dynamic> loggingStream() {
    return Stream<dynamic>.periodic(Duration(seconds: 1));
  }

  @override
  Future<bool> setSpeakerphoneOn(bool on) {
    setSpeakerPhoneOnWasCalled = true;
    speakerPhoneOn = on;
    return Future.delayed(Duration(milliseconds: 1), () => speakerPhoneOn);
  }

  @override
  Future<bool> getSpeakerphoneOn() {
    getSpeakerPhoneOnWasCalled = true;
    return Future.delayed(Duration(milliseconds: 1), () => speakerPhoneOn);
  }

  @override
  Future<int> connectToRoom(ConnectOptionsModel connectOptions) {
    connectToRoomWasCalled = true;
    return Future.delayed(Duration(milliseconds: 1), () => 1);
  }

  @override
  Future<bool> enableVideoTrack({bool enabled, String name}) {
    enableVideoTrackWasCalled = true;
    return Future.delayed(Duration(milliseconds: 1), () => enabled);
  }

  @override
  Future<bool> enableAudioTrack({bool enable, String name}) {
    enableAudioTrackWasCalled = true;
    return Future.delayed(Duration(milliseconds: 1), () => enable);
  }

  @override
  Future<void> sendMessage({String message, String name}) {
    sendMessageWasCalled = true;
    return Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Future<void> sendBuffer({ByteBuffer message, String name}) {
    sendBufferWasCalled = true;
    return Future.delayed(Duration(milliseconds: 1));
  }

  @override
  Future<CameraSource> switchCamera() async {
    switchCameraWasCalled = true;
    return Future.delayed(Duration(milliseconds: 1), () => CameraSource.FRONT_CAMERA);
  }

  @override
  Future<bool> hasTorch() async {
    hasTorchWasCalled = true;
    return Future.delayed(Duration(milliseconds: 1), () => true);
  }

  @override
  Future<void> setTorch(bool enable) async {
    torchEnabled = enable;
    return Future.delayed(Duration(milliseconds: 1), () {});
  }

  final _roomController = StreamController<BaseRoomEvent>();

  void addRoomEvent(BaseRoomEvent event) {
    _roomController.sink.add(event);
  }

  @override
  Stream<BaseRoomEvent> roomStream(int internalId) {
    return _roomController.stream;
  }

  final _localParticipantController = StreamController<BaseLocalParticipantEvent>();

  void addLocalParticipantEvent(BaseLocalParticipantEvent event) => _localParticipantController.sink.add(event);

  @override
  Stream<BaseLocalParticipantEvent> localParticipantStream(int internalId) {
    return _localParticipantController.stream;
  }

  final _remoteParticipantController = StreamController<BaseRemoteParticipantEvent>();

  void addRemoteParticipantEvent(BaseRemoteParticipantEvent event) => _remoteParticipantController.sink.add(event);

  @override
  Stream<BaseRemoteParticipantEvent> remoteParticipantStream(int internalId) {
    return _remoteParticipantController.stream;
  }

  final _remoteDataTrackController = StreamController<BaseRemoteDataTrackEvent>();

  void addRemoteDataTrackEvent(BaseRemoteDataTrackEvent event) => _remoteDataTrackController.sink.add(event);

  @override
  Stream<BaseRemoteDataTrackEvent> remoteDataTrackStream(int internalId) {
    return _remoteDataTrackController.stream;
  }
}

import 'dart:async';
import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/capturers/camera_event.dart';

import 'enums/enum_exports.dart';
import 'models/model_exports.dart';

export 'enums/enum_exports.dart';
export 'models/model_exports.dart';
export 'audio_codecs/audio_codec.dart';
export 'video_codecs/video_codec.dart';

import 'method_channel_programmable_video.dart';

/// The interface that implementations of programmable_video must implement.
///
/// Platform implementations should extend this class rather than implement it as `programmable_video`
/// does not consider newly added methods to be breaking changes. Extending this class
/// (using `extends`) ensures that the subclass will get the default implementation, while
/// platform implementations that `implements` this interface will be broken by newly added
/// [ProgrammableVideoPlatform] methods.
abstract class ProgrammableVideoPlatform extends PlatformInterface {
  /// Constructs a ProgrammableVideoPlatform.
  ProgrammableVideoPlatform() : super(token: _token);

  static final Object _token = Object();

  static ProgrammableVideoPlatform _instance = MethodChannelProgrammableVideo();

  /// The default instance of [ProgrammableVideoPlatform] to use.
  ///
  /// Defaults to [MethodChannelProgrammableVideo].
  static ProgrammableVideoPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [ProgrammableVideoPlatform] when they register themselves.
  static set instance(ProgrammableVideoPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  //#region Functions

  /// Calls native code to disconnect from a room.
  Future<void> disconnect() {
    throw UnimplementedError('disconnect() has not been implemented.');
  }

  /// You can listen to these logs on the [loggingStream].
  Future<void> setNativeDebug(bool native) {
    throw UnimplementedError('setNativeDebug() has not been implemented.');
  }

  /// Calls native code to set the speaker mode on or off.
  Future<bool> setSpeakerphoneOn(bool on) {
    throw UnimplementedError('setSpeakerphoneOn() has not been implemented.');
  }

  /// Calls native code to check if speaker mode is enabled.
  Future<bool> getSpeakerphoneOn() {
    throw UnimplementedError('getSpeakerphoneOn() has not been implemented.');
  }

  /// Calls native code to connect to a room.
  Future<int> connectToRoom(ConnectOptionsModel connectOptions) {
    throw UnimplementedError('connectToRoom() has not been implemented.');
  }

  /// Calls native code to set the state of the local video track.
  ///
  /// The results of this operation are signaled to other Participants in the same Room.
  /// When a video track is disabled, blank frames are sent in place of video frames from a video capturer.
  Future<bool> enableVideoTrack({bool enabled, String name}) {
    throw UnimplementedError('enableVideoTrack() has not been implemented.');
  }

  /// Calls native code to send a String message.
  Future<void> sendMessage({String message, String name}) {
    throw UnimplementedError('sendMessage() has not been implemented.');
  }

  /// Calls native code to send a ByteBuffer message.
  Future<void> sendBuffer({ByteBuffer message, String name}) {
    throw UnimplementedError('sendBuffer() has not been implemented.');
  }

  /// Calls native code to enable the LocalAudioTrack.
  Future<bool> enableAudioTrack({bool enable, String name}) {
    throw UnimplementedError('enableAudioTrack() has not been implemented.');
  }

  /// Calls native code to enable playback of the RemoteAudioTrack.
  Future<void> enableRemoteAudioTrack({bool enable, String sid}) {
    throw UnimplementedError('enableRemoteAudioTrack() has not been implemented.');
  }

  /// Calls native code to check if playback is enabled for the RemoteAudioTrack.
  Future<bool> isRemoteAudioTrackPlaybackEnabled(String sid) {
    throw UnimplementedError('isRemoteAudioTrackPlaybackEnabled() has not been implemented.');
  }

  /// Calls native code to switch the camera.
  Future<CameraSource> switchCamera() {
    throw UnimplementedError('switchCamera() has not been implemented.');
  }

  /// Calls native code to find if the active camera has a flash.
  Future<bool> hasTorch() {
    throw UnimplementedError('hasTorch() has not been implemented.');
  }

  /// Calls native code to change the torch state.
  Future<void> setTorch(bool enabled) {
    throw UnimplementedError('setTorch(bool enabled) has not been implemented.');
  }
  //#endregion

  //#region Streams

  /// Stream of the CameraEvent model.
  ///
  /// This stream is used to listen for async events after interactions with the camera.
  Stream<BaseCameraEvent> cameraStream() {
    throw UnimplementedError('cameraStream() has not been implemented');
  }

  /// Stream of the BaseRoomEvent model.
  ///
  /// This stream is used to update the Room in a plugin implementation.
  Stream<BaseRoomEvent> roomStream(int internalId) {
    throw UnimplementedError('roomStream() has not been implemented');
  }

  /// Stream of the BaseRemoteParticipantEvent model.
  ///
  /// This stream is used to update the RemoteParticipants in a plugin implementation.
  Stream<BaseRemoteParticipantEvent> remoteParticipantStream(int internalId) {
    throw UnimplementedError('remoteParticipantStream() has not been implemented');
  }

  /// Stream of the BaseLocalParticipantEvent model.
  ///
  /// This stream is used to update the LocalParticipant in a plugin implementation.
  Stream<BaseLocalParticipantEvent> localParticipantStream(int internalId) {
    throw UnimplementedError('localParticipantStream() has not been implemented');
  }

  /// Stream of the BaseRemoteDataTrackEvent model.
  ///
  /// This stream is used to update the RemoteDataTrack in a plugin implementation.
  Stream<BaseRemoteDataTrackEvent> remoteDataTrackStream(int internalId) {
    throw UnimplementedError('remoteDataTrackStream() has not been implemented');
  }

  /// Stream of dynamic that contains all the native logging output.
  Stream<dynamic> loggingStream() {
    throw UnimplementedError('loggingStream() has not been implemented');
  }
  //#endregion
}

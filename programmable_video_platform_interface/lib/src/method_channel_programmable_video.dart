import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:enum_to_string/enum_to_string.dart';

import 'enums/enum_exports.dart';
import 'models/model_exports.dart';
import 'programmable_video_platform_interface.dart';

/// An implementation of [ProgrammableVideoPlatform] that uses method channels.
class MethodChannelProgrammableVideo extends ProgrammableVideoPlatform {
  static const MethodChannel _methodChannel = MethodChannel('twilio_programmable_video');

  //#region Functions

  /// Calls native code to disconnect from a room.
  @override
  Future<void> disconnect() {
    return _methodChannel.invokeMethod('disconnect');
  }

  /// You can listen to these logs on the [loggingStream].
  @override
  Future<void> setNativeDebug(bool native) {
    return _methodChannel.invokeMethod('debug', {'native': native});
  }

  /// Calls native code to set the speaker mode on or off.
  @override
  Future<bool> setSpeakerphoneOn(bool on) {
    assert(on != null);
    return _methodChannel.invokeMethod('setSpeakerphoneOn', {'on': on});
  }

  /// Calls native code to check if speaker mode is enabled.
  @override
  Future<bool> getSpeakerphoneOn() {
    return _methodChannel.invokeMethod('getSpeakerphoneOn');
  }

  /// Calls native code to connect to a room.
  @override
  Future<int> connectToRoom(ConnectOptionsModel connectOptions) {
    return _methodChannel.invokeMethod('connect', connectOptions.toMap());
  }

  /// Calls native code to set the state of the local video track.
  ///
  /// The results of this operation are signaled to other Participants in the same Room.
  /// When a video track is disabled, blank frames are sent in place of video frames from a video capturer.
  @override
  Future<bool> enableVideoTrack({bool enabled, String name}) {
    return _methodChannel.invokeMethod('LocalVideoTrack#enable', <String, dynamic>{'name': name, 'enable': enabled});
  }

  /// Calls native code to send a ByteBuffer message.
  @override
  Future<void> sendMessage({String message, String name}) {
    return _methodChannel.invokeMethod('LocalDataTrack#sendString', <String, dynamic>{'name': name, 'message': message});
  }

  ///Calls native code to send a ByteBuffer message.
  @override
  Future<void> sendBuffer({ByteBuffer message, String name}) {
    // Platform Channel Data types don't support ByteBuffer at the moment, so we need to convert it to
    // a data type the channels do understand (https://flutter.dev/docs/development/platform-integration/platform-channels#codec).
    return _methodChannel.invokeMethod('LocalDataTrack#sendByteBuffer', <String, dynamic>{'name': name, 'message': message.asUint8List()});
  }

  /// Calls native code to enable the LocalAudioTrack.
  @override
  Future<bool> enableAudioTrack({bool enable, String name}) {
    return _methodChannel.invokeMethod('LocalAudioTrack#enable', <String, dynamic>{'name': name, 'enable': enable});
  }

  ///Calls native code to switch the camera.
  @override
  Future<CameraSource> switchCamera() async {
    final methodData = await MethodChannel('twilio_programmable_video').invokeMethod('CameraCapturer#switchCamera');

    return EnumToString.fromString(CameraSource.values, methodData['cameraSource']);
  }
  //#endregion

  //#region roomStream
  /// EventChannel over which the native code sends updates concerning the Room.
  final roomChannel = EventChannel('twilio_programmable_video/room');

  Stream<BaseRoomEvent> _roomStream;

  /// Stream of the BaseRoomEvent model.
  ///
  /// This stream is used to update the Room in a plugin implementation.
  @override
  Stream<BaseRoomEvent> roomStream(int internalId) {
    _roomStream ??= roomChannel.receiveBroadcastStream(internalId).map(parseRoomEvent);
    return _roomStream;
  }

  /// Parses a map send from native code to a [BaseRoomEvent].
  BaseRoomEvent parseRoomEvent(dynamic event) {
    final String eventName = event['name'];
    final data = Map<String, dynamic>.from(event['data']);
    // If no room data is received, skip the event.
    if (data['room'] == null) return SkipAbleRoomEvent();

    final roomMap = Map<String, dynamic>.from(data['room']);

    LocalParticipantModel localParticipant;
    if (roomMap['localParticipant'] != null) {
      localParticipant = LocalParticipantModel.fromEventChannelMap(Map<String, dynamic>.from(roomMap['localParticipant']));
    }

    final remoteParticipants = <RemoteParticipantModel>[];
    if (roomMap['remoteParticipants'] != null) {
      final List<Map<String, dynamic>> remoteParticipantsList = roomMap['remoteParticipants'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();

      for (final remoteParticipantMap in remoteParticipantsList) {
        remoteParticipants.add(RemoteParticipantModel.fromEventChannelMap(remoteParticipantMap));
      }
    }

    RemoteParticipantModel dominantSpeaker;
    if (roomMap['dominantSpeaker'] != null) {
      final dominantSpeakerMap = Map<String, dynamic>.from(roomMap['dominantSpeaker']);
      dominantSpeaker = RemoteParticipantModel.fromEventChannelMap(dominantSpeakerMap);
    }

    RemoteParticipantModel remoteParticipant;
    if (data['remoteParticipant'] != null) {
      final remoteParticipantMap = Map<String, dynamic>.from(data['remoteParticipant']);
      remoteParticipant = RemoteParticipantModel.fromEventChannelMap(remoteParticipantMap);
    }

    TwilioExceptionModel twilioException;
    if (event['error'] != null) {
      final errorMap = Map<String, dynamic>.from(event['error'] as Map<dynamic, dynamic>);
      twilioException = TwilioExceptionModel(errorMap['code'] as int, errorMap['message']);
    }

    Region mediaRegion;
    if (roomMap['mediaRegion'] != null) {
      mediaRegion = EnumToString.fromString(Region.values, roomMap['mediaRegion']);
    }

    final roomModel =
        RoomModel(name: roomMap['name'], sid: roomMap['sid'], mediaRegion: mediaRegion, state: EnumToString.fromString(RoomState.values, roomMap['state']), localParticipant: localParticipant, remoteParticipants: remoteParticipants);

    switch (eventName) {
      case 'connectFailure':
        return ConnectFailure(roomModel, twilioException);
        break;
      case 'connected':
        return Connected(roomModel);
        break;
      case 'disconnected':
        return Disconnected(roomModel, twilioException);
        break;
      case 'participantConnected':
        return ParticipantConnected(roomModel, remoteParticipant);
        break;
      case 'participantDisconnected':
        return ParticipantDisconnected(roomModel, remoteParticipant);
        break;
      case 'reconnected':
        return Reconnected(roomModel);
        break;
      case 'reconnecting':
        return Reconnecting(roomModel, twilioException);
        break;
      case 'recordingStarted':
        return RecordingStarted(roomModel);
        break;
      case 'recordingStopped':
        return RecordingStopped(roomModel);
        break;
      case 'dominantSpeakerChanged':
        return DominantSpeakerChanged(roomModel, dominantSpeaker);
        break;
      default:
        return SkipAbleRoomEvent();
        break;
    }
  }
  //#endregion

  //#region remoteParticipantStream

  /// EventChannel over which the native code sends updates concerning the RemoteParticipants.
  final remoteParticipantChannel = EventChannel('twilio_programmable_video/remote');

  Stream<BaseRemoteParticipantEvent> _remoteParticipantStream;

  /// Stream of the BaseRemoteParticipantEvent model.
  ///
  /// This stream is used to update the RemoteParticipants in a plugin implementation.
  @override
  Stream<BaseRemoteParticipantEvent> remoteParticipantStream(int internalId) {
    _remoteParticipantStream ??= remoteParticipantChannel.receiveBroadcastStream(internalId).map(parseRemoteParticipantEvent);
    return _remoteParticipantStream;
  }

  /// Parses a map send from native code to a [BaseRemoteParticipantEvent].
  BaseRemoteParticipantEvent parseRemoteParticipantEvent(dynamic event) {
    final eventName = event['name'];
    final data = Map<String, dynamic>.from(event['data']);

    // If no remoteParticipant data is received, skip the event.
    if (data['remoteParticipant'] == null) {
      return SkipAbleRemoteParticipantEvent();
    }
    final remoteParticipantMap = Map<String, dynamic>.from(data['remoteParticipant']);
    final remoteParticipantModel = RemoteParticipantModel.fromEventChannelMap(remoteParticipantMap);

    RemoteAudioTrackPublicationModel remoteAudioTrackPublicationModel;
    if (data['remoteAudioTrackPublication'] != null) {
      final remoteAudioTrackPublicationMap = Map<String, dynamic>.from(data['remoteAudioTrackPublication']);
      remoteAudioTrackPublicationModel = RemoteAudioTrackPublicationModel.fromEventChannelMap(remoteAudioTrackPublicationMap);
    }

    RemoteAudioTrackModel remoteAudioTrackModel;
    if (['audioTrackSubscribed', 'audioTrackUnsubscribed', 'audioTrackEnabled', 'audioTrackDisabled'].contains(eventName)) {
      assert(remoteAudioTrackPublicationModel != null);
      remoteAudioTrackModel = remoteAudioTrackPublicationModel.remoteAudioTrack;
      if (remoteAudioTrackModel == null) {
        final remoteAudioTrackMap = Map<String, dynamic>.from(data['remoteAudioTrack']);
        remoteAudioTrackModel = RemoteAudioTrackModel.fromEventChannelMap(remoteAudioTrackMap);
      }
    }

    RemoteDataTrackPublicationModel remoteDataTrackPublicationModel;
    if (data['remoteDataTrackPublication'] != null) {
      final remoteDataTrackPublicationMap = Map<String, dynamic>.from(data['remoteDataTrackPublication']);
      remoteDataTrackPublicationModel = RemoteDataTrackPublicationModel.fromEventChannelMap(remoteDataTrackPublicationMap);
    }

    RemoteDataTrackModel remoteDataTrackModel;
    if (['dataTrackSubscribed', 'dataTrackUnsubscribed'].contains(eventName)) {
      assert(remoteDataTrackPublicationModel != null);
      remoteDataTrackModel = remoteDataTrackPublicationModel.remoteDataTrack;
      if (remoteDataTrackModel == null) {
        final remoteDataTrackMap = Map<String, dynamic>.from(data['remoteDataTrack']);
        remoteDataTrackModel = RemoteDataTrackModel.fromEventChannelMap(remoteDataTrackMap);
      }
    }

    RemoteVideoTrackPublicationModel remoteVideoTrackPublicationModel;
    if (data['remoteVideoTrackPublication'] != null) {
      final remoteVideoTrackPublicationMap = Map<String, dynamic>.from(data['remoteVideoTrackPublication']);
      remoteVideoTrackPublicationModel = RemoteVideoTrackPublicationModel.fromEventChannelMap(remoteVideoTrackPublicationMap);
    }

    RemoteVideoTrackModel remoteVideoTrackModel;
    if (['videoTrackSubscribed', 'videoTrackUnsubscribed', 'videoTrackEnabled', 'videoTrackDisabled'].contains(eventName)) {
      assert(remoteVideoTrackPublicationModel != null);
      remoteVideoTrackModel = remoteVideoTrackPublicationModel.remoteVideoTrack;
      if (remoteVideoTrackModel == null) {
        final remoteVideoTrackMap = Map<String, dynamic>.from(data['remoteVideoTrack']);
        remoteVideoTrackModel = RemoteVideoTrackModel.fromEventChannelMap(remoteVideoTrackMap);
      }
    }

    TwilioExceptionModel twilioException;
    if (event['error'] != null) {
      final errorMap = Map<String, dynamic>.from(event['error'] as Map<dynamic, dynamic>);
      twilioException = TwilioExceptionModel(errorMap['code'] as int, errorMap['message']);
    }

    switch (eventName) {
      case 'audioTrackDisabled':
        assert(remoteAudioTrackPublicationModel != null);
        return RemoteAudioTrackDisabled(remoteParticipantModel, remoteAudioTrackPublicationModel);
        break;
      case 'audioTrackEnabled':
        assert(remoteAudioTrackPublicationModel != null);
        return RemoteAudioTrackEnabled(remoteParticipantModel, remoteAudioTrackPublicationModel);
        break;
      case 'audioTrackPublished':
        assert(remoteAudioTrackPublicationModel != null);
        return RemoteAudioTrackPublished(remoteParticipantModel, remoteAudioTrackPublicationModel);
        break;
      case 'audioTrackSubscribed':
        assert(remoteAudioTrackPublicationModel != null);
        assert(remoteAudioTrackModel != null);
        return RemoteAudioTrackSubscribed(remoteParticipantModel: remoteParticipantModel, remoteAudioTrackPublicationModel: remoteAudioTrackPublicationModel, remoteAudioTrackModel: remoteAudioTrackModel);
        break;
      case 'audioTrackSubscriptionFailed':
        assert(remoteAudioTrackPublicationModel != null);
        assert(twilioException != null);
        return RemoteAudioTrackSubscriptionFailed(remoteParticipantModel: remoteParticipantModel, remoteAudioTrackPublicationModel: remoteAudioTrackPublicationModel, exception: twilioException);
        break;
      case 'audioTrackUnpublished':
        assert(remoteAudioTrackPublicationModel != null);
        return RemoteAudioTrackUnpublished(remoteParticipantModel, remoteAudioTrackPublicationModel);
        break;
      case 'audioTrackUnsubscribed':
        assert(remoteAudioTrackPublicationModel != null);
        assert(remoteAudioTrackModel != null);
        return RemoteAudioTrackUnsubscribed(remoteParticipantModel: remoteParticipantModel, remoteAudioTrackPublicationModel: remoteAudioTrackPublicationModel, remoteAudioTrackModel: remoteAudioTrackModel);
        break;
      case 'dataTrackPublished':
        assert(remoteDataTrackPublicationModel != null);
        return RemoteDataTrackPublished(remoteParticipantModel, remoteDataTrackPublicationModel);
        break;
      case 'dataTrackSubscribed':
        assert(remoteDataTrackPublicationModel != null);
        assert(remoteDataTrackModel != null);
        return RemoteDataTrackSubscribed(remoteParticipantModel: remoteParticipantModel, remoteDataTrackPublicationModel: remoteDataTrackPublicationModel, remoteDataTrackModel: remoteDataTrackModel);
        break;
      case 'dataTrackSubscriptionFailed':
        assert(remoteDataTrackPublicationModel != null);
        assert(twilioException != null);
        return RemoteDataTrackSubscriptionFailed(remoteParticipantModel: remoteParticipantModel, remoteDataTrackPublicationModel: remoteDataTrackPublicationModel, exception: twilioException);
        break;
      case 'dataTrackUnpublished':
        assert(remoteDataTrackPublicationModel != null);
        return RemoteDataTrackUnpublished(remoteParticipantModel, remoteDataTrackPublicationModel);
        break;
      case 'dataTrackUnsubscribed':
        assert(remoteDataTrackPublicationModel != null);
        assert(remoteDataTrackModel != null);
        return RemoteDataTrackUnsubscribed(remoteParticipantModel: remoteParticipantModel, remoteDataTrackPublicationModel: remoteDataTrackPublicationModel, remoteDataTrackModel: remoteDataTrackModel);
        break;
      case 'videoTrackDisabled':
        assert(remoteVideoTrackPublicationModel != null);
        return RemoteVideoTrackDisabled(remoteParticipantModel, remoteVideoTrackPublicationModel);
        break;
      case 'videoTrackEnabled':
        assert(remoteVideoTrackPublicationModel != null);
        return RemoteVideoTrackEnabled(remoteParticipantModel, remoteVideoTrackPublicationModel);
        break;
      case 'videoTrackPublished':
        assert(remoteVideoTrackPublicationModel != null);
        return RemoteVideoTrackPublished(remoteParticipantModel, remoteVideoTrackPublicationModel);
        break;
      case 'videoTrackSubscribed':
        assert(remoteVideoTrackPublicationModel != null);
        assert(remoteVideoTrackModel != null);
        return RemoteVideoTrackSubscribed(remoteParticipantModel: remoteParticipantModel, remoteVideoTrackPublicationModel: remoteVideoTrackPublicationModel, remoteVideoTrackModel: remoteVideoTrackModel);
        break;
      case 'videoTrackSubscriptionFailed':
        assert(remoteVideoTrackPublicationModel != null);
        assert(twilioException != null);
        return RemoteVideoTrackSubscriptionFailed(remoteParticipantModel: remoteParticipantModel, remoteVideoTrackPublicationModel: remoteVideoTrackPublicationModel, exception: twilioException);
        break;
      case 'videoTrackUnpublished':
        assert(remoteVideoTrackPublicationModel != null);
        return RemoteVideoTrackUnpublished(remoteParticipantModel, remoteVideoTrackPublicationModel);
        break;
      case 'videoTrackUnsubscribed':
        assert(remoteVideoTrackPublicationModel != null);
        assert(remoteVideoTrackModel != null);
        return RemoteVideoTrackUnsubscribed(remoteParticipantModel: remoteParticipantModel, remoteVideoTrackPublicationModel: remoteVideoTrackPublicationModel, remoteVideoTrackModel: remoteVideoTrackModel);
        break;
      default:
        return SkipAbleRemoteParticipantEvent();
        break;
    }
  }
  //#endregion

  //#region localParticipantStream

  /// EventChannel over which the native code sends updates concerning the LocalParticipant.
  final localParticipantChannel = EventChannel('twilio_programmable_video/local');

  Stream<BaseLocalParticipantEvent> _localParticipantStream;

  /// Stream of the BaseLocalParticipantEvent model.
  ///
  /// This stream is used to update the LocalParticipant in a plugin implementation.
  @override
  Stream<BaseLocalParticipantEvent> localParticipantStream(int internalId) {
    _localParticipantStream ??= localParticipantChannel.receiveBroadcastStream(internalId).map(parseLocalParticipantEvent);
    return _localParticipantStream;
  }

  /// Parses a map send from native code to a [BaseLocalParticipantEvent].
  BaseLocalParticipantEvent parseLocalParticipantEvent(dynamic event) {
    final data = Map<String, dynamic>.from(event['data']);
    // If no localParticipant data is received, skip the event.
    if (data['localParticipant'] == null) return SkipAbleLocalParticipantEvent();

    final localParticipantModel = LocalParticipantModel.fromEventChannelMap(Map<String, dynamic>.from(data['localParticipant']));

    final String eventName = event['name'];

    LocalAudioTrackPublicationModel localAudioTrackPublication;
    if (data['localAudioTrackPublication'] != null) {
      final localAudioTrackPublicationMap = Map<String, dynamic>.from(data['localAudioTrackPublication']);
      localAudioTrackPublication = LocalAudioTrackPublicationModel.fromEventChannelMap(localAudioTrackPublicationMap);
    }

    TrackModel localAudioTrack;
    if (data['localAudioTrack'] != null) {
      final map = Map<String, dynamic>.from(data['localAudioTrack']);
      localAudioTrack = TrackModel.fromEventChannelMap(map);
    }

    LocalDataTrackPublicationModel localDataTrackPublication;
    if (data['localDataTrackPublication'] != null) {
      final map = Map<String, dynamic>.from(data['localDataTrackPublication']);
      localDataTrackPublication = LocalDataTrackPublicationModel.fromEventChannelMap(map);
    }

    DataTrackModel localDataTrack;
    if (data['localDataTrack'] != null) {
      final map = Map<String, dynamic>.from(data['localDataTrack']);
      localDataTrack = DataTrackModel.fromEventChannelMap(map);
    }

    LocalVideoTrackPublicationModel localVideoTrackPublication;
    if (data['localVideoTrackPublication'] != null) {
      final map = Map<String, dynamic>.from(data['localVideoTrackPublication']);
      localVideoTrackPublication = LocalVideoTrackPublicationModel.fromEventChannelMap(map);
    }

    LocalVideoTrackModel localVideoTrack;
    if (data['localVideoTrack'] != null) {
      final map = Map<String, dynamic>.from(data['localVideoTrack']);
      localVideoTrack = LocalVideoTrackModel.fromEventChannelMap(map);
    }

    TwilioExceptionModel twilioException;
    if (event['error'] != null) {
      final errorMap = Map<String, dynamic>.from(event['error'] as Map<dynamic, dynamic>);
      twilioException = TwilioExceptionModel(errorMap['code'] as int, errorMap['message']);
    }

    switch (eventName) {
      case 'audioTrackPublished':
        return LocalAudioTrackPublished(localParticipantModel, localAudioTrackPublication);
        break;
      case 'audioTrackPublicationFailed':
        return LocalAudioTrackPublicationFailed(localAudioTrack: localAudioTrack, exception: twilioException, localParticipantModel: localParticipantModel);
        break;
      case 'dataTrackPublished':
        return LocalDataTrackPublished(localParticipantModel, localDataTrackPublication);
        break;
      case 'dataTrackPublicationFailed':
        return LocalDataTrackPublicationFailed(localDataTrack: localDataTrack, exception: twilioException, localParticipantModel: localParticipantModel);
        break;
      case 'videoTrackPublished':
        return LocalVideoTrackPublished(localParticipantModel, localVideoTrackPublication);
        break;
      case 'videoTrackPublicationFailed':
        return LocalVideoTrackPublicationFailed(localVideoTrack: localVideoTrack, exception: twilioException, localParticipantModel: localParticipantModel);
        break;
      default:
        return SkipAbleLocalParticipantEvent();
        break;
    }
  }
  //#endregion

  //#region remoteDataTrackStream

  /// EventChannel over which the native code sends updates concerning the RemoteDataTrack.
  final remoteDataTrackChannel = EventChannel('twilio_programmable_video/remote_data_track');

  Stream<BaseRemoteDataTrackEvent> _remoteDataTrackStream;

  /// Stream of the BaseRemoteDataTrackEvent model.
  ///
  /// This stream is used to update the RemoteDataTrack in a plugin implementation.
  @override
  Stream<BaseRemoteDataTrackEvent> remoteDataTrackStream(int internalId) {
    _remoteDataTrackStream ??= remoteDataTrackChannel.receiveBroadcastStream(internalId).map(parseRemoteDataTrackEvent);
    return _remoteDataTrackStream;
  }

  /// Parses a map send from native code to a [BaseRemoteDataTrackEvent].
  BaseRemoteDataTrackEvent parseRemoteDataTrackEvent(dynamic event) {
    final eventName = event['name'];
    final data = Map<String, dynamic>.from(event['data']);
    // If no RemoteDataTrack data is received, skip the event.
    if (data['remoteDataTrack'] == null) {
      return SkipAbleRemoteDataTrackEvent();
    }
    final remoteDataTrackModel = RemoteDataTrackModel.fromEventChannelMap(data['remoteDataTrack']);
    switch (eventName) {
      case 'stringMessage':
        return StringMessage(remoteDataTrackModel, data['message'] as String);
        break;
      case 'bufferMessage':
        // Although data['message'] technically is of type Uint8List, we still need to create a new
        // `Uint8List.fromList(data['message']` in order to get the buffer output right.
        //
        // If we directly get the buffer from data['message'] in either one of the following ways,
        // the buffer contains wrong data! Don't know why, but it does...
        //
        // - data['message'].buffer
        // - (data['message'] as Uint8List).buffer
        //
        return BufferMessage(remoteDataTrackModel, Uint8List.fromList(data['message']).buffer);
        break;
      default:
        return UnknownEvent(remoteDataTrackModel, eventName);
        break;
    }
  }
  //#endregion

  /// Stream of dynamic that contains all the native logging output.
  @override
  Stream<dynamic> loggingStream() {
    return EventChannel('twilio_programmable_video/logging').receiveBroadcastStream();
  }
}

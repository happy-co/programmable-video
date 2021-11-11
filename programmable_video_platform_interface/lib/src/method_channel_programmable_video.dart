import 'dart:async';
import 'dart:typed_data';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/capturers/camera_event.dart';
import 'package:twilio_programmable_video_platform_interface/src/camera_source.dart';

import 'enums/enum_exports.dart';
import 'models/local_participant/local_participant_event.dart';
import 'models/model_exports.dart';
import 'programmable_video_platform_interface.dart';

/// An implementation of [ProgrammableVideoPlatform] that uses method channels.
class MethodChannelProgrammableVideo extends ProgrammableVideoPlatform {
  /// Constructs a MethodChannelProgrammableVideo.
  MethodChannelProgrammableVideo()
      : _methodChannel = MethodChannel('twilio_programmable_video'),
        _cameraChannel = EventChannel('twilio_programmable_video/camera'),
        _roomChannel = EventChannel('twilio_programmable_video/room'),
        _remoteParticipantChannel = EventChannel('twilio_programmable_video/remote'),
        _localParticipantChannel = EventChannel('twilio_programmable_video/local'),
        _remoteDataTrackChannel = EventChannel('twilio_programmable_video/remote_data_track'),
        _audioNotificationChannel = EventChannel('twilio_programmable_video/audio_notification'),
        _loggingChannel = EventChannel('twilio_programmable_video/logging'),
        super();

  /// This constructor is only used for testing and shouldn't be accessed by
  /// users of the plugin. It may break or change at any time.
  @visibleForTesting
  MethodChannelProgrammableVideo.private(
    this._methodChannel,
    this._cameraChannel,
    this._roomChannel,
    this._remoteParticipantChannel,
    this._localParticipantChannel,
    this._remoteDataTrackChannel,
    this._audioNotificationChannel,
    this._loggingChannel,
  );

  //#region Functions

  final MethodChannel _methodChannel;

  /// Calls native code to disconnect from a room.
  @override
  Future<void> disconnect() {
    return _methodChannel.invokeMethod('disconnect');
  }

  /// You can listen to these logs on the [loggingStream].
  @override
  Future<void> setNativeDebug(bool native, bool audio) {
    return _methodChannel.invokeMethod(
      'debug',
      {
        'native': native,
        'audio': audio,
      },
    );
  }

  /// Calls native code to set the speaker mode on or off.
  @Deprecated('Use setAudioSettings for more reliable audio output management.')
  @override
  Future<bool?> setSpeakerphoneOn(bool on) {
    return _methodChannel.invokeMethod(
      'setSpeakerphoneOn',
      {
        'on': on,
      },
    );
  }

  /// Calls native code to set the speaker and bluetooth settings.
  /// The native layer will then observe changes to audio state and apply
  /// these settings as needed.
  ///
  /// Bluetooth is given priority over speakers.
  /// In short, if:
  /// `speakerphoneEnabled == true && bluetoothEnabled == true`
  /// and a bluetooth device is connected, it will be used.
  /// If no bluetooth device is connected, the speaker will be used.
  ///
  /// if:
  /// `speakerphoneEnabled == true && bluetoothEnabled == false`
  /// and a bluetooth device is connected, the speaker will be used.
  ///
  /// if: `speakerphoneEnabled == false && bluetoothEnabled == false`
  /// The receiver, if the device has one, will be used.
  /// If there is a wired headset connected to an android device in this
  /// scenario, it will be used.
  @override
  Future setAudioSettings(bool speakerphoneEnabled, bool bluetoothPreferred) {
    return _methodChannel.invokeMethod(
      'setAudioSettings',
      {
        'speakerphoneEnabled': speakerphoneEnabled,
        'bluetoothPreferred': bluetoothPreferred,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> getAudioSettings() async {
    final result = await _methodChannel.invokeMethod('getAudioSettings', null);
    return Map<String, dynamic>.from(result);
  }

  /// Calls native code to reset the speaker and bluetooth settings to their default values.
  /// The native layer will stop observing and managing changes to audio state.
  /// Default values are:
  /// `speakerphoneEnabled = true`
  /// `bluetoothEnabled = true`
  @override
  Future disableAudioSettings() {
    return _methodChannel.invokeMethod('disableAudioSettings', null);
  }

  /// Calls native code to check if speaker mode is enabled.
  @Deprecated('Use getAudioSettings for more reliable audio output management.')
  @override
  Future<bool?> getSpeakerphoneOn() {
    return _methodChannel.invokeMethod('getSpeakerphoneOn');
  }

  /// Calls native code to get stats.
  @override
  Future<Map<dynamic, dynamic>?> getStats() async {
    return _methodChannel.invokeMethod('getStats');
  }

  @override
  Future<bool> deviceHasReceiver() async {
    return await _methodChannel.invokeMethod('deviceHasReceiver');
  }

  /// Calls native code to connect to a room.
  @override
  Future<int?> connectToRoom(ConnectOptionsModel connectOptions) {
    return _methodChannel.invokeMethod('connect', connectOptions.toMap());
  }

  /// Calls native code to set the state of the local video track.
  ///
  /// The results of this operation are signaled to other Participants in the same Room.
  /// When a video track is disabled, blank frames are sent in place of video frames from a video capturer.
  @override
  Future<bool?> enableVideoTrack(bool enabled, String name) {
    return _methodChannel.invokeMethod(
      'LocalVideoTrack#enable',
      <String, dynamic>{
        'name': name,
        'enable': enabled,
      },
    );
  }

  /// Calls native code to send a String message.
  @override
  Future<void> sendMessage(String message, String name) {
    return _methodChannel.invokeMethod(
      'LocalDataTrack#sendString',
      <String, dynamic>{
        'name': name,
        'message': message,
      },
    );
  }

  /// Calls native code to send a ByteBuffer message.
  @override
  Future<void> sendBuffer(ByteBuffer message, String name) {
    // Platform Channel Data types don't support ByteBuffer at the moment, so we need to convert it to
    // a data type the channels do understand (https://flutter.dev/docs/development/platform-integration/platform-channels#codec).
    return _methodChannel.invokeMethod(
      'LocalDataTrack#sendByteBuffer',
      <String, dynamic>{
        'name': name,
        'message': message.asUint8List(),
      },
    );
  }

  /// Calls native code to enable the LocalAudioTrack.
  @override
  Future<bool?> enableAudioTrack(bool enable, String name) {
    return _methodChannel.invokeMethod(
      'LocalAudioTrack#enable',
      <String, dynamic>{
        'name': name,
        'enable': enable,
      },
    );
  }

  /// Calls native code to enable playback of the RemoteAudioTrack.
  @override
  Future<void> enableRemoteAudioTrack(bool enable, String sid) {
    return _methodChannel.invokeMethod(
      'RemoteAudioTrack#enablePlayback',
      <String, dynamic>{
        'sid': sid,
        'enable': enable,
      },
    );
  }

  /// Calls native code to check if playback is enabled for the RemoteAudioTrack.
  @override
  Future<bool?> isRemoteAudioTrackPlaybackEnabled(String sid) {
    return _methodChannel.invokeMethod(
      'RemoteAudioTrack#isPlaybackEnabled',
      <String, dynamic>{
        'sid': sid,
      },
    );
  }

  @override
  Future<List<CameraSource>> getSources() async {
    List<Object?> methodData = await _methodChannel.invokeMethod(
      'CameraSource#getSources',
      null,
    );
    return methodData.map((dynamic source) => CameraSource.fromMap(Map<String, dynamic>.from(source))).toList();
  }

  /// Calls native code to switch the camera.
  ///
  /// Returns the new camera source.
  @override
  Future<CameraSource> switchCamera(CameraSource source) async {
    final methodData = await _methodChannel.invokeMethod('CameraCapturer#switchCamera', <String, dynamic>{
      'cameraId': source.cameraId,
    });

    return CameraSource.fromMap(Map<String, dynamic>.from(methodData['source']));
  }

  /// Calls native code to change the torch state.
  @override
  Future<void> setTorch(bool enable) async {
    await _methodChannel.invokeMethod('CameraCapturer#setTorch', <String, dynamic>{
      'enable': enable,
    });
  }

//#endregion

//#region cameraStream
  /// EventChannel over which the native code sends updates concerning the Room.
  final EventChannel _cameraChannel;

  Stream<BaseCameraEvent>? _cameraStream;

  /// Stream of the BaseRoomEvent model.
  ///
  /// This stream is used to update the Room in a plugin implementation.
  @override
  Stream<BaseCameraEvent> cameraStream() {
    _cameraStream ??= _cameraChannel.receiveBroadcastStream().map(_parseCameraEvent);
    return _cameraStream!;
  }

  BaseCameraEvent _parseCameraEvent(dynamic event) {
    final String? eventName = event['name'];
    final data = Map<String, dynamic>.from(event['data']);
    final sourceData = data['capturer']['source'];
    if (sourceData != null && sourceData['cameraId'] != null) {
      final model = CameraCapturerModel(
        CameraSource.fromMap(Map<String, dynamic>.from(sourceData)),
        data['capturer']['type'],
      );

      switch (eventName) {
        case 'cameraSwitched':
          return CameraSwitched(model);
        case 'firstFrameAvailable':
          return FirstFrameAvailable(model);
        case 'cameraError':
          late TwilioExceptionModel twilioException;
          if (event['error'] != null) {
            final errorMap = Map<String, dynamic>.from(event['error'] as Map<dynamic, dynamic>);
            twilioException = TwilioExceptionModel(errorMap['code'] as int, errorMap['message']);
          }
          return CameraError(model, twilioException);
        default:
      }
    }

    return SkippableCameraEvent();
  }

//#endregion

//#region roomStream
  /// EventChannel over which the native code sends updates concerning the Room.
  final EventChannel _roomChannel;

  Stream<BaseRoomEvent>? _roomStream;

  /// Stream of the BaseRoomEvent model.
  ///
  /// This stream is used to update the Room in a plugin implementation.
  @override
  Stream<BaseRoomEvent> roomStream(int internalId) {
    _roomStream ??= _roomChannel.receiveBroadcastStream(internalId).map(_parseRoomEvent);
    return _roomStream!;
  }

  /// Parses a map send from native code to a [BaseRoomEvent].
  BaseRoomEvent _parseRoomEvent(dynamic event) {
    final eventName = event['name'];
    final data = Map<String, dynamic>.from(event['data']);

    // If no room data is received, skip the event.
    final room = data['room'];
    if (room == null) return SkippableRoomEvent();

    final roomMap = Map<String, dynamic>.from(room);

    LocalParticipantModel? localParticipant;
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

    RemoteParticipantModel? dominantSpeaker;
    if (roomMap['dominantSpeaker'] != null) {
      final dominantSpeakerMap = Map<String, dynamic>.from(roomMap['dominantSpeaker']);
      dominantSpeaker = RemoteParticipantModel.fromEventChannelMap(dominantSpeakerMap);
    }

    late RemoteParticipantModel remoteParticipant;
    if (data['remoteParticipant'] != null) {
      final remoteParticipantMap = Map<String, dynamic>.from(data['remoteParticipant']);
      remoteParticipant = RemoteParticipantModel.fromEventChannelMap(remoteParticipantMap);
    }

    TwilioExceptionModel? twilioException;
    if (event['error'] != null) {
      final errorMap = Map<String, dynamic>.from(event['error'] as Map<dynamic, dynamic>);
      twilioException = TwilioExceptionModel(errorMap['code'] as int, errorMap['message']);
    }

    Region? mediaRegion;
    if (roomMap['mediaRegion'] != null) {
      mediaRegion = EnumToString.fromString(Region.values, roomMap['mediaRegion']);
    }

    final roomModel = RoomModel(
      name: roomMap['name'],
      sid: roomMap['sid'],
      mediaRegion: mediaRegion,
      state: EnumToString.fromString(RoomState.values, roomMap['state'])!,
      localParticipant: localParticipant,
      remoteParticipants: remoteParticipants,
    );

    switch (eventName) {
      case 'connectFailure':
        return ConnectFailure(roomModel, twilioException);
      case 'connected':
        return Connected(roomModel);
      case 'disconnected':
        return Disconnected(roomModel, twilioException);
      case 'participantConnected':
        return ParticipantConnected(roomModel, remoteParticipant);
      case 'participantDisconnected':
        return ParticipantDisconnected(roomModel, remoteParticipant);
      case 'reconnected':
        return Reconnected(roomModel);
      case 'reconnecting':
        return Reconnecting(roomModel, twilioException);
      case 'recordingStarted':
        return RecordingStarted(roomModel);
      case 'recordingStopped':
        return RecordingStopped(roomModel);
      case 'dominantSpeakerChanged':
        return DominantSpeakerChanged(roomModel, dominantSpeaker);
      default:
        return SkippableRoomEvent();
    }
  }

//#endregion

//#region remoteParticipantStream

  /// EventChannel over which the native code sends updates concerning the RemoteParticipants.
  final EventChannel _remoteParticipantChannel;

  Stream<BaseRemoteParticipantEvent>? _remoteParticipantStream;

  /// Stream of the BaseRemoteParticipantEvent model.
  ///
  /// This stream is used to update the RemoteParticipants in a plugin implementation.
  @override
  Stream<BaseRemoteParticipantEvent> remoteParticipantStream(int internalId) {
    _remoteParticipantStream ??= _remoteParticipantChannel.receiveBroadcastStream(internalId).map(_parseRemoteParticipantEvent);
    return _remoteParticipantStream!;
  }

  /// Parses a map send from native code to a [BaseRemoteParticipantEvent].
  BaseRemoteParticipantEvent _parseRemoteParticipantEvent(dynamic event) {
    final eventName = event['name'];
    final data = Map<String, dynamic>.from(event['data']);

    // If no remoteParticipant data is received, skip the event.
    if (data['remoteParticipant'] == null) {
      return SkippableRemoteParticipantEvent();
    }
    final remoteParticipantMap = Map<String, dynamic>.from(data['remoteParticipant']);
    final remoteParticipantModel = RemoteParticipantModel.fromEventChannelMap(remoteParticipantMap);

    late RemoteAudioTrackPublicationModel remoteAudioTrackPublicationModel;
    if (data['remoteAudioTrackPublication'] != null) {
      final remoteAudioTrackPublicationMap = Map<String, dynamic>.from(data['remoteAudioTrackPublication']);
      remoteAudioTrackPublicationModel = RemoteAudioTrackPublicationModel.fromEventChannelMap(remoteAudioTrackPublicationMap);
    }

    RemoteAudioTrackModel? remoteAudioTrackModel;
    if (['audioTrackSubscribed', 'audioTrackUnsubscribed', 'audioTrackEnabled', 'audioTrackDisabled'].contains(eventName)) {
      remoteAudioTrackModel = remoteAudioTrackPublicationModel.remoteAudioTrack;
      if (remoteAudioTrackModel == null) {
        final remoteAudioTrackMap = Map<String, dynamic>.from(data['remoteAudioTrack']);
        remoteAudioTrackModel = RemoteAudioTrackModel.fromEventChannelMap(remoteAudioTrackMap);
      }
    }

    late RemoteDataTrackPublicationModel remoteDataTrackPublicationModel;
    if (data['remoteDataTrackPublication'] != null) {
      final remoteDataTrackPublicationMap = Map<String, dynamic>.from(data['remoteDataTrackPublication']);
      remoteDataTrackPublicationModel = RemoteDataTrackPublicationModel.fromEventChannelMap(remoteDataTrackPublicationMap);
    }

    RemoteDataTrackModel? remoteDataTrackModel;
    if (['dataTrackSubscribed', 'dataTrackUnsubscribed'].contains(eventName)) {
      remoteDataTrackModel = remoteDataTrackPublicationModel.remoteDataTrack;
      if (remoteDataTrackModel == null) {
        final remoteDataTrackMap = Map<String, dynamic>.from(data['remoteDataTrack']);
        remoteDataTrackModel = RemoteDataTrackModel.fromEventChannelMap(remoteDataTrackMap);
      }
    }

    late RemoteVideoTrackPublicationModel remoteVideoTrackPublicationModel;
    if (data['remoteVideoTrackPublication'] != null) {
      final remoteVideoTrackPublicationMap = Map<String, dynamic>.from(data['remoteVideoTrackPublication']);
      remoteVideoTrackPublicationModel = RemoteVideoTrackPublicationModel.fromEventChannelMap(remoteVideoTrackPublicationMap);
    }

    RemoteVideoTrackModel? remoteVideoTrackModel;
    if (['videoTrackSubscribed', 'videoTrackUnsubscribed', 'videoTrackEnabled', 'videoTrackDisabled'].contains(eventName)) {
      remoteVideoTrackModel = remoteVideoTrackPublicationModel.remoteVideoTrack;
      if (remoteVideoTrackModel == null) {
        final remoteVideoTrackMap = Map<String, dynamic>.from(data['remoteVideoTrack']);
        remoteVideoTrackModel = RemoteVideoTrackModel.fromEventChannelMap(remoteVideoTrackMap);
      }
    }

    TwilioExceptionModel? twilioException;
    if (event['error'] != null) {
      final errorMap = Map<String, dynamic>.from(event['error'] as Map<dynamic, dynamic>);
      twilioException = TwilioExceptionModel(errorMap['code'] as int, errorMap['message']);
    }

    switch (eventName) {
      case 'audioTrackDisabled':
        return RemoteAudioTrackDisabled(
          remoteParticipantModel,
          remoteAudioTrackPublicationModel,
        );
      case 'audioTrackEnabled':
        return RemoteAudioTrackEnabled(
          remoteParticipantModel,
          remoteAudioTrackPublicationModel,
        );
      case 'audioTrackPublished':
        return RemoteAudioTrackPublished(
          remoteParticipantModel,
          remoteAudioTrackPublicationModel,
        );
      case 'audioTrackSubscribed':
        return (remoteAudioTrackModel != null)
            ? RemoteAudioTrackSubscribed(
                remoteParticipantModel: remoteParticipantModel,
                remoteAudioTrackPublicationModel: remoteAudioTrackPublicationModel,
                remoteAudioTrackModel: remoteAudioTrackModel,
              )
            : SkippableRemoteParticipantEvent();
      case 'audioTrackSubscriptionFailed':
        return (twilioException != null)
            ? RemoteAudioTrackSubscriptionFailed(
                remoteParticipantModel: remoteParticipantModel,
                remoteAudioTrackPublicationModel: remoteAudioTrackPublicationModel,
                exception: twilioException,
              )
            : SkippableRemoteParticipantEvent();
      case 'audioTrackUnpublished':
        return RemoteAudioTrackUnpublished(
          remoteParticipantModel,
          remoteAudioTrackPublicationModel,
        );
      case 'audioTrackUnsubscribed':
        return (remoteAudioTrackModel != null)
            ? RemoteAudioTrackUnsubscribed(
                remoteParticipantModel: remoteParticipantModel,
                remoteAudioTrackPublicationModel: remoteAudioTrackPublicationModel,
                remoteAudioTrackModel: remoteAudioTrackModel,
              )
            : SkippableRemoteParticipantEvent();
      case 'dataTrackPublished':
        return RemoteDataTrackPublished(
          remoteParticipantModel,
          remoteDataTrackPublicationModel,
        );
      case 'dataTrackSubscribed':
        return (remoteDataTrackModel != null)
            ? RemoteDataTrackSubscribed(
                remoteParticipantModel: remoteParticipantModel,
                remoteDataTrackPublicationModel: remoteDataTrackPublicationModel,
                remoteDataTrackModel: remoteDataTrackModel,
              )
            : SkippableRemoteParticipantEvent();
      case 'dataTrackSubscriptionFailed':
        assert(twilioException != null);
        return RemoteDataTrackSubscriptionFailed(
          remoteParticipantModel: remoteParticipantModel,
          remoteDataTrackPublicationModel: remoteDataTrackPublicationModel,
          exception: twilioException!,
        );
      case 'dataTrackUnpublished':
        return RemoteDataTrackUnpublished(
          remoteParticipantModel,
          remoteDataTrackPublicationModel,
        );
      case 'dataTrackUnsubscribed':
        return (remoteDataTrackModel != null)
            ? RemoteDataTrackUnsubscribed(
                remoteParticipantModel: remoteParticipantModel,
                remoteDataTrackPublicationModel: remoteDataTrackPublicationModel,
                remoteDataTrackModel: remoteDataTrackModel,
              )
            : SkippableRemoteParticipantEvent();
      case 'videoTrackDisabled':
        return RemoteVideoTrackDisabled(
          remoteParticipantModel,
          remoteVideoTrackPublicationModel,
        );
      case 'videoTrackEnabled':
        return RemoteVideoTrackEnabled(
          remoteParticipantModel,
          remoteVideoTrackPublicationModel,
        );
      case 'videoTrackPublished':
        return RemoteVideoTrackPublished(
          remoteParticipantModel,
          remoteVideoTrackPublicationModel,
        );
      case 'videoTrackSubscribed':
        return (remoteVideoTrackModel != null)
            ? RemoteVideoTrackSubscribed(
                remoteParticipantModel: remoteParticipantModel,
                remoteVideoTrackPublicationModel: remoteVideoTrackPublicationModel,
                remoteVideoTrackModel: remoteVideoTrackModel,
              )
            : SkippableRemoteParticipantEvent();
      case 'videoTrackSubscriptionFailed':
        return (twilioException != null)
            ? RemoteVideoTrackSubscriptionFailed(
                remoteParticipantModel: remoteParticipantModel,
                remoteVideoTrackPublicationModel: remoteVideoTrackPublicationModel,
                exception: twilioException,
              )
            : SkippableRemoteParticipantEvent();
      case 'videoTrackUnpublished':
        return RemoteVideoTrackUnpublished(
          remoteParticipantModel,
          remoteVideoTrackPublicationModel,
        );
      case 'videoTrackUnsubscribed':
        return (remoteVideoTrackModel != null)
            ? RemoteVideoTrackUnsubscribed(
                remoteParticipantModel: remoteParticipantModel,
                remoteVideoTrackPublicationModel: remoteVideoTrackPublicationModel,
                remoteVideoTrackModel: remoteVideoTrackModel,
              )
            : SkippableRemoteParticipantEvent();
      case 'networkQualityLevelChanged':
        NetworkQualityLevel? networkQualityLevel;
        if (data['networkQualityLevel'] != null) {
          networkQualityLevel = EnumToString.fromString(NetworkQualityLevel.values, data['networkQualityLevel']) ?? NetworkQualityLevel.NETWORK_QUALITY_LEVEL_UNKNOWN;
        }

        final networkQualityLevelEnum = networkQualityLevel;
        return (networkQualityLevelEnum != null)
            ? RemoteNetworkQualityLevelChanged(
                remoteParticipantModel,
                networkQualityLevelEnum,
              )
            : SkippableRemoteParticipantEvent();
      default:
        return SkippableRemoteParticipantEvent();
    }
  }

  /// EventChannel over which the native code sends updates concerning the LocalParticipant.
  final EventChannel _localParticipantChannel;

  Stream<BaseLocalParticipantEvent>? _localParticipantStream;

  /// Stream of the BaseLocalParticipantEvent model.
  ///
  /// This stream is used to update the LocalParticipant in a plugin implementation.
  @override
  Stream<BaseLocalParticipantEvent> localParticipantStream(int internalId) {
    _localParticipantStream ??= _localParticipantChannel.receiveBroadcastStream(internalId).map(_parseLocalParticipantEvent);
    return _localParticipantStream!;
  }

  /// Parses a map send from native code to a [BaseLocalParticipantEvent].
  BaseLocalParticipantEvent _parseLocalParticipantEvent(dynamic event) {
    final data = Map<String, dynamic>.from(event['data']);
    // If no localParticipant data is received, skip the event.
    if (data['localParticipant'] == null) {
      return SkippableLocalParticipantEvent();
    }

    final localParticipantModel = LocalParticipantModel.fromEventChannelMap(Map<String, dynamic>.from(data['localParticipant']));

    final String? eventName = event['name'];

    TwilioExceptionModel? twilioException;
    if (event['error'] != null) {
      final errorMap = Map<String, dynamic>.from(event['error'] as Map<dynamic, dynamic>);
      twilioException = TwilioExceptionModel(errorMap['code'] as int, errorMap['message']);
    }

    final exception = twilioException;

    switch (eventName) {
      case 'audioTrackPublished':
        LocalAudioTrackPublicationModel? localAudioTrackPublication;
        if (data['localAudioTrackPublication'] != null) {
          final localAudioTrackPublicationMap = Map<String, dynamic>.from(data['localAudioTrackPublication']);
          localAudioTrackPublication = LocalAudioTrackPublicationModel.fromEventChannelMap(localAudioTrackPublicationMap);
        }

        final localAudioTrackPublicationModel = localAudioTrackPublication;
        return (localAudioTrackPublicationModel != null)
            ? LocalAudioTrackPublished(
                localParticipantModel,
                localAudioTrackPublicationModel,
              )
            : SkippableLocalParticipantEvent();
      case 'audioTrackPublicationFailed':
        TrackModel? localAudioTrack;
        if (data['localAudioTrack'] != null) {
          final map = Map<String, dynamic>.from(data['localAudioTrack']);
          localAudioTrack = LocalAudioTrackModel.fromEventChannelMap(map);
        }

        final localAudioTrackModel = localAudioTrack as LocalAudioTrackModel?;
        return (exception != null && localAudioTrackModel != null)
            ? LocalAudioTrackPublicationFailed(
                localAudioTrack: localAudioTrackModel,
                exception: exception,
                localParticipantModel: localParticipantModel,
              )
            : SkippableLocalParticipantEvent();
      case 'dataTrackPublished':
        LocalDataTrackPublicationModel? localDataTrackPublication;
        if (data['localDataTrackPublication'] != null) {
          final map = Map<String, dynamic>.from(data['localDataTrackPublication']);
          localDataTrackPublication = LocalDataTrackPublicationModel.fromEventChannelMap(map);
        }

        final localDataTrackPublicationModel = localDataTrackPublication;
        return (localDataTrackPublicationModel != null)
            ? LocalDataTrackPublished(
                localParticipantModel,
                localDataTrackPublicationModel,
              )
            : SkippableLocalParticipantEvent();
      case 'dataTrackPublicationFailed':
        LocalDataTrackModel? localDataTrack;
        if (data['localDataTrack'] != null) {
          final map = Map<String, dynamic>.from(data['localDataTrack']);
          localDataTrack = LocalDataTrackModel.fromEventChannelMap(map);
        }

        final localDataTrackModel = localDataTrack;
        return (localDataTrackModel != null && exception != null)
            ? LocalDataTrackPublicationFailed(
                localDataTrack: localDataTrackModel,
                exception: exception,
                localParticipantModel: localParticipantModel,
              )
            : SkippableLocalParticipantEvent();
      case 'videoTrackPublished':
        LocalVideoTrackPublicationModel? localVideoTrackPublication;
        if (data['localVideoTrackPublication'] != null) {
          final map = Map<String, dynamic>.from(data['localVideoTrackPublication']);
          localVideoTrackPublication = LocalVideoTrackPublicationModel.fromEventChannelMap(map);
        }

        final localVideoTrackPublicationModel = localVideoTrackPublication;
        return (localVideoTrackPublicationModel != null)
            ? LocalVideoTrackPublished(
                localParticipantModel,
                localVideoTrackPublicationModel,
              )
            : SkippableLocalParticipantEvent();
      case 'videoTrackPublicationFailed':
        LocalVideoTrackModel? localVideoTrack;
        if (data['localVideoTrack'] != null) {
          final map = Map<String, dynamic>.from(data['localVideoTrack']);
          localVideoTrack = LocalVideoTrackModel.fromEventChannelMap(map);
        }

        final localVideoTrackModel = localVideoTrack;
        return (localVideoTrackModel != null && exception != null)
            ? LocalVideoTrackPublicationFailed(
                localVideoTrack: localVideoTrackModel,
                exception: exception,
                localParticipantModel: localParticipantModel,
              )
            : SkippableLocalParticipantEvent();
      case 'networkQualityLevelChanged':
        NetworkQualityLevel? networkQualityLevel;
        if (data['networkQualityLevel'] != null) {
          networkQualityLevel = EnumToString.fromString(NetworkQualityLevel.values, data['networkQualityLevel']) ?? NetworkQualityLevel.NETWORK_QUALITY_LEVEL_UNKNOWN;
        }

        final networkQualityLevelEnum = networkQualityLevel;
        return (networkQualityLevelEnum != null)
            ? LocalNetworkQualityLevelChanged(
                localParticipantModel,
                networkQualityLevelEnum,
              )
            : SkippableLocalParticipantEvent();
      default:
        return SkippableLocalParticipantEvent();
    }
  }

//#endregion

//#region remoteDataTrackStream

  /// EventChannel over which the native code sends updates concerning the RemoteDataTrack.
  final EventChannel _remoteDataTrackChannel;

  Stream<BaseRemoteDataTrackEvent>? _remoteDataTrackStream;

  /// Stream of the BaseRemoteDataTrackEvent model.
  ///
  /// This stream is used to update the RemoteDataTrack in a plugin implementation.
  @override
  Stream<BaseRemoteDataTrackEvent> remoteDataTrackStream(int internalId) {
    _remoteDataTrackStream ??= _remoteDataTrackChannel.receiveBroadcastStream(internalId).map(_parseRemoteDataTrackEvent);
    return _remoteDataTrackStream!;
  }

  /// Parses a map send from native code to a [BaseRemoteDataTrackEvent].
  BaseRemoteDataTrackEvent _parseRemoteDataTrackEvent(dynamic event) {
    final eventName = event['name'];
    final data = Map<String, dynamic>.from(event['data']);
    // If no RemoteDataTrack data is received, skip the event.
    if (data['remoteDataTrack'] == null) {
      return SkippableRemoteDataTrackEvent();
    }
    final remoteDataTrackModel = RemoteDataTrackModel.fromEventChannelMap(Map<String, dynamic>.from(data['remoteDataTrack']));
    switch (eventName) {
      case 'stringMessage':
        return StringMessage(remoteDataTrackModel, data['message'] as String?);
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
      default:
        return UnknownEvent(remoteDataTrackModel, eventName);
    }
  }

//#endregion

//#region audioNotificationStream

  /// EventChannel over which the native code sends audio route change notifications.
  final EventChannel _audioNotificationChannel;

  Stream<BaseAudioNotificationEvent>? _audioNotificationStream;

  /// Stream of the BaseRemoteDataTrackEvent model.
  ///
  /// This stream is used to update the RemoteDataTrack in a plugin implementation.
  @override
  Stream<BaseAudioNotificationEvent> audioNotificationStream() {
    _audioNotificationStream ??= _audioNotificationChannel.receiveBroadcastStream().map(_parseAudioNotificationEvent);
    return _audioNotificationStream!;
  }

  /// Parses a map send from native code to a [BaseRemoteDataTrackEvent].
  BaseAudioNotificationEvent _parseAudioNotificationEvent(dynamic event) {
    print('ProgrammableVideoInstance::parseAudioNotificationEvent => $event');
    final eventName = event['name'];
    final data = Map<String, dynamic>.from(event['data']);
    final deviceName = data['deviceName'];
    final bluetooth = data['bluetooth'] ?? false;
    final wired = data['wired'] ?? false;

    // If no device name is received, skip the event.
    if (deviceName == null) {
      return SkippableAudioEvent();
    }

    switch (eventName) {
      case 'newDeviceAvailable':
        return NewDeviceAvailableEvent(
          deviceName: deviceName,
          bluetooth: bluetooth,
          wired: wired,
        );
      case 'oldDeviceUnavailable':
        return OldDeviceUnavailableEvent(
          deviceName: deviceName,
          bluetooth: bluetooth,
          wired: wired,
        );
      default:
        return SkippableAudioEvent();
    }
  }

//#endregion

  /// Stream of dynamic that contains all the native logging output.
  final EventChannel _loggingChannel;

  @override
  Stream<dynamic> loggingStream() {
    return _loggingChannel.receiveBroadcastStream();
  }
}

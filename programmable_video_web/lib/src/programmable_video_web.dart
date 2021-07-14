import 'dart:async';
import 'dart:html';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:programmable_video_web/src/interop/classes/js_map.dart';
import 'package:programmable_video_web/src/interop/classes/local_audio_track_publication.dart';
import 'package:programmable_video_web/src/interop/classes/local_data_track_publication.dart';
import 'package:programmable_video_web/src/interop/classes/local_video_track_publication.dart';
import 'package:programmable_video_web/src/interop/classes/remote_audio_track.dart';
import 'package:programmable_video_web/src/interop/classes/remote_audio_track_publication.dart';
import 'package:programmable_video_web/src/interop/classes/remote_participant.dart';
import 'package:programmable_video_web/src/interop/classes/room.dart';
import 'package:programmable_video_web/src/interop/connect.dart';
import 'package:programmable_video_web/src/interop/classes/logger.dart';
import 'package:programmable_video_web/src/listeners//room_event_listener.dart';
import 'package:programmable_video_web/src/listeners/local_participant_event_listener.dart';

import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

class ProgrammableVideoPlugin extends ProgrammableVideoPlatform {
  static Room? _room;
  static RoomEventListener? _roomListener;
  static LocalParticipantEventListener? _localParticipantListener;

  // TODO add listeners for camera and remotedatatrack stream
  static final _roomStreamController = StreamController<BaseRoomEvent>.broadcast();
  static final _cameraStreamController = StreamController<BaseCameraEvent>.broadcast();
  static final _localParticipantController = StreamController<BaseLocalParticipantEvent>.broadcast();
  static final _remoteParticipantController = StreamController<BaseRemoteParticipantEvent>.broadcast();
  static final _remoteDataTrackController = StreamController<BaseRemoteDataTrackEvent>.broadcast();
  static final _loggingStreamController = StreamController<String>.broadcast();

  static var _nativeDebug = false;
  static var _sdkDebugSetup = false;
  static final _registeredRemoteParticipantViewFactories = [];

  static void debug(String msg) {
    if (_nativeDebug) _loggingStreamController.add(msg);
  }

  static void registerWith(Registrar registrar) {
    ProgrammableVideoPlatform.instance = ProgrammableVideoPlugin();
    _createLocalViewFactory();
  }

  static void _createLocalViewFactory() {
    ui.platformViewRegistry.registerViewFactory('local-video-track-html', (int viewId) {
      final room = _room;
      if (room != null) {
        final localVideoTrackElement = room.localParticipant.videoTracks.values().next().value.track.attach()..style.objectFit = 'cover';
        debug('Created local video track view for:  ${room.localParticipant.sid}');
        return localVideoTrackElement;
      } else {
        // TODO: review behaviour in scenario where `_room` is `null`.
        return DivElement();
      }
    });
  }

  static void _createRemoteViewFactory(String remoteParticipantSid, String remoteVideoTrackSid) {
    ui.platformViewRegistry.registerViewFactory('remote-video-track-#$remoteVideoTrackSid-html', (int viewId) {
      final remoteVideoTrack = _room?.participants.toDartMap()[remoteParticipantSid]?.videoTracks.toDartMap()[remoteVideoTrackSid]?.track;
      // TODO: flatten this out
      if (remoteVideoTrack != null) {
        final remoteVideoTrackElement = remoteVideoTrack.attach()..style.objectFit = 'cover';
        debug('Created remote video track view for: $remoteParticipantSid');
        return remoteVideoTrackElement;
      } else {
        // TODO: review behaviour in scenario where `_room` is `null`.
        return DivElement();
      }
    });
  }

  //#region Functions
  @override
  Widget createLocalVideoTrackWidget({bool mirror = true, Key? key}) {
    final room = _room;

    if (room != null) {
      debug('Created local video track widget for: ${room.localParticipant.sid}');
      return HtmlElementView(viewType: 'local-video-track-html', key: key);
    } else {
      throw Exception('NotConnected. LocalVideoTrack is not fully initialized until connection.');
    }
  }

  @override
  Widget createRemoteVideoTrackWidget({
    required String remoteParticipantSid,
    required String remoteVideoTrackSid,
    bool mirror = true,
    Key? key,
  }) {
    key ??= ValueKey(remoteVideoTrackSid);

    if (!_registeredRemoteParticipantViewFactories.contains(remoteParticipantSid)) {
      _createRemoteViewFactory(remoteParticipantSid, remoteVideoTrackSid);
      _registeredRemoteParticipantViewFactories.add(remoteParticipantSid);
    }
    debug('Created remote video track widget for: $remoteParticipantSid');
    return HtmlElementView(viewType: 'remote-video-track-#$remoteVideoTrackSid-html', key: key);
  }

  void _onConnected() async {
    final room = _room;
    if (room != null) {
      _roomListener = RoomEventListener(room, _roomStreamController, _remoteParticipantController);
      _roomListener!.addListeners();
      _localParticipantListener = LocalParticipantEventListener(room.localParticipant, _localParticipantController);
      _localParticipantListener!.addListeners();

      final _roomModel = Connected(room.toModel());
      _roomStreamController.add(_roomModel);
      debug('Connected to room: ${room.name}');
      _roomStreamController.onListen = null;
    }
  }

  @override
  Future<int> connectToRoom(ConnectOptionsModel connectOptions) async {
    _roomStreamController.onListen = _onConnected;

    try {
      _room = await connectWithModel(connectOptions);
    } catch (err) {
      ProgrammableVideoPlugin.debug(err.toString());
      throw PlatformException(code: 'INIT_ERROR', message: 'Failed to connect to room', details: '');
    }
    return 0;
  }

  @override
  Future<void> disconnect() async {
    debug('Disconnecting to room: ${_room?.name}');
    _roomListener?.removeListeners();
    _localParticipantListener?.removeListeners();
    final localParticipant = _room?.localParticipant;
    if (localParticipant != null) {
      final audioTracks = localParticipant.audioTracks.values();
      iteratorForEach<LocalAudioTrackPublication>(audioTracks, (publication) {
        debug('ProgrammableVideoWeb::disconnect => unpublishing ${publication.track.kind} track ${publication.trackSid}');
        _room?.localParticipant.unpublishTrack(publication.track);
        return false;
      });

      final videoTracks = localParticipant.videoTracks.values();
      iteratorForEach<LocalVideoTrackPublication>(videoTracks, (publication) {
        debug('ProgrammableVideoWeb::disconnect => unpublishing ${publication.track.kind} track ${publication.trackSid}');
        _room?.localParticipant.unpublishTrack(publication.track);
        return false;
      });

      final dataTracks = localParticipant.dataTracks.values();
      iteratorForEach<LocalDataTrackPublication>(dataTracks, (publication) {
        debug('ProgrammableVideoWeb::disconnect => unpublishing ${publication.track.kind} track ${publication.trackSid}');
        _room?.localParticipant.unpublishTrack(publication.track);
        return false;
      });
    }
    _room?.disconnect();
    _room = null;
    _roomListener = null;
    _localParticipantListener = null;
  }

  @override
  Future<bool> enableAudioTrack(bool enable, String name) {
    final localAudioTracks = _room?.localParticipant.audioTracks.values();
    if (localAudioTracks != null) {
      iteratorForEach<LocalAudioTrackPublication>(localAudioTracks, (localAudioTrack) {
        final found = localAudioTrack.trackName == name;
        if (found) {
          enable ? localAudioTrack.track.enable() : localAudioTrack.track.disable();
        }
        return found;
      });
      debug('${enable ? 'Enabled' : 'Disabled'} Local Audio Track');
      return Future(() => enable);
    } else {
      throw PlatformException(code: 'NOT_FOUND', message: 'No LocalAudioTrack found with the name \'$name\'');
    }
  }

  @override
  Future<bool> enableVideoTrack(bool enabled, String name) {
    final localVideoTracks = _room?.localParticipant.videoTracks.values();
    if (localVideoTracks != null) {
      iteratorForEach<LocalVideoTrackPublication>(localVideoTracks, (localVideoTrack) {
        final found = localVideoTrack.trackName == name;
        if (found) {
          enabled ? localVideoTrack.track.enable() : localVideoTrack.track.disable();
        }
        return found;
      });

      debug('${enabled ? 'Enabled' : 'Disabled'} Local Video Track');
      return Future(() => enabled);
    } else {
      throw PlatformException(code: 'NOT_FOUND', message: 'No LocalVideoTrack found with the name \'$name\'');
    }
  }

  @override
  Future<void> setNativeDebug(bool native) async {
    final logger = Logger.getLogger('twilio-video');
    // Currently also enabling SDK debugging when native is true
    if (native && !_sdkDebugSetup) {
      final originalFactory = logger.methodFactory;
      logger.methodFactory = allowInterop((methodName, logLevel, loggerName) {
        final method = originalFactory(methodName, logLevel, loggerName);
        return allowInterop((datetime, logLevel, component, message, [data = '', misc = '']) {
          final output = '[  WEBSDK  ] $datetime $logLevel $component $message $data';
          method(output, datetime, logLevel, component, message, data);
        });
      });
      _sdkDebugSetup = true;
    }
    // Adding native debugging
    _nativeDebug = native;

    // Adding sdk debugging (can be set to 'debug' for more detail"
    native ? logger.setLevel('info') : logger.setLevel('warn');
  }

  @override
  Future<bool> setSpeakerphoneOn(bool on) {
    return Future(() => true);
  }

  @override
  Future<bool> getSpeakerphoneOn() {
    return Future(() => true);
  }

  @override
  Future<CameraSource> switchCamera() {
    return Future(() => CameraSource.FRONT_CAMERA);
  }

  @override
  Future<bool> hasTorch() async {
    return Future(() => false);
  }

  @override
  Future<void> setTorch(bool enabled) async {}

  @override
  Future<void> sendMessage(String message, String name) {
    return Future(() {});
  }

  @override
  Future<void> sendBuffer(ByteBuffer message, String name) {
    return Future(() {});
  }

  RemoteAudioTrack? _getRemoteAudioTrack(String sid) {
    var remoteAudioTrack;
    final room = _room;
    if (room != null) {
      iteratorForEach<RemoteParticipant>(room.participants.values(), (remoteParticipant) {
        var found = false;
        iteratorForEach<RemoteAudioTrackPublication>(remoteParticipant.audioTracks.values(), (audioTrack) {
          if (audioTrack.trackSid == sid) {
            remoteAudioTrack = audioTrack.track;
            found = true;
          }
          return found;
        });
        return found;
      });
      if (remoteAudioTrack == null) {
        throw PlatformException(code: 'NOT_FOUND', message: 'The track with sid: $sid was not found');
      }
      return remoteAudioTrack;
    }
  }

  @override
  Future<void> enableRemoteAudioTrack(bool enable, String sid) {
    final remoteAudioTrack = _getRemoteAudioTrack(sid);
    if (remoteAudioTrack == null) {
      throw PlatformException(
        code: 'NOT_FOUND',
        message: 'No RemoteAudioTrack found with sid $sid',
        details: null,
      );
    }

    final remoteTrackElement = document.getElementById(remoteAudioTrack.name) as AudioElement?;
    if (remoteTrackElement == null) {
      throw PlatformException(
        code: 'NOT_FOUND',
        message: 'No AudioElement found for RemoteAudioTrack with sid: $sid',
        details: null,
      );
    }

    remoteTrackElement.muted = !enable;

    debug('${enable ? 'Enabled' : 'Disabled'} Remote Audio Track');
    return Future(() {});
  }

  @override
  Future<bool> isRemoteAudioTrackPlaybackEnabled(String sid) {
    final remoteAudioTrack = _getRemoteAudioTrack(sid);
    if (remoteAudioTrack == null) {
      return Future.value(false);
    }
    final remoteTrackElement = document.getElementById(remoteAudioTrack.name) as AudioElement?;
    final isEnabled = remoteTrackElement != null ? !remoteTrackElement.muted : false;
    return Future(() => isEnabled);
  }

  //#endregion

  //#region Streams
  @override
  Stream<BaseCameraEvent> cameraStream() {
    return _cameraStreamController.stream;
  }

  @override
  Stream<BaseRoomEvent> roomStream(int internalId) {
    return _roomStreamController.stream;
  }

  @override
  Stream<BaseRemoteParticipantEvent> remoteParticipantStream(int internalId) {
    return _remoteParticipantController.stream;
  }

  @override
  Stream<BaseLocalParticipantEvent> localParticipantStream(int internalId) {
    return _localParticipantController.stream;
  }

  @override
  Stream<BaseRemoteDataTrackEvent> remoteDataTrackStream(int internalId) {
    return _remoteDataTrackController.stream;
  }

  @override
  Stream<dynamic> loggingStream() {
    return _loggingStreamController.stream;
  }
//#endregion
}

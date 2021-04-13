import 'dart:async';
import 'dart:ui' as ui;

import 'package:dartlin/dartlin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:js/js.dart';
import 'package:pedantic/pedantic.dart';
import 'package:programmable_video_web/src/interop/classes/local_audio_track.dart';
import 'package:programmable_video_web/src/interop/classes/local_audio_track_publication.dart';
import 'package:programmable_video_web/src/interop/classes/local_data_track.dart';
import 'package:programmable_video_web/src/interop/classes/local_data_track_publication.dart';
import 'package:programmable_video_web/src/interop/classes/local_participant.dart';
import 'package:programmable_video_web/src/interop/classes/local_track_publication.dart';
import 'package:programmable_video_web/src/interop/classes/local_video_track.dart';
import 'package:programmable_video_web/src/interop/classes/local_video_track_publication.dart';
import 'package:programmable_video_web/src/interop/classes/room.dart';
import 'package:programmable_video_web/src/interop/classes/twilio_error.dart';
import 'package:programmable_video_web/src/interop/connect.dart';
import 'package:programmable_video_web/src/interop/network_quality_level.dart';

import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

class ProgrammableVideoPlugin extends ProgrammableVideoPlatform {
  static Room _room;

  static final _roomStreamController = StreamController<BaseRoomEvent>();
  static final _localParticipantController = StreamController<BaseLocalParticipantEvent>();

  static void registerWith(Registrar registrar) {
    ProgrammableVideoPlatform.instance = ProgrammableVideoPlugin();
  }

  //#region Functions
  @override
  Widget createLocalVideoTrackWidget({bool mirror = true, Key key}) {
    if (_room == null) {
      return null;
    }

    final localVideoTrackElement = _room.localParticipant.videoTracks.values().next().value.track.attach()..style.objectFit = 'cover';

    ui.platformViewRegistry.registerViewFactory(
      'local-video-track-html',
      (int viewId) => localVideoTrackElement,
    );

    return HtmlElementView(viewType: 'local-video-track-html');
  }

  @override
  Future<int> connectToRoom(ConnectOptionsModel connectOptions) async {
    unawaited(
      connectWithModel(connectOptions).then((room) {
        _room = room;

        _roomStreamController.add(
          Connected(_room.toModel()),
        );

        _addRoomEventListeners();
        _addLocalParticipantEventListeners(_room.localParticipant);
      }),
    );

    return 0;
  }

  @override
  Future<void> disconnect() async {
    _room?.disconnect();
  }

  @override
  Future<bool> enableAudioTrack({bool enable, String name}) {
    final localAudioTrack = _room?.localParticipant?.audioTracks?.values()?.next()?.value?.track;

    enable ? localAudioTrack?.enable() : localAudioTrack?.disable();

    return Future(() => enable);
  }

  @override
  Future<bool> enableVideoTrack({bool enabled, String name}) {
    final localVideoTrack = _room?.localParticipant?.videoTracks?.values()?.next()?.value?.track;

    enabled ? localVideoTrack?.enable() : localVideoTrack?.disable();

    return Future(() => enabled);
  }

  @override
  Future<void> setNativeDebug(bool native) async {}

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
  //#endregion

  //#region Streams
  @override
  Stream<BaseCameraEvent> cameraStream() {
    return Stream.empty();
  }

  @override
  Stream<BaseRoomEvent> roomStream(int internalId) {
    return _roomStreamController.stream;
  }

  @override
  Stream<BaseRemoteParticipantEvent> remoteParticipantStream(int internalId) {
    return Stream.empty();
  }

  @override
  Stream<BaseLocalParticipantEvent> localParticipantStream(int internalId) {
    return _localParticipantController.stream;
  }

  @override
  Stream<BaseRemoteDataTrackEvent> remoteDataTrackStream(int internalId) {
    return Stream.empty();
  }

  @override
  Stream<dynamic> loggingStream() {
    return Stream.empty();
  }
  //#endregion

  void _addRoomEventListeners() {
    //#region room event callbacks
    void on(String eventName, Function eventHandler) => _room.on(
          eventName,
          allowInterop(eventHandler),
        );

    on(
      'disconnected',
      (Room room, TwilioError error) => _roomStreamController.add(Disconnected(
        room.toModel(),
        error.let((it) => it.toModel()),
      )),
    );
    //TODO: register event callBacks on the remoteParticipant from this event
    on('participantConnected', () => _roomStreamController.add(SkipAbleRoomEvent()));
    on('participantDisconnected', () => _roomStreamController.add(SkipAbleRoomEvent()));
    on('participantReconnected', () => _roomStreamController.add(SkipAbleRoomEvent()));
    on('participantReconnecting', () => _roomStreamController.add(SkipAbleRoomEvent()));
    on('reconnected', () => _roomStreamController.add(Reconnected(_room.toModel())));
    on(
      'reconnecting',
      (TwilioError error) => _roomStreamController.add(
        Reconnecting(_room.toModel(), error.toModel()),
      ),
    );
    on('recordingStarted', () => _roomStreamController.add(RecordingStarted(_room.toModel())));
    on('recordingStopped', () => _roomStreamController.add(RecordingStopped(_room.toModel())));
    on('trackDimensionsChanged', () => _roomStreamController.add(SkipAbleRoomEvent()));
    on('trackDisabled', () => _roomStreamController.add(SkipAbleRoomEvent()));
    on('trackEnabled', () => _roomStreamController.add(SkipAbleRoomEvent()));
    on('trackMessage', () => _roomStreamController.add(SkipAbleRoomEvent()));
    on('trackPublished', () => _roomStreamController.add(SkipAbleRoomEvent()));
    on('trackPublishPriorityChanged', () => _roomStreamController.add(SkipAbleRoomEvent()));
    on('trackStarted', () => _roomStreamController.add(SkipAbleRoomEvent()));
    on('trackSubscribed', () => _roomStreamController.add(SkipAbleRoomEvent()));
    on('trackSwitchedOff', () => _roomStreamController.add(SkipAbleRoomEvent()));
    on('trackSwitchedOn', () => _roomStreamController.add(SkipAbleRoomEvent()));
    on('trackUnpublished', () => _roomStreamController.add(SkipAbleRoomEvent()));
    on('trackUnsubscribed', () => _roomStreamController.add(SkipAbleRoomEvent()));
    //#endregion
  }

  void _addLocalParticipantEventListeners(LocalParticipant localParticipant) {
    localParticipant.on('trackPublished', allowInterop((LocalTrackPublication publication) {
      when(publication.kind, {
        'audio': () {
          _localParticipantController.add(LocalAudioTrackPublished(
            localParticipant.toModel(),
            (publication as LocalAudioTrackPublication).toModel(),
          ));
        },
        'data': () {
          _localParticipantController.add(LocalDataTrackPublished(
            localParticipant.toModel(),
            (publication as LocalDataTrackPublication).toModel(),
          ));
        },
        'video': () {
          _localParticipantController.add(LocalVideoTrackPublished(
            localParticipant.toModel(),
            (publication as LocalVideoTrackPublication).toModel(),
          ));
        },
      });
    }));

    localParticipant.on('trackPublicationFailed', allowInterop((TwilioError error, dynamic localTrack) {
      when(localTrack.kind, {
        'audio': () {
          _localParticipantController.add(LocalAudioTrackPublicationFailed(
            exception: error.toModel(),
            localAudioTrack: (localTrack as LocalAudioTrack).toModel(),
            localParticipantModel: localParticipant.toModel(),
          ));
        },
        'data': () {
          _localParticipantController.add(LocalDataTrackPublicationFailed(
            exception: error.toModel(),
            localDataTrack: (localTrack as LocalDataTrack).toModel(true),
            localParticipantModel: localParticipant.toModel(),
          ));
        },
        'video': () {
          _localParticipantController.add(LocalVideoTrackPublicationFailed(
            exception: error.toModel(),
            localVideoTrack: (localTrack as LocalVideoTrack).toModel(),
            localParticipantModel: localParticipant.toModel(),
          ));
        },
      });
    }));

    localParticipant.on(
      'networkQualityLevelChanged',
      allowInterop(
        (int networkQualityLevel, dynamic networkQualityStats) {
          _localParticipantController.add(
            LocalNetworkQualityLevelChanged(
              localParticipant.toModel(),
              networkQualityLevelFromInt(networkQualityLevel),
            ),
          );
        },
      ),
    );
  }
}

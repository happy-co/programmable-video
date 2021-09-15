import 'dart:async';

import 'package:js/js.dart';
import 'package:dartlin/dartlin.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_audio_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_audio_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_data_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_data_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_participant.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_video_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/local_video_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/twilio_error.dart';
import 'package:twilio_programmable_video_web/src/interop/network_quality_level.dart';
import 'package:twilio_programmable_video_web/src/listeners/base_listener.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

class LocalParticipantEventListener extends BaseListener {
  final LocalParticipant _localParticipant;
  final StreamController<BaseLocalParticipantEvent> _localParticipantController;

  LocalParticipantEventListener(this._localParticipant, this._localParticipantController);

  void addListeners() {
    debug('Adding LocalParticipantEventListeners for ${_localParticipant.sid}');
    _on('trackPublished', onTrackPublished);
    _on('trackPublicationFailed', onTrackPublicationFailed);
    _on('networkQualityLevelChanged', onNetworkQualityLevelChanged);
  }

  void removeListeners() {
    debug('Removed LocalParticipantEventListeners for ${_localParticipant.sid}');
    _off('trackPublished', onTrackPublished);
    _off('trackPublicationFailed', onTrackPublicationFailed);
    _off('networkQualityLevelChanged', onNetworkQualityLevelChanged);
  }

  void _on(String eventName, Function eventHandler) => _localParticipant.on(
        eventName,
        allowInterop(eventHandler),
      );

  void _off(String eventName, Function eventHandler) => _localParticipant.off(
        eventName,
        allowInterop(eventHandler),
      );

  void onTrackPublished(LocalTrackPublication publication) {
    debug('Added Local${capitalize(publication.kind)}TrackPublished Event');
    when(publication.kind, {
      'audio': () {
        _localParticipantController.add(LocalAudioTrackPublished(
          _localParticipant.toModel(),
          (publication as LocalAudioTrackPublication).toModel(),
        ));
      },
      'data': () {
        _localParticipantController.add(LocalDataTrackPublished(
          _localParticipant.toModel(),
          (publication as LocalDataTrackPublication).toModel(),
        ));
      },
      'video': () {
        _localParticipantController.add(LocalVideoTrackPublished(
          _localParticipant.toModel(),
          (publication as LocalVideoTrackPublication).toModel(),
        ));
      },
    });
  }

  void onTrackPublicationFailed(TwilioError error, dynamic localTrack) {
    debug('Added Local${capitalize(localTrack.kind)}TrackPublicationFailed Event');
    when(localTrack.kind, {
      'audio': () {
        _localParticipantController.add(LocalAudioTrackPublicationFailed(
          exception: error.toModel(),
          localAudioTrack: (localTrack as LocalAudioTrack).toModel(),
          localParticipantModel: _localParticipant.toModel(),
        ));
      },
      'data': () {
        _localParticipantController.add(LocalDataTrackPublicationFailed(
          exception: error.toModel(),
          localDataTrack: (localTrack as LocalDataTrack).toModel(true),
          localParticipantModel: _localParticipant.toModel(),
        ));
      },
      'video': () {
        _localParticipantController.add(LocalVideoTrackPublicationFailed(
          exception: error.toModel(),
          localVideoTrack: (localTrack as LocalVideoTrack).toModel(),
          localParticipantModel: _localParticipant.toModel(),
        ));
      },
    });
  }

  void onNetworkQualityLevelChanged(int networkQualityLevel, dynamic networkQualityStats) {
    debug('Added LocalNetworkQualityLevelChanged Event');
    _localParticipantController.add(
      LocalNetworkQualityLevelChanged(
        _localParticipant.toModel(),
        networkQualityLevelFromInt(networkQualityLevel),
      ),
    );
  }
}

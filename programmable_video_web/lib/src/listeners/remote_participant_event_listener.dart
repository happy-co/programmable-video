import 'dart:async';
import 'dart:html';

import 'package:dartlin/control_flow.dart';
import 'package:js/js.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_audio_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_audio_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_data_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_data_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_participant.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_video_track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/remote_video_track_publication.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/track.dart';
import 'package:twilio_programmable_video_web/src/interop/classes/twilio_error.dart';
import 'package:twilio_programmable_video_web/src/interop/network_quality_level.dart';
import 'package:twilio_programmable_video_web/src/listeners/base_listener.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

class RemoteParticipantEventListener extends BaseListener {
  final RemoteParticipant _remoteParticipant;
  final StreamController<BaseRemoteParticipantEvent> _remoteParticipantController;

  RemoteParticipantEventListener(this._remoteParticipant, this._remoteParticipantController);

  void addListeners() {
    debug('Adding RemoteParticipantEventListeners for ${_remoteParticipant.sid}');
    _on('trackDisabled', onTrackDisabled);
    _on('trackEnabled', onTrackEnabled);
    _on('trackPublished', onTrackPublished);
    _on('trackUnpublished', onTrackUnpublished);
    _on('trackSubscribed', onTrackSubscribed);
    _on('trackUnsubscribed', onTrackUnsubscribed);
    _on('trackSubscriptionFailed', onTrackSubscriptionFailed);
    _on('networkQualityLevelChanged', onNetworkQualityLevelChanged);
  }

  void removeListeners() {
    debug('Removing RemoteParticipantEventListeners for ${_remoteParticipant.sid}');
    _off('trackDisabled', onTrackDisabled);
    _off('trackEnabled', onTrackEnabled);
    _off('trackPublished', onTrackPublished);
    _off('trackUnpublished', onTrackUnpublished);
    _off('trackSubscribed', onTrackSubscribed);
    _off('trackUnsubscribed', onTrackUnsubscribed);
    _off('trackSubscriptionFailed', onTrackSubscriptionFailed);
    _off('networkQualityLevelChanged', onNetworkQualityLevelChanged);
  }

  void _on(String eventName, Function eventHandler) => _remoteParticipant.on(
        eventName,
        allowInterop(eventHandler),
      );

  void _off(String eventName, Function eventHandler) => _remoteParticipant.off(
        eventName,
        allowInterop(eventHandler),
      );

  void onTrackDisabled(RemoteTrackPublication publication) {
    debug('Added Remote${capitalize(publication.kind)}TrackDisabled Event');
    when(publication.kind, {
      'audio': () => onTrackDisabledAudio(publication as RemoteAudioTrackPublication),
      'video': () => onTrackDisabledVideo(publication as RemoteVideoTrackPublication),
    });
  }

  void onTrackDisabledAudio(RemoteAudioTrackPublication publication) => _remoteParticipantController.add(RemoteAudioTrackDisabled(
        _remoteParticipant.toModel(),
        publication.toModel(),
      ));

  void onTrackDisabledVideo(RemoteVideoTrackPublication publication) {
    _remoteParticipantController.add(RemoteVideoTrackDisabled(
      _remoteParticipant.toModel(),
      publication.toModel(),
    ));
  }

  void onTrackEnabled(RemoteTrackPublication publication) {
    debug('Added Remote${capitalize(publication.kind)}TrackEnabled Event');
    when(publication.kind, {
      'audio': () => onTrackEnabledAudio(publication as RemoteAudioTrackPublication),
      'video': () => onTrackEnabledVideo(publication as RemoteVideoTrackPublication),
    });
  }

  void onTrackEnabledAudio(RemoteAudioTrackPublication publication) => _remoteParticipantController.add(
        RemoteAudioTrackEnabled(
          _remoteParticipant.toModel(),
          publication.toModel(),
        ),
      );

  void onTrackEnabledVideo(RemoteVideoTrackPublication publication) => _remoteParticipantController.add(
        RemoteVideoTrackEnabled(
          _remoteParticipant.toModel(),
          publication.toModel(),
        ),
      );

  void onTrackPublished(RemoteTrackPublication publication) {
    debug('Added Remote${capitalize(publication.kind)}TrackPublished Event');
    when(publication.kind, {
      'audio': () => onTrackPublishedAudio(publication as RemoteAudioTrackPublication),
      'video': () => onTrackPublishedVideo(publication as RemoteVideoTrackPublication),
      'data': () => onTrackPublishedData(publication as RemoteDataTrackPublication)
    });
  }

  void onTrackPublishedAudio(RemoteAudioTrackPublication publication) => _remoteParticipantController.add(
        RemoteAudioTrackPublished(
          _remoteParticipant.toModel(),
          publication.toModel(),
        ),
      );

  void onTrackPublishedData(RemoteDataTrackPublication publication) {
    _remoteParticipantController.add(
      RemoteDataTrackPublished(
        _remoteParticipant.toModel(),
        publication.toModel(),
      ),
    );
  }

  void onTrackPublishedVideo(RemoteVideoTrackPublication publication) => _remoteParticipantController.add(
        RemoteVideoTrackPublished(
          _remoteParticipant.toModel(),
          publication.toModel(),
        ),
      );

  void onTrackUnpublished(RemoteTrackPublication publication) {
    debug('Added Remote${capitalize(publication.kind)}TrackUnpublished Event');
    when(publication.kind, {
      'audio': () => onTrackUnpublishedAudio(publication as RemoteAudioTrackPublication),
      'video': () => onTrackUnpublishedVideo(publication as RemoteVideoTrackPublication),
      'data': () => onTrackUnpublishedData(publication as RemoteDataTrackPublication)
    });
  }

  void onTrackUnpublishedAudio(RemoteAudioTrackPublication publication) => _remoteParticipantController.add(
        RemoteAudioTrackUnpublished(
          _remoteParticipant.toModel(),
          publication.toModel(),
        ),
      );

  void onTrackUnpublishedData(RemoteDataTrackPublication publication) => _remoteParticipantController.add(
        RemoteDataTrackUnpublished(
          _remoteParticipant.toModel(),
          publication.toModel(),
        ),
      );

  void onTrackUnpublishedVideo(RemoteVideoTrackPublication publication) => _remoteParticipantController.add(
        RemoteVideoTrackUnpublished(
          _remoteParticipant.toModel(),
          publication.toModel(),
        ),
      );

  void onTrackSubscribed(Track track, RemoteTrackPublication publication) {
    debug('Added Remote${capitalize(track.kind)}TrackSubscribed Event');
    when(track.kind, {
      'audio': () {
        final audioTrack = track as RemoteAudioTrack;
        final audioElement = audioTrack.attach();
        audioElement.id = track.name;
        document.body?.append(audioElement);
        debug('Attached audio element');
        _remoteParticipantController.add(
          RemoteAudioTrackSubscribed(
            remoteParticipantModel: _remoteParticipant.toModel(),
            remoteAudioTrackPublicationModel: (publication as RemoteAudioTrackPublication).toModel(),
            remoteAudioTrackModel: audioTrack.toModel(),
          ),
        );
      },
      'data': () {
        _remoteParticipantController.add(
          RemoteDataTrackSubscribed(
            remoteParticipantModel: _remoteParticipant.toModel(),
            remoteDataTrackPublicationModel: (publication as RemoteDataTrackPublication).toModel(),
            remoteDataTrackModel: (track as RemoteDataTrack).toModel(),
          ),
        );
      },
      'video': () {
        _remoteParticipantController.add(
          RemoteVideoTrackSubscribed(
            remoteParticipantModel: _remoteParticipant.toModel(),
            remoteVideoTrackPublicationModel: (publication as RemoteVideoTrackPublication).toModel(),
            remoteVideoTrackModel: (track as RemoteVideoTrack).toModel(),
          ),
        );
      },
    });
  }

  void onTrackUnsubscribed(Track track, RemoteTrackPublication publication) {
    debug('Added Remote${capitalize(track.kind)}TrackUnsubscribed Event');
    when(track.kind, {
      'audio': () {
        final audioTrack = track as RemoteAudioTrack;
        final mediaElements = audioTrack.detach();
        mediaElements.forEach((element) => (element as MediaElement).remove());
        debug('Detached audio element');
        _remoteParticipantController.add(
          RemoteAudioTrackUnsubscribed(
            remoteParticipantModel: _remoteParticipant.toModel(),
            remoteAudioTrackPublicationModel: (publication as RemoteAudioTrackPublication).toModel(),
            remoteAudioTrackModel: audioTrack.toModel(),
          ),
        );
      },
      'data': () {
        _remoteParticipantController.add(
          RemoteDataTrackUnsubscribed(
            remoteParticipantModel: _remoteParticipant.toModel(),
            remoteDataTrackPublicationModel: (publication as RemoteDataTrackPublication).toModel(),
            remoteDataTrackModel: (track as RemoteDataTrack).toModel(),
          ),
        );
      },
      'video': () {
        _remoteParticipantController.add(
          RemoteVideoTrackUnsubscribed(
            remoteParticipantModel: _remoteParticipant.toModel(),
            remoteVideoTrackPublicationModel: (publication as RemoteVideoTrackPublication).toModel(),
            remoteVideoTrackModel: (track as RemoteVideoTrack).toModel(),
          ),
        );
      },
    });
  }

  void onTrackSubscriptionFailed(TwilioError error, RemoteTrackPublication publication) {
    debug('Added Remote${capitalize(publication.kind)}TrackSubscriptionFailed Event');

    when(publication.kind, {
      'audio': () {
        _remoteParticipantController.add(
          RemoteAudioTrackSubscriptionFailed(
            remoteParticipantModel: _remoteParticipant.toModel(),
            remoteAudioTrackPublicationModel: (publication as RemoteAudioTrackPublication).toModel(),
            exception: error.toModel(),
          ),
        );
      },
      'data': () {
        _remoteParticipantController.add(
          RemoteDataTrackSubscriptionFailed(
            remoteParticipantModel: _remoteParticipant.toModel(),
            remoteDataTrackPublicationModel: (publication as RemoteDataTrackPublication).toModel(),
            exception: error.toModel(),
          ),
        );
      },
      'video': () {
        _remoteParticipantController.add(
          RemoteVideoTrackSubscriptionFailed(
            remoteParticipantModel: _remoteParticipant.toModel(),
            remoteVideoTrackPublicationModel: (publication as RemoteVideoTrackPublication).toModel(),
            exception: error.toModel(),
          ),
        );
      },
    });
  }

  void onNetworkQualityLevelChanged(int networkQualityLevel, dynamic networkQualityStats) {
    debug('Added RemoteNetworkQualityLevelChanged Event');
    _remoteParticipantController.add(
      RemoteNetworkQualityLevelChanged(
        _remoteParticipant.toModel(),
        networkQualityLevelFromInt(networkQualityLevel),
      ),
    );
  }
}

import 'package:flutter/foundation.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// Model that a plugin implementation can use to construct a RemoteParticipant.
class RemoteParticipantModel {
  final String identity;
  final String sid;

  final List<RemoteAudioTrackPublicationModel> remoteAudioTrackPublications;
  final List<RemoteDataTrackPublicationModel> remoteDataTrackPublications;
  final List<RemoteVideoTrackPublicationModel> remoteVideoTrackPublications;

  const RemoteParticipantModel({@required this.identity, @required this.sid, @required this.remoteAudioTrackPublications, @required this.remoteDataTrackPublications, @required this.remoteVideoTrackPublications})
      : assert(identity != null),
        assert(sid != null),
        assert(remoteAudioTrackPublications != null),
        assert(remoteDataTrackPublications != null),
        assert(remoteVideoTrackPublications != null);

  factory RemoteParticipantModel.fromEventChannelMap(Map<String, dynamic> map) {
    var remoteAudioTrackPublications = <RemoteAudioTrackPublicationModel>[];
    if (map['remoteAudioTrackPublications'] != null) {
      final List<Map<String, dynamic>> remoteAudioTrackPublicationsList = map['remoteAudioTrackPublications'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();

      for (final remoteAudioTrackPublicationMap in remoteAudioTrackPublicationsList) {
        remoteAudioTrackPublications.add(RemoteAudioTrackPublicationModel.fromEventChannelMap(remoteAudioTrackPublicationMap));
      }
    }

    var remoteDataTrackPublications = <RemoteDataTrackPublicationModel>[];
    if (map['remoteDataTrackPublications'] != null) {
      final List<Map<String, dynamic>> remoteDataTrackPublicationsList = map['remoteDataTrackPublications'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();

      for (final remoteDataTrackPublicationMap in remoteDataTrackPublicationsList) {
        remoteDataTrackPublications.add(RemoteDataTrackPublicationModel.fromEventChannelMap(remoteDataTrackPublicationMap));
      }
    }

    var remoteVideoTrackPublications = <RemoteVideoTrackPublicationModel>[];
    if (map['remoteVideoTrackPublications'] != null) {
      final List<Map<String, dynamic>> remoteVideoTrackPublicationsList = map['remoteVideoTrackPublications'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();

      for (final remoteVideoTrackPublicationMap in remoteVideoTrackPublicationsList) {
        remoteVideoTrackPublications.add(RemoteVideoTrackPublicationModel.fromEventChannelMap(remoteVideoTrackPublicationMap));
      }
    }

    return RemoteParticipantModel(
        identity: map['identity'], sid: map['sid'], remoteAudioTrackPublications: remoteAudioTrackPublications, remoteDataTrackPublications: remoteDataTrackPublications, remoteVideoTrackPublications: remoteVideoTrackPublications);
  }

  @override
  String toString() {
    var remoteAudioTrackPublicationsString = '';
    for (var remoteAudioTrackPublication in remoteAudioTrackPublications) {
      remoteAudioTrackPublicationsString += remoteAudioTrackPublication.toString() + ', ';
    }

    var remoteDataTrackPublicationsString = '';
    for (var remoteDataTrackPublication in remoteDataTrackPublications) {
      remoteDataTrackPublicationsString += remoteDataTrackPublication.toString() + ', ';
    }

    var remoteVideoTrackPublicationsString = '';
    for (var remoteVideoTrackPublication in remoteVideoTrackPublications) {
      remoteVideoTrackPublicationsString += remoteVideoTrackPublication.toString() + ', ';
    }

    return '''{ 
      identity: $identity,
      sid: $sid,
      remoteAudioTrackPublications: [$remoteAudioTrackPublicationsString],
      remoteDataTrackPublications: [$remoteDataTrackPublicationsString],
      remoteVideoTrackPublications: [$remoteVideoTrackPublicationsString]
      }''';
  }
}

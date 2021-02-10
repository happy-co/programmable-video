import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter/foundation.dart';
import 'package:twilio_programmable_video_platform_interface/src/enums/enum_exports.dart';
import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

/// Model that a plugin implementation can use to construct a LocalParticipant.
class LocalParticipantModel {
  final String identity;
  final String sid;
  final String signalingRegion;

  final List<LocalAudioTrackPublicationModel> localAudioTrackPublications;
  final List<LocalDataTrackPublicationModel> localDataTrackPublications;
  final List<LocalVideoTrackPublicationModel> localVideoTrackPublications;

  final NetworkQualityLevel networkQualityLevel;

  const LocalParticipantModel({
    @required this.identity,
    @required this.sid,
    @required this.signalingRegion,
    @required this.localAudioTrackPublications,
    @required this.localDataTrackPublications,
    @required this.localVideoTrackPublications,
    @required this.networkQualityLevel,
  })  : assert(identity != null),
        assert(sid != null),
        assert(signalingRegion != null),
        assert(localAudioTrackPublications != null),
        assert(localDataTrackPublications != null),
        assert(localVideoTrackPublications != null),
        assert(networkQualityLevel != null);

  factory LocalParticipantModel.fromEventChannelMap(Map<String, dynamic> map) {
    var localAudioTrackPublications = <LocalAudioTrackPublicationModel>[];
    if (map['localAudioTrackPublications'] != null) {
      final List<Map<String, dynamic>> localAudioTrackPublicationsList = map['localAudioTrackPublications'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();

      for (final localAudioTrackPublicationMap in localAudioTrackPublicationsList) {
        localAudioTrackPublications.add(LocalAudioTrackPublicationModel.fromEventChannelMap(localAudioTrackPublicationMap));
      }
    }

    var localDataTrackPublications = <LocalDataTrackPublicationModel>[];
    if (map['localDataTrackPublications'] != null) {
      final List<Map<String, dynamic>> localDataTrackPublicationsList = map['localDataTrackPublications'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();

      for (final localDataTrackPublicationMap in localDataTrackPublicationsList) {
        localDataTrackPublications.add(LocalDataTrackPublicationModel.fromEventChannelMap(localDataTrackPublicationMap));
      }
    }

    var localVideoTrackPublications = <LocalVideoTrackPublicationModel>[];
    if (map['localVideoTrackPublications'] != null) {
      final List<Map<String, dynamic>> localDataTrackPublicationsList = map['localVideoTrackPublications'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();

      for (final localVideoTrackPublicationMap in localDataTrackPublicationsList) {
        localVideoTrackPublications.add(LocalVideoTrackPublicationModel.fromEventChannelMap(localVideoTrackPublicationMap));
      }
    }

    var networkQualityLevel = EnumToString.fromString(NetworkQualityLevel.values, map['networkQualityLevel']) ?? NetworkQualityLevel.NETWORK_QUALITY_LEVEL_UNKNOWN;

    return LocalParticipantModel(
      identity: map['identity'],
      sid: map['sid'],
      signalingRegion: map['signalingRegion'],
      localAudioTrackPublications: localAudioTrackPublications,
      localDataTrackPublications: localDataTrackPublications,
      localVideoTrackPublications: localVideoTrackPublications,
      networkQualityLevel: networkQualityLevel,
    );
  }

  @override
  String toString() {
    var localAudioTrackPublicationsString = '';
    for (var localAudioTrackPublication in localAudioTrackPublications) {
      localAudioTrackPublicationsString += localAudioTrackPublication.toString() + ',';
    }

    var localDataTrackPublicationsString = '';
    for (var localDataTrackPublication in localDataTrackPublications) {
      localDataTrackPublicationsString += localDataTrackPublication.toString() + ',';
    }

    var localVideoTrackPublicationsString = '';
    for (var localVideoTrackPublication in localVideoTrackPublications) {
      localVideoTrackPublicationsString += localVideoTrackPublication.toString() + ',';
    }

    return '''{ 
      identity: $identity,
      sid: $sid,
      signalingRegion: $signalingRegion,
      localAudioTrackPublications: [ $localAudioTrackPublicationsString ],
      localDataTrackPublications: [ $localDataTrackPublicationsString ],
      localVideoTrackPublications: [ $localVideoTrackPublicationsString ],
      networkQualityLevel: $networkQualityLevel
      }''';
  }
}

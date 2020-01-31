part of twilio_unofficial_programmable_video;

/// Represents the local participant of a [Room] you are connected to.
class LocalParticipant implements Participant {
  final String _identity;

  final String _sid;

  final String _signalingRegion;

  NetworkQualityLevel _networkQualityLevel;

  final List<LocalAudioTrackPublication> _localAudioTrackPublications = <LocalAudioTrackPublication>[];

//  List<LocalVideoTrackPublication> _localVideoTrackPublications = <LocalVideoTrackPublication>[];

  final List<LocalVideoTrackPublication> _localVideoTrackPublications = <LocalVideoTrackPublication>[];

  /// The SID of this [LocalParticipant].
  @override
  String get sid {
    return _sid;
  }

  /// The identity of this [LocalParticipant].
  @override
  String get identity {
    return _identity;
  }

  /// Where the [LocalParticipant] signalling traffic enters and exits Twilio's communications cloud.
  ///
  /// This property reflects the region passed to [ConnectOptions.region] and when `gll` (the default value) is provided, the region that was selected will use latency based routing.
  String get signalingRegion {
    return _signalingRegion;
  }

  /// The network quality of the [LocalParticipant].
  NetworkQualityLevel get networkQualityLevel {
    return _networkQualityLevel;
  }

  /// Read-only list of local audio track publications.
  List<LocalAudioTrackPublication> get localAudioTracks {
    return [..._localAudioTrackPublications];
  }

//  /// Read-only list of local data track publications.
//  List<LocalDataTrackPublication> get localDataTracks {
//    return [..._localDataTrackPublications];
//  }

  /// Read-only list of local video track publications.
  List<LocalVideoTrackPublication> get localVideoTracks {
    return [..._localVideoTrackPublications];
  }

  /// Read-only list of audio track publications.
  @override
  List<AudioTrackPublication> get audioTracks {
    return [..._localAudioTrackPublications];
  }

//  /// Read-only list of data track publications.
//  List<DataTrackPublication> get dataTracks {
//    return [..._localDataTrackPublications];
//  }

  /// Read-only list of video track publications.
  @override
  List<VideoTrackPublication> get videoTracks {
    return [..._localVideoTrackPublications];
  }

  LocalParticipant(this._identity, this._sid, this._signalingRegion)
      : assert(_identity != null),
        assert(_sid != null),
        assert(_signalingRegion != null);

  /// Construct from a map.
  factory LocalParticipant._fromMap(Map<String, dynamic> map) {
    var localParticipant = LocalParticipant(map['identity'], map['sid'], map['signalingRegion']);
    localParticipant._updateFromMap(map);
    return localParticipant;
  }

  /// Update properties from a map.
  void _updateFromMap(Map<String, dynamic> map) {
    _networkQualityLevel = EnumToString.fromString(NetworkQualityLevel.values, map['networkQualityLevel']) ?? NetworkQualityLevel.NETWORK_QUALITY_LEVEL_UNKNOWN;

    if (map['localAudioTrackPublications'] != null) {
      final List<Map<String, dynamic>> localAudioTrackPublicationsList = map['localAudioTrackPublications'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();
      for (final localAudioTrackPublicationMap in localAudioTrackPublicationsList) {
        final localAudioTrackPublication = _localAudioTrackPublications.firstWhere(
          (p) => p.trackSid == localAudioTrackPublicationMap['sid'],
          orElse: () => LocalAudioTrackPublication._fromMap(localAudioTrackPublicationMap),
        );
        if (!_localAudioTrackPublications.contains(localAudioTrackPublication)) {
          _localAudioTrackPublications.add(localAudioTrackPublication);
        }
        localAudioTrackPublication._updateFromMap(localAudioTrackPublicationMap);
      }
    }

    if (map['localVideoTrackPublications'] != null) {
      final List<Map<String, dynamic>> localVideoTrackPublicationsList = map['localVideoTrackPublications'].map<Map<String, dynamic>>((r) => Map<String, dynamic>.from(r)).toList();
      for (final localVideoTrackPublicationMap in localVideoTrackPublicationsList) {
        final localVideoTrackPublication = _localVideoTrackPublications.firstWhere(
          (p) => p.trackSid == localVideoTrackPublicationMap['sid'],
          orElse: () => LocalVideoTrackPublication._fromMap(localVideoTrackPublicationMap),
        );
        if (!_localVideoTrackPublications.contains(localVideoTrackPublication)) {
          _localVideoTrackPublications.add(localVideoTrackPublication);
        }
        localVideoTrackPublication._updateFromMap(localVideoTrackPublicationMap);
      }
    }
  }
}

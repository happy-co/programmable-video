class EventChannelMaps {
  EventChannelMaps._();

  static const roomMap = {
    'sid': 'RMba7d25a843ce72748a1eb92fff757389',
    'name': 'gg',
    'state': 'CONNECTED',
    'mediaRegion': 'us1',
    'localParticipant': localParticipantMap,
    'remoteParticipants': [remoteParticipantMap]
  };

  static const remoteParticipantMap = {
    'identity': '4927e419e604ee7c',
    'sid': 'PAaf82147cb066cedcf978be215197bb09',
    'remoteAudioTrackPublications': [remoteAudioTrackPublicationMap],
    'remoteDataTrackPublications': [remoteDataTrackPublicationMap],
    'remoteVideoTrackPublications': [remoteVideoTrackPublicationMap]
  };

  static const remoteAudioTrackMap = {
    'sid': 'MT159e9a9186060d6aeeec8ba7a5e0ae26',
    'name': 'C8C40bABF30F89b2CaE3998221F0B61a',
    'enabled': true,
  };

  static const remoteAudioTrackPublicationMap = {
    'sid': 'MT159e9a9186060d6aeeec8ba7a5e0ae26',
    'name': 'C8C40bABF30F89b2CaE3998221F0B61a',
    'enabled': true,
    'subscribed': true,
    'remoteAudioTrack': remoteAudioTrackMap,
  };

  static const remoteDataTrackMap = {
    'name': 'BDDAEB2f7B7E1bE28105469E3FBc2F2C',
    'enabled': true,
    'ordered': true,
    'reliable': true,
    'maxPacketLifeTime': 65535,
    'maxRetransmits': 65535,
    'sid': 'BDDAEB2f7B7E1bE28105469E3FBc2F2C',
  };

  static const remoteDataTrackPublicationMap = {
    'sid': 'MT159e9a9186060d6aeeec8ba7a5e0ae26',
    'name': 'C8C40bABF30F89b2CaE3998221F0B61a',
    'enabled': true,
    'subscribed': true,
    'remoteDataTrack': remoteDataTrackMap,
  };

  static const remoteVideoTrackMap = {
    'sid': 'MT0c3b60d5b2ab87269e3c9f456798b9d7',
    'name': '9b1a4A64bC3822562c4b1dCeccC2F157',
    'enabled': true,
  };

  static const remoteVideoTrackPublicationMap = {
    'sid': 'MT0c3b60d5b2ab87269e3c9f456798b9d7',
    'name': '9b1a4A64bC3822562c4b1dCeccC2F157',
    'enabled': true,
    'subscribed': true,
    'remoteVideoTrack': remoteVideoTrackMap,
  };

  static const localParticipantMap = {
    'identity': 'f9d91472f2afa205',
    'sid': 'PA2c5543f3b09fad4c74b60472c3bc3857',
    'signalingRegion': 'de1',
    'networkQualityLevel': 'NETWORK_QUALITY_LEVEL_UNKNOWN',
    'localAudioTrackPublications': [localAudioTrackPublicationMap],
    'localDataTrackPublications': [localDataTrackPublicationMap],
    'localVideoTrackPublications': [localVideoTrackPublicationMap],
  };

  static const localAudioTrackMap = {
    'name': 'F80dCafa9EDC47fEc306cAf2Db8aC9a9',
    'enabled': true,
  };

  static const localAudioTrackPublicationMap = {'sid': 'MT7d48cf998e0e669597a64a2d4765ced6', 'localAudioTrack': localAudioTrackMap};

  static const localDataTrackMap = {
    'name': 'BDDAEB2f7B7E1bE28105469E3FBc2F2C',
    'enabled': true,
    'ordered': true,
    'reliable': true,
    'maxPacketLifeTime': 65535,
    'maxRetransmits': 65535,
  };

  static const localDataTrackPublicationMap = {'sid': 'MTbb9a4179496054a4b6dea62601fa6107', 'localDataTrack': localDataTrackMap};

  static const localVideoTrackMap = {
    'name': 'ff7181B9df9'
        'C4fe80b75cE24ec5A24a4',
    'enabled': true,
    'videoCapturer': {'type': 'CameraCapturer', 'cameraSource': 'FRONT_CAMERA'}
  };

  static const localVideoTrackPublicationMap = {'sid': 'MTa6d9276e5a198dbd9725a55d5fb7eb4c', 'localVideoTrack': localVideoTrackMap};

  static const errorMap = {'code': 20101, 'message': 'invalid token'};
}

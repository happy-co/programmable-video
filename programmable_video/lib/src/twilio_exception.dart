part of twilio_programmable_video;

/// Twilio Video SDK Exception.
class TwilioException implements Exception {
  /// This exception is iOS only.
  static final int unknownException = 0;
  static final int accessTokenInvalidException = 20101;
  static final int accessTokenHeaderInvalidException = 20102;
  static final int accessTokenIssuerInvalidException = 20103;
  static final int accessTokenExpiredException = 20104;
  static final int accessTokenNotYetValidException = 20105;
  static final int accessTokenGrantsInvalidException = 20106;
  static final int accessTokenSignatureInvalidException = 20107;
  static final int signalingConnectionErrorException = 53000;
  static final int signalingConnectionDisconnectedException = 53001;
  static final int signalingConnectionTimeoutException = 53002;
  static final int signalingIncomingMessageInvalidException = 53003;
  static final int signalingOutgoingMessageInvalidException = 53004;
  static final int signalingDnsResolutionErrorException = 53005;
  static final int signalingServerBusyException = 53006;
  static final int roomNameInvalidException = 53100;
  static final int roomNameTooLongException = 53101;
  static final int roomNameCharsInvalidException = 53102;
  static final int roomCreateFailedException = 53103;
  static final int roomConnectFailedException = 53104;
  static final int roomMaxParticipantsExceededException = 53105;
  static final int roomNotFoundException = 53106;
  static final int roomMaxParticipantsOutOfRangeException = 53107;
  static final int roomTypeInvalidException = 53108;
  static final int roomTimeoutOutOfRangeException = 53109;
  static final int roomStatusCallbackMethodInvalidException = 53110;
  static final int roomStatusCallbackInvalidException = 53111;
  static final int roomStatusInvalidException = 53112;
  static final int roomRoomExistsException = 53113;
  static final int roomInvalidParametersException = 53114;
  static final int roomMediaRegionInvalidException = 53115;
  static final int roomMediaRegionUnavailableException = 53116;
  static final int roomSubscriptionOperationNotSupportedException = 53117;
  static final int roomRoomCompletedException = 53118;
  static final int roomAccountLimitExceededException = 53119;
  static final int participantIdentityInvalidException = 53200;
  static final int participantIdentityTooLongException = 53201;
  static final int participantIdentityCharsInvalidException = 53202;
  static final int participantMaxTracksExceededException = 53203;
  static final int participantNotFoundException = 53204;
  static final int participantDuplicateIdentityException = 53205;
  static final int participantAccountLimitExceededException = 53206;
  static final int participantInvalidSubscribeRuleException = 53215;
  static final int trackInvalidException = 53300;
  static final int trackNameInvalidException = 53301;
  static final int trackNameTooLongException = 53302;
  static final int trackNameCharsInvalidException = 53303;
  static final int trackNameIsDuplicatedException = 53304;
  static final int trackServerTrackCapacityReachedException = 53305;
  static final int trackDataTrackMessageTooLargeException = 53306;
  static final int trackDataTrackSendBufferFullException = 53307;
  static final int mediaClientLocalDescFailedException = 53400;
  static final int mediaServerLocalDescFailedException = 53401;
  static final int mediaClientRemoteDescFailedException = 53402;
  static final int mediaServerRemoteDescFailedException = 53403;
  static final int mediaNoSupportedCodecException = 53404;
  static final int mediaConnectionErrorException = 53405;
  static final int mediaDataTrackFailedException = 53406;
  static final int mediaDtlsTransportFailedException = 53407;
  static final int mediaIceRestartNotAllowedException = 53408;
  static final int configurationAcquireFailedException = 53500;
  static final int configurationAcquireTurnFailedException = 53501;

  /// Code indicator, should match any of the [TwilioException] static properties.
  final int code;

  /// Message containing a short explanation.
  final String message;

  const TwilioException(this.code, this.message);

  @override
  String toString() {
    return 'TwilioException: code: $code, message: $message';
  }

  /// Construct from a [TwilioExceptionModel].
  factory TwilioException._fromModel(TwilioExceptionModel model) {
    return TwilioException(model.code, model.message);
  }
}

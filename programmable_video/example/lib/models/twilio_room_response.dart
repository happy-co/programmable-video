import 'package:enum_to_string/enum_to_string.dart';
import 'package:recase/recase.dart';
import 'package:twilio_programmable_video/twilio_programmable_video.dart';
import 'package:twilio_programmable_video_example/models/twilio_enums.dart';

class TwilioRoomLinks {
  final String participants;
  final String recordings;

  TwilioRoomLinks({this.participants, this.recordings});

  factory TwilioRoomLinks.fromMap(Map<String, String> data) {
    if (data == null) {
      return null;
    }
    return TwilioRoomLinks(
      participants: data['participants'],
      recordings: data['recordings'],
    );
  }

  Map<String, String> toMap() {
    return {'participants': participants, 'recordings': recordings};
  }
}

class TwilioRoomResponse {
  final String accountSid;
  final DateTime dateCreated;
  final DateTime dateUpdated;
  final TwilioRoomStatus status;
  final TwilioRoomType type;
  final String sid;
  final bool enableTurn;
  final String uniqueName;
  final int maxParticipants;
  final int duration;
  final TwilioStatusCallbackMethod statusCallbackMethod;
  final String statusCallback;
  final bool recordParticipantsOnConnect;
  final List<TwilioVideoCodec> videoCodecs;
  final Region mediaRegion;
  final DateTime endTime;
  final String url;
  final TwilioRoomLinks links;

  TwilioRoomResponse({
    this.accountSid,
    this.dateCreated,
    this.dateUpdated,
    this.status,
    this.type,
    this.sid,
    this.enableTurn,
    this.uniqueName,
    this.maxParticipants,
    this.duration,
    this.statusCallbackMethod,
    this.statusCallback,
    this.recordParticipantsOnConnect,
    this.videoCodecs,
    this.mediaRegion,
    this.endTime,
    this.url,
    this.links,
  });

  factory TwilioRoomResponse.fromMap(Map<String, dynamic> data) {
    if (data == null) {
      return null;
    }
    return TwilioRoomResponse(
      accountSid: data['accountSid'],
      duration: data['duration'],
      dateCreated: DateTime.tryParse(data['dateCreated'] ?? ''),
      dateUpdated: DateTime.tryParse(data['dateUpdated'] ?? ''),
      enableTurn: data['enableTurn'],
      endTime: DateTime.tryParse(data['endTime'] ?? ''),
      links: TwilioRoomLinks.fromMap(Map<String, String>.from(data['links'])),
      maxParticipants: data['maxParticipants'],
      mediaRegion: EnumToString.fromString(Region.values, data['mediaRegion']),
      recordParticipantsOnConnect: data['recordParticipantsOnConnect'],
      sid: data['sid'],
      status: EnumToString.fromString(TwilioRoomStatus.values, data['status'].toString().camelCase),
      statusCallback: data['statusCallback'],
      statusCallbackMethod: EnumToString.fromString(TwilioStatusCallbackMethod.values, data['statusCallbackMethod']),
      type: EnumToString.fromString(TwilioRoomType.values, data['type'].toString().camelCase),
      uniqueName: data['uniqueName'],
      url: data['url'],
      videoCodecs: (List<String>.from(data['videoCodecs']))
          .map(
            (String videoCodec) => EnumToString.fromString(TwilioVideoCodec.values, videoCodec),
          )
          .toList(),
    );
  }
}

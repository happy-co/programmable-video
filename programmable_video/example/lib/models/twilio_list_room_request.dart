import 'package:enum_to_string/enum_to_string.dart';
import 'package:intl/intl.dart';
import 'package:recase/recase.dart';
import 'package:twilio_programmable_video_example/models/twilio_enums.dart';

class TwilioListRoomRequest {
  final DateTime? dateCreatedAfter;
  final DateTime? dateCreatedBefore;
  final int? limit;
  final TwilioRoomStatus? status;
  final String uniqueName;

  TwilioListRoomRequest({
    this.dateCreatedAfter,
    this.dateCreatedBefore,
    this.limit,
    this.status,
    required this.uniqueName,
  });

  factory TwilioListRoomRequest.fromMap(Map<String, dynamic> data) {
    return TwilioListRoomRequest(
      dateCreatedAfter: DateTime.tryParse(data['dateCreatedAfter'] ?? ''),
      dateCreatedBefore: DateTime.tryParse(data['dateCreatedBefore'] ?? ''),
      limit: data['limit'],
      status: EnumToString.fromString(TwilioRoomStatus.values, data['status'].toString().camelCase),
      uniqueName: data['uniqueName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dateCreatedAfter': DateFormat('yyyy-MM-dd').format(dateCreatedAfter!),
      'dateCreatedBefore': DateFormat('yyyy-MM-dd').format(dateCreatedBefore!),
      'limit': limit,
      'status': status != null ? EnumToString.convertToString(status).paramCase : null,
      'uniqueName': uniqueName,
    };
  }
}

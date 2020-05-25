import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:twilio_programmable_video_example/models/twilio_list_room_request.dart';
import 'package:twilio_programmable_video_example/models/twilio_list_room_response.dart';
import 'package:twilio_programmable_video_example/models/twilio_room_by_sid_request.dart';
import 'package:twilio_programmable_video_example/models/twilio_room_by_unique_name_request.dart';
import 'package:twilio_programmable_video_example/models/twilio_room_request.dart';
import 'package:twilio_programmable_video_example/models/twilio_room_response.dart';
import 'package:twilio_programmable_video_example/models/twilio_room_token_request.dart';
import 'package:twilio_programmable_video_example/models/twilio_room_token_response.dart';

abstract class BackendService {
  Future<TwilioRoomResponse> completeRoomBySid(TwilioRoomBySidRequest twilioRoomBySidRequest);
  Future<TwilioRoomResponse> createRoom(TwilioRoomRequest twilioRoomRequest);
  Future<TwilioRoomTokenResponse> createToken(TwilioRoomTokenRequest twilioRoomTokenRequest);
  Future<TwilioRoomResponse> getRoomBySid(TwilioRoomBySidRequest twilioRoomBySidRequest);
  Future<TwilioRoomResponse> getRoomByUniqueName(TwilioRoomByUniqueNameRequest twilioRoomByUniqueNameRequest);
  Future<TwilioListRoomResponse> listRooms(TwilioListRoomRequest twilioListRoomRequest);
}

class FirebaseFunctions implements BackendService {
  FirebaseFunctions._();

  static final instance = FirebaseFunctions._();

  final CloudFunctions cf = CloudFunctions(region: 'europe-west1');

  @override
  Future<TwilioRoomResponse> completeRoomBySid(TwilioRoomBySidRequest twilioRoomBySidRequest) async {
    try {
      final response = await cf.getHttpsCallable(functionName: 'completeRoomBySid').call(twilioRoomBySidRequest.toMap());
      return TwilioRoomResponse.fromMap(Map<String, dynamic>.from(response.data));
    } on CloudFunctionsException catch (e) {
      throw PlatformException(
        code: e.code,
        message: e.message,
        details: e.details,
      );
    }
  }

  @override
  Future<TwilioRoomResponse> createRoom(TwilioRoomRequest twilioRoomRequest) async {
    try {
      final response = await cf.getHttpsCallable(functionName: 'createRoom').call(twilioRoomRequest.toMap());
      return TwilioRoomResponse.fromMap(Map<String, dynamic>.from(response.data));
    } on CloudFunctionsException catch (e) {
      throw PlatformException(
        code: e.code,
        message: e.message,
        details: e.details,
      );
    }
  }

  @override
  Future<TwilioRoomTokenResponse> createToken(TwilioRoomTokenRequest twilioRoomTokenRequest) async {
    try {
      final response = await cf.getHttpsCallable(functionName: 'createToken').call(twilioRoomTokenRequest.toMap());
      return TwilioRoomTokenResponse.fromMap(Map<String, dynamic>.from(response.data));
    } on CloudFunctionsException catch (e) {
      throw PlatformException(
        code: e.code,
        message: e.message,
        details: e.details,
      );
    }
  }

  @override
  Future<TwilioRoomResponse> getRoomBySid(TwilioRoomBySidRequest twilioRoomBySidRequest) async {
    try {
      final response = await cf.getHttpsCallable(functionName: 'getRoomBySid').call(twilioRoomBySidRequest.toMap());
      return TwilioRoomResponse.fromMap(Map<String, dynamic>.from(response.data));
    } on CloudFunctionsException catch (e) {
      throw PlatformException(
        code: e.code,
        message: e.message,
        details: e.details,
      );
    }
  }

  @override
  Future<TwilioRoomResponse> getRoomByUniqueName(TwilioRoomByUniqueNameRequest twilioRoomByUniqueNameRequest) async {
    try {
      final response = await cf.getHttpsCallable(functionName: 'getRoomByUniqueName').call(twilioRoomByUniqueNameRequest.toMap());
      return TwilioRoomResponse.fromMap(Map<String, dynamic>.from(response.data));
    } on CloudFunctionsException catch (e) {
      throw PlatformException(
        code: e.code,
        message: e.message,
        details: e.details,
      );
    }
  }

  @override
  Future<TwilioListRoomResponse> listRooms(TwilioListRoomRequest twilioListRoomRequest) async {
    try {
      final response = await cf.getHttpsCallable(functionName: 'listRooms').call(twilioListRoomRequest.toMap());
      return TwilioListRoomResponse.fromMap(Map<String, dynamic>.from(response.data));
    } on CloudFunctionsException catch (e) {
      throw PlatformException(
        code: e.code,
        message: e.message,
        details: e.details,
      );
    }
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:twilio_programmable_video_platform_interface/src/method_channel_programmable_video.dart';
import 'package:twilio_programmable_video_platform_interface/src/programmable_video_platform_interface.dart';

void main() {
  group('ProgrammableVideoPlatform', () {
    test('MethodChannelProgrammableVideo is the default instance', () {
      expect(ProgrammableVideoPlatform.instance, isA<MethodChannelProgrammableVideo>());
    });

    test('Cannot be implemented', () {
      expect(() {
        ProgrammableVideoPlatform.instance = ImplementsProgrammableVideoPlatform();
      }, throwsAssertionError);
    });

    test('Can be extended', () {
      ProgrammableVideoPlatform.instance = ExtendsProgrammableVideoPlatform();
    });

    test('Unimplemented methods should throw UnimplementedError', () {
      ProgrammableVideoPlatform.instance = ExtendsProgrammableVideoPlatform();

      expect(() => ProgrammableVideoPlatform.instance.disconnect(), throwsUnimplementedError);
      expect(() => ProgrammableVideoPlatform.instance.setNativeDebug(true), throwsUnimplementedError);
      expect(() => ProgrammableVideoPlatform.instance.setSpeakerphoneOn(true), throwsUnimplementedError);
      expect(() => ProgrammableVideoPlatform.instance.getSpeakerphoneOn(), throwsUnimplementedError);
      expect(() => ProgrammableVideoPlatform.instance.connectToRoom(MockConnectOptionsModel()), throwsUnimplementedError);
      expect(() => ProgrammableVideoPlatform.instance.enableVideoTrack(), throwsUnimplementedError);
      expect(() => ProgrammableVideoPlatform.instance.sendMessage(), throwsUnimplementedError);
      expect(() => ProgrammableVideoPlatform.instance.sendBuffer(), throwsUnimplementedError);
      expect(() => ProgrammableVideoPlatform.instance.enableAudioTrack(), throwsUnimplementedError);
      expect(() => ProgrammableVideoPlatform.instance.switchCamera(), throwsUnimplementedError);
      expect(() => ProgrammableVideoPlatform.instance.roomStream(0), throwsUnimplementedError);
      expect(() => ProgrammableVideoPlatform.instance.remoteParticipantStream(0), throwsUnimplementedError);
      expect(() => ProgrammableVideoPlatform.instance.localParticipantStream(0), throwsUnimplementedError);
      expect(() => ProgrammableVideoPlatform.instance.remoteDataTrackStream(0), throwsUnimplementedError);
      expect(() => ProgrammableVideoPlatform.instance.loggingStream(), throwsUnimplementedError);
      expect(() => ProgrammableVideoPlatform.instance.enableRemoteAudioTrack(enable: true, sid: 'sid'), throwsUnimplementedError);
      expect(() => ProgrammableVideoPlatform.instance.isRemoteAudioTrackPlaybackEnabled('sid'), throwsUnimplementedError);
    });
  });
}

class MockConnectOptionsModel extends Mock implements ConnectOptionsModel {}

class ImplementsProgrammableVideoPlatform extends Mock implements ProgrammableVideoPlatform {}

class ExtendsProgrammableVideoPlatform extends ProgrammableVideoPlatform {}

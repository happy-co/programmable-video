import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video/src/parts.dart';
import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';

import 'mock_platform_interface.dart';

void main() {
  group('.send()', () {
    test('should call interface code to send a String message', () async {
      final mockInterface = MockInterface();
      ProgrammableVideoPlatform.instance = mockInterface;
      final localDataTrack = LocalDataTrack(
        DataTrackOptions(ordered: true, maxRetransmits: 10, maxPacketLifeTime: -1, name: 'name5'),
      );
      await localDataTrack.send('message');

      expect(mockInterface.sendMessageWasCalled, true);
    });
  });

  group('.sendBuffer()', () {
    test('should call interface code to send a String message', () async {
      final mockInterface = MockInterface();
      ProgrammableVideoPlatform.instance = mockInterface;
      final localDataTrack = LocalDataTrack(
        DataTrackOptions(ordered: true, maxRetransmits: 10, maxPacketLifeTime: -1, name: 'name6'),
      );
      final list = 'This data has been sent over the ByteBuffer channel of the DataTrack API'.codeUnits;
      var bytes = Uint8List.fromList(list);
      await localDataTrack.sendBuffer(bytes.buffer);

      expect(mockInterface.sendBufferWasCalled, true);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video/src/parts.dart';

void main() {
  group('DataTrackOptions()', () {
    test('maxRetransmits and maxPacketLifeTime should be mutually exclusive', () async {
      expect(() => DataTrackOptions(maxRetransmits: 10, maxPacketLifeTime: 10, name: 'name1'), throwsAssertionError);
      expect(DataTrackOptions(maxRetransmits: 10, name: 'name2'), isA<DataTrackOptions>());
      expect(DataTrackOptions(maxPacketLifeTime: 10, name: 'name3'), isA<DataTrackOptions>());
      expect(DataTrackOptions(name: 'name4'), isA<DataTrackOptions>());
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video/src/parts.dart';

void main() {
  group('DataTrackOptions()', () {
    test('should not construct without ordered', () async {
      expect(() => DataTrackOptions(ordered: null), throwsAssertionError);
    });

    test('should not construct without maxPacketLifeTime', () async {
      expect(() => DataTrackOptions(maxPacketLifeTime: null), throwsAssertionError);
    });

    test('should not construct without maxRetransmits', () async {
      expect(() => DataTrackOptions(maxRetransmits: null), throwsAssertionError);
    });

    test('maxRetransmits and maxPacketLifeTime should be mutually exclusive', () async {
      expect(() => DataTrackOptions(maxRetransmits: 10, maxPacketLifeTime: 10), throwsAssertionError);
      expect(DataTrackOptions(maxRetransmits: 10), isA<DataTrackOptions>());
      expect(DataTrackOptions(maxPacketLifeTime: 10), isA<DataTrackOptions>());
      expect(DataTrackOptions(), isA<DataTrackOptions>());
    });
  });
}

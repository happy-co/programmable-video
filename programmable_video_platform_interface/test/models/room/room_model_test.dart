import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video_platform_interface/src/enums/enum_exports.dart';
import 'package:twilio_programmable_video_platform_interface/src/enums/region.dart';

import 'package:twilio_programmable_video_platform_interface/src/models/model_exports.dart';

import '../model_instances.dart';

void main() {
  final name = 'name';
  final sid = 'sid';
  final mediaRegion = Region.br1;
  final state = RoomState.CONNECTING;
  final localParticipant = ModelInstances.localParticipantModel;
  final remoteParticipants = [ModelInstances.remoteParticipantModel];

  group('.toString()', () {
    test('should return correct String', () {
      final model = RoomModel(
        name: name,
        sid: sid,
        mediaRegion: mediaRegion,
        state: state,
        localParticipant: localParticipant,
        remoteParticipants: remoteParticipants,
      );
      expect(
        model.toString(),
        '{ sid: $sid, name: $name, state: $state, mediaRegion: $mediaRegion, localParticipant: $localParticipant, remoteParticipants: [ ${remoteParticipants[0].toString()}, ] }',
      );
    });
  });

  group('RoomModel()', () {
    test('should not construct without name', () {
      expect(
          () => RoomModel(
                name: null,
                sid: sid,
                mediaRegion: mediaRegion,
                state: state,
                localParticipant: localParticipant,
                remoteParticipants: remoteParticipants,
              ),
          throwsAssertionError);
    });
  });
}

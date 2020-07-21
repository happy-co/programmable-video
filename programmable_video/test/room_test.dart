import 'package:flutter_test/flutter_test.dart';
import 'package:twilio_programmable_video/src/parts.dart';

import 'package:twilio_programmable_video_platform_interface/twilio_programmable_video_platform_interface.dart';
import 'mock_platform_interface.dart';
import 'model_instances.dart';

void main() {
  group('.disconnect()', () {
    test('should call interface code to disconnect from room', () async {
      final mockInterface = MockInterface();
      ProgrammableVideoPlatform.instance = mockInterface;
      final room = Room(0);
      await room.disconnect();

      expect(mockInterface.disconnectWasCalled, true);
    });
  });

  MockInterface mockInterface;
  Room room;
  setUp(() {
    mockInterface = MockInterface();
    ProgrammableVideoPlatform.instance = mockInterface;
    room = Room(0);
  });

  group('Room', () {
    test('should update properties correctly from an interface event', () async {
      final updateRoom = RoomModel(
        name: 'updateRoom',
        sid: 'updateRoomSid',
        mediaRegion: Region.jp1,
        state: RoomState.RECONNECTING,
        localParticipant: ModelInstances.localParticipantModel,
        remoteParticipants: <RemoteParticipantModel>[],
      );

      mockInterface.addRoomEvent(Connected(updateRoom));
      expect(await room.onConnected.first, room);
      expect(room.name, updateRoom.name);
      expect(room.sid, updateRoom.sid);
      expect(room.mediaRegion, updateRoom.mediaRegion);
      expect(room.state, updateRoom.state);
    });
  });

  group('.onConnected', () {
    test('should return current room after a `Connected` event arrives from the interface', () async {
      mockInterface.addRoomEvent(Connected(ModelInstances.roomModel));
      expect(await room.onConnected.first, room);
    });
  });

  group('.onDisconnected', () {
    test('should return correct `RoomDisconnectedEvent` after a `Disconnected` event arrives from the interface', () async {
      final exceptionModel = ModelInstances.twilioExceptionModel;
      mockInterface.addRoomEvent(Disconnected(ModelInstances.roomModel, exceptionModel));
      final event = await room.onDisconnected.first;
      expect(event.room, room);
      expect(event.exception.code, exceptionModel.code);
      expect(event.exception.message, exceptionModel.message);
    });
  });

  group('.onConnectFailure', () {
    test('should return correct `RoomConnectFailureEvent` after a `ConnectFailure` event arrives from the interface', () async {
      final exceptionModel = ModelInstances.twilioExceptionModel;
      mockInterface.addRoomEvent(ConnectFailure(ModelInstances.roomModel, exceptionModel));
      final event = await room.onConnectFailure.first;
      expect(event.room, room);
      expect(event.exception.code, exceptionModel.code);
      expect(event.exception.message, exceptionModel.message);
    });
  });

  group('.onDominantSpeakerChange', () {
    test('should return correct `DominantSpeakerChangedEvent` after a `DominantSpeakerChanged` event arrives from the interface', () async {
      final remoteParticipantModel = ModelInstances.remoteParticipantModel;
      mockInterface.addRoomEvent(DominantSpeakerChanged(ModelInstances.roomModel, remoteParticipantModel));
      final event = await room.onDominantSpeakerChange.first;
      expect(event.room, room);
      expect(
        event.remoteParticipant,
        room.remoteParticipants.firstWhere(
          (RemoteParticipant p) => p.sid == event.remoteParticipant.sid,
          orElse: () => null,
        ),
      );
    });
  });

  group('.onParticipantConnected', () {
    test('should return correct `RoomParticipantConnectedEvent` after a `ParticipantConnected` event arrives from the interface', () async {
      final remoteParticipantModel = ModelInstances.remoteParticipantModel;
      mockInterface.addRoomEvent(ParticipantConnected(ModelInstances.roomModel, remoteParticipantModel));
      final event = await room.onParticipantConnected.first;
      expect(event.room, room);
      expect(
        event.remoteParticipant,
        room.remoteParticipants.firstWhere(
          (RemoteParticipant p) => p.sid == event.remoteParticipant.sid,
          orElse: () => null,
        ),
      );
    });
  });

  group('.onParticipantDisconnected', () {
    test('should return correct `RoomParticipantDisconnectedEvent` after a `ParticipantDisconnected` event arrives from the interface', () async {
      final remoteParticipantModel = ModelInstances.remoteParticipantModel;
      mockInterface.addRoomEvent(ParticipantDisconnected(ModelInstances.roomModel, remoteParticipantModel));
      final event = await room.onParticipantDisconnected.first;
      expect(event.room, room);
      expect(
        null,
        room.remoteParticipants.firstWhere(
          (RemoteParticipant p) => p.sid == event.remoteParticipant.sid,
          orElse: () => null,
        ),
      );
    });
  });

  group('.onReconnected', () {
    test('should return current room after a `Reconnected` event arrives from the interface', () async {
      mockInterface.addRoomEvent(Reconnected(ModelInstances.roomModel));
      expect(await room.onReconnected.first, room);
    });
  });

  group('.onReconnecting', () {
    test('should return correct `RoomReconnectingEvent` after a `Reconnecting` event arrives from the interface', () async {
      final exceptionModel = ModelInstances.twilioExceptionModel;
      mockInterface.addRoomEvent(Reconnecting(ModelInstances.roomModel, exceptionModel));
      final event = await room.onReconnecting.first;
      expect(event.room, room);
      expect(event.exception.code, exceptionModel.code);
      expect(event.exception.message, exceptionModel.message);
    });
  });

  group('.onRecordingStarted', () {
    test('should return current room after a `RecordingStarted` event arrives from the interface', () async {
      mockInterface.addRoomEvent(RecordingStarted(ModelInstances.roomModel));
      expect(await room.onRecordingStarted.first, room);
    });
  });

  group('.onRecordingStopped', () {
    test('should return current room after a `RecordingStarted` event arrives from the interface', () async {
      mockInterface.addRoomEvent(RecordingStopped(ModelInstances.roomModel));
      expect(await room.onRecordingStopped.first, room);
    });
  });
}

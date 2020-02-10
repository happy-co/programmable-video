import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twilio_unofficial_programmable_video/twilio_unofficial_programmable_video.dart';
import 'package:twilio_unofficial_programmable_video_example/conference/conference_button_bar.dart';
import 'package:twilio_unofficial_programmable_video_example/conference/draggable_publisher.dart';
import 'package:twilio_unofficial_programmable_video_example/conference/participant_widget.dart';
import 'package:twilio_unofficial_programmable_video_example/debug.dart';
import 'package:twilio_unofficial_programmable_video_example/room/room_model.dart';
import 'package:twilio_unofficial_programmable_video_example/shared/services/platform_service.dart';
import 'package:twilio_unofficial_programmable_video_example/shared/widgets/noise_box.dart';
import 'package:twilio_unofficial_programmable_video_example/shared/widgets/platform_alert_dialog.dart';
import 'package:twilio_unofficial_programmable_video_example/shared/widgets/platform_exception_alert_dialog.dart';
import 'package:wakelock/wakelock.dart';

class ConferencePage extends StatefulWidget {
  final RoomModel roomModel;

  const ConferencePage({
    Key key,
    @required this.roomModel,
  }) : super(key: key);

  @override
  _ConferencePageState createState() => _ConferencePageState();
}

class _ConferencePageState extends State<ConferencePage> {
  final StreamController<ParticipantMediaEnabled> _onAudioEnabledStreamController = StreamController<ParticipantMediaEnabled>.broadcast();
  Stream<ParticipantMediaEnabled> _onAudioEnabledStream;
  final StreamController<ParticipantMediaEnabled> _onVideoEnabledStreamController = StreamController<ParticipantMediaEnabled>.broadcast();
  Stream<ParticipantMediaEnabled> _onVideoEnabledStream;

  CameraCapturer _cameraCapturer;

  Room _room;
  String _deviceId;
  final StreamController<bool> _onButtonBarVisibleStreamController = StreamController<bool>.broadcast();

  final List<ParticipantWidget> _participants = [];
  final List<ParticipantBuffer> _participantBuffer = [];
  final List<StreamSubscription> _streamSubscriptions = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _wakeLock(true);
    _getDeviceId();
    _connectToRoom();
    _onAudioEnabledStream = _onAudioEnabledStreamController.stream;
    _onVideoEnabledStream = _onVideoEnabledStreamController.stream;
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(<DeviceOrientation>[
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _wakeLock(false);
    _disposeStreamsAndSubscriptions();
    super.dispose();
  }

  Future<void> _disposeStreamsAndSubscriptions() async {
    await _onButtonBarVisibleStreamController.close();
    await _onAudioEnabledStreamController.close();
    await _onVideoEnabledStreamController.close();
    for (var streamSubscription in _streamSubscriptions) {
      await streamSubscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        onTap: null,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Stack(
                children: <Widget>[
                  _buildParticipants(context, constraints.biggest),
                  ConferenceButtonBar(
                    videoEnabled: _onVideoEnabledStream,
                    audioEnabled: _onAudioEnabledStream,
                    onVideoEnabled: _onLocalVideoEnabled,
                    onAudioEnabled: _onLocalAudioEnabled,
                    onHangup: _onHangup,
                    onSwitchCamera: _onSwitchCamera,
                    onPersonAdd: _onPersonAdd,
                    onPersonRemove: _onPersonRemove,
                    onShow: _onShowBar,
                    onHide: _onHideBar,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _getDeviceId() async {
    try {
      _deviceId = await PlatformService.deviceId;
    } catch (err) {
      Debug.log(err);
      _deviceId = DateTime.now().millisecondsSinceEpoch.toString();
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _connectToRoom() async {
    try {
      await TwilioUnofficialProgrammableVideo.debug(dart: true, native: true);
      _cameraCapturer = CameraCapturer(CameraSource.FRONT_CAMERA);
      var connectOptions = ConnectOptions(widget.roomModel.token)
        ..roomName(widget.roomModel.name)
        ..preferAudioCodecs([OpusCodec()])
        ..audioTracks([LocalAudioTrack(true)])
        ..videoTracks([LocalVideoTrack(true, _cameraCapturer)]);

      _room = await TwilioUnofficialProgrammableVideo.connect(connectOptions);

      _streamSubscriptions.add(_room.onConnected.listen(_onConnected));
      _streamSubscriptions.add(_room.onParticipantConnected.listen(_onParticipantConnected));
      _streamSubscriptions.add(_room.onParticipantDisconnected.listen(_onParticipantDisconnected));
      _streamSubscriptions.add(_room.onConnectFailure.listen(_onConnectFailure));
    } catch (err) {
      Debug.log(err);
      await PlatformExceptionAlertDialog(
        exception: err,
      ).show(context);
      Navigator.of(context).pop();
    }
  }

  ParticipantWidget _buildParticipant({
    @required Widget child,
    @required String id,
    @required bool audioEnabled,
    @required bool videoEnabled,
    RemoteParticipant remoteParticipant,
  }) {
    return ParticipantWidget(
      id: remoteParticipant?.sid,
      isRemote: remoteParticipant != null,
      child: child,
      audioEnabled: audioEnabled,
      videoEnabled: videoEnabled,
    );
  }

  void _onConnected(RoomEvent roomEvent) {
    Debug.log('onConnected => state: ${roomEvent.room.state}');
    setState(() {
      if (roomEvent.room.state == RoomState.CONNECTED) {
        // Only add ourselves when connected for the first time
        _participants.add(
          _buildParticipant(
            child: roomEvent.room.localParticipant.localVideoTracks[0].localVideoTrack.widget(),
            id: _deviceId,
            audioEnabled: true,
            videoEnabled: true,
          ),
        );
      }
      for (final remoteParticipant in roomEvent.room.remoteParticipants) {
        var participant = _participants.firstWhere((participant) => participant.id == remoteParticipant.sid, orElse: () => null);
        if (participant == null) {
          Debug.log('Adding participant that was already present in the room ${remoteParticipant.sid}, before I connected');
          _addRemoteParticipantListeners(remoteParticipant);
        }
      }
    });
  }

  void _onParticipantConnected(RoomEvent roomEvent) {
    Debug.log('onParticipantConnected, ${roomEvent.remoteParticipant.sid}');
    _addRemoteParticipantListeners(roomEvent.remoteParticipant);
  }

  void _addRemoteParticipantListeners(RemoteParticipant remoteParticipant) {
    Debug.log('Adding listeners to remoteParticipant ${remoteParticipant.sid}');
    _streamSubscriptions.add(remoteParticipant.onAudioTrackDisabled.listen(_onAudioTrackDisabled));
    _streamSubscriptions.add(remoteParticipant.onAudioTrackEnabled.listen(_onAudioTrackEnabled));
    _streamSubscriptions.add(remoteParticipant.onAudioTrackPublished.listen(_onAudioTrackPublished));
    _streamSubscriptions.add(remoteParticipant.onAudioTrackSubscribed.listen(_onAudioTrackSubscribed));
    _streamSubscriptions.add(remoteParticipant.onAudioTrackSubscriptionFailed.listen(_onAudioTrackSubscriptionFailed));
    _streamSubscriptions.add(remoteParticipant.onAudioTrackUnpublished.listen(_onAudioTrackUnpublished));
    _streamSubscriptions.add(remoteParticipant.onAudioTrackUnsubscribed.listen(_onAudioTrackUnsubscribed));

    _streamSubscriptions.add(remoteParticipant.onVideoTrackDisabled.listen(_onVideoTrackDisabled));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackEnabled.listen(_onVideoTrackEnabled));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackPublished.listen(_onVideoTrackPublished));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackSubscribed.listen(_onVideoTrackSubscribed));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackSubscriptionFailed.listen(_onVideoTrackSubscriptionFailed));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackUnpublished.listen(_onVideoTrackUnpublished));
    _streamSubscriptions.add(remoteParticipant.onVideoTrackUnsubscribed.listen(_onVideoTrackUnsubscribed));
  }

  void _onParticipantDisconnected(RoomEvent roomEvent) {
    Debug.log('onParticipantDisconnected: ${roomEvent.remoteParticipant.sid}');
    setState(() {
      _participants.removeWhere((ParticipantWidget p) => p.id == roomEvent.remoteParticipant.sid);
    });
  }

  Future<void> _onConnectFailure(RoomEvent roomEvent) async {
    Debug.log('onConnectFailure: ${roomEvent.exception}');
    await PlatformAlertDialog(
      title: 'Connect failure',
      content: roomEvent.exception.message,
      defaultActionText: 'OK',
    ).show(context);
    Navigator.of(context).pop();
  }

  void _onAudioTrackDisabled(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('onAudioTrackDisabled, ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteAudioTrack.sid}, isEnabled: ${remoteParticipantEvent.remoteAudioTrack.isEnabled}');
    _setRemoteAudioEnabled(remoteParticipantEvent);
  }

  void _onAudioTrackEnabled(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('onAudioTrackEnabled, ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteAudioTrack.sid}, isEnabled: ${remoteParticipantEvent.remoteAudioTrack.isEnabled}');
    _setRemoteAudioEnabled(remoteParticipantEvent);
  }

  void _onAudioTrackPublished(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('onAudioTrackPublished, ${remoteParticipantEvent.remoteParticipant.sid}}');
  }

  void _onAudioTrackSubscribed(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('onAudioTrackSubscribed, ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteAudioTrackPublication.trackSid}');
    _addOrUpdateParticipant(remoteParticipantEvent);
  }

  void _onAudioTrackSubscriptionFailed(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('onAudioTrackSubscriptionFailed, ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteAudioTrackPublication.trackSid}');
    PlatformAlertDialog(
      title: 'AudioTrack Subscription Failed',
      content: remoteParticipantEvent.exception.toString(),
      defaultActionText: 'OK',
    ).show(context);
  }

  void _onAudioTrackUnpublished(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('onAudioTrackUnpublished, ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteAudioTrackPublication.trackSid}');
  }

  void _onAudioTrackUnsubscribed(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('onAudioTrackUnsubscribed, ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteAudioTrack.sid}');
  }

  void _onVideoTrackDisabled(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('onVideoTrackDisabled, ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteVideoTrack.sid}, isEnabled: ${remoteParticipantEvent.remoteVideoTrack.isEnabled}');
    _setRemoteVideoEnabled(remoteParticipantEvent);
  }

  void _onVideoTrackEnabled(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('onVideoTrackEnabled, ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteVideoTrack.sid}, isEnabled: ${remoteParticipantEvent.remoteVideoTrack.isEnabled}');
    _setRemoteVideoEnabled(remoteParticipantEvent);
  }

  void _onVideoTrackPublished(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('onVideoTrackPublished, ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteVideoTrackPublication.trackSid}');
  }

  void _onVideoTrackSubscribed(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('onVideoTrackSubscribed, ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteVideoTrack.sid}');
    _addOrUpdateParticipant(remoteParticipantEvent);
  }

  void _onVideoTrackSubscriptionFailed(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('onVideoTrackSubscriptionFailed, ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteVideoTrackPublication.trackSid}');
    PlatformAlertDialog(
      title: 'VideoTrack Subscription Failed',
      content: remoteParticipantEvent.exception.toString(),
      defaultActionText: 'OK',
    ).show(context);
  }

  void _onVideoTrackUnpublished(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('onVideoTrackUnpublished, ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteVideoTrackPublication.trackSid}');
  }

  void _onVideoTrackUnsubscribed(RemoteParticipantEvent remoteParticipantEvent) {
    Debug.log('onVideoTrackUnsubscribed, ${remoteParticipantEvent.remoteParticipant.sid}, ${remoteParticipantEvent.remoteVideoTrack.sid}');
  }

  void _addOrUpdateParticipant(RemoteParticipantEvent remoteParticipantEvent) {
    final participant = _participants.firstWhere(
      (ParticipantWidget participant) => participant.id == remoteParticipantEvent.remoteParticipant.sid,
      orElse: () => null,
    );
    if (participant != null) {
      Debug.log('Participant found: ${participant.id}, updating A/V enabled values');
      _setRemoteVideoEnabled(remoteParticipantEvent);
      _setRemoteAudioEnabled(remoteParticipantEvent);
    } else {
      final bufferedParticipant = _participantBuffer.firstWhere(
        (ParticipantBuffer participant) => participant.id == remoteParticipantEvent.remoteParticipant.sid,
        orElse: () => null,
      );
      if (bufferedParticipant != null) {
        _participantBuffer.remove(bufferedParticipant);
      } else if (remoteParticipantEvent.remoteVideoTrack == null) {
        Debug.log('Audio subscription came first, waiting for the video subscription...');
        _participantBuffer.add(
          ParticipantBuffer(
            id: remoteParticipantEvent.remoteParticipant.sid,
            audioEnabled: remoteParticipantEvent.remoteAudioTrackPublication?.remoteAudioTrack?.isEnabled ?? true,
          ),
        );
        return;
      }
      Debug.log('New participant, adding: ${remoteParticipantEvent.remoteParticipant.sid}');
      setState(() {
        _participants.insert(
          0,
          _buildParticipant(
            child: remoteParticipantEvent.remoteVideoTrack.widget(),
            id: remoteParticipantEvent.remoteParticipant.sid,
            remoteParticipant: remoteParticipantEvent.remoteParticipant,
            audioEnabled: remoteParticipantEvent.remoteAudioTrackPublication?.remoteAudioTrack?.isEnabled ?? bufferedParticipant?.audioEnabled ?? true,
            videoEnabled: remoteParticipantEvent.remoteVideoTrackPublication?.remoteVideoTrack?.isEnabled ?? true,
          ),
        );
      });
    }
  }

  void _setRemoteAudioEnabled(RemoteParticipantEvent remoteParticipantEvent) {
    if (remoteParticipantEvent.remoteAudioTrackPublication == null) {
      return;
    }
    setState(() {
      var index = _participants.indexWhere((ParticipantWidget participant) => participant.id == remoteParticipantEvent.remoteParticipant.sid);
      if (index < 0) {
        return;
      }
      var participant = _participants[index];
      _participants.replaceRange(
        index,
        index + 1,
        [
          participant.copyWith(audioEnabled: remoteParticipantEvent.remoteAudioTrackPublication.isTrackEnabled),
        ],
      );
    });
  }

  void _setRemoteVideoEnabled(RemoteParticipantEvent remoteParticipantEvent) {
    if (remoteParticipantEvent.remoteVideoTrackPublication == null) {
      return;
    }
    setState(() {
      var index = _participants.indexWhere((ParticipantWidget participant) => participant.id == remoteParticipantEvent.remoteParticipant.sid);
      if (index < 0) {
        return;
      }
      var participant = _participants[index];
      _participants.replaceRange(
        index,
        index + 1,
        [
          participant.copyWith(videoEnabled: remoteParticipantEvent.remoteVideoTrackPublication.isTrackEnabled),
        ],
      );
    });
  }

  Future<void> _onLocalVideoEnabled() async {
    final localVideoTrack = _room.localParticipant.localVideoTracks[0].localVideoTrack;
    await localVideoTrack.enable(!localVideoTrack.isEnabled);
    setState(() {
      var index = _participants.indexWhere((ParticipantWidget participant) => !participant.isRemote);
      if (index < 0) {
        return;
      }
      var participant = _participants[index];
      _participants.replaceRange(
        index,
        index + 1,
        [
          participant.copyWith(videoEnabled: localVideoTrack.isEnabled),
        ],
      );
    });
    _onVideoEnabledStreamController.add(
      ParticipantMediaEnabled(
        isEnabled: localVideoTrack.isEnabled,
      ),
    );
    Debug.log('onVideoEnabled: ${localVideoTrack.isEnabled}');
  }

  Future<void> _onLocalAudioEnabled() async {
    final localAudioTrack = _room.localParticipant.localAudioTracks[0].localAudioTrack;
    await localAudioTrack.enable(!localAudioTrack.isEnabled);

    setState(() {
      var index = _participants.indexWhere((ParticipantWidget participant) => !participant.isRemote);
      if (index < 0) {
        return;
      }
      var participant = _participants[index];
      _participants.replaceRange(
        index,
        index + 1,
        [
          participant.copyWith(audioEnabled: localAudioTrack.isEnabled),
        ],
      );
    });

    _onAudioEnabledStreamController.add(
      ParticipantMediaEnabled(
        isEnabled: localAudioTrack.isEnabled,
      ),
    );

    Debug.log('onAudioEnabled: ${localAudioTrack.isEnabled}');
  }

  Future<void> _onHangup() async {
    Debug.log('onHangup');
    await _room.disconnect();
    Navigator.of(context).pop();
  }

  void _onSwitchCamera() {
    Debug.log('onSwitchCamera');
    _cameraCapturer.switchCamera();
  }

  void _onPersonAdd() {
    setState(() {
      if (_participants.length < 18) {
        _participants.insert(
          0,
          ParticipantWidget(
            id: (_participants.length + 1).toString(),
            child: Stack(
              children: <Widget>[
                const Placeholder(),
                Center(
                  child: Text(
                    (_participants.length + 1).toString(),
                    style: const TextStyle(
                      shadows: <Shadow>[
                        Shadow(
                          blurRadius: 3.0,
                          color: Color.fromARGB(255, 0, 0, 0),
                        ),
                        Shadow(
                          blurRadius: 8.0,
                          color: Color.fromARGB(255, 255, 255, 255),
                        ),
                      ],
                      fontSize: 80,
                    ),
                  ),
                ),
              ],
            ),
            isRemote: true,
            audioEnabled: true,
            videoEnabled: true,
            isDummy: true,
          ),
        );
      } else {
        PlatformAlertDialog(
          title: 'Maximum reached',
          content: 'Currently the lay-out can only render a maximum of 18 participants',
          defaultActionText: 'OK',
        ).show(context);
      }
    });
  }

  void _onPersonRemove() {
    Debug.log('onPersonRemove');
    var dummy = _participants.firstWhere((participant) => participant.isDummy, orElse: () => null);
    if (dummy != null) {
      setState(() {
        _participants.remove(dummy);
      });
    }
  }

  Widget _buildParticipants(BuildContext context, Size size) {
    final children = <Widget>[];

    if (_participants.length <= 2) {
      _buildOverlayLayout(context, size, children);
      return Stack(children: children);
    }

    void buildInCols(bool removeLocalBeforeChunking, bool moveLastOfEachRowToNextRow, int columns) {
      _buildLayoutInGrid(
        context,
        size,
        children,
        removeLocalBeforeChunking: removeLocalBeforeChunking,
        moveLastOfEachRowToNextRow: moveLastOfEachRowToNextRow,
        columns: columns,
      );
    }

    if (_participants.length <= 3) {
      buildInCols(true, false, 1);
    } else if (_participants.length == 5) {
      buildInCols(false, true, 2);
    } else if (_participants.length <= 6 || _participants.length == 8) {
      buildInCols(false, false, 2);
    } else if (_participants.length == 7 || _participants.length == 9) {
      buildInCols(true, false, 2);
    } else if (_participants.length == 10) {
      buildInCols(false, true, 3);
    } else if (_participants.length == 13 || _participants.length == 16) {
      buildInCols(true, false, 3);
    } else if (_participants.length <= 18) {
      buildInCols(false, false, 3);
    }

    return Column(
      children: children,
    );
  }

  void _buildOverlayLayout(BuildContext context, Size size, List<Widget> children) {
    if (_participants.isEmpty) {
      children.add(Container(
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ));
      return;
    }
    if (_participants.length == 1) {
      children.add(_buildNoiseBox());
    } else {
      final remoteParticipant = _participants.firstWhere((ParticipantWidget participant) => participant.isRemote, orElse: () => null);
      if (remoteParticipant != null) {
        children.add(remoteParticipant);
      }
    }

    final localParticipant = _participants.firstWhere((ParticipantWidget participant) => !participant.isRemote, orElse: () => null);
    if (localParticipant != null) {
      children.add(DraggablePublisher(
        child: localParticipant,
        availableScreenSize: size,
        onButtonBarVisible: _onButtonBarVisibleStreamController.stream,
      ));
    }
  }

  void _buildLayoutInGrid(BuildContext context, Size size, List<Widget> children, {bool removeLocalBeforeChunking = false, bool moveLastOfEachRowToNextRow = false, int columns = 2}) {
    ParticipantWidget localParticipant;
    if (removeLocalBeforeChunking) {
      localParticipant = _participants.firstWhere((ParticipantWidget participant) => !participant.isRemote, orElse: () => null);
      if (localParticipant != null) {
        _participants.remove(localParticipant);
      }
    }
    final chunkedParticipants = chunk(array: _participants, size: columns);
    if (localParticipant != null) {
      chunkedParticipants.last.add(localParticipant);
      _participants.add(localParticipant);
    }

    if (moveLastOfEachRowToNextRow) {
      for (var i = 0; i < chunkedParticipants.length - 1; i++) {
        var participant = chunkedParticipants[i].removeLast();
        chunkedParticipants[i + 1].insert(0, participant);
      }
    }

    for (final participantChunk in chunkedParticipants) {
      final rowChildren = <Widget>[];
      for (final participant in participantChunk) {
        rowChildren.add(
          Container(
            width: size.width / participantChunk.length,
            height: size.height / chunkedParticipants.length,
            child: participant,
          ),
        );
      }
      children.add(
        Container(
          height: size.height / chunkedParticipants.length,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: rowChildren,
          ),
        ),
      );
    }
  }

  NoiseBox _buildNoiseBox() {
    return NoiseBox(
      density: NoiseBoxDensity.xLow,
      backgroundColor: Colors.grey.shade900,
      child: Center(
        child: Container(
          color: Colors.black54,
          width: double.infinity,
          height: 40,
          child: Center(
            child: Text(
              'Waiting for another participant to connect to the room...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  List<List<T>> chunk<T>({@required List<T> array, @required int size}) {
    final result = <List<T>>[];
    if (array.isEmpty || size <= 0) {
      return result;
    }
    var first = 0;
    var last = size;
    final totalLoop = array.length % size == 0 ? array.length ~/ size : array.length ~/ size + 1;
    for (var i = 0; i < totalLoop; i++) {
      if (last > array.length) {
        result.add(array.sublist(first, array.length));
      } else {
        result.add(array.sublist(first, last));
      }
      first = last;
      last = last + size;
    }
    return result;
  }

  void _onShowBar() {
    setState(() {
      SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom, SystemUiOverlay.top]);
    });
    _onButtonBarVisibleStreamController.add(true);
  }

  void _onHideBar() {
    setState(() {
      SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    });
    _onButtonBarVisibleStreamController.add(false);
  }

  Future<void> _wakeLock(bool enable) async {
    try {
      return await (enable ? Wakelock.enable() : Wakelock.disable());
    } catch (err) {
      Debug.log('Unable to change the Wakelock and set it to $enable');
      Debug.log(err);
    }
  }
}
